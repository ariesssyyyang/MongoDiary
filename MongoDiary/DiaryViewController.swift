//
//  ViewController.swift
//  MongoDiary
//
//  Created by Aries Yang on 2019/1/5.
//  Copyright © 2019 Aries Yang. All rights reserved.
//

import UIKit

class DiaryTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
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
