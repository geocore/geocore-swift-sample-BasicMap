//
//  GeocoreTag.swift
//  GeocoreKit
//
//  Created by Purbo Mohamad on 11/22/15.
//
//

import Foundation
import Alamofire
import SwiftyJSON
import PromiseKit

public enum GeocoreTagType: String {
    case System = "SYSTEM_TAG"
    case User = "USER_TAG"
    case Unknown = ""
}

open class GeocoreTaggableOperation: GeocoreObjectOperation {
    
    private var tagIdsToAdd: [String]?
    private var tagIdsToDelete: [String]?
    private var tagNamesToAdd: [String]?
    private var tagNamesToDelete: [String]?
    
    open func tag(_ tagIdsOrNames: [String]) -> Self {
        for tagIdOrName in tagIdsOrNames {
            // for now, assume that if the tag starts with 'TAG-', it's a tag id, otherwise it's a name
            if tagIdOrName.hasPrefix("TAG-") {
                if self.tagIdsToAdd == nil {
                    self.tagIdsToAdd = [tagIdOrName]
                } else {
                    self.tagIdsToAdd?.append(tagIdOrName)
                }
            } else {
                if self.tagNamesToAdd == nil {
                    self.tagNamesToAdd = [tagIdOrName]
                } else {
                    self.tagNamesToAdd?.append(tagIdOrName)
                }
            }
        }
        return self
    }
    
    open func untag(_ tagIdsOrNames: [String]) -> Self {
        for tagIdOrName in tagIdsOrNames {
            // for now, assume that if the tag starts with 'TAG-', it's a tag id, otherwise it's a name
            if tagIdOrName.hasPrefix("TAG-") {
                if self.tagIdsToDelete == nil {
                    self.tagIdsToDelete = [tagIdOrName]
                } else {
                    self.tagIdsToDelete?.append(tagIdOrName)
                }
            } else {
                if self.tagNamesToDelete == nil {
                    self.tagNamesToDelete = [tagIdOrName]
                } else {
                    self.tagNamesToDelete?.append(tagIdOrName)
                }
            }
        }
        return self
    }
    
    open override func buildQueryParameters() -> Alamofire.Parameters {
        var dict = super.buildQueryParameters()
        if let tagIdsToAdd = self.tagIdsToAdd {
            if tagIdsToAdd.count > 0 {
                dict["tag_ids"] = tagIdsToAdd.joined(separator: ",")
            }
        }
        if let tagNamesToAdd = self.tagNamesToAdd {
            if tagNamesToAdd.count > 0 {
                dict["tag_names"] = tagNamesToAdd.joined(separator: ",")
            }
        }
        if let tagIdsToDelete = self.tagIdsToDelete {
            if tagIdsToDelete.count > 0 {
                dict["del_tag_ids"] = tagIdsToDelete.joined(separator: ",")
            }
        }
        if let tagNamesToDelete = self.tagNamesToDelete {
            if tagNamesToDelete.count > 0 {
                dict["del_tag_names"] = tagNamesToDelete.joined(separator: ",")
            }
        }
        return dict as [String : AnyObject];
    }
    
}

open class GeocoreTaggableQuery: GeocoreObjectQuery {
    
    private var tagIds: [String]?
    private var tagNames: [String]?
    private var excludedTagIds: [String]?
    private var excludedTagNames: [String]?
    private var tagDetails = false
    
    /**
     Set tag IDs to be submitted as request parameter.
     
     - parameter tagIds: Tag IDs to be submitted
     
     - returns: The updated query object to be chain-called.
     */
    open func with(tagIds: [String]) -> Self {
        self.tagIds = tagIds
        return self
    }
    
    open func exclude(tagIds: [String]) -> Self {
        self.excludedTagIds = tagIds
        return self
    }
    
    /**
     Set tag names to be submitted as request parameter.
     
     - parameter tagNames: Tag names to be submitted
     
     - returns: The updated query object to be chain-called.
     */
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
    
    open override func buildQueryParameters() -> [String: Any] {
        var dict = super.buildQueryParameters()
        if let tagIds = self.tagIds { dict["tag_ids"] = tagIds.joined(separator: ",") }
        if let tagNames = self.tagNames { dict["tag_names"] = tagNames.joined(separator: ",") }
        if let excludedTagIds = self.excludedTagIds { dict["excl_tag_ids"] = excludedTagIds.joined(separator: ",") }
        if let excludedTagNames = self.excludedTagNames { dict["excl_tag_names"] = excludedTagNames.joined(separator: ",") }
        if tagDetails { dict["tag_detail"] = "true" }
        return dict as [String : Any]
    }
    
}

open class GeocoreTaggable: GeocoreObject {
    
    open var tags: [GeocoreTag]?
    
    public override init() {
        super.init()
    }
    
    public required init(_ json: JSON) {
        if let tagsJSON = json["tags"].array {
            self.tags = tagsJSON.map({ GeocoreTag($0) })
        }
        super.init(json)
    }
    
}

open class GeocoreTag: GeocoreObject {
    
    open var type: GeocoreTagType?
    
    public override init() {
        super.init()
    }
    
    public required init(_ json: JSON) {
        if let type = json["type"].string { self.type = GeocoreTagType(rawValue: type) }
        super.init(json)
    }
    
    open override func asDictionary() -> [String : Any] {
        var dict = super.asDictionary()
        if let type = self.type { dict["type"] = type.rawValue as AnyObject? }
        return dict
    }
}
