//
//  TableViewController.swift
//  Lab1
//
//  Created by Fall2019 on 9/12/19.
//  Copyright © 2019 JBRT. All rights reserved.
//

import UIKit

class TableViewController: UITableViewController {
    
    var articles = [Article]()
    var articleCount = Double()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if Int(self.articleCount) > self.articles.count {
            self.articleCount = Double(self.articles.count)
            return self.articles.count + 1
        }
        else {
            return Int(self.articleCount) + 1
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "tableHeader", for: indexPath)
            cell.textLabel!.text = "\(Int(self.articleCount)) news articles found"
            
            return cell
        }
            
        let imageUrl = URL(string: articles[indexPath.row - 1].urlToImage)
        var data : Data? = nil
        
        if let imageUrl = imageUrl {
            data = try? Data(contentsOf: imageUrl)
        }
        
        if let imageData = data {
            let cell = tableView.dequeueReusableCell(withIdentifier: "imageTableRow", for: indexPath)
            cell.imageView!.image = UIImage(data: imageData)
            cell.textLabel!.text = self.articles[indexPath.row - 1].title
            
            return cell
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "simpleTableRow", for: indexPath)
            cell.textLabel!.text = self.articles[indexPath.row - 1].title
            
            return cell
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueToNews"{
            let cell = sender as! UITableViewCell
            let indexPath = tableView.indexPathForSelectedRow
            
            let vc = segue.destination as! NewsViewController
            vc.image = cell.imageView!.image
            vc.article = self.articles[indexPath!.row - 1]
        }
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

}
