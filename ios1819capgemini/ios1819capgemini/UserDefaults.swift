//
//  UserDefaults.swift
//  ios1819capgemini
//
//  Created by Minh Tran on 27.12.18.
//  Copyright © 2018 TUM LS1. All rights reserved.
//

import Foundation

//swiftlint:disable all
extension UserDefaults {
    
    // MARK: Navigation Arrows Settings
    func setNavigationArrows(value: Bool) {
        set(value, forKey: UserDefaultsKeys.navigationArrows.rawValue)
    }
    func getNavigationArrows() -> Bool {
        return bool(forKey: UserDefaultsKeys.navigationArrows.rawValue)
    }
    
    // MARK: Feature Points Settings
    func setFeaturePoints(value: Bool) {
        set(value, forKey: UserDefaultsKeys.featurePoints.rawValue)
    }
    func getFeaturePoints() -> Bool {
        return bool(forKey: UserDefaultsKeys.featurePoints.rawValue)
    }

    // MARK: Bounding Boxes Settings
    func setBoundingBoxes(value: Bool) {
        set(value, forKey: UserDefaultsKeys.boundingBoxes.rawValue)
    }
    func getBoundingBoxes() -> Bool {
        return bool(forKey: UserDefaultsKeys.boundingBoxes.rawValue)
    }
    
    // MARK: Incident Distance Settings
    func setIncidentDistance(value: Bool) {
        set(value, forKey: UserDefaultsKeys.incidentDistance.rawValue)
    }
    func getIncidentDistance() -> Bool {
        return bool(forKey: UserDefaultsKeys.incidentDistance.rawValue)
    }
    
    // MARK: Place Pins Before Detection Settings
    func setPlacePinsBeforeDetection(value: Bool) {
        set(value, forKey: UserDefaultsKeys.placePinsBeforeDetection.rawValue)
    }
    func getPlacePinsBeforeDetection() -> Bool {
        return bool(forKey: UserDefaultsKeys.placePinsBeforeDetection.rawValue)
    }
    
    // MARK: Info Plane Settings
    func setInfoPlane(value: Bool) {
        set(value, forKey: UserDefaultsKeys.infoPlane.rawValue)
    }
    func getInfoPlane() -> Bool {
        return bool(forKey: UserDefaultsKeys.infoPlane.rawValue)
    }
    
    // MARK: Haptic Feedback Settings
    func setHapticFeedback(value: Bool) {
        set(value, forKey: UserDefaultsKeys.hapticFeedback.rawValue)
    }
    func getHapticFeedback() -> Bool {
        return bool(forKey: UserDefaultsKeys.hapticFeedback.rawValue)
    }
    
    // MARK: Automatic Detection Settings
    func setAutomaticDetection(value: Bool) {
        set(value, forKey: UserDefaultsKeys.automaticDetection.rawValue)
    }
    func getAutomaticDetection() -> Bool {
        return bool(forKey: UserDefaultsKeys.automaticDetection.rawValue)
    }
    
    // MARK: Screenshot Settings
    func setScreenshot(value: Bool) {
        set(value, forKey: UserDefaultsKeys.screenshot.rawValue)
    }
    func getScreenshot() -> Bool {
        return bool(forKey: UserDefaultsKeys.screenshot.rawValue)
    }
    
    static func registerDefaults() {
        UserDefaults.standard.register(defaults: ["navigationArrows": true,
                                                  "featurePoints": true,
                                                  "boundingBoxes": false,
                                                  "incidentDistance": true,
                                                  "placePinsBeforeDetection": false,
                                                  "infoPlane": true,
                                                  "hapticFeedback": true,
                                                  "automaticDetection": true,
                                                  "screenshot": true])
    }
    static func restoreDefaults() {
        let defaults = UserDefaults.standard
        defaults.setAutomaticDetection(value: true)
        defaults.setHapticFeedback(value: true)
        defaults.setIncidentDistance(value: true)
        defaults.setBoundingBoxes(value: false)
        defaults.setNavigationArrows(value: true)
        defaults.setInfoPlane(value: true)
        defaults.setFeaturePoints(value: true)
        defaults.setPlacePinsBeforeDetection(value: false)
        defaults.setScreenshot(value: true)
    }
    static func getCurrentSettings() -> [Setting] {
        return [Setting(key: UserDefaultsKeys.navigationArrows.rawValue, value: UserDefaults.standard.getNavigationArrows()),
                Setting(key: UserDefaultsKeys.featurePoints.rawValue, value: UserDefaults.standard.getFeaturePoints()),
                Setting(key: UserDefaultsKeys.boundingBoxes.rawValue, value: UserDefaults.standard.getBoundingBoxes()),
                Setting(key: UserDefaultsKeys.incidentDistance.rawValue, value: UserDefaults.standard.getIncidentDistance()),
                Setting(key: UserDefaultsKeys.placePinsBeforeDetection.rawValue, value: UserDefaults.standard.getPlacePinsBeforeDetection()),
                Setting(key: UserDefaultsKeys.infoPlane.rawValue, value: UserDefaults.standard.getInfoPlane()),
                Setting(key: UserDefaultsKeys.automaticDetection.rawValue, value: UserDefaults.standard.getAutomaticDetection()),
                Setting(key: UserDefaultsKeys.hapticFeedback.rawValue, value: UserDefaults.standard.getHapticFeedback()),
                Setting(key: UserDefaultsKeys.screenshot.rawValue, value: UserDefaults.standard.getScreenshot())]
    }
    static func getCurrentSettingsFormalized() -> [Setting] {
        return [Setting(key: "Set Navigation Arrows", value: UserDefaults.standard.getNavigationArrows()),
                Setting(key: "Set Feature Points", value: UserDefaults.standard.getFeaturePoints()),
                Setting(key: "Set Bounding Boxes", value: UserDefaults.standard.getBoundingBoxes()),
                Setting(key: "Show Incident Distance", value: UserDefaults.standard.getIncidentDistance()),
                Setting(key: "Allow Placing Pins Before Detection", value: UserDefaults.standard.getPlacePinsBeforeDetection()),
                Setting(key: "Show Info Plane", value: UserDefaults.standard.getInfoPlane()),
                Setting(key: "Automatic Detection", value: UserDefaults.standard.getAutomaticDetection()),
                Setting(key: "Haptic Feedback", value: UserDefaults.standard.getHapticFeedback()),
                Setting(key: "Screenshot Taking", value: UserDefaults.standard.getScreenshot())]
    }
    
}

struct Setting {
    let key : String
    let value : Bool
    
    init(key: String, value: Bool) {
        self.key = key
        self.value = value
    }
}
enum UserDefaultsKeys: String {
    case navigationArrows
    case featurePoints
    case boundingBoxes
    case incidentDistance
    case placePinsBeforeDetection
    case infoPlane
    case hapticFeedback
    case automaticDetection
    case screenshot
}
