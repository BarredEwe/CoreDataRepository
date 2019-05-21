//
//  ViewController.swift
//  CoreDataRepository
//
//  Created by BarredEwe on 05/21/2019.
//  Copyright (c) 2019 BarredEwe. All rights reserved.
//

import UIKit
import CoreDataRepository

class ViewController: UIViewController {

    private let repository = CoreDataRepository<TestObject>()

    override func viewDidLoad() {
        super.viewDidLoad()
        try? repository.save(item: TestStruct(title: "Test title"))
        print(repository.fetchAll())
        try? repository.deleteAll()
        print(repository.fetchAll())
    }
}

