//
//  ViewController.swift
//  BetterReminders
//
//  Created by Joe Holt on 2/28/17.
//  Copyright © 2017 Joe Holt. All rights reserved.
//

import UIKit
import UserNotifications
import UserNotificationsUI

class MainTableViewController: UITableViewController, UIPopoverPresentationControllerDelegate, UIAdaptivePresentationControllerDelegate, AddClassDelegate, UIViewControllerPreviewingDelegate, UIGestureRecognizerDelegate {
    
    let defaults = UserDefaults.standard
    var classes: [JHSchoolClass]?
    var classesByDay: [String: [JHSchoolClass]]!
    var forceLoadData: Bool = false
    var notificationsEnabled: Bool = true
    var center = UNUserNotificationCenter.current()
    var myAppDelegate = UIApplication.shared.delegate as! AppDelegate
    var tasksToAdd: [[String: JHTask]]? {
        didSet {
            addNotificationTasks()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Schedule"
        
        // set observer for UIApplicationWillEnterForeground
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: .UIApplicationWillEnterForeground, object: nil)
        
        getData()
        setUp()

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //Notifications still bugged
        
        setUpNotifications()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        loadTasksFromNotification()
    }
    
    // my selector that was defined above
    func willEnterForeground() {
        print(myAppDelegate.tasksToAdd)
        loadTasksFromNotification()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "ClassCell")
        let c = classGivenIndexPath(indexPath: indexPath)
        cell.textLabel?.text = "\(c.name!)"
        let outputFormatter = DateFormatter()
        outputFormatter.timeStyle = .short
        cell.detailTextLabel?.text = "\(outputFormatter.string(from: c.startDate))-\(outputFormatter.string(from: c.endDate))"
        cell.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "classToTask", sender: self)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return classesByDay.keys.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let days: [String] = Array(classesByDay.keys).reversed()    //Reversed so "A" day is first
        return "\(days[section]) Day"
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let days: [String] = Array(classesByDay.keys).reversed()    //Reversed so "A" day is first
        return classesByDay[days[section]]!.count
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction(style: .destructive, title: "Delete", handler: {_,_ in 
            self.deleteClass(at: indexPath)
        })
        let editAction = UITableViewRowAction(style: .normal, title: "Edit", handler: {
            _,_ in
            self.editClass(at: indexPath)
        })
        editAction.backgroundColor = UIColor.blue
        return [deleteAction, editAction]
    }
    
    func registerHomeWorkNotifications(forDates dates: [Date]) {
        
        //Set notifications for the end of each class, each week day
        for date in dates {
            let requesetString: String! = stringByAppendingDateAndTime(string: "classFinishedRequest", date: date)
            let actionString: String! = stringByAppendingDateAndTime(string: "classFinshedAction", date: date)
            print("Hour: \(Calendar.current.component(.hour, from: date))")
            print("Minute: \(Calendar.current.component(.minute, from: date)))")
            let hour = Calendar.current.component(.hour, from: date)
            let minute = Calendar.current.component(.minute, from: date)
            createNotificationWithTextField(title: "Enter assigned homework", body: "class=\"Class\" \nname=\"Name\" \ndueDate=\"04/15/17\" \ntimeToComplete=\"01:15\"", launchDateHour: hour, launchDateMinute: minute, repeats: false, requestId: requesetString, actionId: actionString, textTitle: "Reminder", textButtonTitle: "Save", textPlaceholder: "Enter arguments here", catagotyId: "classFinishedCatagory", center: center)
        }
    }
    
    func stringByAppendingDateAndTime(string: String, date: Date) -> String! {
        //Notificatin ids must be unique so I add the dates and times for id
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let weekDay = Calendar.current.component(.weekday, from: date)
        let timeString = formatter.string(from: date)
        return string + "." + String(weekDay) + "." + timeString
    }
    
    func getClassEndDatesForWeek() -> [Date] {
        //Returns the endtimes of each class for each work day
        var classEndDatesForWeek = [Date]()
        let endTimes = getEndTimes()
        for time in endTimes {
            var newComponents = DateComponents()
            let hour = Calendar.current.component(.hour, from: time)
            let minute = Calendar.current.component(.minute, from: time)
            newComponents.hour = hour
            newComponents.minute = minute
            let date = Calendar.current.date(from: newComponents)
            print("Hour: \(Calendar.current.component(.hour, from: date!))")
            print("Minute: \(Calendar.current.component(.minute, from: date!))")
            classEndDatesForWeek.append(date!)
        }
        return classEndDatesForWeek
    }
    
    func getEndTimes() -> [Date] {
        //Returns an array of the end times
        var endTimes = [Date]()
        for c in classes! {
            if !endTimes.contains(c.endDate) {
                endTimes.append(c.endDate)
            }
        }
        return endTimes
    }
    
    func editClass(at indexPath: IndexPath) {
        //Edit class
        displayClassCreationPopup(editing: true, forClass: classGivenIndexPath(indexPath: indexPath))
    }
    
    func deleteClass(at indexPath: IndexPath) {
        //Confirm with user then delete class
        let ac = UIAlertController(title: "Delete Class", message: "Are you sure you would like to delete \(self.classGivenIndexPath(indexPath: indexPath).name!)? All of the classes tasks will also be deleted.", preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: "Delete Class", style: .destructive, handler: {
            action in
            //Deletes class at index path and then reloads data
            //Finds the class in classesByDay structure then deletes in from classes array, could be redone for betterr reading and efficency
            let clas = self.classGivenIndexPath(indexPath: indexPath)
            var i = 0
            for c in self.classes! {
                if c == clas {
                    self.classes?.remove(at: i)
                    break
                }
                i += 1
            }
            self.saveClasses()
            self.refreshData()
            self.tableView.reloadData()
        }))
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(ac, animated: true, completion: nil)
    }
    
    func didAddNewClass() {
        //New class added from popover view controller
        getData()
        tableView.reloadData()
    }
    
    func didFinishEditing() {
         //Finished editing a class
        getData()
        tableView.reloadData()
    }
    
    func didCancelAddNewClass() {
        //Cancled creation of new class from popover view contorller
    }
    
    func setUp() {
        //General code to set up app when launched
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.add, target: self, action: #selector(addButtonSelected))
        
        //Long press nav bar
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(navBarLongPress(sender:)))
        longPress.delegate = self
        navigationController?.navigationBar.addGestureRecognizer(longPress)
        
        //Register view for 3D touch preview
        registerForPreviewing(with: self, sourceView: view)
        
    }
    
    func navBarLongPress(sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            var message = "Unknown"
            if getTotalTimeToComplete() != (0, 0) {
                let (hour, minute) = getTotalTimeToComplete()
                var hourText = "hours"
                var minuteText = "minutes"
                if hour == 1 {
                    hourText = "hour"
                }
                if minute == 1 {
                    minuteText = "minute"
                }
                message = "\(hour) \(hourText) \(minute) \(minuteText)"
            } else {
                message = "You're done!"
            }
            let ac = UIAlertController(title: "Estimated Time to Complete HW", message: message, preferredStyle: .alert)
            let action = UIAlertAction(title: "Fuck", style: .default, handler: { _ in })
            ac.addAction(action)
            present(ac, animated: true, completion: nil)
        }
    }
    
    func setUpNotifications() {
        //Registers notifications if needed
        var currentNotifications: [UNNotificationRequest] = []
        
        center.getPendingNotificationRequests(completionHandler: {
            requests in
            DispatchQueue.main.async {
                //print(requests.count)
                currentNotifications = requests
                if self.notificationsEnabled == true {
                    if currentNotifications.count == 0 {
                        //Load notifications for the current weekif there a none loaded
                        //var dateC = DateComponents()
                        //dateC.hour =
                        //dateC.minute = 14
                        //let date = Calendar.current.date(from: dateC)
                        let dates: [Date] = self.getClassEndDatesForWeek()
                        self.registerHomeWorkNotifications(forDates: dates)
                    }
                }
            }
        })
        
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        // Peek and pop - Present a VC preview when force touching it
        if let indexPath = tableView.indexPathForRow(at: location) {
            previewingContext.sourceRect = tableView.rectForRow(at: indexPath)
            
            let vc = storyboard?.instantiateViewController(withIdentifier: "TaskVC") as! TaskVC
            vc.clas = classGivenIndexPath(indexPath: indexPath)
            let navVC = UINavigationController(rootViewController: vc)
            navVC.title = "\(vc.clas.name)"
            
            return navVC
        }
        return nil
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        // Peek and pop - Presents the view contorller when popping - hacky implementation
        let navVC = viewControllerToCommit as! UINavigationController
        let vc = navVC.viewControllers[0] as! TaskVC
        let clas = vc.clas
        let newVC = storyboard?.instantiateViewController(withIdentifier: "TaskVC") as! TaskVC
        newVC.clas = clas
        self.navigationController?.pushViewController(newVC, animated: true)
    }
    
    func addButtonSelected() {
        //Add button selected in nav bar
        displayClassCreationPopup()
    }
    
    func displayClassCreationPopup(editing: Bool = false, forClass: JHSchoolClass? = nil) {
        //Instantiate and display popup for creating/editing a class
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyBoard.instantiateViewController(withIdentifier: "popoverClassAdd") as! ClassPopoverVC
        vc.delegate = self
        vc.forEditing = editing
        vc.editClass = forClass
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .popover
        if let presentationController = nav.popoverPresentationController {
            presentationController.delegate = self
            presentationController.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
            presentationController.sourceView = self.view
            let width = self.view.bounds.width - 30
            let height = UIScreen.main.bounds.height - 150
            presentationController.sourceRect = CGRect(x: (self.view.bounds.width - width)/2, y: 0.0, width: width, height: height - 300)
            self.present(nav, animated: true, completion: nil)
        }
    }
    
    func presentationController(_ controller: UIPresentationController, viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle) -> UIViewController? {
        //Gives the view controller to be displayed in the popover view contorller
        let navigationController = UINavigationController(rootViewController: controller.presentedViewController)
        let btnDone = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(MainTableViewController.dismissView))
        navigationController.topViewController?.navigationItem.rightBarButtonItem = btnDone
        return navigationController
    }
    
    func dismissView() {
        //Called from presentationController:controller:viewControllerForAdaptivePresentationStyle
        self.dismiss(animated: true, completion: nil)
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        //.none sets the popover style as an actual popover rather than a full screen view
        return UIModalPresentationStyle.none
    }
    
    func getData() {
        //Gets data, either from JSON or NSUserDefaults depending on launch
        let launchedBefore = defaults.bool(forKey: "launchedBefore")
        if !launchedBefore || forceLoadData == true {
            //First Launch
            defaults.set(true, forKey: "launchedBefore")
            print("First Launch")
            parseScheduleJSON()
            setUpNotifications()
        } else {
            //Not first launch
            loadClasses()
        }
        classes = sortClassesByStartTime(classes: classes!)
        classesByDay = sortClassesByDay(classes: classes!)
        
        loadTasksFromNotification()
    }
    
    func loadTasksFromNotification() {
        //Get data from tasks that are needed
        tasksToAdd = myAppDelegate.tasksToAdd
        saveClasses()
        myAppDelegate.tasksToAdd = []
    }
    
    func refreshData() {
        //Refreshs classes
        classes = sortClassesByStartTime(classes: classes!)
        classesByDay = sortClassesByDay(classes: classes!)
    }
    
    func loadJSON(fromFile file: String, ofType type: String) -> JSON? {
        //Loads the school scheduele JSON containing class info from the main bundle
        if let path = Bundle.main.path(forResource: file, ofType: type) {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .alwaysMapped)
                let jsonObj = JSON(data: data)
                if jsonObj != JSON.null {
                    return jsonObj
                } else {
                    print("Couldn't get JSON from file, check to make sure the file is correct")
                }
            } catch let error {
                print(error.localizedDescription)
            }
        } else {
            print("Invlaide file name/path")
        }
        return nil
    }
    
    func parseScheduleJSON() {
        //Parses JSON of school classes in the app bundle
        //Used for easy adding of classes -- Wont be used in final user version
        if let json = loadJSON(fromFile: "Classes", ofType: "json") {
            classes = [JHSchoolClass]()
            for item in json["Classes"].arrayValue {
                if let name = item["name"].string {
                    if let day = item["day"].string {
                        if let startTime = item["startTime"].string {
                            if let endTime = item["endTime"].string {
                                let startDate: Date = dateFromString(time: startTime)
                                let endDate: Date = dateFromString(time: endTime)
                                let c = JHSchoolClass(name: name, startDate: startDate, endDate: endDate, day: day)
                                classes!.append(c)
                                saveClasses()
                            } else {
                                print("Error parsing JSON")
                            }
                        } else {
                            print("Error parsing JSON")
                        }
                    } else {
                        print("Error parsing JSON")
                    }
                } else {
                    print("Error parsing JSON")
                }
            }
        } else {
            print("JSON not parsed properly")
        }
    }
    
    func sortClassesByDay(classes: [JHSchoolClass]) -> [String: [JHSchoolClass]] {
        //Organizes classes into which class scheduele day in order for tableView organization
        classesByDay = [String: [JHSchoolClass]]()
        for c in classes {
            if classesByDay[c.day] == nil {
                classesByDay[c.day] = [c]
            } else {
                classesByDay[c.day]?.append(c)
            }
        }
        return classesByDay
    }
    
    func sortClassesByStartTime(classes: [JHSchoolClass]) -> [JHSchoolClass] {
        // Sorts classes by startDate method
        let newClasses = classes.sorted(by: { $0.startDate.compare($1.startDate) == .orderedAscending })
        return newClasses
    }
    
    func addNotificationTasks() {
        //Add tasks that were requested by notifications
        if let tasksToAdd = tasksToAdd {
            for group in tasksToAdd {
                for key in group.keys {
                    for clas in classes! {
                        if clas.name == key {
                            print("Added task \(group[key]?.name) to \(key)")
                            clas.addTask(task: group[key]!)
                        }
                    }
                }
            }
        }
    }
    
    
    func loadClasses() {
        //Loads classes from defaults
        let data = defaults.object(forKey: "classes") as! Data
        classes = NSKeyedUnarchiver.unarchiveObject(with: data) as? [JHSchoolClass]
    }
    
    func saveClasses() {
        //Save classes from defaults
        let data: Data = NSKeyedArchiver.archivedData(withRootObject: classes!)
        defaults.set(data, forKey: "classes")
    }
    
    func classGivenIndexPath(indexPath: IndexPath) -> JHSchoolClass {
        //Hacky method to return the class of a given indexPath on the table view from classesByDay
        let day = dayGivenIndexPath(indexPath: indexPath)
        let clas = classesByDay[day]?[(indexPath.row)]
        return clas!
    }
    
    func dayGivenIndexPath(indexPath: IndexPath) -> String {
        //Day given an index path of a class
        return Array(classesByDay.keys).reversed()[(indexPath.section)] as String
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let nextVC = segue.destination as! TaskVC
        let indexPath = tableView.indexPathForSelectedRow
        nextVC.clas = classGivenIndexPath(indexPath: indexPath!)
        nextVC.classes = classes
    }
    
    func getTotalTimeToComplete() -> (Int, Int) {
        var timeMinutes = 0
        var timeHours = 0
        for c in classes! {
            for t in c.tasks {
                if t.completed == false {
                    let tComps = Calendar.current.dateComponents(in: .current, from: t.estimatedTimeToComplete)
                    timeHours += tComps.hour!
                    timeMinutes += tComps.minute!
                }
            }
        }
        return (timeHours, timeMinutes)
    }
    
    
}

