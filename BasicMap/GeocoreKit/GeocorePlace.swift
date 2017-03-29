//
//  GeocorePlace.swift
//  GeocoreKit
//
//  Created by Purbo Mohamad on 11/21/15.
//
//

import Foundation
import Alamofire
import SwiftyJSON
import PromiseKit

open class GeocorePlacesSmallestBound: GeocoreInitializableFromJSON {
    
    fileprivate(set) open var minLatitude: Double?
    fileprivate(set) open var minLongitude: Double?
    fileprivate(set) open var maxLatitude: Double?
    fileprivate(set) open var maxLongitude: Double?
    
    public required init(_ json: JSON) {
        self.minLatitude = json["min_lat"].double
        self.minLongitude = json["min_lon"].double
        self.maxLatitude = json["max_lat"].double
        self.maxLongitude = json["max_lon"].double
    }
    
    open func center() -> (Double, Double)? {
        if let maxlat = self.maxLatitude, let minlat = self.minLatitude, let maxlon = self.maxLongitude, let minlon = self.minLongitude {
            return ((maxlat + minlat)/2, (maxlon + minlon)/2)
        } else {
            return nil
        }
    }
    
    open func span() -> (Double, Double)? {
        if let maxlat = self.maxLatitude, let minlat = self.minLatitude, let maxlon = self.maxLongitude, let minlon = self.minLongitude {
            return (abs(maxlat - minlat), abs(maxlon - minlon))
        } else {
            return nil
        }
    }

}

open class GeocorePlaceOperation: GeocoreTaggableOperation {
    
}

open class GeocorePlaceQuery: GeocoreTaggableQuery {
    
    fileprivate(set) open var centerLatitude: Double?
    fileprivate(set) open var centerLongitude: Double?
    fileprivate(set) open var radius: Double?
    
    fileprivate(set) open var minimumLatitude: Double?
    fileprivate(set) open var minimumLongitude: Double?
    fileprivate(set) open var maximumLatitude: Double?
    fileprivate(set) open var maximumLongitude: Double?
    
    fileprivate(set) open var checkinable: Bool?
    fileprivate(set) open var validItems: Bool?
    fileprivate var eventDetails = false
    
    open func withCenter(latitude: Double, longitude: Double) -> Self {
        self.centerLatitude = latitude
        self.centerLongitude = longitude
        return self
    }
    
    open func withRadius(_ radius: Double) -> Self {
        self.radius = radius
        return self
    }
    
    open func withRectangle(minimumLatitude: Double, minimumLongitude: Double, maximumLatitude: Double, maximumLongitude: Double) -> Self {
        self.minimumLatitude = minimumLatitude
        self.minimumLongitude = minimumLongitude
        self.maximumLatitude = maximumLatitude
        self.maximumLongitude = maximumLongitude
        return self
    }
    
    open func onlyCheckinable() -> Self {
        self.checkinable = true
        return self
    }
    
    open func onlyValidItems() -> Self {
        self.validItems = true
        return self
    }
    
    open func withEventDetails() -> Self {
        self.eventDetails = true
        return self
    }
    
    open func get() -> Promise<GeocorePlace> {
        return self.get(forService: "/places")
    }
    
    open class func get(_ id: String) -> Promise<GeocorePlace> {
        return GeocorePlaceQuery().with(id: id).get();
    }
    
    open func all() -> Promise<[GeocorePlace]> {
        return self.all(forService: "/places")
    }
    
    open override func buildQueryParameters() -> Alamofire.Parameters {
        var dict = super.buildQueryParameters()
        if eventDetails { dict["event_detail"] = "true" }
        if let checkinable = self.checkinable { if checkinable { dict["checkinable"] = "true" } }
        return dict
    }
    
