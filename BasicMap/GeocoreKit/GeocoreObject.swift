//
//  GeocoreObject.swift
//  GeocoreKit
//
//  Created by Purbo Mohamad on 4/15/15.
//
//

import Foundation
import SwiftyJSON
import PromiseKit
import Alamofire
#if os(iOS)
    import UIKit
    import AlamofireImage
#endif

// MARK: - Object Operations and Queries

/**
    Base class for all operations that can be used to interact with Geocore services
    to fetch and manipulate Geocore objects.
 */
open class GeocoreObjectOperation {
    
    private(set) open var id: String?
    private(set) open var customDataValue: String?
    private(set) open var customDataKey: String?
    
    public init() {
    }
    
    /**
     Assign the object ID to operate on.
     
     - parameter id: Object ID
     
     - returns: The updated operation object to be chain-called.
     */
    open func with(id: String) -> Self {
        self.id = id
        return self
    }
    
    open func with(customDataKey: String) -> Self {
        self.customDataKey = customDataKey
        return self
    }
    
    open func having(customDataValue value: String, forKey: String) -> Self {
        self.customDataValue = value
        self.customDataKey = forKey
        return self
    }
    
    open func buildPath(forService service: String) -> String {
        if let id = self.id {
            return "\(service)/\(id)"
        } else {
            return service
        }
    }
    
    open func buildPath(forService service: String, withSubPath subPath: String) -> String? {
        if let id = self.id {
            return "\(service)/\(id)\(subPath)"
        } else {
            return nil
        }
    }
    
    open func buildQueryParameters() -> Alamofire.Parameters {
        return Alamofire.Parameters()
    }
    
    open func save<TI: GeocoreIdentifiable, TO: GeocoreInitializableFromJSON>(_ obj: TI, forService service: String) -> Promise<TO> {
        if let sid = obj.sid {
            // use sid to determine whether this 'save' is for 'create' or 'update'
            // withId will only work for 'update'
            self.id = "\(sid)"
        }
        let params = buildQueryParameters()
        if params.count > 0 {
            return Geocore.sharedInstance.promisedPOST(buildPath(forService: service), parameters: params, body: obj.asDictionary())
        } else {
            return Geocore.sharedInstance.promisedPOST(buildPath(forService: service), parameters: nil, body: obj.asDictionary())
        }
    }
    
    open func delete<T: GeocoreIdentifiable>(_ obj: T, forService: String) -> Promise<T> {
        if let id = obj.id {
            self.id = id
            return Geocore.sharedInstance.promisedDELETE(buildPath(forService: forService))
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.invalidParameter(message: "Unsaved object cannot be deleted")) }
        }
    }
    
    open func deleteCustomData() -> Promise<GeocoreObject> {
        if let _ = self.id, let customDataKey = self.customDataKey {
            return Geocore.sharedInstance.promisedDELETE(buildPath(forService: "/objs", withSubPath: "/customData/\(customDataKey)")!)
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.invalidParameter(message: "Expecting id, custom data key")) }
        }
    }
    
}

open class GeocoreObjectQuery: GeocoreObjectOperation {
    
    private(set) open var unlimitedRecords: Bool
    private(set) open var name: String?
    private(set) open var fromDate: Date?
    private(set) open var page: Int?
    private(set) open var numberPerPage: Int?
    private(set) open var recentlyCreated: Bool?
    private(set) open var recentlyUpdated: Bool?
    private(set) open var associatedWithUnendingEvent: Bool?
    
    public override init() {
        self.unlimitedRecords = false
    }
    
    open func with(name: String) -> Self {
        self.name = name
        return self
    }
    
