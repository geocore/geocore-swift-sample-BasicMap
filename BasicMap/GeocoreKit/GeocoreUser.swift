//
//  GeocoreUser.swift
//  GeocoreKit
//
//  Created by Purbo Mohamad on 11/21/15.
//
//

import Foundation
import Alamofire
import SwiftyJSON
import PromiseKit
#if os(iOS)
    import UIKit
#endif

public enum GeocoreUserEventRelationshipType: String {
    case organizer = "ORGANIZER"
    case performer = "PERFORMER"
    case participant = "PARTICIPANT"
    case attendant = "ATTENDANT"
    case custom01 = "CUSTOM01"
    case custom02 = "CUSTOM02"
    case custom03 = "CUSTOM03"
    case custom04 = "CUSTOM04"
    case custom05 = "CUSTOM05"
    case custom06 = "CUSTOM06"
    case custom07 = "CUSTOM07"
    case custom08 = "CUSTOM08"
    case custom09 = "CUSTOM09"
    case custom10 = "CUSTOM10"
}

public enum GeocoreUserPlaceRelationshipType: String {
    case creator = "CREATOR"
    case owner = "OWNER"
    case manager = "MANAGER"
    case organizer = "ORGANIZER"
    case staff = "STAFF"
    case seller = "SELLER"
    case agent = "AGENT"
    case realtor = "REALTOR"
    case follower = "FOLLOWER"
    case supporter = "SUPPORTER"
    case visitor = "VISITOR"
    case customer = "CUSTOMER"
    case player = "PLAYER"
    case member = "MEMBER"
    case buyer = "BUYER"
    case custom01 = "CUSTOM01"
    case custom02 = "CUSTOM02"
    case custom03 = "CUSTOM03"
    case custom04 = "CUSTOM04"
    case custom05 = "CUSTOM05"
    case custom06 = "CUSTOM06"
    case custom07 = "CUSTOM07"
    case custom08 = "CUSTOM08"
    case custom09 = "CUSTOM09"
    case custom10 = "CUSTOM10"
}

open class GeocoreUserOperation: GeocoreTaggableOperation {
    
    fileprivate var groupIds: [String]?
    
    open func addTo(groupIds: [String]) {
        self.groupIds = groupIds
    }
    
    open override func buildQueryParameters() -> Alamofire.Parameters {
        var dict = super.buildQueryParameters()
        if let groupIds = self.groupIds {
            dict["group_ids"] = groupIds.joined(separator: ",")
        }
        dict["project_id"] = Geocore.sharedInstance.projectId
        return dict
    }
    
    open func register(user: GeocoreUser, callback: @escaping (GeocoreResult<GeocoreUser>) -> Void) {
        Geocore.sharedInstance.POST(
            "/register",
            parameters: buildQueryParameters(),
            body: user.asDictionary(),
            callback: callback)
    }
    
    open func register(user: GeocoreUser) -> Promise<GeocoreUser> {
        let params = buildQueryParameters()
        if params.count > 0 {
            return Geocore.sharedInstance.promisedPOST(
                "/register",
                parameters: params,
                body: user.asDictionary())
        } else {
            return Geocore.sharedInstance.promisedPOST(
                "/register",
                parameters: user.asDictionary())
        }
    }
    
}

open class GeocoreUserTagOperation: GeocoreTaggableOperation {
    
    open func update() -> Promise<[GeocoreTag]> {
        let params = buildQueryParameters()
        if params.count > 0 {
            if let path = buildPath(forService: "/users", withSubPath: "/tags") {
                // body cannot be nil, otherwise params will go to body
                return Geocore.sharedInstance.promisedPOST(path, parameters: params, body: [String: Any]())
            } else {
                return Promise { fulfill, reject in reject(GeocoreError.invalidParameter(message: "Expecting id")) }
            }
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.invalidParameter(message: "Expecting tag parameters")) }
        }
    }
    
}

open class GeocoreUserQuery: GeocoreTaggableQuery {
    
    fileprivate(set) open var alternateIdIndex: Int?
    
