//
//  DGPreferencesViewController.h
//  DoNotGive
//
//  Created by Vladislav Korotnev on 3/23/13.
//  Copyright (c) 2013 Vladislav Korotnev. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DGPreferencesViewController : NSViewController
@property (assign) IBOutlet NSButton *denyGive;
@property (assign) IBOutlet NSButton *performKick;
- (IBAction)preferenceChanged:(id)sender;
- (void)refresh;

@end
