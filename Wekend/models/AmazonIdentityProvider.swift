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
        
        printLog("token")
        
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
        
        printLog("clear")
        
        super.clear()
    }
    
    func getCredentialsByURL() -> AWSTask<AmazonCognitoCredential> {
        
        printLog("getCredentialByURL start")
        
        let tokenRequest = AWSTaskCompletionSource<AmazonCognitoCredential>()
        
        guard let getTokenURL = URL(string: Configuration.ApiGateway.GETTOKEN_URL) else {
            fatalError("AmazonIdentityProvider > getCredentialsByURL > make URL Error")
        }
        
        var getTokenRequest = URLRequest(url: getTokenURL)
        getTokenRequest.httpMethod = "POST"
        getTokenRequest.cachePolicy = .reloadIgnoringCacheData
        
        guard let username = UserDefaults.Account.string(forKey: .userName) else {
            fatalError("AmazonIdentityProvider > User never logged in")
        }
        
        let deviceKey = UserDefaults.Account.string(forKey: .deviceKey)
        let timestamp = Utilities.getTimestamp()
        
        printLog("timeStamp: \(timestamp)")
        printLog("deviceKey: \(String(describing: deviceKey))")
        
        let loginString = Configuration.Cognito.DEVELOPER_PROVIDER_NAME + username
        
        var body: [String : Any] = [String : Any]()
        body[GetTokenKeys.uid.rawValue] = UserDefaults.Account.string(forKey: .deviceUid)!
        body[GetTokenKeys.timestamp.rawValue] = timestamp
        body[GetTokenKeys.loginString.rawValue] = Utilities.dictionaryToString(map: [Configuration.Cognito.DEVELOPER_PROVIDER_NAME : username])
        
        if let cachedIdentityId = UserDefaults.Authentication.string(forKey: .identityId) {
            printLog("getCredentialsByURL > cachedIdentityId : \(cachedIdentityId)")
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
            printLog("Error: cannot create JSON from body")
            return AWSTask(result: nil)
        }
        
        printLog("getCredentialByURL > URLSession start")
        
        URLSession.shared.dataTask(with: getTokenRequest) {
            (data, response, error) in
            
            guard let responseData = data else {
                self.printLog("Error : no response")
                return
            }
            
            self.printLog("getCredentialsByURL > data : \(responseData.base64EncodedString())")
            
            do {
                guard let receiveCredential = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String : Any] else {
                    self.printLog("Could not get JSON from response as Dictionary")
                    return
                }
                
                guard let identityId = receiveCredential["identityId"] as? String else {
                    self.printLog("Could not get identityId from JSON")
                    return
                }
                
                guard let token = receiveCredential["token"] as? String else {
                    self.printLog("Could not get token from JSON")
                    return
                }
                
                self.printLog("getCredentialsByURL > identityId : \(identityId)")
                self.printLog("getCredentialsByURL > token : \(token)")
                
                self.identityId = identityId
                
                let credential = AmazonCognitoCredential(token: token, identityId: identityId)
                
                tokenRequest.set(result: credential)
                
            } catch {
                self.printLog("Error parsing response from POST tokenURL")
                
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
        
        printLog("register")
        
        let registerTask = AWSTaskCompletionSource<NSString>()
        
        let apiClient = WEKENDAuthenticationAPIClient.default()
        
        let registerRequest = WEKENDRegisterRequestModel()!
        registerRequest.username = username
        registerRequest.password = password
        registerRequest.nickname = nickname
        registerRequest.gender = gender
        registerRequest.birth = birth as NSNumber
        registerRequest.phone = phone
        
        apiClient.registeruserPost(registerRequest).continueWith(block: {
            (task: AWSTask) -> Any? in
            
            self.printLog("register AWSTask > start")
            
            if task.error != nil {
                self.printLog("register AWSTask error")
                
                registerTask.set(error: task.error!)
                
                return nil
            } else {
                self.printLog("register AWSTask not error")
                let response = task.result as! WEKENDRegisterResponseModel
                self.printLog("register > response > result : " + response.result!)
                self.printLog("register > response > userid : " + response.userid!)
                
                registerTask.set(result: response.userid! as NSString?)
                
                return response
            }
        })
        
        return registerTask.task
    }
    
    func loginUser(username: String, password: String) -> AWSTask<NSString> {
        
        printLog("login > username : " + username + ", password : " + password)
        
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
        
        apiClient.loginuserPost(loginRequest).continueWith(block: {
            (task: AWSTask) -> Any? in
            
            if task.error != nil {
                self.printLog("login > response > failed : \(String(describing: task.error))")
                return nil
            } else {
                
                guard let response = task.result as? WEKENDLoginResponseModel else {
//                    fatalError("AmazonIdentityProvider > loginUser response Error")
                    // TODO : Alert Login failed
                    self.printLog("LoginUser Error")
                    return nil
                }
                
                guard let enable = response.enable else {
                    loginTask.set(error: AuthenticateError.userDisabled)
                    return loginTask.task
                }
                
                guard let userId = response.userid,
                      let deviceKey = response.key else {
                    // TODO : Alert Login Failed
                    self.printLog("AmazonIdentityProvider > loginUser > AWS Login Function return nil")
                    return loginTask.set(error: AuthenticateError.userNotFound)
                }
                
                self.printLog("login > response > userId : " + userId)
                self.printLog("login > response > key : " + deviceKey)
                self.printLog("login > response > enable : " + enable)
                
                UserDefaults.Account.set(username, forKey: .userName)
                UserDefaults.Account.set(userId, forKey: .userId)
                UserDefaults.Account.set(deviceUid, forKey: .deviceUid)
                UserDefaults.Account.set(deviceKey, forKey: .deviceKey)
                
                loginTask.set(result: response.enable as NSString?)
                
                return response
            }
        })
        
        return loginTask.task
    }
    
    func logout() {
        
        printLog("logout")
        
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
        
        UserInfoManager.sharedInstance.destroy()
        ProductInfoManager.sharedInstance.destroy()
        LikeDBManager.sharedInstance.destroy()
        ReceiveMailManager.sharedInstance.destory()
        SendMailManager.sharedInstance.destory()
        
        AmazonClientManager.sharedInstance.clearCredentials()
        
        let loginStoryBoard = Constants.StoryboardName.Login
        let loginboard = UIStoryboard(name: loginStoryBoard.rawValue, bundle: nil)
        
        guard let loginVC = loginboard.instantiateViewController(withIdentifier: loginStoryBoard.identifier) as? UINavigationController,
            let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                self.printLog("AmazonClientManager > didFinishLaunching > get VC and AppDelegate Error")
                return
        }
        
        appDelegate.window!.rootViewController = loginVC
        appDelegate.window!.makeKeyAndVisible()
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