    open func forAlternateIdIndex(_ alternateIdIndex: Int) -> Self {
        self.alternateIdIndex = alternateIdIndex
        return self
    }
    
    open override func buildQueryParameters() -> Alamofire.Parameters {
        var dict = super.buildQueryParameters()
        if let alternateIdIndex = self.alternateIdIndex {
            dict["alt"] = alternateIdIndex
        }
        return dict
    }
    
    open func get() -> Promise<GeocoreUser> {
        return self.get(forService: "/users")
    }
    
    open func eventRelationships() -> Promise<[GeocoreUserEvent]> {
        if let userId = self.id {
            return GeocoreUserEventQuery().with(object1Id: userId).all()
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.invalidParameter(message: "Expecting id")) }
        }
    }
    
    open func eventRelationships(_ event: GeocoreEvent) -> Promise<[GeocoreUserEvent]> {
        if let userId = self.id {
            return GeocoreUserEventQuery()
                .with(object1Id: userId)
                .with(object2Id: event.id!)
                .all()
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.invalidParameter(message: "Expecting id")) }
        }
    }
    
    open func placeRelationships() -> Promise<[GeocoreUserPlace]> {
        if let userId = self.id {
            return GeocoreUserPlaceQuery().with(object1Id: userId).all()
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.invalidParameter(message: "Expecting id")) }
        }
    }
    
    open func placeRelationships(_ place: GeocorePlace) -> Promise<[GeocoreUserPlace]> {
        if let userId = self.id {
            return GeocoreUserPlaceQuery()
                .with(object1Id: userId)
                .with(object2Id: place.id!)
                .all()
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.invalidParameter(message: "Expecting id")) }
        }
    }
    
    open func itemRelationships() -> Promise<[GeocoreUserItem]> {
        if let userId = self.id {
            return GeocoreUserItemQuery().with(object1Id: userId).all()
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.invalidParameter(message: "Expecting id")) }
        }
    }
    
}

open class GeocoreUser: GeocoreTaggable {
    
    public static let customDataKeyFacebookID = "sns.fb.id"
    public static let customDataKeyFacebookName = "sns.fb.name"
    public static let customDataKeyFacebookEmail = "sns.fb.email"
    public static let customDataKeyTwitterID = "sns.tw.id"
    public static let customDataKeyTwitterName = "sns.tw.name"
    public static let customDataKeyGooglePlusID = "sns.gp.id"
    public static let customDataKeyGooglePlusName = "sns.gp.name"
    
    public static let customDataKeyiOSPushToken = "push.ios.token"
    public static let customDataKeyiOSPushLanguage = "push.ios.lang"
    public static let customDataKeyiOSPushEnabled = "push.enabled"
    
    public var alternateId1: String?
    public var alternateId2: String?
    public var alternateId3: String?
    public var alternateId4: String?
    public var alternateId5: String?
    
    public var password: String?
    public var email: String?
    private(set) public var lastLocationTime: Date?
    private(set) public var lastLocation: GeocorePoint?
    
    public override init() {
        super.init()
    }
    
    public required init(_ json: JSON) {
        
        self.email = json["email"].string
        self.alternateId1 = json["alternateId1"].string
        self.alternateId2 = json["alternateId2"].string
        self.alternateId3 = json["alternateId3"].string
        self.alternateId4 = json["alternateId4"].string
        self.alternateId5 = json["alternateId5"].string
        
        self.lastLocationTime = Date.fromGeocoreFormattedString(json["lastLocationTime"].string)
        self.lastLocation = GeocorePoint(json["lastLocation"])
        super.init(json)
    }
    
    open override func asDictionary() -> [String: Any] {
        var dict = super.asDictionary()
        if let password = self.password { dict["password"] = password as AnyObject? }
        if let email = self.email { dict["email"] = email as AnyObject? }
        if let alternateId1 = self.alternateId1 { dict["alternateId1"] = alternateId1 as AnyObject? }
        if let alternateId2 = self.alternateId2 { dict["alternateId2"] = alternateId2 as AnyObject? }
        if let alternateId3 = self.alternateId3 { dict["alternateId3"] = alternateId3 as AnyObject? }
        if let alternateId4 = self.alternateId4 { dict["alternateId4"] = alternateId4 as AnyObject? }
        if let alternateId5 = self.alternateId5 { dict["alternateId5"] = alternateId5 as AnyObject? }
        return dict
    }
    