    open func updatedAfter(date: Date) -> Self {
        self.fromDate = date
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
    
    open func orderByRecentlyCreated() -> Self {
        self.recentlyCreated = true
        return self
    }
    
    open func orderByRecentlyUpdated() -> Self {
        self.recentlyUpdated = true
        return self
    }
    
    open func onlyObjectsAssociatedWithUnendingEvent() -> Self {
        self.associatedWithUnendingEvent = true
        return self
    }
    
    open override func buildQueryParameters() -> Alamofire.Parameters {
        var dict = super.buildQueryParameters()
        if unlimitedRecords {
            dict["num"] = 0
        } else {
            if let page = self.page {
                dict["page"] = page
            }
            if let numberPerPage = self.numberPerPage {
                dict["num"] = numberPerPage
            }
        }
        if let fromDate = self.fromDate {
            dict["from_date"] = DateFormatter.dateFormatterForGeocore().string(from: fromDate)
        }
        if let recentlyCreated = self.recentlyCreated {
            dict["recent_created"] = recentlyCreated
        }
        if let recentlyUpdated = self.recentlyUpdated {
            dict["recent_updated"] = recentlyUpdated
        }
        if let associatedWithUnendingEvent = self.associatedWithUnendingEvent {
            if (associatedWithUnendingEvent) {
                dict["bf_ev_end"] = DateFormatter.dateFormatterForGeocore().string(from: Date())
            }
        }
        
        return dict
    }
    
    open func get<T: GeocoreInitializableFromJSON>(forService: String) -> Promise<T> {
        if id != nil {
            return Geocore.sharedInstance.promisedGET(buildPath(forService: forService), parameters: buildQueryParameters())
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.invalidParameter(message: "Expecting id")) }
        }
    }
    
    open func all<T: GeocoreInitializableFromJSON>(forService: String) -> Promise<[T]> {
        return Geocore.sharedInstance.promisedGET(buildPath(forService: forService), parameters: buildQueryParameters())
    }
    
    open func get() -> Promise<GeocoreObject> {
        return self.get(forService: "/objs")
    }
    
    open func lastUpdate(forService: String) -> Promise<Date> {
        return Promise { fulfill, reject in
            Geocore.sharedInstance.GET("\(forService)/lastUpdate", callback: { (result: GeocoreResult<GeocoreGenericResult>) -> Void in
                switch result {
                case .success(let value):
                    if let lastUpdate = value.json["lastUpdate"].string {
                        if let lastUpdateDate = DateFormatter.dateFormatterForGeocore().date(from: lastUpdate) {
                            fulfill(lastUpdateDate)
                        } else {
                            reject(GeocoreError.unexpectedResponse(message: "Unable to convert lastUpdate to NSDate: \(lastUpdate)"))
                        }
                    } else {
                        reject(GeocoreError.unexpectedResponse(message: "Unable to find lastUpdate in response"))
                    }
                case .failure(let error):
                    reject(error)
                }
            })
        }
    }  
    
}

open class GeocoreObjectBinaryOperation: GeocoreObjectOperation {
    
    private(set) open var key: String?
    private(set) open var mimeType: String = "application/octet-stream"
    private(set) open var data: Data?
    
    open func with(key: String) -> Self {
        self.key = key
        return self
    }
    
    open func with(mimeType: String) -> Self {
        self.mimeType = mimeType
        return self
    }
    
    open func with(data: Data) -> Self {
        self.data = data
        return self
    }
    
    open func upload() -> Promise<GeocoreBinaryDataInfo> {
        if let id = self.id, let key = self.key, let data = self.data {
            return Geocore.sharedInstance.promisedUploadPOST(
                "/objs/\(id)/bins/\(key)",
                fieldName: "data",
                fileName: "data",
                mimeType: self.mimeType,
                fileContents: data)
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.invalidParameter(message: "Expecting both key and data")) }
        }
    }
    
    open func binaries() -> Promise<[String]> {
        if let path = buildPath(forService: "/objs", withSubPath: "/bins") {
            let generics: Promise<[GeocoreGenericResult]> = Geocore.sharedInstance.promisedGET(path, parameters: nil)
            return generics.then { (generics) -> [String] in
                var bins = [String]()
                for generic in generics {
                    bins.append(generic.json.string!)
                }
                return bins
            }
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.invalidParameter(message: "Expecting id")) }
        }
    }
    
    open func binary() -> Promise<GeocoreBinaryDataInfo> {
        if let key = self.key {
            if let path = buildPath(forService: "/objs", withSubPath: "/bins/\(key)/url") {
                return Geocore.sharedInstance.promisedGET(path, parameters: nil)
            } else {
                return Promise { fulfill, reject in reject(GeocoreError.invalidParameter(message: "Expecting id")) }
            }
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.invalidParameter(message: "Expecting key")) }
        }
    }
    
    open func url() -> Promise<String> {
        return self.binary().then { (binaryDataInfo) -> Promise<String> in
            if let url = binaryDataInfo.url {
                // TODO: should support https!
                // for now just replace https with http
                var finalUrl = url
                if (url.hasPrefix("https")) {
                    finalUrl = "http\(url.substring(from: url.index(url.startIndex, offsetBy: 5)))"
                }
                //print("url -> \(finalUrl)")
                return Promise(value: finalUrl)
                //return Promise(value: url)
            } else {
                return Promise { fulfill, reject in reject(GeocoreError.unexpectedResponse(message: "url is nil")) }
            }
        }
    }
    
    open func url<T>(_ transform: @escaping (String?, String) -> T) -> Promise<T> {
        return Promise { fulfill, reject in
            self.url()
                .then { url in
                    fulfill(transform(self.id, url))
                }
                .catch { error in
                    print("error getting url for id -> \(self.id)")
                    reject(error)
                }
        }
    }
    
    open func url<T>(_ transform: @escaping (String?, String?, String) -> T) -> Promise<T> {
        return Promise { fulfill, reject in
            self.url()
                .then { url in
                    fulfill(transform(self.id, self.key, url))
                }
                .catch { error in
                    print("error getting url for id -> \(self.id), \(self.key)")
                    reject(error)
            }
        }
    }
    
