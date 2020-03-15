//
//  DBManager.h
//  mPiler
//
//  Created by Harikrishna on 17/05/16.
//  Copyright © 2016 Harikrishna. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DBManager : NSObject

@property (nonatomic, strong) NSMutableArray *arrColumnName;
@property (nonatomic) long affectedRows;
@property (nonatomic) long long lastInsertedRowId;

- (instancetype)initWithDatabaseFileName:(NSString *)dbFileName;
- (NSArray *)loadDataFromDB:(NSString *)query;
- (void)executeQuery:(NSString *)query;

@end