    open func nearest() -> Promise<[GeocorePlace]> {
        if let centerLatitude = self.centerLatitude, let centerLongitude = self.centerLongitude {
            var dict = buildQueryParameters()
            dict["lat"] = centerLatitude as AnyObject?
            dict["lon"] = centerLongitude as AnyObject?
            return Geocore.sharedInstance.promisedGET("/places/search/nearest", parameters: dict)
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.invalidParameter(message: "Expecting center lat-lon")) }
        }
    }
    
    open func smallestBounds() -> Promise<GeocorePlacesSmallestBound> {
        if let centerLatitude = self.centerLatitude, let centerLongitude = self.centerLongitude {
            var dict = buildQueryParameters()
            dict["lat"] = centerLatitude as AnyObject?
            dict["lon"] = centerLongitude as AnyObject?
            return Geocore.sharedInstance.promisedGET("/places/search/smallestbounds", parameters: dict)
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.invalidParameter(message: "Expecting center lat-lon")) }
        }
    }
    
    fileprivate func circleQuery(_ withPath: String) -> Promise<[GeocorePlace]> {
        if let centerLatitude = self.centerLatitude, let centerLongitude = self.centerLongitude, let radius = self.radius {
            var dict = buildQueryParameters()
            dict["lat"] = centerLatitude as AnyObject?
            dict["lon"] = centerLongitude as AnyObject?
            dict["radius"] = radius as AnyObject?
            return Geocore.sharedInstance.promisedGET(withPath, parameters: dict)
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.invalidParameter(message: "Expecting center lat-lon, radius")) }
        }
    }
    
    open func withinCircle() -> Promise<[GeocorePlace]> {
        return self.circleQuery("/places/search/within/circle")
    }
    
    open func intersectsCircle() -> Promise<[GeocorePlace]> {
        return self.circleQuery("/places/search/intersects/circle")
    }
    
    fileprivate func rectangleQuery(_ withPath: String) -> Promise<[GeocorePlace]> {
        if let minlat = self.minimumLatitude, let maxlat = self.maximumLatitude, let minlon = self.self.minimumLongitude, let maxlon = self.maximumLongitude  {
            var dict = buildQueryParameters()
            dict["min_lat"] = minlat as AnyObject?
            dict["max_lat"] = maxlat as AnyObject?
            dict["min_lon"] = minlon as AnyObject?
            dict["max_lon"] = maxlon as AnyObject?
            return Geocore.sharedInstance.promisedGET(withPath, parameters: dict)
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.invalidParameter(message: "Expecting min/max lat-lon")) }
        }
    }
    
    open func withinRectangle() -> Promise<[GeocorePlace]> {
        return self.rectangleQuery("/places/search/within/rect")
    }
    
    open func intersectsRectangle() -> Promise<[GeocorePlace]> {
        return self.rectangleQuery("/places/search/intersects/rect")
    }
    
    open func events() -> Promise<[GeocoreEvent]> {
        if let path = buildPath(forService: "/places", withSubPath: "/events") {
            return Geocore.sharedInstance.promisedGET(path)
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.invalidParameter(message: "Expecting id")) }
        }
    }
    
    open func eventRelationships() -> Promise<[GeocorePlaceEvent]> {
        if let path = buildPath(forService: "/places", withSubPath: "/events/relationships") {
            return Geocore.sharedInstance.promisedGET(path)
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.invalidParameter(message: "Expecting id")) }
        }
    }
    
    open func items() -> Promise<[GeocoreItem]> {
        if let path = buildPath(forService: "/places", withSubPath: "/items") {
            var dict = buildQueryParameters()
            if let validItems = self.validItems { if validItems { dict["valid_only"] = "true" as AnyObject? } }
            return Geocore.sharedInstance.promisedGET(path, parameters: dict)
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.invalidParameter(message: "Expecting id")) }
        }
    }
    
}

open class GeocorePlace: GeocoreTaggable {
    
    open var shortName: String?
    open var shortDescription: String?
    open var point: GeocorePoint?
    open var distanceLimit: Float?
    
    open var prefetchedEvents: [GeocoreEvent]?
    
    // TODO: clumsy but will do for now
    // probably should immutabilize all the things
    open var operation: GeocorePlaceOperation?
    
    public override init() {
        super.init()
    }
    
    public required init(_ json: JSON) {
        self.shortName = json["shortName"].string
        self.shortDescription = json["shortDescription"].string
        self.point = GeocorePoint(json["point"])
        self.distanceLimit = json["distanceLimit"].float
        if let eventsJSON = json["events"].array {
            self.prefetchedEvents = eventsJSON.map({ GeocoreEvent($0) })
        }
        super.init(json)
    }
    
    open override func asDictionary() -> [String : Any] {
        var dict = super.asDictionary()
        if let shortName = self.shortName { dict["shortName"] = shortName }
        if let shortDescription = self.shortDescription { dict["shortDescription"] = shortDescription }
        if let point = self.point { dict["point"] = point.asDictionary() }
        if let distanceLimit = self.distanceLimit { dict["distanceLimit"] = distanceLimit }
        return dict
    }
    
