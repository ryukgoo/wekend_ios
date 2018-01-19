//
//  AmazonIdentityProvider.swift
//  Wekend
//
//  Created by Kim Young-wook on 2016. 12. 7..
//  Copyright © 2016년 Kim Young-wook. All rights reserved.
//

import Foundation
import AWSCognito

final class AmazonIdentityProvider : AWSCognitoCredentialsProviderHelper {
    
    // TODO : make cachedIdentityId(not self.identityId)
    
    // Handles getting the login
    override func logins() -> AWSTask<NSDictionary> {
        
        if UserDefaults.Account.string(forKey: .userName) == nil {
            return AWSTask(result: nil)
        } else {
//            return super.logins()
            return getCredentialsByURL().continueWith(block: {
                credentialTask -> AWSTask<NSDictionary> in
                guard let credential = credentialTask.result else {
                    return AWSTask(result: nil)
                }
                
                return AWSTask(result: [Configuration.Cognito.AMAZON_PROVIDER : credential.token])
            }) as! AWSTask<NSDictionary>
        }
        
    }
    
    override func token() -> AWSTask<NSString> {
        print("\(className) > \(#function)")
        return getCredentialsByURL().continueWith(block: {
            credentialTask -> AWSTask<NSString> in
            guard let credential = credentialTask.result else {
                return AWSTask(result: nil)
            }
            
            self.identityId = credential.identityId
            UserDefaults.Authentication.set(self.identityId, forKey: .identityId)
            
            return AWSTask(result: credential.token as NSString)
        }) as! AWSTask<NSString>
    }
    
    override func clear() {
        print("\(className) > \(#function)")
        super.clear()
    }
    
