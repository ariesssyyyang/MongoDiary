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
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Destroy", style: .plain, target: self, action: #selector(handleDestroy))
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

    @objc func handleDestroy() {
        let destroyAlert = UIAlertController(title: "WARNING", message: "Are you sure you want to delete all?", preferredStyle: .alert)
        let yesAction = UIAlertAction(title: "YES", style: .default) { (_) in
            self.deleteAllDocuments(with: [:])
            self.retrieveDocuments()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        destroyAlert.addAction(yesAction)
        destroyAlert.addAction(cancelAction)
        self.present(destroyAlert, animated: true, completion: nil)
    }

    func createDocument(restaurant: String, mrt: String) {
        do {
            let jsonData = try JSONEncoder().encode(["_id": randomString(), "restaurant": restaurant, "mrt": mrt])
            let localMongeClient = try stitchClient.serviceClient(
                fromFactory: mongoClientFactory
            )
            let diaryCollection = try localMongeClient.db("diary_db").collection("diary")
            _ = try diaryCollection.insertOne(Document(fromJSON: jsonData))
        } catch {
            debugPrint("Failed to initialize MongoDB Stitch iOS SDK: \(error)")
        }
    }

    func updateDocument(by id: String, with body: Document) {
        do {
            let localMongoClient = try stitchClient.serviceClient(
                fromFactory: mongoClientFactory
            )
            let diaryCollection = try localMongoClient.db("diary_db").collection("diary")
            try diaryCollection.updateOne(filter: ["_id": id], update: ["$set": body])
            self.retrieveDocuments()
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
            let diaryCollection = try localMongoClient.db("diary_db").collection("diary")
            try diaryCollection.find().forEach { (diary) in
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
            let diaryCollection = try localMongoClient.db("diary_db").collection("diary")
            try diaryCollection.deleteOne(["_id": id])
            self.retrieveDocuments()
        } catch {
            debugPrint("Failed to initialize MongoDB Stitch iOS SDK: \(error)")
        }
    }

    func deleteAllDocuments(with query: Document) {
        do {
            let localMongoClient = try stitchClient.serviceClient(
                fromFactory: mongoClientFactory
            )
            let diaryCollection = try localMongoClient.db("diary_db").collection("diary")
            try diaryCollection.deleteMany(query)
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
        cell.textLabel?.text = diaryList[indexPath.row]["restaurant"] ?? "not available"
        cell.detailTextLabel?.text = diaryList[indexPath.row]["mrt"] ?? "n/a"
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

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let diary = diaryList[indexPath.row]
        guard
            let id = diary["id"],
            let restaurant = diary["restaurant"],
            let mrt = diary["mrt"]
        else { return }
        let editAlert = UIAlertController(title: "Editing", message: "Tap save after editing.", preferredStyle: .alert)
        let optionAlert = UIAlertController(title: "To update which one?", message: "Please choose the field you want to update.", preferredStyle: .actionSheet)
        let updateRestaurantOpt = UIAlertAction(title: "Restaurant", style: .default) { (_) in
            editAlert.addTextField { (restaurantTextField) in
                restaurantTextField.text = restaurant
            }
            let save = UIAlertAction(title: "Save", style: .default) { (_) in
                guard
                    let newRestaurant = editAlert.textFields?.first?.text
                else { return }
                self.diaryList[indexPath.row] = ["id": id, "restaurant": newRestaurant, "mrt": mrt]
                self.updateDocument(by: id, with: ["restaurant": newRestaurant])
            }
            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            editAlert.addAction(save)
            editAlert.addAction(cancel)
            self.present(editAlert, animated: true, completion: nil)
        }
        let updateMrtOpt = UIAlertAction(title: "MRT", style: .default) { (_) in
            editAlert.addTextField { (mrtTextField) in
                mrtTextField.text = mrt
            }
            let save = UIAlertAction(title: "Save", style: .default) { (_) in
                let textFields = editAlert.textFields
                guard
                    let newMrt = textFields?.first?.text
                else { return }
                self.diaryList[indexPath.row] = ["id": id, "restaurant": restaurant, "mrt":newMrt]
                self.updateDocument(by: id, with: ["mrt": newMrt])
            }
            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            editAlert.addAction(save)
            editAlert.addAction(cancel)
            self.present(editAlert, animated: true, completion: nil)
        }
        let cancelOpt = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        optionAlert.addAction(cancelOpt)
        optionAlert.addAction(updateRestaurantOpt)
        optionAlert.addAction(updateMrtOpt)
        self.present(optionAlert, animated: true, completion: nil)
    }
}