    open class func userId(withSuffix suffix: String) -> String {
        if let projectId = Geocore.sharedInstance.projectId {
            if projectId.hasPrefix("PRO") {
                // user ID pattern: USE-[project_suffix]-[user_id_suffix]
                return "USE\(projectId.substring(from: projectId.index(projectId.startIndex, offsetBy: 3)))-\(suffix)"
            } else {
                return suffix
            }
        } else {
            return suffix
        }
    }
    
    open class func defaultName() -> String {
        #if os(iOS)
            #if (arch(i386) || arch(x86_64))
                // iOS simulator
                return "IOS_SIMULATOR"
            #else
                // iOS device
                return UIDevice.current.identifierForVendor!.uuidString
            #endif
        #else
            // TODO: generate ID on OSX based on user's device ID
            return "DEFAULT"
        #endif
    }
    
    open class func defaultId() -> String {
        return userId(withSuffix: defaultName())
    }
    
    open class func defaultEmail() -> String {
        return "\(defaultName())@geocore.jp"
    }
    
    open class func defaultPassword() -> String {
        return String(defaultId().characters.reversed())
    }
    
    open func setFacebookUser(_ id: String, name: String) {
        _ = self
            .addCustomData(GeocoreUser.customDataKeyFacebookID, value: id)
            .addCustomData(GeocoreUser.customDataKeyFacebookName, value: name)
    }
    
    open func isFacebookUser() -> Bool {
        if let customData = self.customData {
            return customData[GeocoreUser.customDataKeyFacebookID] != nil
        }
        return false
    }
    
    open func facebookID() -> String? {
        if let customData = self.customData {
            if let val = customData[GeocoreUser.customDataKeyFacebookID] {
                return val
            }
        }
        return nil
    }
    
    open func facebookName() -> String? {
        if let customData = self.customData {
            if let val = customData[GeocoreUser.customDataKeyFacebookName] {
                return val
            }
        }
        return nil
    }
    
    open func setTwitterUser(_ id: String, name: String) {
        _ = self
            .addCustomData(GeocoreUser.customDataKeyTwitterID, value: id)
            .addCustomData(GeocoreUser.customDataKeyTwitterName, value: name)
    }
    
    open func isTwitterUser() -> Bool {
        if let customData = self.customData {
            return customData[GeocoreUser.customDataKeyTwitterID] != nil
        }
        return false
    }
    
    open func twitterID() -> String? {
        if let customData = self.customData {
            if let val = customData[GeocoreUser.customDataKeyTwitterID] {
                return val
            }
        }
        return nil
    }
    
    open func twitterName() -> String? {
        if let customData = self.customData {
            if let val = customData[GeocoreUser.customDataKeyTwitterName] {
                return val
            }
        }
        return nil
    }
    
    open func setGooglePlusUser(_ id: String, name: String) {
        _ = self
            .addCustomData(GeocoreUser.customDataKeyGooglePlusID, value: id)
            .addCustomData(GeocoreUser.customDataKeyGooglePlusName, value: name)
    }
    
    open func isGooglePlusUser() -> Bool {
        if let customData = self.customData {
            return customData[GeocoreUser.customDataKeyGooglePlusID] != nil
        }
        return false
    }
    
    open func googlePlusID() -> String? {
        if let customData = self.customData {
            if let val = customData[GeocoreUser.customDataKeyGooglePlusID] {
                return val
            }
        }
        return nil
    }
    
    open func googlePlusName() -> String? {
        if let customData = self.customData {
            if let val = customData[GeocoreUser.customDataKeyGooglePlusName] {
                return val
            }
        }
        return nil
    }
    