#if os(iOS)
    open func image() -> Promise<UIImage> {
        return Promise { fulfill, reject in
            self.url()
                .then { url in
                    Alamofire.request(url).responseImage { response in
                        if let image = response.result.value {
                            fulfill(image)
                        } else if let error = response.result.error {
                            reject(GeocoreError.unexpectedResponse(message: "Error downloading image: \(error)"))
                        } else {
                            reject(GeocoreError.unexpectedResponse(message: "Error downloading image: unknown error"))
                        }
                    }
                }
                .catch { error in
                    reject(error)
                }
        }
    }
    
    open func image<T>(_ transform: @escaping (String?, GeocoreBinaryDataInfo, UIImage) -> T) -> Promise<T> {
        return Promise { fulfill, reject in
            self.binary()
                .then { binaryDataInfo -> Void in
                    //print("binaryDataInfo -> \(binaryDataInfo)")
                    if let url = binaryDataInfo.url {
                        // TODO: should support https!
                        // for now just replace https with http
                        var finalUrl = url
                        if (url.hasPrefix("https")) {
                            finalUrl = "http\(url.substring(from: url.index(url.startIndex, offsetBy: 5)))"
                        }
                        //print("url -> \(finalUrl)")
                        Alamofire.request(finalUrl).responseImage { response in
                            if let image = response.result.value {
                                fulfill(transform(self.id, binaryDataInfo, image))
                            } else if let error = response.result.error {
                                reject(GeocoreError.unexpectedResponse(message: "Error downloading image: \(error)"))
                            } else {
                                reject(GeocoreError.unexpectedResponse(message: "Error downloading image: unknown error"))
                            }
                        }
                    } else {
                        reject(GeocoreError.unexpectedResponse(message: "Error downloading image: URL unavailable"))
                    }
                }
                .catch { error in
                    reject(error)
                }
        }
    }
#endif
    
}

// MARK: -

/**
    Information about binary data uploads.
 */
open class GeocoreBinaryDataInfo: GeocoreInitializableFromJSON {
    
    private(set) open var key: String?
    private(set) open var url: String?
    private(set) open var contentLength: Int64?
    private(set) open var contentType: String?
    private(set) open var lastModified: Date?
    
    public init() {
    }
    
    public required init(_ json: JSON) {
        if json.type == .string {
            self.key = json.string
        } else {
            self.key = json["key"].string
            self.url = json["url"].string
            self.contentLength = json["metadata"]["contentLength"].int64
            self.contentType = json["metadata"]["contentType"].string
            self.lastModified = Date.fromGeocoreFormattedString(json["metadata"]["lastModified"].string)
        }
    }
    
}

// MARK: -

open class GeocoreRelationshipOperation {
    
    private(set) open var id1: String?
    private(set) open var id2: String?
    private(set) open var customData: [String: String?]?
    
    open func with(object1Id: String) -> Self {
        self.id1 = object1Id
        return self
    }
    
