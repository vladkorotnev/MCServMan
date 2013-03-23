//
//  DGPreferencesViewController.m
//  DoNotGive
//
//  Created by Vladislav Korotnev on 3/23/13.
//  Copyright (c) 2013 Vladislav Korotnev. All rights reserved.
//

#import "DGPreferencesViewController.h"

@interface DGPreferencesViewController ()

@end

@implementation DGPreferencesViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (IBAction)preferenceChanged:(id)sender {
    [[NSUserDefaults standardUserDefaults]setBool:self.denyGive.state forKey:@"DONOTGIVE_denyGive"];
    [[NSUserDefaults standardUserDefaults]setBool:self.performKick.state forKey:@"DONOTGIVE_kick"];
}
- (void)refresh {
    self.denyGive.state=[[NSUserDefaults standardUserDefaults]boolForKey:@"DONOTGIVE_denyGive"];
    self.performKick.state=[[NSUserDefaults standardUserDefaults]boolForKey:@"DONOTGIVE_kick"];
}
@end
