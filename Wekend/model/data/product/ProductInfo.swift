//
//  ProductInfo.swift
//  Wekend
//
//  Created by Kim Young-wook on 2016. 11. 23..
//  Copyright © 2016년 Kim Young-wook. All rights reserved.
//

import Foundation
import AWSDynamoDB

class ProductInfo: AWSDynamoDBObjectModel, AWSDynamoDBModeling {
    
    struct Schema {
        static let TABLE_NAME = "product_db"
        static let INDEX_STATUS_LIKECOUNT = "ProductStatus-LikeCount-index"
        static let INDEX_STATUS_UPDATEDTIME = "ProductStatus-UpdatedTime-index"
        static let INDEX_MAIN_UPDATEDTIME = "MainCategory-UpdatedTime-index"
    }
    
    struct Attribute {
        static let PRODUCT_ID = "ProductId"
        static let TITLE_KOR = "TitleKor"
        static let TITLE_ENG = "TitleEng"
        static let SUB_TITLE = "SubTitle"
        static let PRODUCT_REGION = "ProductRegion"
        static let MAIN_CATEGORY = "MainCategory"
        static let SUB_CATEGORY = "SubCategory"
        static let DESCRIPTION = "Description"
        static let TELEPHONE = "Telephone"
        static let ADDRESS = "Address"
        static let PRICE = "Price"
        static let PARKING = "Parking"
        static let OPERATION_TIME = "OperationTime"
        static let FACEBOOK = "Facebook"
        static let BLOG = "Blog"
        static let INSTAGRAM = "Instagram"
        static let HOMEPAGE = "Homepage"
        static let ETC = "Etc"
        static let IMAGE_COUNT = "ImageCount"
        static let UPDATED_TIME = "UpdatedTime"
        static let LIKECOUNT = "LikeCount"
        static let PRODUCT_STATUS = "ProductStatus"
        static let MALE_LIKE_TIME = "MaleLikeTime"
        static let FEMALE_LIKE_TIME = "FemaleLikeTime"
    }
    
    struct Title {
        static let PRICE = "가격대"
        static let PARKING = "주차"
        static let OPERATING_TIME = "영업시간"
    }
    
    struct RawValue {
        static let STATUS_ENABLED = "Enabled"
        static let LIKECOUNT_DELEMETER = 1000000
    }
    
    // MARK: Ignore Properties
    
    var regionMap : [Int : String]?
    var isLike: Bool = false
    
    
    // MARK: Attributes
    
    var ProductId: Int = -1
    var TitleKor: String?
    var TitleEng: String?
    var SubTitle: String?
    var ProductRegion: Any?
    var MainCategory: Any?
    var SubCategory: Any?
    var Description: String?
    var Telephone: String?
    var Address: String?
    var SubAddress: String?
    var Price: String?
    var Parking: String?
    var OperationTime: String?
    var Facebook: String?
    var Blog: String?
    var Instagram: String?
    var Homepage: String?
    var Etc: String?
    var ImageCount: Any?
    var UpdatedTime: String?
    var ProductStatus: String?
    var LikeCount: Int = 0
    
    // MARK: - For ReadState
    var MaleLikeTime: String?
    var FemaleLikeTime: String?
    
    var realLikeCount: Int {
        get {
            return Int(LikeCount / RawValue.LIKECOUNT_DELEMETER)
        }
        set {
            LikeCount = newValue * RawValue.LIKECOUNT_DELEMETER + self.ProductId
        }
    }
    
    // MARK: Initialization
    
    static func dynamoDBTableName() -> String {
        return Schema.TABLE_NAME
    }
    
    static func hashKeyAttribute() -> String {
        return Attribute.PRODUCT_ID
    }
    
    static func ignoreAttributes() -> [String] {
        return ["isLike", "regionMap", "realLikeCount", "toMergedDescription"]
    }
}

extension ProductInfo {
    var toDescriptionForDetail : String {
        
        var result: String = ""
        
        if let description = Description {
            result += description.htmlToString
        }
        if let price = Price {
            result += "\n\n" + "\(ProductInfo.Title.PRICE) : " + price
        }
        if let parking = Parking {
            result += "\n\n" + "\(ProductInfo.Title.PARKING) : " + parking
        }
        if let operatingTime = OperationTime {
            result += "\n\n" + "\(ProductInfo.Title.OPERATING_TIME) : " + operatingTime
        }
        
        return result
    }
    
    var toDescriptionForProfile : String {
        return "\(TitleKor ?? "캠페인") 바로가기"
    }
}

class ProductReadState: AWSDynamoDBObjectModel, AWSDynamoDBModeling {
    
