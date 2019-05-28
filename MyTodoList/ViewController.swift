//
//  ViewController.swift
//  MyTodoList
//
//  Created by Keito Omura on 2019/05/17.
//  Copyright © 2019 Keito Omura. All rights reserved.
//

import UIKit
import Firebase

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var todoList = [MyTodo]()
    var db: Firestore!

    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        db = Firestore.firestore()
        db.collection("todos").order(by: "createdAt").addSnapshotListener { querySnapshot, error in
            guard let snapshot = querySnapshot else {
                print("Error fetching snapshot: \(error!)")
                return
            }
            snapshot.documentChanges.forEach { diff in
                let data = diff.document.data()
                if (diff.type == .added) {
                    self.todoList.append(MyTodo(diff.document.documentID, data["title"] as! String, data["done"] as! Bool))
                }
                if (diff.type == .modified) {
                    if diff.oldIndex == diff.newIndex {
                        self.todoList[Int(diff.newIndex)] = MyTodo(diff.document.documentID, data["title"] as! String, data["done"] as! Bool)
                    } else {
                        self.todoList.remove(at: Int(diff.oldIndex))
                        self.todoList.append(MyTodo(diff.document.documentID, data["title"] as! String, data["done"] as! Bool))
                    }
                }
                if (diff.type == .removed) {
                    self.todoList.remove(at: Int(diff.oldIndex))
                }
            }
            self.tableView.reloadData()
        }
    }


    @IBAction func tapAddButton(_ sender: Any) {
        let aleartController = UIAlertController(title: "ToDo追加", message: "ToDoを入力してください", preferredStyle: UIAlertController.Style.alert)
        aleartController.addTextField(configurationHandler: nil)
        let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) { (action: UIAlertAction) in
            if let textField = aleartController.textFields?.first {
                self.db.collection("todos").addDocument(data: [
                    "title": textField.text!,
                    "done": false,
                    "createdAt": FieldValue.serverTimestamp()
                ]) { err in
                    if let err = err {
                        print("Error adding document: \(err)")
                    } else {
                        print("Document added!!")
                    }
                }
            }
        }
        aleartController.addAction(okAction)
        let cancelButton = UIAlertAction(title: "CANCEL", style: UIAlertAction.Style.default, handler: nil)
        aleartController.addAction(cancelButton)
        present(aleartController, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return todoList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "todoCell", for: indexPath)
        let myTodo = todoList[indexPath.row]
        cell.textLabel?.text = myTodo.todoTitle
        if myTodo.todoDone {
            cell.accessoryType = UITableViewCell.AccessoryType.checkmark
        } else {
            cell.accessoryType = UITableViewCell.AccessoryType.none
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let myTodo = todoList[indexPath.row]
        if myTodo.todoDone {
            myTodo.todoDone = false
        } else {
            myTodo.todoDone = true
        }
        self.db.collection("todos").document(myTodo.id).updateData([
            "done": myTodo.todoDone
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCell.EditingStyle.delete {
            let myTodo = todoList[indexPath.row]
            db.collection("todos").document(myTodo.id).delete() { err in
                if let err = err {
                    print("Error removing document: \(err)")
                } else {
                    print("Document successfully removed!")
                }
            }
        }
    }
}

class MyTodo {
    var id: String
    var todoTitle: String?
    var todoDone: Bool = false
    
    init(_ id: String, _ title: String, _ done: Bool) {
        self.todoTitle = title
        self.todoDone = done
        self.id = id
    }
}
