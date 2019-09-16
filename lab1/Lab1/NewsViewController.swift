//
//  NewsViewController.swift
//  Lab1
//
//  Created by Fall2019 on 9/15/19.
//  Copyright © 2019 JBRT. All rights reserved.
//

import UIKit

class NewsViewController: UIViewController, UIScrollViewDelegate {
    
    var article : Article? = nil
    var image : UIImage? = nil
    var imageView : UIImageView? = nil
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var scrollHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var newsTitle: UILabel!
    @IBOutlet weak var newsContent: UITextView!
    
    @IBOutlet weak var newsSource: UILabel!
    @IBOutlet weak var newsAuthor: UILabel!
    @IBOutlet weak var newsPublishedAt: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let image = self.image {
            self.imageView = UIImageView(image: image)
            
            self.scrollView.addSubview(self.imageView!)
            self.scrollView.contentSize = image.size
            self.scrollView.minimumZoomScale = 0.1
            self.scrollView.delegate = self
        }
        else {
            scrollHeightConstraint.isActive = false
            self.scrollView.isHidden = true
        }
        
        self.newsTitle.text = self.article!.title
        self.newsContent.text = self.article!.content
        
        self.newsSource.text = "Source: \(self.article!.source)"
        self.newsPublishedAt.text = "Published: \(self.article!.publishedAt)"
        
        if self.article!.author.trimmingCharacters(in: .whitespaces).isEmpty {
            self.newsAuthor.text = "Author: Unkown"
        }
        else {
            self.newsAuthor.text = "Author: \(self.article!.author)"
        }
        
        self.newsSource.isHidden = true
        self.newsAuthor.isHidden = true
        self.newsPublishedAt.isHidden = true
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }

    @IBAction func segmentedControlPressed(_ sender: UISegmentedControl) {
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            self.newsSource.isHidden = true
            self.newsAuthor.isHidden = true
            self.newsPublishedAt.isHidden = true

            self.scrollView.isHidden = false
            self.newsTitle.isHidden = false
            self.newsContent.isHidden = false
        case 1:
            self.scrollView.isHidden = true
            self.newsTitle.isHidden = true
            self.newsContent.isHidden = true
            
            self.newsSource.isHidden = false
            self.newsAuthor.isHidden = false
            self.newsPublishedAt.isHidden = false
        default: break
        }
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
