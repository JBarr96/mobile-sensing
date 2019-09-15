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

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        print(articleCount)
        return self.articles.count + 1
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TableHeader", for: indexPath)
            cell.textLabel!.text = "\(self.articles.count) news articles found:"
            
            return cell
        }
            
        let imageUrl = URL(string: articles[indexPath.row - 1].urlToImage)
        var data : Data? = nil
        
        if let imageUrl = imageUrl {
            data = try? Data(contentsOf: imageUrl)
        }
        
        if let imageData = data {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ImageTableRow", for: indexPath)
            cell.imageView!.image = UIImage(data: imageData)
            cell.textLabel!.text = self.articles[indexPath.row - 1].title
            
            return cell
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SimpleTableRow", for: indexPath)
            cell.textLabel!.text = self.articles[indexPath.row - 1].title
            
            return cell
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
