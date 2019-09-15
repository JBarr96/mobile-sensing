//
//  ViewController.swift
//  Lab1
//
//  Created by Johnathan Barr on 9/3/19.
//  Copyright © 2019 JBRT. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var articleCountLabel: UILabel!
    @IBOutlet weak var searchField: UITextField!
    @IBOutlet weak var dateRangePicker: UIPickerView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var collectionViewSwitch: UISwitch!
    
    
    var articleCount = 10
    let dataSource = ["Today", "Past Week", "Past 2 Weeks", "Past Month"]
    var articles = [Article]()
    var sliderValue = 0.0;
    var collectionView = false;

    override func viewDidLoad() {
        super.viewDidLoad()
        self.articleCountLabel.text = "Number of articles: \(articleCount)"
        self.collectionViewSwitch.setOn(false, animated: true)
        self.dateRangePicker.dataSource = self
        self.dateRangePicker.delegate = self
        self.searchField.delegate = self
        
        _ = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.changeTitleColor), userInfo: nil, repeats: true)
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
    
    @IBAction func collectionViewSwitchDidChange(_ sender: UISwitch) {
        if sender.isOn {
            self.collectionView = true
        }
        else{
            self.collectionView = false
        }
    }
    
    @IBAction func sliderDidChange(_ sender: UISlider) {
        self.sliderValue = Double(sender.value)
        self.titleLabel.textColor = UIColor(hue: CGFloat(self.sliderValue), saturation: 1, brightness: 1, alpha: 1.0)
    }
    
    @IBAction func searchGo(_ sender: Any) {
        if (self.searchField!.text != nil && self.searchField!.text!.trimmingCharacters(in: .whitespacesAndNewlines) != ""){
            let selectedVal = pickerView(self.dateRangePicker, titleForRow: self.dateRangePicker.selectedRow(inComponent: 0), forComponent: 0)
            
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
            
            let requestUrl = "https://newsapi.org/v2/top-headlines?q=\(self.searchField.text!.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: " ", with: "+"))&from=\(dateString)&sortBy=publishedAt&apiKey=3df038d929f24dbabf7bdf5b22fd38c8"
            
            self.articles = makeUrlRequest(requestString: requestUrl)
            
            if collectionView{
                self.performSegue(withIdentifier: "segueToCollectionView", sender: self)
            }
            else {
                self.performSegue(withIdentifier: "segueToTableView", sender: self)
            }
        }
        else{
            let modal = Modal()
            self.view.addSubview(modal)
        }
    }
    
    @objc func changeTitleColor(){
        self.titleLabel.shadowColor = .random
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func makeUrlRequest(requestString: String) -> [Article] {
        let url = URL(string: requestString)!
        var responseData = Data()
        
        let semaphore = DispatchSemaphore(value: 0)
        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
            guard let data = data else { return }
            responseData = data
            semaphore.signal()
        }
        
        task.resume()
        semaphore.wait()
        let responseJson = try? JSONSerialization.jsonObject(with: responseData, options: [])
        
        var articleArray = [Article]()
        
        if let responseDict = responseJson as? [String: Any] {
            if let articles = responseDict["articles"] as! [Any]? {
                for article in articles {
                    let articleDict = article as! [String: Any]
                    let source: String = {
                        if !(articleDict["source"]! is NSNull) {
                            return ((articleDict["source"]! as! Dictionary)["name"]!) as String
                        } else {
                            return ""
                        }
                    }()
                    let author: String = {
                        if !(articleDict["author"]! is NSNull) {
                            return articleDict["author"]! as! String
                        } else {
                            return ""
                        }
                    }()
                    let title: String = {
                        if !(articleDict["title"]! is NSNull) {
                            return articleDict["title"]! as! String
                        } else {
                            return ""
                        }
                    }()
                    let description: String = {
                        if !(articleDict["description"]! is NSNull) {
                            return articleDict["description"]! as! String
                        } else {
                            return ""
                        }
                    }()
                    let url: String = {
                        if !(articleDict["url"]! is NSNull) {
                            return articleDict["url"]! as! String
                        } else {
                            return ""
                        }
                    }()
                    let urlToImage: String = {
                        if !(articleDict["urlToImage"]! is NSNull) {
                            return articleDict["urlToImage"]! as! String
                        } else {
                            return ""
                        }
                    }()
                    let publishedAt: String = {
                        if !(articleDict["publishedAt"]! is NSNull) {
                            return articleDict["publishedAt"]! as! String
                        } else {
                            return ""
                        }
                    }()
                    let content: String = {
                        if !(articleDict["content"]! is NSNull) {
                            return articleDict["content"]! as! String
                        } else {
                            return ""
                        }
                    }()

                    articleArray.append(Article(source: source, author: author, title: title, description: description, url: url, urlToImage: urlToImage, publishedAt: publishedAt, content: content))
                }
            }
        }
        return articleArray
    }
    
    func convertToDictionary(text: String) -> Any? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: [])
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueToTableView"{
            let vc = segue.destination as! TableViewController
            vc.articles = self.articles
            vc.articleCount = Double(self.articleCount)
        }
        else if segue.identifier == "segueToCollectionView"{
            let vc = segue.destination as! CollectionViewController
            vc.articles = self.articles
            vc.articleCount = Double(self.articleCount)
        }
    }
        
}

extension UIColor {
    static var random: UIColor {
        return UIColor(red: .random(in: 0...1),
                       green: .random(in: 0...1),
                       blue: .random(in: 0...1),
                       alpha: 1.0)
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
