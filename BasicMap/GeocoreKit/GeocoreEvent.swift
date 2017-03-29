//
//  GeocoreEvent.swift
//  GeocoreKit
//
//  Created by Purbo Mohamad on 11/30/15.
//  Copyright © 2015 MapMotion. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import PromiseKit

open class GeocoreEventQuery: GeocoreTaggableQuery {
    
    fileprivate(set) open var centerLatitude: Double?
    fileprivate(set) open var centerLongitude: Double?
    
    open func withCenter(latitude: Double, longitude: Double) -> Self {
        self.centerLatitude = latitude
        self.centerLongitude = longitude
        return self
    }
    
    open func get() -> Promise<GeocoreEvent> {
        return self.get(forService: "/events")
    }
    
    open func all() -> Promise<[GeocoreEvent]> {
        return self.all(forService: "/events")
    }
    
    open func places() -> Promise<[GeocorePlace]> {
        if let path = buildPath(forService: "/events", withSubPath: "/places") {
            return Geocore.sharedInstance.promisedGET(path)
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.invalidParameter(message: "Expecting id")) }
        }
    }
    
    open func tags() -> Promise<[GeocoreTag]> {
        if let path = buildPath(forService: "/events", withSubPath: "/tags") {
            return Geocore.sharedInstance.promisedGET(path)
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.invalidParameter(message: "Expecting id")) }
        }
    }
    
    open func placeRelationships() -> Promise<[GeocorePlaceEvent]> {
        if let path = buildPath(forService: "/events", withSubPath: "/places/relationships") {
            return Geocore.sharedInstance.promisedGET(path)
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.invalidParameter(message: "Expecting id")) }
        }
    }
    
    open func nearest() -> Promise<[GeocoreEvent]> {
        if let centerLatitude = self.centerLatitude, let centerLongitude = self.centerLongitude {
            var dict = super.buildQueryParameters()
            dict["lat"] = centerLatitude as AnyObject?
            dict["lon"] = centerLongitude as AnyObject?
            return Geocore.sharedInstance.promisedGET("/events/search/nearest", parameters: dict)
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.invalidParameter(message: "Expecting center lat-lon")) }
        }
    }
    
}

open class GeocoreEvent: GeocoreTaggable {
    
    fileprivate(set) open var timeStart: Date?
    fileprivate(set) open var timeEnd: Date?
    
    public override init() {
        super.init()
    }
    
    public required init(_ json: JSON) {
        self.timeStart = Date.fromGeocoreFormattedString(json["timeStart"].string)
        self.timeEnd = Date.fromGeocoreFormattedString(json["timeEnd"].string)
        super.init(json)
    }
    
    open override func asDictionary() -> [String: Any] {
        var dict = super.asDictionary()
        if let timeStart = self.timeStart { dict["timeStart"] = timeStart.geocoreFormattedString() }
        if let timeEnd = self.timeEnd { dict["timeEnd"] = timeEnd.geocoreFormattedString() }
        return dict
    }
    
    open class func get(_ id: String) -> Promise<GeocoreEvent> {
        return GeocoreEventQuery().with(id: id).get();
    }
    
    open override func query() -> GeocoreEventQuery {
        if let id = self.id {
            return GeocoreEventQuery().with(id: id)
        } else {
            return GeocoreEventQuery()
        }
    }
    
    open class func all() -> Promise<[GeocoreEvent]> {
        return GeocoreEventQuery().all()
    }
    
    open func places() -> Promise<[GeocorePlace]> {
        return query().places()
    }
    
    open func tags() -> Promise<[GeocoreTag]> {
        return query().tags()
    }
    
    open func currentlyOpen() -> Bool {
        if let timeStart = self.timeStart, let timeEnd = self.timeEnd {
            let now = Date()
            return timeStart.timeIntervalSince1970 <= now.timeIntervalSince1970 && now.timeIntervalSince1970 <= timeEnd.timeIntervalSince1970
        }
        return false
    }
    
}

