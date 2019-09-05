//
//  ViewController.swift
//  Lab1
//
//  Created by Johnathan Barr on 9/3/19.
//  Copyright © 2019 JBRT. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIGestureRecognizerDelegate {

    @IBOutlet weak var searchField: UITextField!
    @IBOutlet weak var searchButton: UIImageView!
    @IBOutlet weak var articleCountLabel: UILabel!
    @IBOutlet weak var dateRangePicker: UIPickerView!

    var articleCount = 10
    let dataSource = ["Today", "Past Week", "Past 2 Weeks", "Past Month"]

    override func viewDidLoad() {
        super.viewDidLoad()
        self.articleCountLabel.text = "Number of articles: \(articleCount)"
        dateRangePicker.dataSource = self
        dateRangePicker.delegate = self

        let UITapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tappedImage))
        view.addGestureRecognizer(UITapRecognizer)
//        UITapRecognizer.delegate = self
//        self.searchButton.addGestureRecognizer(UITapRecognizer)
//        self.searchButton.isUserInteractionEnabled = true
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
        print("Button tapped")
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
