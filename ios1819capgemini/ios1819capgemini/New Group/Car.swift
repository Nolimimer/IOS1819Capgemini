//
//  Car.swift
//  ios1819capgemini
//
//  Created by MembrainDev on 19.11.18.
//  Copyright © 2018 TUM LS1. All rights reserved.
//

// MARK: Imports
import Foundation

// MARK: - Car
public class Car {
    private var vin: String
    private var carParts: [CarPartComponent]
    
    init(vin: String) {
        self.vin = vin
        carParts = [CarPartComponent]()
    }
}
