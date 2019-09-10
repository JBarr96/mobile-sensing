//
//  ViewController.swift
//  Lab1
//
//  Created by Johnathan Barr on 9/3/19.
//  Copyright © 2019 JBRT. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITextFieldDelegate, UIGestureRecognizerDelegate {

    @IBOutlet weak var searchField: UITextField!
    @IBOutlet weak var searchButton: UIImageView!
    @IBOutlet weak var articleCountLabel: UILabel!
    @IBOutlet weak var dateRangePicker: UIPickerView!
    
    var articleCount = 10
    let dataSource = ["Today", "Past Week", "Past 2 Weeks", "Past Month"]
    var response = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        self.articleCountLabel.text = "Number of articles: \(articleCount)"
        self.dateRangePicker.dataSource = self
        self.dateRangePicker.delegate = self
        self.searchField.delegate = self

        let UITapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tappedImage))
        view.addGestureRecognizer(UITapRecognizer)
    }

    var previousValue = 0
    @IBAction func articleStepper(_ sender: UIStepper) {
        if Int(sender.value) > previousValue {
            articleCount += 1
        } else {
            articleCount -= 1
            if articleCount < 0 {
                articleCount = 0
            }
        }
        sender.value = 0.0
        self.articleCountLabel.text = "Number of articles: \(articleCount)"
    }
    
    @objc func tappedImage() {
        var selectedVal = pickerView(self.dateRangePicker, titleForRow: self.dateRangePicker.selectedRow(inComponent: 0), forComponent: 0)

        var selectedDate = Date()
        switch selectedVal {
            case "Today":
                selectedDate = Date()
            case "Past Week":
                selectedDate = Date(timeIntervalSinceNow: -604800)
            case "Past 2 Weeks":
                selectedDate = Date(timeIntervalSinceNow: -1209600)
            case "Past Month":
                selectedDate = Date(timeIntervalSinceNow: -2592000)
            default:
                selectedDate = Date()
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: selectedDate)
        
        let requestUrl = "https://newsapi.org/v2/everything?q=\(self.searchField.text!.trimmingCharacters(in: .whitespacesAndNewlines))&from=\(dateString)&sortBy=publishedAt&country=us&apiKey=3df038d929f24dbabf7bdf5b22fd38c8"
        print(requestUrl)
        
        self.response = makeUrlRequest(requestString: requestUrl)
        
        print("Button tapped")
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // TODO: return JSON serialized object instead of string
    func makeUrlRequest(requestString: String) -> String {
        let url = URL(string: requestString)!
        var responseString = ""
        
        let semaphore = DispatchSemaphore(value: 0)
        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
            guard let data = data else { return }
            responseString = String(data: data, encoding: .utf8)!
            semaphore.signal()
        }
        
        task.resume()
        semaphore.wait()
        return responseString
    }
    
}

extension ViewController: UIPickerViewDelegate, UIPickerViewDataSource{
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return dataSource.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return dataSource[row]
    }
}
