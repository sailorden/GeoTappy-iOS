//
//  Group.h
//  GeoTappy
//
//  Created by Dylan Marriott on 11/10/14.
//  Copyright (c) 2014 Dylan Marriott. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Favourite.h"

@interface Group : NSObject <NSCoding, Favourite>

@property (nonatomic) NSString* name;
@property (nonatomic) NSMutableArray* users;

- (void)save;

@end