    func getCredentialsByURL() -> AWSTask<AmazonCognitoCredential> {
        
        print("\(className) > \(#function) > start")
        
        let tokenRequest = AWSTaskCompletionSource<AmazonCognitoCredential>()
        
        guard let getTokenURL = URL(string: Configuration.ApiGateway.GETTOKEN_URL) else {
            fatalError("\(className) > \(#function) > make URL Error")
        }
        
        var getTokenRequest = URLRequest(url: getTokenURL)
        getTokenRequest.httpMethod = "POST"
        getTokenRequest.cachePolicy = .reloadIgnoringCacheData
        
        guard let username = UserDefaults.Account.string(forKey: .userName) else {
            fatalError("\(className) > \(#function) > User never logged in")
        }
        
        let deviceKey = UserDefaults.Account.string(forKey: .deviceKey)
        let timestamp = Utilities.getTimestamp()
        
        print("\(className) > \(#function) > timeStamp: \(timestamp)")
        print("\(className) > \(#function) > deviceKey: \(String(describing: deviceKey))")
        
        let loginString = Configuration.Cognito.DEVELOPER_PROVIDER_NAME + username
        
        var body: [String : Any] = [String : Any]()
        body[GetTokenKeys.uid.rawValue] = UserDefaults.Account.string(forKey: .deviceUid)!
        body[GetTokenKeys.timestamp.rawValue] = timestamp
        body[GetTokenKeys.loginString.rawValue] = Utilities.dictionaryToString(map: [Configuration.Cognito.DEVELOPER_PROVIDER_NAME : username])
        
        if let cachedIdentityId = UserDefaults.Authentication.string(forKey: .identityId) {
            print("\(className) > \(#function) > cachedIdentityId : \(cachedIdentityId)")
            body[GetTokenKeys.identityId.rawValue] = cachedIdentityId
            body[GetTokenKeys.signature.rawValue] = Utilities.getSignature(dateToSign: timestamp + loginString + cachedIdentityId, key: deviceKey!)
        } else {
            body[GetTokenKeys.signature.rawValue] = Utilities.getSignature(dateToSign: timestamp + loginString, key: deviceKey!)
        }

        let jsonData: Data
        do {
            jsonData = try JSONSerialization.data(withJSONObject: body, options: [])
            getTokenRequest.httpBody = jsonData
        } catch {
            print("\(className) > \(#function) > Error: cannot create JSON from body")
            return AWSTask(result: nil)
        }
        
        print("\(className) > \(#function) > URLSession start")
        
        URLSession.shared.dataTask(with: getTokenRequest) {
            (data, response, error) in
            
            guard let responseData = data else {
                print("\(self.className) > \(#function) > Error : no response")
                return
            }
            
            print("\(self.className) > \(#function) > data : \(responseData.base64EncodedString())")
            
            do {
                guard let receiveCredential = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String : Any] else {
                    print("\(self.className) > \(#function) > Could not get JSON from response as Dictionary")
                    return
                }
                
                guard let identityId = receiveCredential["identityId"] as? String else {
                    print("\(self.className) > \(#function) > Could not get identityId from JSON")
                    return
                }
                
                guard let token = receiveCredential["token"] as? String else {
                    print("\(self.className) > \(#function) > Could not get token from JSON")
                    return
                }
                
                print("\(self.className) > \(#function) > identityId : \(identityId)")
                print("\(self.className) > \(#function) > token : \(token)")
                
                self.identityId = identityId
                
                let credential = AmazonCognitoCredential(token: token, identityId: identityId)
                
                tokenRequest.set(result: credential)
                
            } catch {
                print("\(self.className) > \(#function) > Error parsing response from POST tokenURL")
                
                if let topController = UIApplication.topViewController() {
                    let alertController = UIAlertController(title: nil,
                                                            message: "세션이 만료되었습니다",
                                                            preferredStyle: .alert)
                    
                    let okAction = UIAlertAction(title: "확인", style: .default, handler: {
                        (action) in self.logout()
                    })
                    
                    alertController.addAction(okAction)
                    
                    if let presentedController = topController.presentedViewController {
                        presentedController.dismiss(animated: true, completion: nil)
                    }
                    
                    topController.present(alertController, animated: true, completion: nil)
                    
                }
                return
            }
            
        }.resume()
        
        
        return tokenRequest.task
    }
    
    func register(username: String, password: String, nickname: String, gender: String, birth: Int, phone: String) -> AWSTask<NSString> {
        
        print("\(className) > \(#function) > register")
        
        let registerTask = AWSTaskCompletionSource<NSString>()
        
        let apiClient = WEKENDAuthenticationAPIClient.default()
        
        let registerRequest = WEKENDRegisterRequestModel()!
        registerRequest.username = username
        registerRequest.password = password
        registerRequest.nickname = nickname
        registerRequest.gender = gender
        registerRequest.birth = birth as NSNumber
        registerRequest.phone = phone
        
        apiClient.registeruserPost(registerRequest).continueWith(executor: AWSExecutor.mainThread()) { task in
            
            print("\(self.className) > \(#function) > register AWSTask > start")
            
            if task.error != nil {
                print("\(self.className) > \(#function) > register AWSTask error")
                
                registerTask.set(error: task.error!)
                
                return nil
            } else {
                print("\(self.className) > \(#function) > AWSTask not error")
                let response = task.result as! WEKENDRegisterResponseModel
                print("\(self.className) > \(#function) > response > result : " + response.result!)
                print("\(self.className) > \(#function) > response > userid : " + response.userid!)
                
                registerTask.set(result: response.userid! as NSString?)
                
                return response
            }
        }
        
        return registerTask.task
    }
    
    func loginUser(username: String, password: String) -> AWSTask<NSString> {
        
        print("\(className) > \(#function) > username : " + username + ", password : " + password)
        
        let loginTask = AWSTaskCompletionSource<NSString>()
        
        let apiClient = WEKENDAuthenticationAPIClient.default()
        
        let deviceUid = Utilities.getDeviceUUID()
        let timestamp = Utilities.getTimestamp()
        let salt = username + Configuration.APP_NAME
        let decryptionKey = Utilities.getSignature(dateToSign: salt, key: password)
        let signature = Utilities.getSignature(dateToSign: timestamp, key: decryptionKey)
        
        let loginRequest = WEKENDLoginRequestModel()!
        loginRequest.username = username
        loginRequest.timestamp = timestamp
        loginRequest.signature = signature
        loginRequest.uid = deviceUid
        
        apiClient.loginuserPost(loginRequest).continueWith(executor: AWSExecutor.mainThread()) { task in
            
            if task.error != nil {
                print("\(self.className) > \(#function) > response > failed : \(String(describing: task.error))")
                return nil
            } else {
                
                guard let response = task.result as? WEKENDLoginResponseModel else {
//                    fatalError("AmazonIdentityProvider > loginUser response Error")
                    // TODO : Alert Login failed
                    print("\(self.className) > \(#function) > LoginUser Error")
                    loginTask.set(error: AuthenticateError.unknown)
                    return nil
                }
                
                guard let enable = response.enable else {
                    loginTask.set(error: AuthenticateError.userDisabled)
                    return loginTask.task
                }
                
                guard let userId = response.userid,
                      let deviceKey = response.key else {
                    // TODO : Alert Login Failed
                    print("\(self.className) > \(#function) > AWS Login Function return nil")
                    return loginTask.set(error: AuthenticateError.userNotFound)
                }
                
                print("\(self.className) > \(#function) > response > userId : " + userId)
                print("\(self.className) > \(#function) > response > key : " + deviceKey)
                print("\(self.className) > \(#function) > response > enable : " + enable)
                
                UserDefaults.Account.set(username, forKey: .userName)
                UserDefaults.Account.set(userId, forKey: .userId)
                UserDefaults.Account.set(deviceUid, forKey: .deviceUid)
                UserDefaults.Account.set(deviceKey, forKey: .deviceKey)
                
                loginTask.set(result: response.enable as NSString?)
                
                return response
            }
        }
        
        return loginTask.task
    }
    
    func logout() {
        
        print("\(className) > \(#function)")
        
        UserDefaults.Account.remove(forKey: .isUserLoggedIn)
        UserDefaults.Account.remove(forKey: .userName)
        UserDefaults.Account.remove(forKey: .userId)
        UserDefaults.Account.remove(forKey: .deviceUid)
        UserDefaults.Account.remove(forKey: .deviceKey)
        UserDefaults.Authentication.remove(forKey: .identityId)
        UserDefaults.NotificationCount.remove(forKey: .like)
        UserDefaults.NotificationCount.remove(forKey: .receiveMail)
        UserDefaults.NotificationCount.remove(forKey: .sendMail)
        UserDefaults.RemoteNotification.remove(forKey: .deviceToken)
        
        UserInfoRepository.shared.destroy()
        ProductRepository.shared.destroy()
        LikeRepository.shared.destroy()
        ReceiveMailRepository.shared.destroy()
        SendMailRepository.shared.destroy()
        
        AmazonClientManager.shared.clearCredentials()
        ApplicationNavigator.shared.showLoginViewController()
    }
    
}

final class AmazonCognitoCredential {
    let token : String
    let identityId : String
    
    init(token: String, identityId: String) {
        self.token = token
        self.identityId = identityId
    }
}

enum GetTokenKeys: String {
    case uid
    case timestamp
    case loginString
    case identityId
    case signature
}