    open func with(object2Id: String) -> Self {
        self.id2 = object2Id
        return self
    }
    
    open func with(customData: [String: String?]) -> Self {
        self.customData = customData
        return self
    }
    
    open func buildPath(forService: String, withSubPath: String) -> String {
        if let id1 = self.id1 {
            if let id2 = self.id2 {
                return "\(forService)/\(id1)\(withSubPath)/\(id2)"
            } else {
                return "\(forService)/\(id1)\(withSubPath)"
            }
        } else {
            return forService
        }
    }
    
    open func buildQueryParameters() -> Alamofire.Parameters {
        return Alamofire.Parameters()
    }

}

open class GeocoreRelationshipBinaryOperation: GeocoreRelationshipOperation {
    
    // TODO: should be refactored so the code can be shared with GeocoreObjectOperation
    private(set) open var key: String?
    private(set) open var mimeType: String = "application/octet-stream"
    private(set) open var data: Data?
    
    open func with(key: String) -> Self {
        self.key = key
        return self
    }
    
    open func with(mimeType: String) -> Self {
        self.mimeType = mimeType
        return self
    }
    
    open func with(data: Data) -> Self {
        self.data = data
        return self
    }
    
    open func upload() -> Promise<GeocoreBinaryDataInfo> {
        if let id1 = self.id1, let id2 = self.id2, let key = self.key, let data = self.data {
            return Geocore.sharedInstance.promisedUploadPOST(
                "/objs/relationship/\(id1)/\(id2)/bins/\(key)",
                fieldName: "data",
                fileName: "data",
                mimeType: self.mimeType,
                fileContents: data)
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.invalidParameter(message: "Expecting ids, key and data")) }
        }
    }
    
    open func binaries() -> Promise<[String]> {
        if let id1 = self.id1, let id2 = self.id2 {
            let path = "/objs/relationship/\(id1)/\(id2)/bins"
            let generics: Promise<[GeocoreGenericResult]> = Geocore.sharedInstance.promisedGET(path, parameters: nil)
            return generics.then { generics -> [String] in
                var bins = [String]()
                for generic in generics {
                    bins.append(generic.json.string!)
                }
                return bins
            }
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.invalidParameter(message: "Expecting ids")) }
        }
    }
    
    open func binary() -> Promise<GeocoreBinaryDataInfo> {
        if let id1 = self.id1, let id2 = self.id2, let key = self.key {
            let path = "/objs/relationship/\(id1)/\(id2)/bins/\(key)"
            return Geocore.sharedInstance.promisedGET(path, parameters: nil)
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.invalidParameter(message: "Expecting ids and key")) }
        }
    }
    
    open func url() -> Promise<String> {
        return self.binary().then { (binaryDataInfo) -> Promise<String> in
            if let url = binaryDataInfo.url {
                // TODO: should support https!
                // for now just replace https with http
                var finalUrl = url
                if (url.hasPrefix("https")) {
                    finalUrl = "http\(url.substring(from: url.index(url.startIndex, offsetBy: 5)))"
                }
                //print("url -> \(finalUrl)")
                return Promise(value: finalUrl)
            } else {
                return Promise { fulfill, reject in reject(GeocoreError.unexpectedResponse(message: "url is nil")) }
            }
        }
    }
    
    open func url<T>(_ transform: @escaping (String?, String?, String) -> T) -> Promise<T> {
        return Promise { fulfill, reject in
            self.url()
                .then { url in
                    fulfill(transform(self.id1, self.id2, url))
                }
                .catch { error in
                    print("error getting url for id -> \(self.id1), \(self.id2)")
                    reject(error)
            }
        }
    }
    