    open func registerForPushNotications(_ token: Data, preferredLanguage: String? = nil, enabled: Bool = true) -> Promise<GeocoreUser> {
        let tokenUpdated = self.updateCustomData(GeocoreUser.customDataKeyiOSPushToken, value: token.description)
        let langUpdated = self.updateCustomData(GeocoreUser.customDataKeyiOSPushLanguage, value: preferredLanguage)
        let enabledUpdated = self.updateCustomData(GeocoreUser.customDataKeyiOSPushEnabled, value: enabled.description)
        if (tokenUpdated || langUpdated || enabledUpdated) {
            return self.save()
        } else {
            return Promise { fulfill, reject in fulfill(self) }
        }
    }
    
    open class func defaultUser() -> GeocoreUser {
        let user = GeocoreUser()
        user.id = GeocoreUser.defaultId()
        user.name = GeocoreUser.defaultName()
        user.email = GeocoreUser.defaultEmail()
        user.password = GeocoreUser.defaultPassword()
        return user
    }
    
    open class func get(_ id: String) -> Promise<GeocoreUser> {
        return GeocoreUserQuery().with(id: id).get();
    }
    
    open func register() -> Promise<GeocoreUser> {
        return GeocoreUserOperation().register(user: self)
    }
    
    open func save() -> Promise<GeocoreUser> {
        return GeocoreObjectOperation().save(self, forService: "/users")
    }
    
    open func eventRelationships() -> Promise<[GeocoreUserEvent]> {
        return GeocoreUserQuery().with(id: self.id!).eventRelationships()
    }
    
    open func eventRelationships(_ event: GeocoreEvent) -> Promise<[GeocoreUserEvent]> {
        return GeocoreUserQuery().with(id: self.id!).eventRelationships(event)
    }
    
    open func placeRelationships() -> Promise<[GeocoreUserPlace]> {
        return GeocoreUserQuery().with(id: self.id!).placeRelationships()
    }
    
    open func placeRelationships(_ place: GeocorePlace) -> Promise<[GeocoreUserPlace]> {
        return GeocoreUserQuery().with(id: self.id!).placeRelationships(place)
    }
    
    open func itemRelationships() -> Promise<[GeocoreUserItem]> {
        return GeocoreUserQuery().with(id: self.id!).itemRelationships()
    }
    
    open func tagOperation() -> GeocoreUserTagOperation {
        return GeocoreUserTagOperation().with(id: self.id!)
    }
    
}

open class GeocoreUserEventOperation: GeocoreRelationshipOperation {
    
    private(set) open var relationshipType: GeocoreUserEventRelationshipType?
    
    open func with(user: GeocoreUser) -> Self {
        _ = super.with(object1Id: user.id!)
        return self
    }
    
    open func with(event: GeocoreEvent) -> Self {
        _ = super.with(object2Id: event.id!)
        return self
    }
    
    open func with(relationshipType: GeocoreUserEventRelationshipType) -> Self {
        self.relationshipType = relationshipType
        return self
    }
    
    open override func buildPath(forService: String, withSubPath: String) -> String {
        if let id1 = self.id1, let id2 = self.id2, let relationshipType = self.relationshipType {
            return "\(forService)/\(id1)\(withSubPath)/\(id2)/\(relationshipType.rawValue)"
        } else {
            return super.buildPath(forService: forService, withSubPath: withSubPath)
        }
    }
    
