//
//  CollectionViewController.swift
//  Lab1
//
//  Created by Johnathan Barr on 9/15/19.
//  Copyright © 2019 JBRT. All rights reserved.
//

import UIKit

private let reuseIdentifier = "ArticleCollectCell"

class CollectionViewController: UICollectionViewController {
    
    var articles = [Article]()
    var articleCount = Double()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        // self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        // Do any additional setup after loading the view.
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueToNewsFromCollection"{
            let cell = sender as! CollectionViewCell
            let indexPath = collectionView.indexPath(for: cell)
            
            let vc = segue.destination as! NewsViewController
            vc.image = cell.cellImage!.image
            vc.article = self.articles[indexPath!.row]
        }
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        if Int(articleCount) < articles.count{
            return Int(articleCount)
        }
        else{
            return articles.count
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! CollectionViewCell
    
        cell.tileLabel.text = self.articles[indexPath.item].title
        
        let imageUrl = URL(string: articles[indexPath.row].urlToImage)
        var data : Data? = nil
        
        if let imageUrl = imageUrl {
            data = try? Data(contentsOf: imageUrl)
        }
        
        if let imageData = data {
            cell.cellImage!.image = UIImage(data: imageData)
        }
        else{
            cell.cellImage!.image = UIImage(named: "no-image-available.png")
        }
    
        return cell
    }

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

}
