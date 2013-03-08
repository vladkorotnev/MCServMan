//
//  TuneCraftSettingViewController.h
//  TuneCraft
//
//  Created by Vladislav Korotnev on 3/5/13.
//  Copyright (c) 2013 Vladislav Korotnev. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TuneCraftSettingViewController : NSViewController
@property (assign) IBOutlet NSButton *autoNP;
@property (assign) IBOutlet NSTextField *userfield;
- (IBAction)autoNPChg:(id)sender;
- (IBAction)userchg:(id)sender;
- (void)loadSetting;
@end