    open func save() -> Promise<GeocoreUserEvent> {
        if self.id1 != nil && id2 != nil && self.relationshipType != nil {
            if let customData = self.customData {
                return Geocore.sharedInstance.promisedPOST(buildPath(forService: "/users", withSubPath: "/events"),
                    parameters: nil, body: customData.filter{ $1 != nil }.map{ ($0, $1!) })
            } else {
                return Geocore.sharedInstance.promisedPOST(buildPath(forService: "/users", withSubPath: "/events"),
                    parameters: nil, body: [String: Any]())
            }
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.invalidParameter(message: "Expecting ids & relationship type")) }
        }
    }
    
    open func organize() -> Promise<GeocoreUserEvent> {
        return with(relationshipType: .organizer).save()
    }
    
    open func perform() -> Promise<GeocoreUserEvent> {
        return with(relationshipType: .performer).save()
    }
    
    open func participate() -> Promise<GeocoreUserEvent> {
        return with(relationshipType: .participant).save()
    }
    
    open func attend() -> Promise<GeocoreUserEvent> {
        return with(relationshipType: .attendant).save()
    }
    
    open func leaveAs(_ relationshipType: GeocoreUserEventRelationshipType) -> Promise<GeocoreUserEvent> {
        self.relationshipType = relationshipType
        if self.id1 != nil && id2 != nil && self.relationshipType != nil {
            return Geocore.sharedInstance.promisedDELETE(buildPath(forService: "/users", withSubPath: "/events"))
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.invalidParameter(message: "Expecting ids & relationship type")) }
        }
    }
    
}

open class GeocoreUserEventQuery: GeocoreRelationshipQuery {
    
    fileprivate(set) open var relationshipType: GeocoreUserEventRelationshipType?
    
    open func withUser(_ user: GeocoreUser) -> Self {
        _ = super.with(object1Id: user.id!)
        return self
    }
    
    open func withEvent(_ event: GeocoreEvent) -> Self {
        _ = super.with(object2Id: event.id!)
        return self
    }
    
    open func with(relationshipType: GeocoreUserEventRelationshipType) -> Self {
        self.relationshipType = relationshipType
        return self
    }
    
    open override func buildPath(forService: String, withSubPath: String) -> String {
        if let id1 = self.id1, let id2 = self.id2, let relationshipType = self.relationshipType {
            return "\(forService)/\(id1)\(withSubPath)/\(id2)/\(relationshipType.rawValue)"
        } else {
            return super.buildPath(forService: forService, withSubPath: withSubPath)
        }
    }
    
    open func get() -> Promise<GeocoreUserEvent> {
        if self.id1 != nil && id2 != nil && self.relationshipType != nil {
            return Geocore.sharedInstance.promisedGET(self.buildPath(forService: "/users", withSubPath: "/events"))
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.invalidParameter(message: "Expecting ids & relationship type")) }
        }
    }
    
    open func all() -> Promise<[GeocoreUserEvent]> {
        if self.id1 != nil {
            return Geocore.sharedInstance.promisedGET(super.buildPath(forService: "/users", withSubPath: "/events"))
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.invalidParameter(message: "Expecting id")) }
        }
    }
    
    open func organization() -> Promise<GeocoreUserEvent> {
        return with(relationshipType: .organizer).get()
    }
    
    open func performance() -> Promise<GeocoreUserEvent> {
        return with(relationshipType: .performer).get()
    }
    
    open func participation() -> Promise<GeocoreUserEvent> {
        return with(relationshipType:.participant).get()
    }
    
    open func attendance() -> Promise<GeocoreUserEvent> {
        return with(relationshipType: .attendant).get()
    }
    
}

open class GeocoreUserEvent: GeocoreRelationship {
    
    open var user: GeocoreUser?
    open var event: GeocoreEvent?
    open var relationshipType: GeocoreUserEventRelationshipType?
    
    public required init(_ json: JSON) {
        super.init(json)
        if let pk = json["pk"].dictionary {
            if let userDict = pk["user"] {
                self.user = GeocoreUser(userDict)
            }
            if let eventDict = pk["event"] {
                self.event = GeocoreEvent(eventDict)
            }
            if let relationshipType = pk["relationship"]?.string {
                self.relationshipType = GeocoreUserEventRelationshipType(rawValue: relationshipType)!
            }
        }
    }
    
    open override func asDictionary() -> [String: Any] {
        var dict = super.asDictionary()
        var pk = [String: Any]()
        if let user = self.user { pk["user"] = user.asDictionary() }
        if let event = self.event { pk["event"] = event.asDictionary() }
        if let relationshipType = self.relationshipType { pk["relationship"] = relationshipType.rawValue as AnyObject? }
        dict["pk"] = pk as AnyObject?
        return dict
    }
    
}

