//
//  SMMinecraftConfig.m
//  MCServMan
//
//  Created by Vladislav Korotnev on 3/6/13.
//  Copyright (c) 2013 Vladislav Korotnev. All rights reserved.
//

#import "SMMinecraftConfig.h"
#import "Defines.h"
@implementation SMMinecraftConfig
-(SMMinecraftConfig*)initFromFile:(NSString*)file{
    self = [super init];
    if (self) {
        
        fpath=file;
        [fpath retain];
        curCfg = [[NSMutableDictionary alloc]init];
        [curCfg retain];
        if ([FM fileExistsAtPath:file]) {
            
            [self _read];
        }
        allPossibleKeys=[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"MCSettingKeys" ofType:@"plist"]];
        [allPossibleKeys retain];
    }
    return self;
}
-(NSString*)descriptionForKey:(NSString*)key; {
    return [[allPossibleKeys objectForKey:key]objectForKey:@"dsc"];
}
-(NSString*)typeAndLimitsFor:(NSString*)key; {
    return [[allPossibleKeys objectForKey:key]objectForKey:@"type"];
}
-(void)writeSetting:(NSString*)setting forKey:(NSString*)key {
    [curCfg setObject:setting forKey:key];
    [curCfg retain];
    [self _write];
}
-(NSString*)readSetting:(NSString*)setting {
    return [curCfg objectForKey:setting];
}
-(NSArray*)allKeys {
    return [curCfg allKeys];
}
-(NSArray*)allPossibleKeys {
    
    return [allPossibleKeys allKeys];
}
-(void)reloadConfigFromFile {
    [self _read];
}
-(void)_write{
    NSString*output  =@"";
    for (NSString*key in curCfg.allKeys) {
        if (![key isEqualToString:@""] && ![[curCfg objectForKey:key]isEqualToString:@""]) {
            NSLog(@"Writing %@=%@",key,[curCfg objectForKey:key]);
            output = [output stringByAppendingFormat:@"%@=%@\n",key,[curCfg objectForKey:key]];
        }
        
    }
    NSError*e=nil;
    [output writeToFile:fpath atomically:false encoding:NSUTF8StringEncoding error:&e];
    if (e != nil) {
        NSAlert* msgBox = [[[NSAlert alloc] init] autorelease];
        [msgBox setMessageText: @"Failed to save server configuration"];
        [msgBox setInformativeText:e.localizedDescription];
        [msgBox addButtonWithTitle: @"OK"];
        [msgBox runModal];
    }
}
-(void)_read{
    NSError*e = nil;
    NSString* conf = nil;
    conf = [NSString stringWithContentsOfFile:fpath encoding:NSUTF8StringEncoding error:&e];
    if (e != nil) {
        NSAlert* msgBox = [[[NSAlert alloc] init] autorelease];
        [msgBox setMessageText: @"Failed to load Minecraft server configuration"];
        [msgBox setInformativeText:e.localizedDescription];
        [msgBox addButtonWithTitle: @"OK"];
        [msgBox runModal];
        return;
    }
    NSArray*lines = [conf componentsSeparatedByString:@"\n"];
    for (NSString*line in lines) {
        if (![line hasPrefix:@"#"] && ![[[line componentsSeparatedByString:@"="]lastObject] isEqualToString:@""] && ![[[line componentsSeparatedByString:@"="]objectAtIndex:0]isEqualToString:@""] ) {
            [curCfg setObject:[[line componentsSeparatedByString:@"="]lastObject] forKey:[[line componentsSeparatedByString:@"="]objectAtIndex:0]];
        }
        
    }
}
@end
