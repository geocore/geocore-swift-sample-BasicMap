//
//  GeocoreUtil.swift
//  GeocoreKit
//
//  Created by Purbo Mohamad on 4/23/15.
//
//

import Foundation

extension DateFormatter {
    
    class func dateFormatterWithEnUsPosixLocaleGMT() -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
        return dateFormatter
    }
    
    class func dateFormatterForGeocore() -> DateFormatter {
        let dateFormatter = DateFormatter.dateFormatterWithEnUsPosixLocaleGMT()
        dateFormatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
        return dateFormatter
    }
}

extension Date {
    
    public func geocoreFormattedString() -> String {
        return Geocore.geocoreDateFormatter.string(from: self)
    }
    
    public static func fromGeocoreFormattedString(_ string: String?) -> Date? {
        if let unwrappedString = string {
            return Geocore.geocoreDateFormatter.date(from: unwrappedString)
        } else {
            return nil
        }
    }
    
}

// adapted from:
// https://gist.github.com/yuchi/b6d751272cf4cb2b841f
extension Dictionary {
    
    func map<K: Hashable, V>(_ transform: (Key, Value) -> (K, V)) -> Dictionary<K, V> {
        var results: Dictionary<K, V> = [:]
        for key in self.keys {
            if let value = self[key] {
                let (u, w) = transform(key, value)
                results.updateValue(w, forKey: u)
            }
        }
        return results
    }
    
    func filter(_ includeElement: (Key, Value) -> Bool) -> Dictionary<Key, Value> {
        var results: Dictionary<Key, Value> = [:]
        for key in self.keys {
            if let value = self[key] {
                if includeElement(key, value) {
                    results.updateValue(value, forKey: key)
                }
            }
        }
        return results
    }
    
}

func +=<KeyType, ValueType>(left: inout Dictionary<KeyType, ValueType>, right: Dictionary<KeyType, ValueType>) {
    for (k, v) in right {
        left.updateValue(v, forKey: k)
    }
}