#if os(iOS)
    open func image() -> Promise<UIImage> {
        return Promise { fulfill, reject in
            self.url()
                .then { url in
                    Alamofire.request(url).responseImage { response in
                        if let image = response.result.value {
                            fulfill(image)
                        } else if let error = response.result.error {
                            reject(GeocoreError.unexpectedResponse(message: "Error downloading image: \(error)"))
                        } else {
                            reject(GeocoreError.unexpectedResponse(message: "Error downloading image: unknown error"))
                        }
                    }
                }
                .catch { error in
                    reject(error)
                }
        }
    }
    
    open func image<T>(_ transform: @escaping (String?, String?, GeocoreBinaryDataInfo, UIImage) -> T) -> Promise<T> {
        return Promise { fulfill, reject in
            self.binary()
                .then { binaryDataInfo -> Void in
                    //print("binaryDataInfo -> \(binaryDataInfo)")
                    if let url = binaryDataInfo.url {
                        // TODO: should support https!
                        // for now just replace https with http
                        var finalUrl = url
                        if (url.hasPrefix("https")) {
                            finalUrl = "http\(url.substring(from: url.index(url.startIndex, offsetBy: 5)))"
                        }
                        //print("url -> \(finalUrl)")
                        Alamofire.request(finalUrl).responseImage { response in
                            if let image = response.result.value {
                                fulfill(transform(self.id1, self.id2, binaryDataInfo, image))
                            } else if let error = response.result.error {
                                reject(GeocoreError.unexpectedResponse(message: "Error downloading image: \(error)"))
                            } else {
                                reject(GeocoreError.unexpectedResponse(message: "Error downloading image: unknown error"))
                            }
                        }
                    } else {
                        reject(GeocoreError.unexpectedResponse(message: "Error downloading image: URL unavailable"))
                    }
                }
                .catch { error in
                    reject(error)
                }
        }
    }
#endif
    
}

open class GeocoreRelationshipQuery: GeocoreRelationshipOperation {
    
    private var tagIds: [String]?
    private var tagNames: [String]?
    private var excludedTagIds: [String]?
    private var excludedTagNames: [String]?
    private var tagDetails = false
    
    open func with(tagIds: [String]) -> Self {
        self.tagIds = tagIds
        return self
    }
    
    open func exclude(tagIds: [String]) -> Self {
        self.excludedTagIds = tagIds
        return self
    }
    
    open func with(tagNames: [String]) -> Self {
        self.tagNames = tagNames
        return self
    }
    
    open func exclude(tagNames: [String]) -> Self {
        self.excludedTagNames = tagNames
        return self
    }
    
    open func withTagDetails() -> Self {
        self.tagDetails = true
        return self
    }
    
    open override func buildQueryParameters() -> Alamofire.Parameters {
        var dict = super.buildQueryParameters()
        if let tagIds = self.tagIds { dict["tag_ids"] = tagIds.joined(separator: ",") }
        if let tagNames = self.tagNames { dict["tag_names"] = tagNames.joined(separator: ",") }
        if let excludedTagIds = self.excludedTagIds { dict["excl_tag_ids"] = excludedTagIds.joined(separator: ",") }
        if let excludedTagNames = self.excludedTagNames { dict["excl_tag_names"] = excludedTagNames.joined(separator: ",") }
        if tagDetails { dict["tag_detail"] = "true" }
        return dict as [String : Any]
    }
    
}

// MARK: -

/**
    Base class of all objects managed by Geocore providing basic properties
    and services.
 */
open class GeocoreObject: GeocoreIdentifiable {
    
    open var sid: Int64?
    open var id: String?
    open var name: String?
    open var desc: String?
    private(set) open var createTime: Date?
    private(set) open var updateTime: Date?
    private(set) open var upvotes: Int64?
    private(set) open var downvotes: Int64?
    open var customData: [String: String?]?
    open var jsonData: JSON?
    
    public init() {
    }
    
    public required init(_ json: JSON) {
        self.sid = json["sid"].int64
        self.id = json["id"].string
        self.name = json["name"].string
        self.desc = json["description"].string
        self.createTime = Date.fromGeocoreFormattedString(json["createTime"].string)
        self.updateTime = Date.fromGeocoreFormattedString(json["updateTime"].string)
        self.upvotes = json["upvotes"].int64
        self.downvotes = json["downvotes"].int64
        self.customData = json["customData"].dictionary?.map { ($0, $1.string) }
        self.jsonData = json["jsonData"]
        if self.jsonData?.type == .null { self.jsonData = nil }
    }
    
