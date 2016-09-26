//
//  CalendarViewController.swift
//  google_api
//
//  Created by 中村祐太 on 2016/09/26.
//  Copyright © 2016年 中村祐太. All rights reserved.
//
import GoogleAPIClient
import GTMOAuth2
import UIKit

class CalendarViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    fileprivate let kKeychainItemName = "Google API"
    fileprivate let kClientID = "188020101111-cdk7pjg6h42jvcqn1kel0uu6ik1o0sot.apps.googleusercontent.com"
    
    fileprivate let service = GTLServiceCalendar()
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableViewAutomaticDimension

        // Do any additional setup after loading the view.
        if let auth = GTMOAuth2ViewControllerTouch.authForGoogleFromKeychain(
            forName: kKeychainItemName,
            clientID: kClientID,
            clientSecret: nil) {
            service.authorizer = auth
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        apiRequest()
    }
    
    func apiRequest() {
        let query = GTLQueryCalendar.queryForEventsList(withCalendarId: "primary")
        query?.maxResults = 10
        query?.timeMin = GTLDateTime(date: NSDate() as Date!, timeZone: NSTimeZone.local)
        query?.singleEvents = true
        query?.orderBy = kGTLCalendarOrderByStartTime
        
        service.executeQuery(
            query!,
            delegate: self,
            didFinish: #selector(CalendarViewController.displayResultWithTicket(_:finishedWithObject:error:))
        )
    }
    
    var events:[GTLCalendarEvent] = []
    func displayResultWithTicket(_ ticket : GTLServiceTicket,
                                 finishedWithObject response : GTLCalendarEvents,
                                 error : NSError?) {
        
        if let error = error {
            showAlert("Error", message: error.localizedDescription)
            return
        }
        events = response.items() as! [GTLCalendarEvent]
        
        
        tableView.reloadData()
    }
    
    
    
    func showAlert(_ title : String, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: UIAlertControllerStyle.alert
        )
        let ok = UIAlertAction(
            title: "OK",
            style: UIAlertActionStyle.default,
            handler: nil
        )
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "tableCell", for: indexPath) as! CustomTableViewCell
        let event = events[indexPath.row]
        cell.title?.text = event.summary
        cell.descriptionText?.text = event.start.jsonString()
        return cell
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
