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
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var scrollHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var newsTitle: UILabel!
    @IBOutlet weak var newsTextBody: UILabel!
    
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
        }
        
        self.newsTitle.text = article!.title
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
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
