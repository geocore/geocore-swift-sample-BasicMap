//
//  Geocore.swift
//  GeocoreKit
//
//  Created by Purbo Mohamad on 2017/02/10.
//  Copyright © 2017 Geocore. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import PromiseKit

// MARK: - Constants

fileprivate struct GeocoreConstants {
    fileprivate static let bundleKeyBaseURL = "GeocoreBaseURL"
    fileprivate static let bundleKeyProjectID = "GeocoreProjectId"
    fileprivate static let httpHeaderAccessTokenName = "Geocore-Access-Token"
}

/// GeocoreKit error code.
///
/// - invalidState: Unexpected internal state. Possibly a bug.
/// - invalidServerResponse: Unexpected server response. Possibly a bug.
/// - unexpectedResponse: Unexpected response format. Possibly a bug.
/// - serverError: Server returns an error.
/// - tokenUndefined: Token is unavailable. Possibly the library is left uninitialized or user is not logged in.
/// - unauthorizedAccess: Access to the specified resource is forbidden. Possibly the user is not logged in.
/// - invalidParameter: One of the parameter passed to the API is invalid.
/// - networkError: Underlying network library produces an error.
public enum GeocoreError: Error {
    case invalidState
    case invalidServerResponse(statusCode: Int)
    case unexpectedResponse(message: String)
    case serverError(code: String, message: String)
    case tokenUndefined
    case unauthorizedAccess
    case invalidParameter(message: String)
    case networkError(error: Error)
    case otherError(error: Error)
}


/// GeocoreError.invalidServerResponse code for locally generated errors.
///
/// - unavailable: No information available about the error. Possibly a bug.
/// - unexpectedResponse: Server returns unexpected (unstructured) response. Possibly a bug.
public enum GeocoreServerResponse: Int {
    case unavailable = -1
    case unexpectedResponse = -2
    case emptyResponse = -3
}

// MARK: - Helper extensions

fileprivate extension Alamofire.URLEncoding {
    
    /// Almost like URLEncoding's encode, except that this will ALWAYS encode the parameters as URL query parameters
    fileprivate func geocoreEncode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        var urlRequest = try urlRequest.asURLRequest()
        
        guard let parameters = parameters else { return urlRequest }
        
        guard let url = urlRequest.url else {
            throw AFError.parameterEncodingFailed(reason: .missingURL)
        }
        
        if var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false), !parameters.isEmpty {
            let percentEncodedQuery = (urlComponents.percentEncodedQuery.map { $0 + "&" } ?? "") + geocoreQuery(parameters)
            urlComponents.percentEncodedQuery = percentEncodedQuery
            urlRequest.url = urlComponents.url
        }
        
        return urlRequest
    }
    
    /// A copy of URLEncoding's query, but it's declared as private
    private func geocoreQuery(_ parameters: [String: Any]) -> String {
        var components: [(String, String)] = []
        
        for key in parameters.keys.sorted(by: <) {
            let value = parameters[key]!
            components += queryComponents(fromKey: key, value: value)
        }
        
        return components.map { "\($0)=\($1)" }.joined(separator: "&")
    }
    
}