    open override func query() -> GeocorePlaceQuery {
        if let id = self.id {
            return GeocorePlaceQuery().with(id: id)
        } else {
            return GeocorePlaceQuery()
        }
    }
    
    open class func all() -> Promise<[GeocorePlace]> {
        return GeocorePlaceQuery().all()
    }
    
    open func events() -> Promise<[GeocoreEvent]> {
        if let prefetchedEvents = self.prefetchedEvents {
            return Promise { fulfill, reject in fulfill(prefetchedEvents) }
        } else {
            return query()
                .events()
                .then { events -> [GeocoreEvent] in
                    self.prefetchedEvents = events
                    return events
                }
        }
    }
    
    @discardableResult
    open func tag(_ tagIdsOrNames: [String]) -> Self {
        if self.operation == nil {
            self.operation = GeocorePlaceOperation()
        }
        _ = self.operation?.tag(tagIdsOrNames)
        return self
    }
    
    open func save() -> Promise<GeocorePlace> {
        if let operation = self.operation {
            return operation.save(self, forService: "/places")
        } else {
            return GeocoreObjectOperation().save(self, forService: "/places")
        }
    }
    
    open func delete() -> Promise<GeocorePlace> {
        return GeocoreObjectOperation().delete(self, forService: "/places")
    }
    
    open func checkin(latitude: Double, longitude: Double) -> Promise<GeocorePlaceCheckin> {
        return self.checkin(latitude: latitude, longitude: longitude, unrestricted: false)
    }
    
    open func checkin(latitude: Double, longitude: Double, unrestricted: Bool) -> Promise<GeocorePlaceCheckin> {
        let checkin = GeocorePlaceCheckin()
        checkin.userId = Geocore.sharedInstance.userId
        checkin.placeId = self.id
        checkin.latitude = latitude
        checkin.longitude = longitude
        checkin.accuracy = 0
        if let placeId = self.id {
            var params: [String: AnyObject]?
            if unrestricted {
                params = ["unrestricted": "true" as AnyObject]
            }
            return Geocore.sharedInstance.promisedPOST("/places/\(placeId)/checkins", parameters: params, body: checkin.asDictionary())
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.invalidParameter(message: "Expecting id")) }
        }
    }
    
}

open class GeocorePlaceCheckin: GeocoreInitializableFromJSON, GeocoreSerializableToJSON {
    
    open var userId: String?
    open var placeId: String?
    open var timestamp: UInt64?
    open var latitude: Double?
    open var longitude: Double?
    open var accuracy: Double?
    open var date: Date?
    
    public init() {
    }

    public required init(_ json: JSON) {
        self.userId = json["userId"].string
        self.placeId = json["placeId"].string
        self.timestamp = json["timestamp"].uInt64
        if let timestamp = self.timestamp {
            self.date = NSDate(timeIntervalSince1970: Double(timestamp)/1000.0) as Date
        }
        self.latitude = json["latitude"].double
        self.longitude = json["longitude"].double
        self.accuracy = json["accuracy"].double
    }
    
    open func asDictionary() -> [String: Any] {
        var dict = [String: Any]()
        if let userId = self.userId { dict["userId"] = userId }
        if let placeId = self.placeId { dict["placeId"] = placeId }
        if let timestamp = self.timestamp { dict["timestamp"] = String(timestamp) }
        if let date = self.date {
            dict["timestamp"] = String(UInt64(date.timeIntervalSince1970 * 1000))
        }
        if let latitude = self.latitude, let longitude = self.longitude {
            dict["latitude"] = String(latitude)
            dict["longitude"] = String(longitude)
        }
        if let accuracy = self.accuracy {
            dict["accuracy"] = String(accuracy)
        }
        return dict
    }
    
}

open class GeocorePlaceEvent: GeocoreRelationship {
    
    open var place: GeocorePlace?
    open var event: GeocoreEvent?
    
    public required init(_ json: JSON) {
        super.init(json)
        if let pk = json["pk"].dictionary {
            if let placeDict = pk["place"] {
                self.place = GeocorePlace(placeDict)
            }
            if let eventDict = pk["event"] {
                self.event = GeocoreEvent(eventDict)
            }
        }
    }
    
}