    struct Schema {
        static let TABLE_NAME = "product_like_state"
    }
    
    struct Attribute {
        static let PRODUCT_ID = "ProductId"
        static let MALE_LIKE_TIME = "MaleLikeTime"
        static let FEMALE_LIKE_TIME = "FemaleLikeTime"
    }
    
    var ProductId: Int = -1
    var MaleLikeTime: String?
    var FemaleLikeTime: String?
    
    static func dynamoDBTableName() -> String {
        return Schema.TABLE_NAME
    }
    
    static func hashKeyAttribute() -> String {
        return Attribute.PRODUCT_ID
    }
    
    static func ignoreAttributes() -> [String] {
        return []
    }
    
}

enum ProductRegion: Int, EnumCollection {
    
    case none = 0
    case seoul1 = 4001
    case seoul2 = 4002
    case seoul3 = 4012
    case seoul4 = 4011
    case seoul5 = 4003
    case seoul6 = 4007
    case seoul7 = 4008
    case seoul8 = 4014
    case seoul9 = 4015
    case seoul10 = 4004
    case seoul11 = 4005
    case seoul12 = 4006
    case seoul13 = 4010
    case seoul14 = 4013
    case seoul15 = 4009
    
    var toString: String {
        switch self {
        case .none:
            return "전체 지역"
        case .seoul1:
            return "압구정/청담/신사"
        case .seoul2:
            return "서래마을/서초/방배"
        case .seoul3:
            return "도곡/대치/양재"
        case .seoul4:
            return "역삼/논현/삼성"
        case .seoul5:
            return "이태원/한남"
        case .seoul6:
            return "삼청/효자/인사"
        case .seoul7:
            return "평창/부암"
        case .seoul8:
            return "종로/광화문"
        case .seoul9:
            return "성북/정동"
        case .seoul10:
            return "홍대/합정"
        case .seoul11:
            return "연남/연희"
        case .seoul12:
            return "이촌/용산"
        case .seoul13:
            return "잠실/송파/강동"
        case .seoul14:
            return "광진/성수"
        case .seoul15:
            return "장충/혜화/기타"
        }
    }
}

enum Category: Int, EnumCollection {
    
    case category = 0
    case food = 101
    case concert = 102
    case leisure = 103
    
    var toString: String {
        switch self {
        case .category:
            return "전체 카테고리"
        case .food:
            return "맛집"
        case .concert:
            return "문화공연"
        case .leisure:
            return "레저스포츠"
        }
    }
}

enum Food: Int, EnumCollection {
    
    case category = 0
    case western = 1001
    case japanese = 1002
    case chinese = 1003
    case korean = 1004
    case asian = 1005
    case dessert = 1006
    case hotel = 1007
    
    var toString: String {
        switch self {
        case .category:
            return "전체 세부 카테고리"
        case .western:
            return "양식"
        case .japanese:
            return "일식"
        case .chinese:
            return "중식"
        case .korean:
            return "한식"
        case .asian:
            return "퓨전/아시안/기타"
        case .dessert:
            return "디저트/브런치"
        case .hotel:
            return "호텔"
        }
    }
}

enum Concert: Int, EnumCollection {
    
    case category = 0
    case exhibition = 2001
    case classic = 2002
    case musical = 2003
    case show = 2004
    
    var toString: String {
        switch self {
        case .category:
            return "전체 세부 카테고리"
        case .exhibition:
            return "전시회"
        case .classic:
            return "클래식/오페라"
        case .musical:
            return "뮤지컬/연극"
        case .show:
            return "일반공연"
        }
    }
}

enum Leisure: Int, EnumCollection {
    
    case category = 0
    case leisure = 3001
    case sports = 3002
    
    var toString: String {
        switch self {
        case .category:
            return "전체 세부 카테고리"
        case .leisure:
            return "레저"
        case .sports:
            return "스포츠"
        }
    }
}

enum SortMode: Int, EnumCollection {
    
    case like = 0
    case date = 1
    
    var toString: String {
        switch self {
        case .date:
            return "최신순"
        case .like :
            return "좋아요순"
        }
    }
}

struct FilterOptions {
    
    var sortMode: SortMode = .date
    var category: Category = .category
    var region: ProductRegion = .none
    var food: Food?
    var concert: Concert?
    var leisure: Leisure?
    
    func isEqual(_ filterOptions: FilterOptions) -> Bool {
        return self.sortMode == filterOptions.sortMode &&
                self.category == filterOptions.category &&
                self.food == filterOptions.food &&
                self.concert == filterOptions.concert &&
                self.leisure == filterOptions.leisure &&
                self.region == filterOptions.region
    }
}
