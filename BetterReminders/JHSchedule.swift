//
//  JHSchedule.swift
//  BetterReminders
//
//  Created by Joe Holt on 4/5/17.
//  Copyright © 2017 Joe Holt. All rights reserved.
//

import UIKit

class JHSchedule: NSObject, NSCoding {

    internal var classes: [JHSchoolClass]!
    
    init(classes: [JHSchoolClass]) {
        self.classes = classes
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.classes = aDecoder.decodeObject(forKey: "classes") as! [JHSchoolClass]
    }
    
    internal func encode(with aCoder: NSCoder) {
        aCoder.encode(classes, forKey: "classes")
    }
    
    /**
        Creates and return an array of unique class endTimes for all classes
        - returns: Array of unique class endTimes for all classes
    */
    private func classEndDates() -> [Date] {
        var endDates = [Date]()
        for c in classes {
            if !endDates.contains(c.endDate) {
                endDates.append(c.endDate)
            }
        }
        return endDates
    }
    
    /**
        Deletes a class at a given index
        - parameter atIndex: the index of the class to be deleted
    */
    internal func removeClass(atIndex index: Int) {
        classes.remove(at: index)
    }
    
    /**
        Creates and array of class endTimes as a Date containing only the hour and minute
        - returns: An array of all class endTimes as dates with only minutes/hours
    */
    internal func classEndTimes() -> [Date] {
        let endDates = classEndDates()
        var endTimes = [Date]()
        for date in endDates {
            var newComponents = DateComponents()
            let hour = Calendar.current.component(.hour, from: date)
            let minute = Calendar.current.component(.minute, from: date)
            newComponents.hour = hour
            newComponents.minute = minute
            let time = Calendar.current.date(from: newComponents)
            endTimes.append(time!)
        }
        return endTimes
    }
    
    /**
        Creates a dictinoary of with the keys as days and the values as an array of classes on that day
        - returns: A dictinoary of with the keys as days and the values as an array of classes on that day
    */
    internal func classesSortedByDay() -> [String: [JHSchoolClass]] {
        var classesByDay = [String: [JHSchoolClass]]()
        for c in classes {
            if classesByDay[c.day] == nil {
                classesByDay[c.day] = [c]
            } else {
                classesByDay[c.day]?.append(c)
            }
        }
        return classesByDay
    }
    
    /**
        Sorts classes by start time
        - returns: An array of the classes sorted by day
    */
    internal func sortClassesByStartTime() -> [JHSchoolClass] {
        return classes.sorted(by: { $0.startDate.compare($1.startDate) == .orderedAscending })
    }
    
    /**
        Returns a class from a given indexPath
        - parameter indexPath: Index path of cell to be returned
        - returns: Cell at the given indexPath in the table view
    */
    internal func classGivenIndexPath(indexPath: IndexPath) -> JHSchoolClass {
        let day = dayGivenIndexPath(indexPath: indexPath)
        let clas = classesSortedByDay()[day]?[(indexPath.row)]
        return clas!
    }
    
    /**
        Returns the day of a class given an indexPath
        - parameter IndexPath: Index path of cell from which a day is requests
        - returns: Day of given indexPath as String
    */
    private func dayGivenIndexPath(indexPath: IndexPath) -> String {
        //Day given an index path of a class
        return Array(classesSortedByDay().keys).reversed()[(indexPath.section - 1)] as String
    }
    
    /**
        Finds total time to complete all tasks in all classes
        - returns: Hours and minutes in form (hour, minute)
    */
    internal func totalTimeToComplete() -> (Int, Int) {
        var totalHours = 0
        var totalMinutes = 0
        for class in classes {
            let (hour, minute) = class.timeToCompleteTasks()
            totalHours += hour
            totalMinutes += minute
        }
        while totalMinutes >= 60 {
            totalMinutes = totalMinutes - 60
            totalHours += 1
        }
        return (totalHours, totalMinutes)
    }
    
    /**
        Saves a task for a given class index
        - parameter task: Task to save
        - parameter index: Class to be saved
    */
    internal func saveTaskForClass(task: JHTask, class c: JHTask){
        for class in classes {
            if class.id == c.id {
                var index = 0
                for t in class.tasks {
                    if t.id == task.id {
                        //save task
                        class.tasks[index] = task
                        break
                    }
                    index += 1
                }
                //Class doesnt have a task with taht id so add a new one
                if index == 0 {
                    class.tasks.append(task)
                }
            }
        }
    }
    
    /**
        Returns an array of the days
        - returns: An array containg all the class days
    */
    internal func classDays() -> [String] {
        return Array(classesSortedByDay().keys).reversed() //reverse so A is frist
    }
    
    /**
     Removes a task
     - parameter id: id of task to be removed
     */
    internal func removeClass(withId id: Int) {
        for i in 0...classes.count - 1 {
            if classes[i].id == id {
                removeClass(atIndex: i)
                break
            }
        }
    }
    

}
