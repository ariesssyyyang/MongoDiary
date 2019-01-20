//
//  ViewController.swift
//  MongoDiary
//
//  Created by Aries Yang on 2019/1/5.
//  Copyright © 2019 Aries Yang. All rights reserved.
//

import UIKit
import StitchCore
import StitchLocalMongoDBService

class DiaryTableViewController: UITableViewController {

    private lazy var stitchClient = Stitch.defaultAppClient!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Hot Pot"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addBarButtonTapped))
    }

    @objc func addBarButtonTapped() {
        let editAlert = UIAlertController(title: "New", message: "What's new?", preferredStyle: .alert)
        editAlert.addTextField { (restaurantTextField) in
            restaurantTextField.placeholder = "restaurant name..."
        }
        editAlert.addTextField { (mrtTextField) in
            mrtTextField.placeholder = "MRT station..."
        }
        let saveAction = UIAlertAction(title: "Save", style: .default) { (_) in
            // - TODO: Create document
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        editAlert.addAction(cancelAction)
        editAlert.addAction(saveAction)
        self.present(editAlert, animated: true, completion: nil)
    }

    func createDocument(restaurant: String, mrt: String) {
        let newDiary: Document = ["restaurant": restaurant, "mrt": mrt]
        do {
            let localMongeClient = try stitchClient.serviceClient(
                fromFactory: mongoClientFactory
            )
            let diaryCollection = try localMongeClient.db("diary_db").collection("diary")
            _ = try diaryCollection.insertOne(newDiary)
        } catch {
            debugPrint("Failed to initialize MongoDB Stitch iOS SDK: \(error)")
        }
    }
}

extension DiaryTableViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        cell.textLabel?.text = "Row: \(indexPath.row)"
        cell.detailTextLabel?.text = "Section: \(indexPath.section)"
        return cell
    }
}
