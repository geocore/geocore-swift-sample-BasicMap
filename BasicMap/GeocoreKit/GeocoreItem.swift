//
//  GeocoreItem.swift
//  GeocoreKit
//
//  Created by Purbo Mohamad on 1/25/16.
//  Copyright © 2016 MapMotion. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import PromiseKit

public enum GeocoreItemType: String {
    case NonConsumable = "NON_CONSUMABLE"
    case Consumable = "CONSUMABLE"
    case Unknown = ""
}

open class GeocoreItemQuery: GeocoreTaggableQuery {
    
    fileprivate(set) open var validItems: Bool?
    
    open func onlyValidItems() -> Self {
        self.validItems = true
        return self
    }
    
    open override func buildQueryParameters() -> Alamofire.Parameters {
        var dict = super.buildQueryParameters()
        if let validItems = self.validItems { if validItems { dict["valid_only"] = "true" } }
        return dict
    }
    
    open func get() -> Promise<GeocoreItem> {
        return self.get(forService: "/items")
    }
    
    open func all() -> Promise<[GeocoreItem]> {
        return self.all(forService: "/items")
    }
    
    open func events() -> Promise<[GeocoreEvent]> {
        if let path = buildPath(forService: "/items", withSubPath: "/events") {
            return Geocore.sharedInstance.promisedGET(path)
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.invalidParameter(message: "Expecting id")) }
        }
    }
    
}

open class GeocoreItem: GeocoreTaggable {
    
    open var shortName: String?
    open var shortDescription: String?
    open var type: GeocoreItemType?
    open var validTimeStart: Date?
    open var validTimeEnd: Date?
    
    public override init() {
        super.init()
    }
    
    public required init(_ json: JSON) {
        self.shortName = json["shortName"].string
        self.shortDescription = json["shortDescription"].string
        if let type = json["type"].string { self.type = GeocoreItemType(rawValue: type) }
        self.validTimeStart = Date.fromGeocoreFormattedString(json["validTimeStart"].string)
        self.validTimeEnd = Date.fromGeocoreFormattedString(json["validTimeEnd"].string)
        super.init(json)
    }
    
    open override func asDictionary() -> [String: Any] {
        var dict = super.asDictionary()
        if let shortName = self.shortName { dict["shortName"] = shortName }
        if let shortDescription = self.shortDescription { dict["shortDescription"] = shortDescription }
        if let type = self.type { dict["type"] = type.rawValue }
        if let validTimeStart = self.validTimeStart { dict["validTimeStart"] = validTimeStart.geocoreFormattedString() }
        if let validTimeEnd = self.validTimeEnd { dict["validTimeEnd"] = validTimeEnd.geocoreFormattedString() }
        return dict
    }
    
    open class func get(_ id: String) -> Promise<GeocoreItem> {
        return GeocoreItemQuery().with(id: id).get();
    }
    
    open override func query() -> GeocoreItemQuery {
        if let id = self.id {
            return GeocoreItemQuery().with(id: id)
        } else {
            return GeocoreItemQuery()
        }
    }
    
    open class func all() -> Promise<[GeocoreItem]> {
        return GeocoreItemQuery().all()
    }
    
}


