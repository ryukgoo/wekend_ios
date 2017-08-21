//
//  ObjC.h
//  Wekend
//
//  Created by Young-Wook Kim on 2017. 7. 27..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ObjC : NSObject

+ (BOOL)catchException:(void(^)())tryBlock error:(__autoreleasing NSError **)error;

@end
