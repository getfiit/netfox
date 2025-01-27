//
//  NFXSettingsController.swift
//  netfox
//
//  Copyright © 2016 netfox. All rights reserved.
//
    
import Foundation

@available(iOSApplicationExtension, unavailable)
class NFXSettingsController: NFXGenericController {
    // MARK: Properties

    let nfxVersionString = "netfox - \(nfxVersion)"
    var nfxURL = "https://github.com/kasketis/netfox"
    
    var tableData = [HTTPModelShortType]()
    var filters = [Bool]()
}