    open func asDictionary() -> [String: Any] {
        // wish this can be automatic
        var dict = [String: Any]()
        if let sid = self.sid { dict["sid"] = sid }
        if let id = self.id { dict["id"] = id }
        if let name = self.name { dict["name"] = name }
        if let desc = self.desc { dict["description"] = desc }
        if let customData = self.customData { dict["customData"] = customData.filter{ $1 != nil }.map{ ($0, $1!) } }
        if let jsonData = self.jsonData { dict["jsonData"] = jsonData.rawString() }
        return dict
    }
    
    open func query() -> GeocoreObjectQuery {
        if let id = self.id {
            return GeocoreObjectQuery().with(id: id)
        } else {
            return GeocoreObjectQuery()
        }
    }
    
    open class func get(_ id: String) -> Promise<GeocoreObject> {
        return GeocoreObjectQuery().with(id: id).get();
    }
    
    open func save() -> Promise<GeocoreObject> {
        return GeocoreObjectOperation().save(self, forService: "/objs")
    }
    
    open func delete() -> Promise<GeocoreObject> {
        return GeocoreObjectOperation().delete(self, forService: "/objs")
    }
    
    open func upload(_ key: String, data: Data, mimeType: String) -> Promise<GeocoreBinaryDataInfo> {
        if let id = self.id {
            return GeocoreObjectBinaryOperation()
                .with(id: id)
                .with(key: key)
                .with(mimeType: mimeType)
                .with(data: data)
                .upload()
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.invalidParameter(message: "Unsaved object cannot upload binaries")) }
        }
    }
    
    open func binaries() -> Promise<[String]> {
        if let id = self.id {
            return GeocoreObjectBinaryOperation()
                .with(id: id)
                .binaries()
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.invalidParameter(message: "Unsaved object doesn't have binaries")) }
        }
    }
    
    open func binary(_ key: String) -> Promise<GeocoreBinaryDataInfo> {
        if let id = self.id {
            return GeocoreObjectBinaryOperation()
                .with(id: id)
                .with(key: key)
                .binary()
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.invalidParameter(message: "Unsaved object doesn't have binaries")) }
        }
    }

#if os(iOS)
    open func image(_ key: String) -> Promise<UIImage> {
        if let id = self.id {
            return GeocoreObjectBinaryOperation()
                .with(id: id)
                .with(key: key)
                .image()
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.invalidParameter(message: "Unsaved object doesn't have binaries")) }
        }
    }
#endif
    
    open func url(_ key: String) -> Promise<String> {
        if let id = self.id {
            return GeocoreObjectBinaryOperation()
                .with(id: id)
                .with(key: key)
                .url()
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.invalidParameter(message: "Unsaved object doesn't have binaries")) }
        }
    }
    
    open func addCustomData(_ key: String, value: String) -> Self {
        if self.customData == nil {
            self.customData = [String: String?]()
        }
        self.customData![key] = value
        return self
    }
    
    open func getCustomData(_ key: String) -> String? {
        if let value = customData?[key] {
            return value
        }
        return nil
    }
    
    open func updateCustomData(_ key: String, value: String?) -> Bool {
        var updated = false
        if let currentValue = self.customData?[key], let newValue = value {
            if currentValue != newValue {
                self.customData![key] = newValue
                updated = true
            }
        } else if self.customData != nil && value != nil {
            self.customData![key] = value
            updated = true
        } else if self.customData == nil && value != nil {
            self.customData = [String: String?]()
            self.customData![key] = value
            updated = true
        }
        return updated
    }
    
    open func deleteCustomData(_ key: String) -> Promise<GeocoreObject> {
        return GeocoreObjectOperation()
            .with(id: self.id!)
            .with(customDataKey: key)
            .deleteCustomData()
    }
    
}

open class GeocoreRelationship: GeocoreInitializableFromJSON, GeocoreSerializableToJSON {
    
    fileprivate(set) open var updateTime: Date?
    open var customData: [String: String?]?
    
    public init() {
    }
    
    public required init(_ json: JSON) {
        self.updateTime = Date.fromGeocoreFormattedString(json["updateTime"].string)
        self.customData = json["customData"].dictionary?.map { ($0, $1.string) }
    }
    
    open func asDictionary() -> [String: Any] {
        // wish this can be automatic
        var dict = [String: Any]()
        if let customData = self.customData { dict["customData"] = customData.filter{ $1 != nil }.map{ ($0, $1!) } }
        return dict
    }

    
}
