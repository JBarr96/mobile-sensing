//
//  OpenCVBridge.m
//  LookinLive
//
//  Created by Eric Larson on 8/27/15.
//  Copyright (c) 2015 Eric Larson. All rights reserved.
//

#import "OpenCVBridge.hh"

#define RED_READINGS_BUFFER_SIZE 310


using namespace cv;

@interface OpenCVBridge()
@property (nonatomic) cv::Mat image;
@property (strong,nonatomic) CIImage* frameInput;
@property (nonatomic) CGRect bounds;
@property (nonatomic) CGAffineTransform transform;
@property (nonatomic) CGAffineTransform inverseTransform;
@property (atomic) cv::CascadeClassifier classifier;

@property float* redReadingsHistory;
@property float* redGraphDataArray;
@property int index;
@property bool haveReadingsBeenCollectedOnce;
@end

@implementation OpenCVBridge



#pragma mark ===Write Your Code Here===
// alternatively you can subclass this class and override the process image function


#pragma mark Define Custom Functions Here
-(float*)processImage{
    cv::Mat frame_gray,image_copy;
    
    Scalar avgPixelIntensity;
    
    // average the pixel color values
    cvtColor(_image, image_copy, CV_BGRA2BGR); // get rid of alpha for processing
    avgPixelIntensity = cv::mean( image_copy );
    
    // push the redGraphDataArray 1 element towards the right
    for(int i = 129; i > 0; i--) {
        self.redGraphDataArray[i] = self.redGraphDataArray[i - 1];
    }
    
    // set the first element to new Red value reading
    self.redGraphDataArray[0] = avgPixelIntensity.val[0];
    
    // store the new Red value in bigger buffer
    self.redReadingsHistory[self.index] = avgPixelIntensity.val[0];
    
    // search for maximas and minimas in the values of red
    if(self.index % 30 == 0 && self.haveReadingsBeenCollectedOnce) {
        // arrays storing locations of maximas and minimas
        bool peaks[RED_READINGS_BUFFER_SIZE];
        bool troughs[RED_READINGS_BUFFER_SIZE];
        
        // initialize maximas and minimas arrays
        for(int i = 0; i < RED_READINGS_BUFFER_SIZE; i++) {
            peaks[i] = false;
            troughs[i] = false;
        }
        
        // set window size for maximas and minimas search
        int windowSize = 10;
        
        // go through our red values buffer with a sliding window
        for(int i = 5; i < RED_READINGS_BUFFER_SIZE - 5 - windowSize; i++) {
            float windowMax = 0;
            float windowMin = 256;
            
            int posMax = 0;
            int posMin = 0;
            
            // loop the size of the sliding window
            for(int j = i; j < i + windowSize; j++) {
                if(self.redReadingsHistory[j] > windowMax) {
                    windowMax = self.redReadingsHistory[j];
                    posMax = j;
                }
                
                if(self.redReadingsHistory[j] < windowMin) {
                    windowMin = self.redReadingsHistory[j];
                    posMin = j;
                }
            }
            
            // check if we found a max
            if(posMax == i + windowSize / 2) {
                peaks[posMax] = true;
            }
            
            // check if we found a min
            if(posMin == i + windowSize / 2) {
                troughs[posMin] = true;
            }
        }
        
        int heartBeatCount = 0;
        bool peakLastSeen = false;
        bool troughLastSeen = true;
        
        // count the number of heart beats in the collected data
        for(int i = 5; i < RED_READINGS_BUFFER_SIZE - 5; i++) {
            // if last time we saw a peak and now we're at a trough
            // then increase the number of heart beats
            if(peakLastSeen && troughs[i]) {
                heartBeatCount++;
                
                peakLastSeen = false;
                troughLastSeen = true;
            }
            
            // if last time we saw a trough and now we're at a peak
            if(troughLastSeen && peaks[i]) {
                peakLastSeen = true;
                troughLastSeen = false;
            }
        }
        
        // convert the number of heart beats to heart beats per minute
        self.heartRate = heartBeatCount * (60 * 30 / (RED_READINGS_BUFFER_SIZE - 10));
    }
    
    // increment index
    self.index++;
    if(self.index == RED_READINGS_BUFFER_SIZE) {
        self.haveReadingsBeenCollectedOnce = true;
        self.index = 0;
    }
    
    // return pointer to the redGraphDataArray for graphing purposes
    return self.redGraphDataArray;
}


#pragma mark ====Do Not Manipulate Code below this line!====
-(void)setTransforms:(CGAffineTransform)trans{
    self.inverseTransform = trans;
    self.transform = CGAffineTransformInvert(trans);
}

-(void)loadHaarCascadeWithFilename:(NSString*)filename{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:filename ofType:@"xml"];
    self.classifier = cv::CascadeClassifier([filePath UTF8String]);
}

-(instancetype)init{
    self = [super init];
    
    if(self != nil){
        self.transform = CGAffineTransformMakeRotation(M_PI_2);
        self.transform = CGAffineTransformScale(self.transform, -1.0, 1.0);
        
        self.inverseTransform = CGAffineTransformMakeScale(-1.0,1.0);
        self.inverseTransform = CGAffineTransformRotate(self.inverseTransform, -M_PI_2);
        
        // initialize variables used by processImage
        self.redGraphDataArray = (float*) malloc(130 * sizeof(float));
        self.redReadingsHistory = (float*) malloc(RED_READINGS_BUFFER_SIZE * sizeof(float));
        
        for(int i = 0; i < 130; i++) {
            self.redGraphDataArray[i] = 0;
        }
        
        for(int i = 0; i < RED_READINGS_BUFFER_SIZE; i++) {
            self.redReadingsHistory[i] = 0;
        }

        self.index = 0;
        self.heartRate = 0;
        self.haveReadingsBeenCollectedOnce = false;
    }
    return self;
}

