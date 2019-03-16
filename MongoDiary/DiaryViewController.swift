//
//  ViewController.swift
//  MongoDiary
//
//  Created by Aries Yang on 2019/1/5.
//  Copyright © 2019 Aries Yang. All rights reserved.
//

import UIKit
import StitchCore
import StitchRemoteMongoDBService

class DiaryTableViewController: UITableViewController {

    private lazy var stitchClient = Stitch.defaultAppClient!
    private let serviceName = "mongodb-atlas"

    var diaryList: [[String: String]] = [] {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Hot Pot"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addBarButtonTapped))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Destroy", style: .plain, target: self, action: #selector(handleDestroy))
        checkLogin()
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

    func loggedIn() {
        retrieveDocuments()
    }

    func checkLogin() {
        if stitchClient.auth.isLoggedIn {
            loggedIn()
        } else {
            doLogin()
        }
    }

    //============================
    //  - MARK: Mongo Serivces
    //============================

    func doLogin() {
        stitchClient.auth.login(withCredential: AnonymousCredential()) { (result) in
            switch result {
            case .success(let user):
                print("👻 logged in: \(user.id)")
                self.loggedIn()
            case .failure(let error):
                print("💩 error logging in \(error)")
            }
        }
    }

    func createDocument(restaurant: String, mrt: String) {
        do {
            let user_id = stitchClient.auth.currentUser!.id
            let jsonData = try JSONEncoder().encode(["restaurant": restaurant, "mrt": mrt, "owner_id": user_id])
            let remoteMongoClient = try stitchClient.serviceClient(
                fromFactory: remoteMongoClientFactory,
                withName: serviceName
            )
            let hotpotCollection = remoteMongoClient.db("diary").collection("hotpot")
            try hotpotCollection.insertOne(Document(fromJSON: jsonData), { (result) in
                switch result {
                case .success(let hotpot):
                    print("👻 Successfully inserted hotpot diary with _id: \(hotpot.insertedId)")
                    self.retrieveDocuments()
                case .failure(let error):
                    print("💩 Failed to insert hotpot diary: \(error)")
                }
            })
        } catch {
            debugPrint("Failed to initialize MongoDB Stitch iOS SDK: \(error)")
        }
    }

    func updateDocument(by id: String, with body: [String: String]) {
        do {
            let jsonData = try JSONEncoder().encode(body)
            let remoteMongoClient = try stitchClient.serviceClient(
                fromFactory: remoteMongoClientFactory,
                withName: serviceName
            )
            let hotpotCollection = remoteMongoClient.db("diary").collection("hotpot")
            try hotpotCollection.updateOne(filter: ["_id": id], update: ["$set": Document(fromJSON: jsonData)], { (result) in
                switch result {
                case .success(let hotpot):
                    print("👻 Successfully updated hotpot diary count: \(hotpot.modifiedCount)")
                    self.retrieveDocuments()
                case .failure(let error):
                    print("💩 Failed to updated hotpot diary: \(error)")
                }
            })
            
        } catch {
            debugPrint("Failed to initialize MongoDB Stitch iOS SDK: \(error)")
        }
    }

    func retrieveDocuments() {
        do {
            let remoteMongoClient = try stitchClient.serviceClient(
                fromFactory: remoteMongoClientFactory,
                withName: serviceName
            )
            let hotpotCollection = remoteMongoClient.db("diary").collection("hotpot")
            hotpotCollection.find().toArray { (results) in
                switch results {
                case .success(let hotpots):
                    print("👻 Successfully found \(hotpots.count) hotpots:")
                    var items: [[String: String]] = []
                    hotpots.forEach({ (hotpot) in
                        guard
                            let id = hotpot["_id"] as? ObjectId,
                            let restaurant = hotpot["restaurant"] as? String,
                            let mrt = hotpot["mrt"] as? String
                            else {
                                print("👿 Failed to parse hotpot diary")
                                return
                            }
                        print("🍲 \(restaurant)")
                        items.append(["id": id.oid, "restaurant": restaurant, "mrt": mrt])
                    })
                    self.diaryList = items
                case .failure(let error):
                    print("💩 Failed to find documents: \(error)")
                }
            }
        } catch {
            debugPrint("Failed to initialize MongoDB Stitch iOS SDK: \(error)")
        }
    }

    func deleteDocument(by id: String) {
        do {
            let remoteMongoClient = try stitchClient.serviceClient(
                fromFactory: remoteMongoClientFactory,
                withName: serviceName
            )
            let hotpotCollection = remoteMongoClient.db("diary").collection("hotpot")
            hotpotCollection.deleteOne(["_id": id]) { (result) in
                switch result {
                case .success(let hotpot):
                    print("👻 Deleted \(hotpot.deletedCount) hotpot.")
                    self.retrieveDocuments()
                case .failure(let error):
                    print("💩 Delete failed with error: \(error)")
                }
            }
        } catch {
            debugPrint("Failed to initialize MongoDB Stitch iOS SDK: \(error)")
        }
    }

    func deleteAllDocuments(with query: Document) {
        do {
            let remoteMongoClient = try stitchClient.serviceClient(
                fromFactory: remoteMongoClientFactory,
                withName: serviceName
            )
            let hotpotCollection = remoteMongoClient.db("diary").collection("hotpot")
            hotpotCollection.deleteMany(query, { (result) in
                switch result {
                case .success(let hotpots):
                    print("👻 Deleted \(hotpots.deletedCount) hotpot(s).")
                    self.retrieveDocuments()
                case .failure(let error):
                    print("💩 Delete failed with error: \(error)")
                }
            })
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
        cell.detailTextLabel?.textColor = .lightGray
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
