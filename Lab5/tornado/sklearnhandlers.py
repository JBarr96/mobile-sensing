#!/usr/bin/python

import time

from pymongo import MongoClient
import tornado.web

from tornado.web import HTTPError
from tornado.httpserver import HTTPServer
from tornado.ioloop import IOLoop
from tornado.options import define, options
from tornado import gen

from basehandler import BaseHandler

from sklearn.neighbors import KNeighborsClassifier
import pickle
from bson.binary import Binary
import json
import numpy as np

import turicreate as tc
from os.path import basename
tc.config.set_num_gpus(-1)

from scipy.io import wavfile as wf


class PrintHandlers(BaseHandler):
    def get(self):
        '''Write out to screen the handlers used
        This is a nice debugging example!
        '''
        self.set_header("Content-Type", "application/json")
        self.write(self.application.handlers_string.replace('),','),\n'))

class UploadLabeledDatapointHandler(BaseHandler):
    def post(self):
        '''Save data point and class label to database
        '''
        # get data from POST body
        data = json.loads(self.request.body.decode("utf-8"))

        vals = data['feature']
        fvals = [float(val) for val in vals]
        label = data['label']

        # create file name using current epoch time 
        file_name = f'audio-sample-{int(time.time())}.wav'

        # save the float array fvals to disk as a wav file
        wf.write(f'../data/audio/{file_name}', 44100, np.array(fvals))

        # save audio label to mongo db
        dbid = self.db.labeledinstances.insert(
            {
                "filename": file_name,
                "label": label
            }
        )

        self.write_json(
            {
                "id":str(dbid),
                "feature":
                    [
                        str(len(fvals))+" Points Received",
                        "min of: " +str(min(fvals)),
                        "max of: " +str(max(fvals))
                    ],
                "label": label,
                "filename": file_name
            }
        )

class UpdateModelForDatasetId(BaseHandler):
    @gen.coroutine
    def post(self):
        '''Train a new model (or update) for given dataset ID
        '''
        # get data from POST body
        data = json.loads(self.request.body.decode("utf-8"))
        ml_model_type  = data['ml_model_type']

        # load the audio data
        audio_data = tc.load_audio('../data/audio')

        audio_file_names = []
        audio_labels = []

        # load the audio file names and labels from mongo
        for a in self.db.labeledinstances.find({}): 
            audio_file_names.append(a['filename'])
            audio_labels.append(a['label'])
            
        meta_data = tc.SFrame(
            {
                'filename': audio_file_names,
                'label': audio_labels
            }
        )

        # join the audio data and the meta data.
        audio_data['filename'] = audio_data['path'].apply(lambda p: basename(p))
        audio_data = audio_data.join(meta_data)

        # fit the model to the data
        acc = -1
        if audio_labels:
            acc = yield self.create_ml_model(audio_data, ml_model_type)

        # send back the resubstitution accuracy
        self.write_json({"resubAccuracy":acc})

    async def create_ml_model(self, audio_data, ml_model_type):
        model = None

        # create the model
        if ml_model_type == 0:
            model = tc.sound_classifier.create(audio_data,
                                                target='label',
                                                feature='audio',
                                                max_iterations=2500)
        elif ml_model_type == 1:
            model = tc.sound_classifier.create(audio_data,
                                                target='label',
                                                feature='audio',
                                                max_iterations=2500,
                                                custom_layer_sizes=[200, 200])
        elif ml_model_type == 2:
            model = tc.sound_classifier.create(audio_data,
                                                target='label',
                                                feature='audio',
                                                max_iterations=2500,
                                                custom_layer_sizes=[100, 100, 50, 50])
        elif ml_model_type == 3:
            model = tc.sound_classifier.create(audio_data,
                                                target='label',
                                                feature='audio',
                                                max_iterations=2500,
                                                custom_layer_sizes=[50, 50, 100, 100])

        # generate an SArray of predictions from the test set
        predictions = model.predict(audio_data)

        # evaluate the model on the training data
        acc = model.evaluate(audio_data)['accuracy']

        model.save(f'../data/models/SoundClassification-{ml_model_type}.model')
        model.export_coreml('../data/core-ml-models/SoundClassification.mlmodel')

        return acc

class PredictOneFromDatasetId(BaseHandler):
    def post(self):
        '''Predict the class of a sent feature vector
        '''
        # get data from POST body
        data = json.loads(self.request.body.decode("utf-8"))    

        ml_model_type  = data['ml_model_type']

        vals = data['feature']
        fvals = [float(val) for val in vals]

        # save audio sample to disk as a wav file
        wf.write(f'../data/temp.wav', 44100, np.array(fvals))

        # load the model from the disk
        loaded_model = tc.load_model(f'../data/models/SoundClassification-{ml_model_type}.model')

        # load the audio data
        audio_data = tc.load_audio('../data/temp.wav')

        predictions = loaded_model.predict(audio_data)
        self.write_json({"prediction": predictions[0]})
