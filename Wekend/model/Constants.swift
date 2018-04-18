//
//  Constants.swift
//  Wekend
//
//  Created by Kim Young-wook on 2016. 12. 2..
//  Copyright © 2016년 Kim Young-wook. All rights reserved.
//

import Foundation

struct Constants {
    
    static let ConsumePoint = 1000
    
    enum StoryboardName: String {
        
        case Main
        case Login
        case LaunchScreen
        
        var identifier: String {
            switch self {
            case .Main:
                return "MainViewController"
            case .Login:
                return "LoginNavigation"
            case .LaunchScreen:
                return "LaunchScreen"
            }
        }
    }
    
    struct ColorInfo {
        static let MAIN = 0xf2797c
        static let DEFAULT = 0xffffff
        
        struct Text {
            struct Mail {
                static let DEFAULT = 0x43434a
                static let RECEIVE = 0xe2154a
                static let SEND = 0x28b1ca
            }
        }
        
    }
    
    struct Title {
        
        struct View {
            static let MAIN = "전체보기"
        }
        
        struct Button {
            // Common
            static let DONE = "완료"
            
            // Like
            static let LIKE = "좋아요"
            static let FRIEND_RECOMMEND = "친구 추천 확인"
        }
        
        struct Cell {
            static let DATE = "DATE"
            static let MADE = "님과 함께가기를 성공하였습니다"
            static let SEND_NOT_MADE = "님에게 함께가기 신청을 했습니다"
            static let RECEIVE_NOT_MADE = "님에게 함께가기 신청이 왔습니다"
            static let SEND_REJECT = "님이 함께가기를 거절하였습니다"
            static let RECEIVE_REJECT = "님과 함께가기를 거절하였습니다"
        }
        
        struct Message {
            static let LOADING = "Loading.."
            static let PLEASE_WAIT = "Please wait"
        }
    }
}

// MARK: Authentication
struct Configuration {
    
    // MARK: Application Default Configuration
    static let APP_NAME = "wekend"
    static let PLATFORM = "APNS"
    
    // MARK: Amazon Cognito Configuration
    static let REGION_TYPE = AWSRegionType.APNortheast1
    static let IDENTITY_POOL_ID = "ap-northeast-1:7fd2e15f-b246-4086-a019-dc6d446bdd99"
    
    // MARK: Developer Authentication Configuration
    struct Cognito {
        static let AMAZON_PROVIDER = "cognito-identity.amazonaws.com"
        static let DEVELOPER_PROVIDER_NAME = "login.entuition.picnic"
        static let DEVELOPER_ENDPOINT = ""
    }
    
    // MARK: S3 Configuration
    struct S3 {
        static let AMAZON_ADDRESS = "s3-ap-northeast-1.amazonaws.com/"
        static let PRODUCT_IMAGE_BUCKET = "entuition-product-images"
        static let PRODUCT_THUMB_BUCKET = "entuition-product-images-thumb"
        static let PROFILE_IMAGE_BUCKET = "entuition-user-profile"
        static let PROFILE_THUMB_BUCKET = "entuition-user-profile-thumb"
        static let PRODUCT_IMAGE_URL = "https://" + PRODUCT_IMAGE_BUCKET + "." + AMAZON_ADDRESS
        static let PRODUCT_THUMB_URL = "https://" + PRODUCT_THUMB_BUCKET + "." + AMAZON_ADDRESS
        static let PROFILE_IMAGE_URL = "https://" + PROFILE_IMAGE_BUCKET + "." + AMAZON_ADDRESS
        static let PROFILE_THUMB_URL = "https://" + PROFILE_THUMB_BUCKET + "." + AMAZON_ADDRESS
        
        static func PRODUCT_IMAGE_NAME(_ index: Int) -> String { return "product_image_\(index).jpg" }
        static func PROFILE_IMAGE_NAME(_ index: Int) -> String { return "profile_image_\(index).jpg" }
    }
    
    struct ApiGateway {
        static let REGISTER_KEY = "WEKENDAuthenticationAPIClient"
        static let GETTOKEN_URL = "https://87tshy6nvg.execute-api.ap-northeast-1.amazonaws.com/beta/gettoken"
        static let VERIFICATION_URL = "https://87tshy6nvg.execute-api.ap-northeast-1.amazonaws.com/beta/verificationcode"
        static let RESETPASSWORD_URL = "https://87tshy6nvg.execute-api.ap-northeast-1.amazonaws.com/beta/resetpassword"
    }
    
    static let GOOGLE_API_KEY = "AIzaSyCFIGoikZsGXBhiesMJjOW40tMMRd8_FtM"
}

enum NotificationDataKey: String {
    
    case aps
    case type
    case productId
    case userId
    
}

// MARK: ViewController Titles
enum NavigationType: Int {
    
    case campaign
    case like
    case mail
    case store
    case drawer
    
    var toString: String {
        switch self {
        case .campaign:
            return "campaign"
        case .like:
            return "like"
        case .mail:
            return "mail"
        case .store:
            return "store"
        case .drawer:
            return "drawer"
        }
    }
}

