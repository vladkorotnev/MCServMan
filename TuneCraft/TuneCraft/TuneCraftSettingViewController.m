//
//  TuneCraftSettingViewController.m
//  TuneCraft
//
//  Created by Vladislav Korotnev on 3/5/13.
//  Copyright (c) 2013 Vladislav Korotnev. All rights reserved.
//

#import "TuneCraftSettingViewController.h"

@interface TuneCraftSettingViewController ()

@end


@implementation TuneCraftSettingViewController
static NSMutableDictionary *prefDict;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}
- (void)readSettings {
    if (!prefDict) {
        if ([[NSFileManager defaultManager]fileExistsAtPath:[@"~/Library/Preferences/com.vladkorotnev.Tunecraft.plist" stringByExpandingTildeInPath]]) {
            prefDict = [NSMutableDictionary dictionaryWithContentsOfFile:[@"~/Library/Preferences/com.vladkorotnev.Tunecraft.plist" stringByExpandingTildeInPath]];
        } else{
            prefDict = [NSMutableDictionary new];
            [prefDict setObject:@"" forKey:@"user"];
            [prefDict setObject:@"1" forKey:@"auto"];
        }

    }
    self.autoNP.state = [[prefDict objectForKey:@"auto"]integerValue];
    self.userfield.stringValue = [prefDict objectForKey:@"user"];
    [prefDict retain];
}
-(void)writeSettings {
    [prefDict writeToFile:[@"~/Library/Preferences/com.vladkorotnev.Tunecraft.plist" stringByExpandingTildeInPath] atomically:false];
}

- (void) loadSetting{
    [self readSettings];
}
- (IBAction)autoNPChg:(id)sender {
    [prefDict setObject:[NSString stringWithFormat:@"%li",self.autoNP.state] forKey:@"auto"];
    [self writeSettings];
}

- (IBAction)userchg:(id)sender {
    [prefDict setObject:self.userfield.stringValue forKey:@"user"];
    [self writeSettings];
}
@end
