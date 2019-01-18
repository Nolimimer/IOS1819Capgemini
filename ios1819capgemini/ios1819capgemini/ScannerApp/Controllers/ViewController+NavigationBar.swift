/*
 Copyright © 2018 Apple Inc.
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
Abstract:
Navigation bar management for the main view controller.
*/

import Foundation
import UIKit

extension ViewController {
    
    func setupNavigationBar() {
        backButton = UIBarButtonItem(title: "Back",
                                     style: .plain,
                                     target: self,
                                     action: #selector(previousButtonTapped(_:)))
        mergeScanButton = UIBarButtonItem(title: "Merge Scans…",
                                          style: .plain,
                                          target: self,
                                          action: #selector(addScanButtonTapped(_:)))
        let startOverButton = UIBarButtonItem(title: "Restart",
                                              style: .plain,
                                              target: self,
                                              action: #selector(restartButtonTapped(_:)))
        doneButton = UIBarButtonItem(title: "Done",
                                            style: .plain,
                                            target: self,
                                            action: #selector(restartButtonTapped(_:)))
        let navigationItem = UINavigationItem(title: "Start")
        navigationItem.leftBarButtonItem = backButton
        navigationItem.rightBarButtonItem = startOverButton
        guard let navBar = navigationBar else {
            return
        }
        navBar.items = [navigationItem]
        
        navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationBar.shadowImage = UIImage()
        navigationBar.isTranslucent = true
    }
    
    func showBackButton(_ show: Bool) {
        guard let navBar = navigationBar, let navItem = navBar.items?.first else {
            return }
        if show {
            navItem.leftBarButtonItem = backButton
        } else {
            navItem.leftBarButtonItem = nil
        }
    }
    
    func showDoneButton() {
        guard let navBar = navigationBar, let navItem = navBar.items?.first else {
            return }
        navItem.rightBarButtonItem = doneButton
        navItem.leftBarButtonItem = nil
    }
    
    func setNavigationBarTitle(_ title: String) {
        guard let navBar = navigationBar, let navItem = navBar.items?.first else {
            return }
        navItem.title = title
    }
}