open class GeocoreUserPlaceOperation: GeocoreRelationshipOperation {
    
    private(set) open var relationshipType: GeocoreUserPlaceRelationshipType?
    
    open func with(user: GeocoreUser) -> Self {
        _ = super.with(object1Id: user.id!)
        return self
    }
    
    open func with(place: GeocorePlace) -> Self {
        _ = super.with(object2Id: place.id!)
        return self
    }
    
    open func with(relationshipType: GeocoreUserPlaceRelationshipType) -> Self {
        self.relationshipType = relationshipType
        return self
    }
    
    open override func buildPath(forService: String, withSubPath: String) -> String {
         if let id1 = self.id1, let id2 = self.id2, let relationshipType = self.relationshipType {
            return "\(forService)/\(id1)\(withSubPath)/\(id2)/\(relationshipType.rawValue)"
        } else {
            return super.buildPath(forService: forService, withSubPath: withSubPath)
        }
    }
    
    open func save() -> Promise<GeocoreUserPlace> {
        if self.id1 != nil && id2 != nil && self.relationshipType != nil {
            if let customData = self.customData {
                return Geocore.sharedInstance.promisedPOST(buildPath(forService: "/users", withSubPath: "/places"),
                    parameters: nil, body: customData.filter{ $1 != nil }.map{ ($0, $1!) })
            } else {
                return Geocore.sharedInstance.promisedPOST(buildPath(forService: "/users", withSubPath: "/places"),
                    parameters: nil, body: [String: AnyObject]())
            }
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.invalidParameter(message: "Expecting ids & relationship type")) }
        }
    }
    
    open func follow() -> Promise<GeocoreUserPlace> {
        return with(relationshipType: .follower).save()
    }
    
    open func leaveAs(_ relationshipType: GeocoreUserPlaceRelationshipType) -> Promise<GeocoreUserPlace> {
        _ = self.with(relationshipType: relationshipType)
        if self.id1 != nil && id2 != nil && self.relationshipType != nil {
            return Geocore.sharedInstance.promisedDELETE(buildPath(forService: "/users", withSubPath: "/places"))
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.invalidParameter(message: "Expecting ids & relationship type")) }
        }
    }
    
    open func unfollow() -> Promise<GeocoreUserPlace> {
        return leaveAs(.follower)
    }
    
}

open class GeocoreUserPlaceQuery: GeocoreRelationshipQuery {
    
    fileprivate(set) open var relationshipType: GeocoreUserPlaceRelationshipType?
    
    open func with(user: GeocoreUser) -> Self {
        _ = super.with(object1Id: user.id!)
        return self
    }
    
    open func with(place: GeocorePlace) -> Self {
        _ = super.with(object2Id: place.id!)
        return self
    }
    
    open func with(relationshipType: GeocoreUserPlaceRelationshipType) -> Self {
        self.relationshipType = relationshipType
        return self
    }
    
    open override func buildPath(forService: String, withSubPath: String) -> String {
        if let id1 = self.id1, let id2 = self.id2, let relationshipType = self.relationshipType {
            return "\(forService)/\(id1)\(withSubPath)/\(id2)/\(relationshipType.rawValue)"
        } else {
            return super.buildPath(forService: forService, withSubPath: withSubPath)
        }
    }
    
    open func get() -> Promise<GeocoreUserPlace> {
        if self.id1 != nil && id2 != nil && self.relationshipType != nil {
            return Geocore.sharedInstance.promisedGET(self.buildPath(forService: "/users", withSubPath: "/places"))
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.invalidParameter(message: "Expecting ids & relationship type")) }
        }
    }
    
    open func all() -> Promise<[GeocoreUserPlace]> {
        if self.id1 != nil {
            var params = buildQueryParameters()
            params["output_format"] = "json.relationship"
            return Geocore.sharedInstance.promisedGET(super.buildPath(forService: "/users", withSubPath: "/places"), parameters: params)
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.invalidParameter(message: "Expecting id")) }
        }
    }
    
    open func asFollower() -> Promise<GeocoreUserPlace> {
        return with(relationshipType: .follower).get()
    }
    
}

