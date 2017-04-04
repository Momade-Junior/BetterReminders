//
//  TaskPopoverVC.swift
//  BetterReminders
//
//  Created by Joe Holt on 4/3/17.
//  Copyright © 2017 Joe Holt. All rights reserved.
//

import UIKit

@objc protocol AddTaskDelegate {
    func didAddTask()
    func didEditTask()
}

class TaskPopoverVC: UITableViewController {
    
    @IBOutlet weak var taskNameTF: UITextField!
    @IBOutlet weak var timeToFinishDP: UIDatePicker!
    @IBOutlet weak var dueDateDP: UIDatePicker!
    
    var delegate: AddTaskDelegate?
    var clas: JHSchoolClass!
    var forEditing: Bool!
    var forTask: JHTask?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Add Task"
        
        setUp()
        
    }
    
    func setUp() {
        //Basic UI set up
        timeToFinishDP.countDownDuration = 60.0 * 15 //Fifteen minutes
        dueDateDP.minimumDate = Date()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(save))
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancel))
        
        //Editing vc not
        if forEditing == true {
            if let task = forTask {
                taskNameTF.text = task.name
                timeToFinishDP.date = task.estimatedTimeToComplete
                dueDateDP.date = task.dueDate
            }
        }
    }
    
    func cancel() {
        dismiss(animated: true, completion: nil)
    }
    
    func save() {
        let name: String!
        if !(taskNameTF.text?.trimmingCharacters(in: .whitespaces).isEmpty)! {
            name = taskNameTF.text
        } else {
            name = "Untitled Task"
        }
        let dueDate = dueDateDP.date
        let ttc = timeToFinishDP.date
        let completed = false
        let newTask = JHTask(name: name, completed: completed, dueDate: dueDate, estimatedTimeToComplete: ttc)
        if forEditing == true {
            //editing
            var index = 0
            for task in clas.tasks {
                if task.id == forTask!.id {
                    clas.tasks[index] = newTask
                }
                index += 1
            }
            delegate?.didEditTask()
        } else {
            clas.addTask(task: newTask)
            delegate?.didAddTask()
        }
        dismiss(animated: true, completion: nil)
    }

}