/// Alamofire's SessionManager extended so that a request can have both URL-encoded parameters and JSON-encoded body
fileprivate extension Alamofire.SessionManager {
    
    @discardableResult
    fileprivate func requestWithParametersAndBody(
        _ url: URLConvertible,
        method: HTTPMethod = .get,
        parameters: Parameters? = nil,
        body: Parameters? = nil,
        headers: HTTPHeaders? = nil) throws -> DataRequest {
        
        // if both parameters & body are defined: JSON encoding for the body, URL encoding for parameters
        // if only parameters is defined: URL encoding for parameters
        // if only body is defined: JSON encoding for body
        
        if let parameters = parameters, let body = body {
            let originalURLRequest = try URLRequest(url: url, method: method, headers: headers)
            var encodedURLRequest = try URLEncoding.default.geocoreEncode(originalURLRequest, with: parameters)
            let data = try JSONSerialization.data(withJSONObject: body, options: [])
            // force JSON encoding
            encodedURLRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            encodedURLRequest.httpBody = data
            
            return request(encodedURLRequest)
        } else if let parameters = parameters {
            let originalURLRequest = try URLRequest(url: url, method: method, headers: headers)
            var encodedURLRequest = try URLEncoding.default.geocoreEncode(originalURLRequest, with: parameters)
            // force JSON encoding
            encodedURLRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            return request(encodedURLRequest)
            //return request(url, method: method, parameters: parameters, encoding: URLEncoding.default, headers: headers)
        } else if let body = body {
            return request(url, method: method, parameters: body, encoding: JSONEncoding.default, headers: headers)
        } else {
            return request(url, method: method, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
        }
    }
    
}

// MARK: - Base structures

/// Representing an object that can be initialized from JSON data.
public protocol GeocoreInitializableFromJSON {
    init(_ json: JSON)
}

/// Representing an object that can be serialized to JSON.
public protocol GeocoreSerializableToJSON {
    func asDictionary() -> [String: Any]
}

/// Representing an object can be identified
public protocol GeocoreIdentifiable: GeocoreInitializableFromJSON, GeocoreSerializableToJSON {
    var sid: Int64? { get set }
    var id: String? { get set }
}

/// A wrapper for raw JSON value returned by Geocore service.
open class GeocoreGenericResult: GeocoreInitializableFromJSON {
    
    private(set) public var json: JSON
    
    public required init(_ json: JSON) {
        self.json = json
    }
}

/// A wrapper for count request returned by Geocore service.
open class GeocoreGenericCountResult: GeocoreInitializableFromJSON {
    
    private(set) public var count: Int?
    
    public required init(_ json: JSON) {
        self.count = json["count"].int
    }
    
}

/// Geographical point in WGS84.
public struct GeocorePoint: GeocoreSerializableToJSON, GeocoreInitializableFromJSON {
    
    public var latitude: Float?
    public var longitude: Float?
    
    public init() {
    }
    
    public init(latitude: Float?, longitude: Float?) {
        self.latitude = latitude
        self.longitude = longitude
    }
    
    public init(_ json: JSON) {
        self.latitude = json["latitude"].float
        self.longitude = json["longitude"].float
    }
    
    public func asDictionary() -> [String: Any] {
        if let latitude = self.latitude, let longitude = self.longitude {
            return ["latitude": latitude, "longitude": longitude]
        } else {
            return [String: Any]()
        }
    }
}

/// Representing a result returned by Geocore service.
///
/// - success: Containing value of the result.
/// - failure: Containing an error.
public enum GeocoreResult<T> {
    case success(T)
    case failure(GeocoreError)
    
    public init(_ value: T) {
        self = .success(value)
    }
    
    public init(_ error: GeocoreError) {
        self = .failure(error)
    }
    
    public var failed: Bool {
        switch self {
        case .failure(_):
            return true
        default:
            return false
        }
    }
    
    public var error: GeocoreError? {
        switch self {
        case .failure(let error):
            return error
        default:
            return nil
        }
    }
    
    public var value: T? {
        switch self {
        case .success(let value):
            return value
        default:
            return nil
        }
    }
    
    public func propagate(toFulfillment fulfill: (T) -> Void, rejection reject: (Error) -> Void) -> Void {
        switch self {
        case .success(let value):
            fulfill(value)
        case .failure(let error):
            reject(error)
        }
    }
}

// MARK: - Main class

/// Main singleton class for accessing Geocore.
open class Geocore {
    
    /// Singleton instance.
    public static let sharedInstance = Geocore()
    /// Default Geocore date formatter
    public static let geocoreDateFormatter = DateFormatter.dateFormatterForGeocore()
    
    /// Currently used Geocore base URL.
    public private(set) var baseURL: String?
    /// Currently used Geocore project ID.
    public private(set) var projectId: String?
    /// Currently logged in user ID (if logged in).
    public private(set) var userId: String?
    /// Access token of currently logged in user (if logged in).
    public var token: String?
    
    private init() {
        baseURL = Bundle.main.object(forInfoDictionaryKey: GeocoreConstants.bundleKeyBaseURL) as? String
        projectId = Bundle.main.object(forInfoDictionaryKey: GeocoreConstants.bundleKeyProjectID) as? String
    }
    
    // MARK: Internal low-level methods
    
    private func buildUrl(_ servicePath: String) throws -> String {
        if let baseURL = self.baseURL {
            return baseURL + servicePath
        } else {
            throw GeocoreError.invalidState
        }
    }
    
    private func extractMultipartInfoFrom(_ body: Alamofire.Parameters? = nil) -> (fileContents: Data, fileName: String, fieldName: String, mimeType: String)? {
        if let fileContents = body?["$fileContents"] as? Data {
            if let fileName = body?["$fileName"] as? String, let fieldName = body?["$fieldName"] as? String, let mimeType = body?["$mimeType"] as? String {
                return (fileContents, fileName, fieldName, mimeType)
            }
        }
        return nil
    }
    
    private func validateUploadRequest(_ body: Alamofire.Parameters? = nil) -> Bool {
        if let _ = body?["$fileContents"] as? Data {
            // uploading file, make sure all required parameters are specified as well
            if let _ = body?["$fileName"] as? String, let _ = body?["$fieldName"] as? String, let _ = body?["$mimeType"] as? String {
                return true
            } else {
                return false
            }
        } else {
            return true
        }
    }
    
    private func buildRequestCompletionHandler(onSuccess: @escaping (JSON) -> Void,
                                               onError: @escaping (GeocoreError) -> Void) -> ((Alamofire.DataResponse<Data>) -> Void) {
        return { (response: Alamofire.DataResponse<Data>) -> Void in
            if let error = response.error {
                print("[ERROR] \(error)")
                onError(.networkError(error: error))
            } else if let statusCode = response.response?.statusCode {
                switch statusCode {
                case 200:
                    if let data = response.data {
                        let json = JSON(data: data)
                        if let status = json["status"].string {
                            if status == "success" {
                                onSuccess(json["result"])
                            } else {
                                onError(.serverError(
                                    code: json["code"].string ?? "",
                                    message: json["message"].string ?? ""))
                            }
                        } else {
                            onError(.invalidServerResponse(
                                statusCode: GeocoreServerResponse.unexpectedResponse.rawValue))
                        }
                    } else {
                        // shouldn't happen
                        onError(.invalidServerResponse(
                            statusCode: GeocoreServerResponse.emptyResponse.rawValue))
                    }
                case 403:
                    onError(.unauthorizedAccess)
                default:
                    onError(.invalidServerResponse(statusCode: statusCode))
                }
            } else {
                onError(.invalidServerResponse(
                    statusCode: GeocoreServerResponse.unavailable.rawValue))
            }
        }
    }
    
    private func request(
        _ url: String,
        method: Alamofire.HTTPMethod,
        parameters: Alamofire.Parameters?,
        body: Alamofire.Parameters?,
        requestCompletionHandler: @escaping (Alamofire.DataResponse<Data>) -> Void) throws {
        
        if !validateUploadRequest(body) {
            // file supposed to be uploaded but file info not provided.
            throw GeocoreError.invalidParameter(message: "Parameter for file upload incomplete")
        } else {
            if let token = self.token {
                if let multipartInfo = self.extractMultipartInfoFrom(body) {
                    // multipart request
                    try Alamofire.upload(
                        multipartFormData: { multipartFormData in
                            multipartFormData.append(
                                multipartInfo.fileContents,
                                withName: multipartInfo.fieldName,
                                fileName: multipartInfo.fileName,
                                mimeType: multipartInfo.mimeType)
                        },
                        with: URLRequest(url: url, method: method, headers: [GeocoreConstants.httpHeaderAccessTokenName: token]),
                        encodingCompletion: { encodingResult in
                            switch encodingResult {
                            case .success(let upload, _, _):
                                upload.responseData(completionHandler: requestCompletionHandler)
                            case .failure(let encodingError):
                                print(encodingError)
                            }
                        })
                } else {
                    // Alamofire request with token
                    try Alamofire.SessionManager.default
                        .requestWithParametersAndBody(
                            url,
                            method: method,
                            parameters: parameters,
                            body: body,
                            headers: [GeocoreConstants.httpHeaderAccessTokenName: token])
                        .responseData(completionHandler: requestCompletionHandler)
                }
            } else {
                // Alamofire request with no token
                try Alamofire.SessionManager.default
                    .requestWithParametersAndBody(
                        url,
                        method: method,
                        parameters: parameters,
                        body: body)
                    .responseData(completionHandler: requestCompletionHandler)
            }
        }
    }
    
    
    /// Generic request
    ///
    /// - Parameters:
    ///   - path: Path relative to base API URL.
    ///   - method: HTTP method
    ///   - parameters: URL query parameters
    ///   - body: HTTP body
    ///   - onSuccess: handler called when request is successful
    ///   - onError: handler called when there is an error
    private func request(
        _ path: String,
        method: Alamofire.HTTPMethod,
        parameters: Alamofire.Parameters?,
        body: Alamofire.Parameters?,
        onSuccess: @escaping (JSON) -> Void,
        onError: @escaping (GeocoreError) -> Void) {
        do {
            try request(
                buildUrl(path),
                method: method,
                parameters: parameters,
                body: body,
                requestCompletionHandler: buildRequestCompletionHandler(onSuccess: onSuccess, onError: onError))
        } catch {
            onError(.otherError(error: error))
        }
    }
    
    /// Request resulting a single result of type T.
    ///
    /// - Parameters:
    ///   - path: Path relative to base API URL.
    ///   - method: HTTP method
    ///   - parameters: URL query parameters
    ///   - body: HTTP body
    ///   - callback: callback to be called when there is a single result of type T or error.
    private func request<T: GeocoreInitializableFromJSON>(
        path: String,
        method: Alamofire.HTTPMethod,
        parameters: Alamofire.Parameters?,
        body: Alamofire.Parameters?,
        callback: @escaping (GeocoreResult<T>) -> Void) {
        request(path,
                method: method,
                parameters: parameters,
                body: body,
                onSuccess: { json in callback(GeocoreResult(T(json))) },
                onError: { error in callback(.failure(error)) })
    }
    
    /// Request resulting multiple result in an array of objects of type T
    ///
    /// - Parameters:
    ///   - path: Path relative to base API URL.
    ///   - method: HTTP method
    ///   - parameters: URL query parameters
    ///   - body: HTTP body
    ///   - callback: callback to be called when there is an array of result of type T or error.
    private func request<T: GeocoreInitializableFromJSON>(
        _ path: String,
        method: Alamofire.HTTPMethod,
        parameters: Alamofire.Parameters?,
        body: Alamofire.Parameters?,
        callback: @escaping (GeocoreResult<[T]>) -> Void) {
        request(path,
                method: method,
                parameters: parameters,
                body: body,
                onSuccess: { json in
                    if let result = json.array {
                        callback(GeocoreResult(result.map { T($0) }))
                    } else {
                        callback(GeocoreResult([]))
                    }
                },
                onError: { error in callback(.failure(error)) })
    }
    
    // MARK: HTTP methods: GET, POST, DELETE, PUT
    
    
    /// Do an HTTP GET request expecting one result of type T
    ///
    /// - Parameters:
    ///   - path: Path relative to base API URL.
    ///   - parameters: URL query parameters
    ///   - callback: callback to be called when there is a single result of type T or error.
    public func GET<T: GeocoreInitializableFromJSON>(
        _ path: String,
        parameters: Alamofire.Parameters? = nil,
        callback: @escaping (GeocoreResult<T>) -> Void) {
        request(path: path, method: .get, parameters: parameters, body: nil, callback: callback)
    }
    
    /// Promise a single result of type T from an HTTP GET request.
    ///
    /// - Parameters:
    ///   - path: Path relative to base API URL.
    ///   - parameters: URL query parameters
    /// - Returns: Promise for a single result of type T.
    public func promisedGET<T: GeocoreInitializableFromJSON>(
        _ path: String,
        parameters: Alamofire.Parameters? = nil) -> Promise<T> {
        return Promise { (fulfill, reject) in
            self.GET(path, parameters: parameters) {
                result in result.propagate(toFulfillment: fulfill, rejection: reject)
            }
        }
    }
    
    /// Do an HTTP GET request expecting an multiple result in an array of objects of type T
    ///
    /// - Parameters:
    ///   - path: Path relative to base API URL.
    ///   - parameters: URL query parameters
    ///   - callback: callback to be called when there is an array of multiple result of type T or error.
    func GET<T: GeocoreInitializableFromJSON>(
        _ path: String,
        parameters: Alamofire.Parameters? = nil,
        callback: @escaping (GeocoreResult<[T]>) -> Void) {
        request(path, method: .get, parameters: parameters, body: nil, callback: callback)
    }
    
    /// Promise multiple result of type T from an HTTP GET request.
    ///
    /// - Parameters:
    ///   - path: Path relative to base API URL.
    ///   - parameters: URL query parameters
    /// - Returns: Promise for a multiple result of type T.
    func promisedGET<T: GeocoreInitializableFromJSON>(
        _ path: String,
        parameters: Alamofire.Parameters? = nil) -> Promise<[T]> {
        return Promise { (fulfill, reject) in
            self.GET(path, parameters: parameters) {
                result in result.propagate(toFulfillment: fulfill, rejection: reject)
            }
        }
    }
    
    /// Do an HTTP POST request expecting one result of type T
    ///
    /// - Parameters:
    ///   - path: Path relative to base API URL.
    ///   - parameters: URL query parameters
    ///   - body: HTTP body
    ///   - callback: callback to be called when there is a single result of type T or error.
    func POST<T: GeocoreInitializableFromJSON>(
        _ path: String,
        parameters: Alamofire.Parameters? = nil,
        body: Alamofire.Parameters? = nil,
        callback: @escaping (GeocoreResult<T>) -> Void) {
        request(path: path, method: .post, parameters: parameters, body: body, callback: callback)
    }
    
    /// Do an HTTP POST request expecting an multiple result in an array of objects of type T
    ///
    /// - Parameters:
    ///   - path: Path relative to base API URL.
    ///   - parameters: URL query parameters
    ///   - body: HTTP body
    ///   - callback: callback to be called when there is an array of multiple result of type T or error.
    func POST<T: GeocoreInitializableFromJSON>(
        _ path: String,
        parameters: Alamofire.Parameters? = nil,
        body: Alamofire.Parameters? = nil,
        callback: @escaping (GeocoreResult<[T]>) -> Void) {
        request(path, method: .post, parameters: parameters, body: body, callback: callback)
    }
    
    /// Do an HTTP POST file upload expecting one result of type T
    ///
    /// - Parameters:
    ///   - path: Path relative to base API URL.
    ///   - parameters: URL query parameters
    ///   - fieldName: Uploaded data field name
    ///   - fileName: Uploaded data file name
    ///   - mimeType: Uploaded data MIME type
    ///   - fileContents: Data to be uploaded
    ///   - callback: callback to be called when there is a single result of type T or error.
    func uploadPOST<T: GeocoreInitializableFromJSON>(
        _ path: String,
        parameters: Alamofire.Parameters? = nil,
        fieldName: String,
        fileName: String,
        mimeType: String,
        fileContents: Data,
        callback: @escaping (GeocoreResult<T>) -> Void) {
        POST(path,
            parameters: parameters,
            body: [
                "$fileContents": fileContents,
                "$fileName": fileName,
                "$fieldName": fieldName,
                "$mimeType": mimeType],
            callback: callback)
    }
    
    /**
     Promise a single result of type T from an HTTP POST request.
     */
    
    
    
    /// Promise a single result of type T from an HTTP POST request.
    ///
    /// - Parameters:
    ///   - path: Path relative to base API URL.
    ///   - parameters: URL query parameters
    ///   - body: HTTP body
    /// - Returns: Promise for a single result of type T.
    func promisedPOST<T: GeocoreInitializableFromJSON>(
        _ path: String,
        parameters: Alamofire.Parameters? = nil,
        body: Alamofire.Parameters? = nil) -> Promise<T> {
        return Promise { (fulfill, reject) in
            self.POST(path, parameters: parameters, body: body) { result in
                result.propagate(toFulfillment: fulfill, rejection: reject)
            }
        }
    }
    
    /// Promise multiple results of type T from an HTTP POST request.
    ///
    /// - Parameters:
    ///   - path: Path relative to base API URL.
    ///   - parameters: URL query parameters
    ///   - body: HTTP body
    /// - Returns: Promise for a multiple result of type T.
    func promisedPOST<T: GeocoreInitializableFromJSON>(
        _ path: String,
        parameters: Alamofire.Parameters? = nil,
        body: Alamofire.Parameters? = nil) -> Promise<[T]> {
        return Promise { (fulfill, reject) in
            self.POST(path, parameters: parameters, body: body) { result in
                result.propagate(toFulfillment: fulfill, rejection: reject)
            }
        }
    }
    
    
    /// Promise one result of type T from an file upload request.
    ///
    /// - Parameters:
    ///   - path: Path relative to base API URL.
    ///   - parameters: URL query parameters
    ///   - fieldName: Uploaded data field name
    ///   - fileName: Uploaded data file name
    ///   - mimeType: Uploaded data MIME type
    ///   - fileContents: Data to be uploaded
    /// - Returns: Promise for a single result of type T.
    func promisedUploadPOST<T: GeocoreInitializableFromJSON>(
        _ path: String,
        parameters: Alamofire.Parameters? = nil,
        fieldName: String,
        fileName: String,
        mimeType: String,
        fileContents: Data) -> Promise<T> {
        return self.promisedPOST(path, parameters: parameters, body: ["$fileContents": fileContents, "$fileName": fileName, "$fieldName": fieldName, "$mimeType": mimeType])
    }
    
    /// Do an HTTP DELETE request expecting one result of type T
    ///
    /// - Parameters:
    ///   - path: Path relative to base API URL.
    ///   - parameters: URL query parameters
    ///   - callback: callback to be called when there is a single result of type T or error.
    func DELETE<T: GeocoreInitializableFromJSON>(
        _ path: String,
        parameters: Alamofire.Parameters? = nil,
        callback: @escaping (GeocoreResult<T>) -> Void) {
        request(path: path, method: .delete, parameters: parameters, body: nil, callback: callback)
    }
    
    /// Promise a single result of type T from an HTTP DELETE request.
    ///
    /// - Parameters:
    ///   - path: Path relative to base API URL.
    ///   - parameters: URL query parameters
    /// - Returns: Promise for a single result of type T.
    func promisedDELETE<T: GeocoreInitializableFromJSON>(
        _ path: String,
        parameters: Alamofire.Parameters? = nil) -> Promise<T> {
        return Promise { (fulfill, reject) in
            self.DELETE(path, parameters: parameters) { result in
                result.propagate(toFulfillment: fulfill, rejection: reject)
            }
        }
    }

    // MARK: User management methods (callback version)
    
    /**
     Login to Geocore with callback.
     
     - parameter userId:   User's ID to be submitted.
     - parameter password: Password for authorizing user.
     - parameter callback: Closure to be called when the token string or an error is returned.
     */
    
    
    /// Login to Geocore with callback.
    ///
    /// - Parameters:
    ///   - userId: User's ID to be submitted.
    ///   - password: Password for authorizing user.
    ///   - alternateIdIndex: alternate ID
    ///   - callback: Closure to be called when the token string or an error is returned.
    public func login(
        userId: String,
        password: String,
        alternateIdIndex: Int = 0,
        callback: @escaping (GeocoreResult<String>) -> Void) {
        
        var params: Alamofire.Parameters = ["id": userId, "password": password, "project_id": self.projectId!]
        if alternateIdIndex > 0 {
            params["alt"] = String(alternateIdIndex)
        }
        
        // make sure we're logged out, otherwise the logic in requestBuilder will break!
        self.logout()
        
        POST("/auth", parameters: params, body: nil) { (result: GeocoreResult<GeocoreGenericResult>) -> Void in
            switch result {
            case .success(let value):
                self.token = value.json["token"].string
                if let token = self.token {
                    self.userId = userId
                    callback(GeocoreResult(token))
                } else {
                    callback(.failure(GeocoreError.invalidState))
                }
            case .failure(let error):
                callback(.failure(error))
            }
        }
    }
    
    public func loginWithDefaultUser(_ callback: @escaping (GeocoreResult<String>) -> Void) {
        // login using default id & password
        self.login(userId: GeocoreUser.defaultId(), password: GeocoreUser.defaultPassword(), alternateIdIndex: 0) { result in
            switch result {
            case .success(_):
                callback(result)
            case .failure(let error):
                // oops! try to register first
                switch error {
                case .serverError(let code, _):
                    if code == "Auth.0001" {
                        // not registered, register the default user first
                        GeocoreUserOperation().register(user: GeocoreUser.defaultUser(), callback: { result in
                            switch result {
                            case .success(_):
                                // successfully registered, now login again
                                self.login(
                                    userId: GeocoreUser.defaultId(),
                                    password: GeocoreUser.defaultPassword(),
                                    alternateIdIndex: 0) { result in
                                        callback(result)
                                    }
                            case .failure(let error):
                                callback(.failure(error))
                            }
                        });
                    } else {
                        // unexpected error
                        callback(.failure(error))
                    }
                default:
                    // unexpected error
                    callback(.failure(error))
                }
            }
        }
    }

    
    // MARK: User management methods (promise version)
    
    /// Promise to login to Geocore.
    ///
    /// - Parameters:
    ///   - userId: User's ID to be submitted.
    ///   - password: Password for authorizing user.
    ///   - alternateIdIndex: alternate ID
    /// - Returns: Promise for token when login is successful.
    public func login(userId: String, password: String, alternateIdIndex: Int = 0) -> Promise<String> {
        return Promise { (fulfill, reject) in
            self.login(userId: userId, password: password, alternateIdIndex: alternateIdIndex) { result in
                result.propagate(toFulfillment: fulfill, rejection: reject)
            }
        }
    }
    
    /// Promise to login to Geocore with default user.
    ///
    /// - Returns: Promise for token when login is successful.
    public func loginWithDefaultUser() -> Promise<String> {
        return Promise { (fulfill, reject) in
            self.loginWithDefaultUser { result in
                result.propagate(toFulfillment: fulfill, rejection: reject)
            }
        }
    }
    
    /// Logout from Geocore.
    public func logout() {
        self.token = nil
        self.userId = nil
    }
    
}