open class GeocoreUserPlace: GeocoreRelationship {
    
    open var user: GeocoreUser?
    open var place: GeocorePlace?
    open var relationshipType: GeocoreUserPlaceRelationshipType?
    
    public required init(_ json: JSON) {
        super.init(json)
        if let pk = json["pk"].dictionary {
            if let userDict = pk["user"] {
                self.user = GeocoreUser(userDict)
            }
            if let placeDict = pk["place"] {
                self.place = GeocorePlace(placeDict)
            }
            if let relationshipType = pk["relationship"]?.string {
                self.relationshipType = GeocoreUserPlaceRelationshipType(rawValue: relationshipType)!
            }
        }
    }
    
    open override func asDictionary() -> [String: Any] {
        var dict = super.asDictionary()
        var pk = [String: Any]()
        if let user = self.user { pk["user"] = user.asDictionary() }
        if let place = self.place { pk["place"] = place.asDictionary() }
        if let relationshipType = self.relationshipType { pk["relationship"] = relationshipType.rawValue as AnyObject? }
        dict["pk"] = pk as AnyObject?
        return dict
    }
    
}

open class GeocoreUserItemOperation: GeocoreRelationshipOperation {
    
    open func with(_ user: GeocoreUser) -> Self {
        _ = super.with(object1Id: user.id!)
        return self
    }
    
    open func with(_ item: GeocoreItem) -> Self {
        _ = super.with(object2Id: item.id!)
        return self
    }
    
    open func adjustAmount(_ amount: Int) -> Promise<GeocoreUserItem> {
        if let id1 = self.id1, let id2 = self.id2 {
            var sign = "-"
            if amount > 0 {
                sign = "+"
            }
            return Geocore.sharedInstance.promisedPOST("/users/\(id1)/items/\(id2)/amount/\(sign)\(abs(amount))")
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.invalidParameter(message: "Expecting ids")) }
        }
    }
    
}

open class GeocoreUserItemQuery: GeocoreRelationshipQuery {
    
    open func with(user: GeocoreUser) -> Self {
        _ = super.with(object1Id: user.id!)
        return self
    }
    
    open func with(item: GeocoreItem) -> Self {
        _ = super.with(object2Id: item.id!)
        return self
    }
    
    open func all() -> Promise<[GeocoreUserItem]> {
        if self.id1 != nil {
            return Geocore.sharedInstance.promisedGET(super.buildPath(forService: "/users", withSubPath: "/items"), parameters: ["output_format": "json.relationship"])
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.invalidParameter(message: "Expecting id")) }
        }
    }
    
}

open class GeocoreUserItem: GeocoreRelationship {
    
    open var user: GeocoreUser?
    open var item: GeocoreItem?
    open var createTime: Date?
    open var amount: Int64?
    open var orderNumber: Int?
    
    public required init(_ json: JSON) {
        super.init(json)
        if let pk = json["pk"].dictionary {
            if let userDict = pk["user"] {
                self.user = GeocoreUser(userDict)
            }
            if let itemDict = pk["item"] {
                self.item = GeocoreItem(itemDict)
            }
            if let createTimeString = pk["createTime"] {
                self.createTime = Date.fromGeocoreFormattedString(createTimeString.string)
            }
        }
        self.amount = json["amount"].int64
        self.orderNumber = json["orderNumber"].int
    }
    
    open override func asDictionary() -> [String: Any] {
        var dict = super.asDictionary()
        var pk = [String: Any]()
        if let user = self.user { pk["user"] = user.asDictionary() }
        if let item = self.item { pk["item"] = item.asDictionary() }
        if let createTime = self.createTime { pk["createTime"] = createTime }
        dict["pk"] = pk
        if let amount = self.amount { dict["amount"] = amount }
        if let orderNumber = self.orderNumber { dict["orderNumber"] = orderNumber }
        return dict
    }
    
}



