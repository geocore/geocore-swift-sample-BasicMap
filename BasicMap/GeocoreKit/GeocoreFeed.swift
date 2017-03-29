//
//  GeocoreFeed.swift
//  GeocoreKit
//
//  Created by Purbo Mohamad on 3/2/16.
//  Copyright © 2016 MapMotion. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import PromiseKit
#if os(iOS)
    import UIKit
#endif

open class GeocoreFeedOperation: GeocoreObjectOperation {
    
    fileprivate(set) open var type: String?
    fileprivate(set) open var idSpecifier: String?
    fileprivate(set) open var content: [String: AnyObject]?
    
    open func with(type: String) -> Self {
        self.type = type
        return self
    }
    
    open func with(idSpecifier: String) -> Self {
        self.idSpecifier = idSpecifier
        return self
    }
    
    open func with(content: [String: AnyObject]) -> Self {
        self.content = content
        return self
    }
    
    open override func buildQueryParameters() -> Alamofire.Parameters {
        var dict = super.buildQueryParameters()
        if let type = self.type { dict["type"] = type }
        if let idSpecifier = self.idSpecifier { dict["spec"] = idSpecifier }
        return dict
    }
    
    open func post() -> Promise<GeocoreFeed> {
        if let path = self.buildPath(forService: "/objs", withSubPath: "/feed"), let content = self.content {
            return Geocore.sharedInstance.promisedPOST(path, parameters: self.buildQueryParameters(), body: content)
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.invalidParameter(message: "Expecting id, content")) }
        }
    }
    
}

open class GeocoreFeedQuery: GeocoreFeedOperation {
    
    fileprivate(set) open var earliestTimestamp: Int64?
    fileprivate(set) open var latestTimestamp: Int64?
    fileprivate(set) open var startTimestamp: Int64?
    fileprivate(set) open var endTimestamp: Int64?
    fileprivate(set) open var page: Int?
    fileprivate(set) open var numberPerPage: Int?
    
    open func notEarlierThan(_ earliestDate: Date) -> Self {
        self.earliestTimestamp = Int64(earliestDate.timeIntervalSince1970 * 1000)
        return self
    }
    
    open func earlierThan(_ latestDate: Date) -> Self {
        self.latestTimestamp = Int64(latestDate.timeIntervalSince1970 * 1000)
        return self
    }
    
    open func startingAt(_ startDate: Date) -> Self {
        self.startTimestamp = Int64(startDate.timeIntervalSince1970 * 1000)
        return self
    }
    
    open func endingAt(_ endDate: Date) -> Self {
        self.endTimestamp = Int64(endDate.timeIntervalSince1970 * 1000)
        return self
    }
    
    open func page(_ page: Int) -> Self {
        self.page = page
        return self
    }
    
    open func numberPerPage(_ numberPerPage: Int) -> Self {
        self.numberPerPage = numberPerPage
        return self
    }
    
    open override func buildQueryParameters() -> Alamofire.Parameters {
        var dict = super.buildQueryParameters()
        if let startTimestamp = self.startTimestamp, let endTimestamp = self.endTimestamp {
            dict["from_timestamp"] = String(startTimestamp)
            dict["to_timestamp"] = String(endTimestamp)
        } else if let earliestTimestamp = self.earliestTimestamp {
            dict["from_timestamp"] = String(earliestTimestamp) as AnyObject?
        } else if let latestTimestamp = self.latestTimestamp {
            dict["to_timestamp"] = String(latestTimestamp) as AnyObject?
        }
        if let page = self.page {
            dict["page"] = page as AnyObject?
        }
        if let numberPerPage = self.numberPerPage {
            dict["num"] = numberPerPage as AnyObject?
        }
        return dict
    }
    
    open func all() -> Promise<[GeocoreFeed]> {
        if let path = self.buildPath(forService: "/objs", withSubPath: "/feed") {
            return Geocore.sharedInstance.promisedGET(path, parameters: self.buildQueryParameters())
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.invalidParameter(message: "Expecting id")) }
        }
    }
    
}

open class GeocoreFeed: GeocoreInitializableFromJSON, GeocoreSerializableToJSON {
    
    open var id: String?
    open var type: String?
    open var timestamp: Int64?
    open var date: Date? {
        get {
            if let timestamp = self.timestamp {
                return Date(timeIntervalSince1970: Double(timestamp)/1000.0)
            } else {
                return nil
            }
        }
        set (newDate) {
            if let someNewDate = newDate {
                self.timestamp = Int64(someNewDate.timeIntervalSince1970 * 1000)
            }
        }
    }
    open var content: [String: AnyObject]?
    
    public init() {
    }
    
    public required init(_ json: JSON) {
        self.id = json["id"].string
        self.type = json["type"].string
        self.timestamp = json["timestamp"].int64
        self.content = json["objContent"].dictionary?.map { (key, optValue) -> (String, String) in
            // some value may be nil (HA???)
            //($0, $1.string!)
            if let value = optValue.string {
                return (key, value)
            } else {
                return (key, "")
            }
        } as [String : AnyObject]?
    }
    
    open func asDictionary() -> [String: Any] {
        if let content = self.content {
            return content
        } else {
            return [String: Any]()
        }
    }
    
    fileprivate func resolveType() -> String? {
        if let type = self.type {
            return type
        } else if let id = self.id {
            if id.hasPrefix("PRO") {
               return "jp.geocore.entity.Project"
            } else if id.hasPrefix("USE") {
               return "jp.geocore.entity.User"
            } else if id.hasPrefix("GRO") {
                return "jp.geocore.entity.Group"
            } else if id.hasPrefix("PLA") {
                return "jp.geocore.entity.Place"
            } else if id.hasPrefix("EVE") {
                return "jp.geocore.entity.Event"
            } else if id.hasPrefix("ITE") {
                return "jp.geocore.entity.Item"
            } else if id.hasPrefix("TAG") {
                return "jp.geocore.entity.Tag"
            }
        }
        return nil
    }
    
    open func post() -> Promise<GeocoreFeed> {
        if let id = self.id, let content = self.content {
            let op = GeocoreFeedOperation().with(id: id).with(content: content)
            if let type = self.resolveType() {
                _ = op.with(type: type)
            }
            return op.post()
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.invalidParameter(message: "Expecting id, content")) }
        }
    }
    
}


