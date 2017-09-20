//
//  LoginService.swift
//  
//
//  Created by Pavlo Dumyak on 1/9/17.
//  Copyright © 2017 Inoxoft Inc. All rights reserved.
//

import Foundation
import Alamofire

let kUserInfoDefaultsKey = "kUserInfoDefaultsKey"

enum LoginErrorType {
    case missedName
    case missedToken
    case invalidToken
    case loginFailed
    case invalidUserInfo
}

struct LoginError: Error {
    let type: LoginErrorType
}

class LoginService {
    
    static let shared = LoginService()
    
    var userInfo: [String:Any]? {
        get {
            return UserDefaults.standard.dictionary(forKey: kUserInfoDefaultsKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: kUserInfoDefaultsKey)
        }
    }
    
    func check(userInfo: [String:Any]?, completion: @escaping (Bool, LoginError?)->()) {
        guard let userInfo = userInfo else {
            completion(false, LoginError(type: .missedToken))
            return
        }
        
        let headers = authHeaders(userInfo: userInfo)
        Alamofire.request(BfreeService.baseURL(kCurrentService) + "/auth/", method: .post, headers: headers).responseJSON { (response) in
            if let userInfo = response.result.value as? [String: Any],
                UserInfo.validate(userInfo) {
                completion(true, nil)
            } else {
                completion(false, LoginError(type: .loginFailed))
            }
        }
    }
    
    func login(name: String, password: String, completion: @escaping (Any?, LoginError?)->()) {
        guard name.characters.count > 0 else {
            completion(nil, LoginError(type: .missedName))
            return
        }
        
        let headers = authHeaders(username: name, password: password)
        
        Alamofire.request(BfreeService.baseURL(kCurrentService) + "/auth/", method: .post, headers: headers)
            .responseJSON { (response) in
                if response.result.isSuccess,
                    let value = response.result.value as? [String: Any] {
                    if self.save(userInfo: value, username: name, password: password) {
                        completion(value, nil)
                    } else {
                        completion(nil, LoginError(type: .invalidUserInfo))
                    }
                } else {
                    completion(nil, LoginError(type: .loginFailed))
                }
        }
    }
    
    func authHeaders(userInfo: [String:Any]?) -> HTTPHeaders? {
        guard let userInfo = userInfo, UserInfo.validate(userInfo),
            let token = userInfo[UserInfoKeys.token.rawValue] as? String,
            token.characters.count > 0 else {
                return nil
        }
        
        var headers = HTTPHeaders()
        headers["Authorization"] = "Basic \(token)"
        return headers
    }
    
    func authHeaders(username: String?, password: String?) -> HTTPHeaders? {
        if let username = username, let password = password,
            let header = Alamofire.Request.authorizationHeader(user: username, password: password) {
            var headers = HTTPHeaders()
            headers[header.key] = header.value
            return headers
        }
        return nil
    }
    
    func save(userInfo: [String: Any]?, username: String?, password: String?) -> Bool {
        if let userInfo = userInfo, UserInfo.validate(userInfo),
            let username = username, let password = password,
            let data = "\(username):\(password)".data(using: .utf8) {
            
            let token = data.base64EncodedString(options: [])
            var newInfo = userInfo
            newInfo[UserInfoKeys.token.rawValue] = token
            self.userInfo = newInfo
            return true
        }
        return false
    }
}
