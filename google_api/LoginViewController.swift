//
//  LoginViewController.swift
//  google_api
//
//  Created by 中村祐太 on 2016/09/26.
//  Copyright © 2016年 中村祐太. All rights reserved.
//

import GoogleAPIClient
import GTMOAuth2
import UIKit

class LoginViewController: UIViewController {
    
    fileprivate let kKeychainItemName = "Google API"
    fileprivate let kClientID = "188020101111-cdk7pjg6h42jvcqn1kel0uu6ik1o0sot.apps.googleusercontent.com"
    
    // If modifying these scopes, delete your previously saved credentials by
    // resetting the iOS simulator or uninstall the app.
    fileprivate let scopes = [kGTLAuthScopeDriveMetadataReadonly,kGTLAuthScopeCalendarReadonly]
    
    fileprivate let service = GTLServiceDrive()
    let output = UITextView()
    
    // When the view loads, create necessary subviews
    // and initialize the Drive API service
    override func viewDidLoad() {
        super.viewDidLoad()
        
        output.frame = view.bounds
        output.isEditable = false
        output.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
        output.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        view.addSubview(output);
        
        if let auth = GTMOAuth2ViewControllerTouch.authForGoogleFromKeychain(
            forName: kKeychainItemName,
            clientID: kClientID,
            clientSecret: nil) {
            service.authorizer = auth
        }
        
    }
    
    // When the view appears, ensure that the Drive API service is authorized
    // and perform API calls
    override func viewDidAppear(_ animated: Bool) {
        
        print("viewDidAppear")
        
        if let authorizer = service.authorizer,
            let canAuth = authorizer.canAuthorize , canAuth {
            fetchFiles()
        } else {
            present(
                createAuthController(),
                animated: true,
                completion: nil
            )
        }
    }
    
    // Construct a query to get names and IDs of 10 files using the Google Drive API
    func fetchFiles() {
        output.text = "Getting files..."
        let query = GTLQueryDrive.queryForFilesList()
        query?.pageSize = 50
        query?.fields = "nextPageToken, files(id, name)"
        service.executeQuery(
            query!,
            delegate: self,
            didFinish: #selector(LoginViewController.displayResultWithTicket(_:finishedWithObject:error:))
        )
    }
    
    // Parse results and display
    func displayResultWithTicket(_ ticket : GTLServiceTicket,
                                 finishedWithObject response : GTLDriveFileList,
                                 error : NSError?) {
        
        if let error = error {
            showAlert("Error", message: error.localizedDescription)
            return
        }
        
        var filesString = ""
        
        if let files = response.files , !files.isEmpty {
            filesString += "Files:\n"
            for file in files as! [GTLDriveFile] {
                filesString += "\(file.name) (\(file.identifier))\n"
            }
        } else {
            filesString = "No files found."
        }
        
        output.text = filesString
    }
    
    
    // Creates the auth controller for authorizing access to Drive API
    fileprivate func createAuthController() -> GTMOAuth2ViewControllerTouch {
        let scopeString = scopes.joined(separator: " ")
        return GTMOAuth2ViewControllerTouch(
            scope: scopeString,
            clientID: kClientID,
            clientSecret: nil,
            keychainItemName: kKeychainItemName,
            delegate: self,
            finishedSelector: #selector(LoginViewController.viewController(_:finishedWithAuth:error:))
        )
    }
    
    // Handle completion of the authorization process, and update the Drive API
    // with the new credentials.
    func viewController(_ vc : UIViewController,
                        finishedWithAuth authResult : GTMOAuth2Authentication, error : NSError?) {
        
        if let error = error {
            service.authorizer = nil
            showAlert("Authentication Error", message: error.localizedDescription)
            return
        }
        
        service.authorizer = authResult
        dismiss(animated: true, completion: nil)
    }
    
    // Helper for showing an alert
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
    
}
