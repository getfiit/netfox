//
//  NFX.swift
//  netfox
//
//  Copyright © 2016 netfox. All rights reserved.
//

import Foundation
import UIKit

private func podPlistVersion() -> String? {
    guard let path = Bundle(identifier: "com.kasketis.netfox-iOS")?.infoDictionary?["CFBundleShortVersionString"] as? String else { return nil }
    return path
}

// TODO: Carthage support
let nfxVersion = podPlistVersion() ?? "0"

// Notifications posted when NFX opens/closes, for client application that wish to log that information.
let nfxWillOpenNotification = "NFXWillOpenNotification"
let nfxWillCloseNotification = "NFXWillCloseNotification"

@objc
open class NFX: NSObject {
    
    // MARK: - Properties
    
    fileprivate enum Constants: String {
        case alreadyStartedMessage = "Already started!"
        case startedMessage = "Started!"
        case stoppedMessage = "Stopped!"
        case prefixForCheck = "nfx"
        case nibName = "NetfoxWindow"
    }
    
    fileprivate var started: Bool = false
    fileprivate var presented: Bool = false
    fileprivate var enabled: Bool = false
    fileprivate var selectedGesture: ENFXGesture = .shake
    fileprivate var ignoredURLs = [String]()
    fileprivate var filters = [Bool]()
    fileprivate var lastVisitDate: Date = Date()
    
    internal var cacheStoragePolicy = URLCache.StoragePolicy.notAllowed
    
    // swiftSharedInstance is not accessible from ObjC
    class var swiftSharedInstance: NFX {
        struct Singleton {
            static let instance = NFX()
        }
        return Singleton.instance
    }
    
    // the sharedInstance class method can be reached from ObjC
    @objc open class func sharedInstance() -> NFX {
        return NFX.swiftSharedInstance
    }
    
    @objc public enum ENFXGesture: Int {
        case shake
        case custom
    }

    @objc open func start() {
        guard !started else {
            showMessage(Constants.alreadyStartedMessage.rawValue)
            return
        }

        started = true
        register()
        enable()
        clearOldData()
        showMessage(Constants.startedMessage.rawValue)
    }
    
    @objc open func stop() {
        unregister()
        disable()
        clearOldData()
        started = false
        showMessage(Constants.stoppedMessage.rawValue)
    }
    
    fileprivate func showMessage(_ msg: String) {
        print("netfox \(nfxVersion) - [https://github.com/kasketis/netfox]: \(msg)")
    }
    
    internal func isEnabled() -> Bool {
        return enabled
    }
    
    internal func enable() {
        enabled = true
    }
    
    internal func disable() {
        enabled = false
    }
    
    fileprivate func register() {
        URLProtocol.registerClass(NFXProtocol.self)
    }
    
    fileprivate func unregister() {
        URLProtocol.unregisterClass(NFXProtocol.self)
    }
    
    @objc func motionDetected() {
        guard started else { return }
        toggleNFX()
    }
    
    @objc open func isStarted() -> Bool {
        return started
    }
    
    @objc open func setCachePolicy(_ policy: URLCache.StoragePolicy) {
        cacheStoragePolicy = policy
    }
    
    @objc open func setGesture(_ gesture: ENFXGesture) {
        selectedGesture = gesture
    }
    
    @objc open func show() {
        guard started else { return }
        showNFX()
    }
    
    @objc open func hide() {
        guard started else { return }
        hideNFX()
    }

    @objc open func toggle()
    {
        guard self.started else { return }
        toggleNFX()
    }
    
    @objc open func ignoreURL(_ url: String) {
        ignoredURLs.append(url)
    }
    
    internal func getLastVisitDate() -> Date {
        return lastVisitDate
    }
    
    fileprivate func showNFX() {
        if presented {
            return
        }
        
        showNFXFollowingPlatform()
        presented = true

    }
    
    fileprivate func hideNFX() {
        if !presented {
            return
        }
        
        NotificationCenter.default.post(name: Notification.Name.NFXDeactivateSearch, object: nil)
        hideNFXFollowingPlatform { () -> Void in
            self.presented = false
            self.lastVisitDate = Date()
        }
    }

    fileprivate func toggleNFX() {
        presented ? hideNFX() : showNFX()
    }
    
    internal func clearOldData() {
        NFXHTTPModelManager.sharedInstance.clear()
        do {
            let documentsPath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.allDomainsMask, true).first!
            let filePathsArray = try FileManager.default.subpathsOfDirectory(atPath: documentsPath)
            for filePath in filePathsArray {
                if filePath.hasPrefix(Constants.prefixForCheck.rawValue) {
                    try FileManager.default.removeItem(atPath: (documentsPath as NSString).appendingPathComponent(filePath))
                }
            }
            
            try FileManager.default.removeItem(atPath: NFXPath.SessionLog)
        } catch {}
    }
    
    func getIgnoredURLs() -> [String] {
        return ignoredURLs
    }
    
    func getSelectedGesture() -> ENFXGesture {
        return selectedGesture
    }
    
    func cacheFilters(_ selectedFilters: [Bool]) {
        filters = selectedFilters
    }
    
    func getCachedFilters() -> [Bool] {
        if filters.isEmpty {
            filters = [Bool](repeating: true, count: HTTPModelShortType.allValues.count)
        }
        return filters
    }
    
}

extension NFX {
    fileprivate var presentingViewController: UIViewController? {
        var rootViewController = UIApplication.shared.keyWindow?.rootViewController
		while let controller = rootViewController?.presentedViewController {
			rootViewController = controller
		}
        return rootViewController
    }

    fileprivate func showNFXFollowingPlatform() {
        let navigationController = UINavigationController(rootViewController: NFXListController_iOS())
        navigationController.navigationBar.isTranslucent = false
        navigationController.navigationBar.tintColor = UIColor.NFXOrangeColor()
        navigationController.navigationBar.barTintColor = UIColor.NFXStarkWhiteColor()
        navigationController.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.NFXOrangeColor()]
        navigationController.modalPresentationStyle = .overFullScreen

        if #available(iOS 13.0, *) {
            navigationController.presentationController?.delegate = self
        }

        presentingViewController?.present(navigationController, animated: true, completion: nil)
    }
    
    fileprivate func hideNFXFollowingPlatform(_ completion: (() -> Void)?) {
        presentingViewController?.dismiss(animated: true, completion: { () -> Void in
            if let notNilCompletion = completion {
                notNilCompletion()
            }
        })
    }
}

extension NFX: UIAdaptivePresentationControllerDelegate {

    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController)
    {
        guard self.started else { return }
        self.presented = false
    }
}
