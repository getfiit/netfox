//
//  NFXListController.swift
//  netfox
//
//  Copyright © 2016 netfox. All rights reserved.
//

import Foundation

@available(iOSApplicationExtension, unavailable)
class NFXListController: NFXGenericController {

    var tableData = [NFXHTTPModel]()
    var filteredTableData = [NFXHTTPModel]()
    
    func updateSearchResultsForSearchControllerWithString(_ searchString: String) {
        let predicateURL = NSPredicate(format: "requestURL contains[cd] '\(searchString)'")
        let predicateMethod = NSPredicate(format: "requestMethod contains[cd] '\(searchString)'")
        let predicateType = NSPredicate(format: "responseType contains[cd] '\(searchString)'")
        let predicates = [predicateURL, predicateMethod, predicateType]
        let searchPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
        
        let array = (NFXHTTPModelManager.sharedInstance.getModels() as NSArray).filtered(using: searchPredicate)
        filteredTableData = array as! [NFXHTTPModel]
    }

    @objc func reloadTableViewData() { }
}
