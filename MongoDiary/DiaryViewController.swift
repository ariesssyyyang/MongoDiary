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

    var diaryList: [[String: String]] = [] {
        didSet {
            self.tableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Hot Pot"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addBarButtonTapped))
        retrieveDocuments()
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
            let textFields = editAlert.textFields
            if let restaurant = textFields?[0].text, let mrt = textFields?[1].text {
                self.createDocument(restaurant: restaurant, mrt: mrt)
            }
            self.retrieveDocuments()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        editAlert.addAction(cancelAction)
        editAlert.addAction(saveAction)
        self.present(editAlert, animated: true, completion: nil)
    }

    func createDocument(restaurant: String, mrt: String) {
        let newDiary: Document = ["_id": randomString(), "restaurant": restaurant, "mrt": mrt]
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

    func retrieveDocuments() {
        var items: [[String: String]] = []
        do {
            let localMongoClient = try stitchClient.serviceClient(
                fromFactory: mongoClientFactory
            )
            let devCollection = try localMongoClient.db("diary_db").collection("diary")
            try devCollection.find().forEach { (diary) in
                guard
                    let id = diary["_id"] as? String,
                    let restaurant = diary["restaurant"] as? String,
                    let mrt = diary["mrt"] as? String
                else { return }
                items.append(["id": id, "restaurant": restaurant, "mrt": mrt])
            }
        } catch {
            debugPrint("Failed to initialize MongoDB Stitch iOS SDK: \(error)")
        }
        self.diaryList = items
    }

    func deleteDocument(by id: String) {
        do {
            let localMongoClient = try stitchClient.serviceClient(
                fromFactory: mongoClientFactory
            )
            let devCollection = try localMongoClient.db("diary_db").collection("diary")
            try devCollection.deleteOne(["_id": id])
            self.retrieveDocuments()
        } catch {
            debugPrint("Failed to initialize MongoDB Stitch iOS SDK: \(error)")
        }
    }

    func deleteAllDocuments(query: Document) {
        do {
            let localMongoClient = try stitchClient.serviceClient(
                fromFactory: mongoClientFactory
            )
            let devCollection = try localMongoClient.db("diary_db").collection("diary")
            try devCollection.deleteMany(query)
        } catch {
            debugPrint("Failed to initialize MongoDB Stitch iOS SDK: \(error)")
        }
    }

    private func randomString() -> String {
        return UUID().uuidString.replacingOccurrences(of: "-", with: "")
    }
}

extension DiaryTableViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return diaryList.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        cell.textLabel?.text = "Restaurant: \(diaryList[indexPath.row]["restaurant"] ?? "not available")"
        cell.detailTextLabel?.text = "MRT: \(diaryList[indexPath.row]["mrt"] ?? "n/a")"
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            guard let id = diaryList[indexPath.row]["id"] else { return }
            diaryList.remove(at: indexPath.row)
            self.deleteDocument(by: id)
        }
    }
}