#pragma mark Bridging OpenCV/CI Functions
// code manipulated from
// http://stackoverflow.com/questions/30867351/best-way-to-create-a-mat-from-a-ciimage
// http://stackoverflow.com/questions/10254141/how-to-convert-from-cvmat-to-uiimage-in-objective-c


-(void) setImage:(CIImage*)ciFrameImage
      withBounds:(CGRect)faceRectIn
      andContext:(CIContext*)context{
    
    CGRect faceRect = CGRect(faceRectIn);
    faceRect = CGRectApplyAffineTransform(faceRect, self.transform);
    ciFrameImage = [ciFrameImage imageByApplyingTransform:self.transform];
    
    
    //get face bounds and copy over smaller face image as CIImage
    //CGRect faceRect = faceFeature.bounds;
    _frameInput = ciFrameImage; // save this for later
    _bounds = faceRect;
    CIImage *faceImage = [ciFrameImage imageByCroppingToRect:faceRect];
    CGImageRef faceImageCG = [context createCGImage:faceImage fromRect:faceRect];
    
    // setup the OPenCV mat fro copying into
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(faceImageCG);
    CGFloat cols = faceRect.size.width;
    CGFloat rows = faceRect.size.height;
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels
    _image = cvMat;
    
    // setup the copy buffer (to copy from the GPU)
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                // Pointer to backing data
                                                    cols,                      // Width of bitmap
                                                    rows,                      // Height of bitmap
                                                    8,                         // Bits per component
                                                    cvMat.step[0],             // Bytes per row
                                                    colorSpace,                // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    // do the copy
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), faceImageCG);
    
    // release intermediary buffer objects
    CGContextRelease(contextRef);
    CGImageRelease(faceImageCG);
    
}

-(CIImage*)getImage{
    
    // convert back
    // setup NS byte buffer using the data from the cvMat to show
    NSData *data = [NSData dataWithBytes:_image.data
                                  length:_image.elemSize() * _image.total()];
    
    CGColorSpaceRef colorSpace;
    if (_image.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    // setup buffering object
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // setup the copy to go from CPU to GPU
    CGImageRef imageRef = CGImageCreate(_image.cols,                                     // Width
                                        _image.rows,                                     // Height
                                        8,                                              // Bits per component
                                        8 * _image.elemSize(),                           // Bits per pixel
                                        _image.step[0],                                  // Bytes per row
                                        colorSpace,                                     // Colorspace
                                        kCGImageAlphaNone | kCGBitmapByteOrderDefault,  // Bitmap info flags
                                        provider,                                       // CGDataProviderRef
                                        NULL,                                           // Decode
                                        false,                                          // Should interpolate
                                        kCGRenderingIntentDefault);                     // Intent
    
    // do the copy inside of the object instantiation for retImage
    CIImage* retImage = [[CIImage alloc]initWithCGImage:imageRef];
    CGAffineTransform transform = CGAffineTransformMakeTranslation(self.bounds.origin.x, self.bounds.origin.y);
    retImage = [retImage imageByApplyingTransform:transform];
    retImage = [retImage imageByApplyingTransform:self.inverseTransform];
    
    // clean up
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return retImage;
}

-(CIImage*)getImageComposite{
    
    // convert back
    // setup NS byte buffer using the data from the cvMat to show
    NSData *data = [NSData dataWithBytes:_image.data
                                  length:_image.elemSize() * _image.total()];
    
    CGColorSpaceRef colorSpace;
    if (_image.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    // setup buffering object
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // setup the copy to go from CPU to GPU
    CGImageRef imageRef = CGImageCreate(_image.cols,                                     // Width
                                        _image.rows,                                     // Height
                                        8,                                              // Bits per component
                                        8 * _image.elemSize(),                           // Bits per pixel
                                        _image.step[0],                                  // Bytes per row
                                        colorSpace,                                     // Colorspace
                                        kCGImageAlphaNone | kCGBitmapByteOrderDefault,  // Bitmap info flags
                                        provider,                                       // CGDataProviderRef
                                        NULL,                                           // Decode
                                        false,                                          // Should interpolate
                                        kCGRenderingIntentDefault);                     // Intent
    
    // do the copy inside of the object instantiation for retImage
    CIImage* retImage = [[CIImage alloc]initWithCGImage:imageRef];
    // now apply transforms to get what the original image would be inside the Core Image frame
    CGAffineTransform transform = CGAffineTransformMakeTranslation(self.bounds.origin.x, self.bounds.origin.y);
    retImage = [retImage imageByApplyingTransform:transform];
    CIFilter* filt = [CIFilter filterWithName:@"CISourceAtopCompositing"
                          withInputParameters:@{@"inputImage":retImage,@"inputBackgroundImage":self.frameInput}];
    retImage = filt.outputImage;
    
    // clean up
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    retImage = [retImage imageByApplyingTransform:self.inverseTransform];
    
    return retImage;
}

-(void)dealloc {
    free(self.redGraphDataArray);
    free(self.redReadingsHistory);
}


@end
