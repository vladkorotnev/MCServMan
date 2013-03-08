//
//  SMMinecraftConfig.h
//  MCServMan
//
//  Created by Vladislav Korotnev on 3/6/13.
//  Copyright (c) 2013 Vladislav Korotnev. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SMMinecraftConfig : NSObject{
    NSString *fpath;
    NSDictionary* allPossibleKeys;
    NSMutableDictionary* curCfg;
}
-(SMMinecraftConfig*)initFromFile:(NSString*)file;
-(void)reloadConfigFromFile;
-(NSString*)descriptionForKey:(NSString*)key;
-(NSString*)typeAndLimitsFor:(NSString*)key;
-(void)writeSetting:(NSString*)setting forKey:(NSString*)key;
-(NSString*)readSetting:(NSString*)setting;
-(NSArray*)allKeys;
-(NSArray*)allPossibleKeys ;
@end
