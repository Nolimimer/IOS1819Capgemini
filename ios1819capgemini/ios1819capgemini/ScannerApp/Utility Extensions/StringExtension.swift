//
//  StringExtension.swift
//  ios1819capgemini
//
//  Created by Anna Kovaleva on 17.01.19.
//  Copyright © 2019 TUM LS1. All rights reserved.
//

import UIKit

extension String {
    private static let slugSafeCharacters = CharacterSet(charactersIn: "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-")
    
    public func convertedToSlug() -> String? {
        if let latin = self.applyingTransform(StringTransform("Any-Latin; Latin-ASCII; Lower;"), reverse: false) {
            let urlComponents = latin.components(separatedBy: String.slugSafeCharacters.inverted)
            let result = urlComponents.filter { !$0.isEmpty }.joined(separator: "_")
            if !result.isEmpty {
                return result
            }
        }
        
        return nil
    }
}
