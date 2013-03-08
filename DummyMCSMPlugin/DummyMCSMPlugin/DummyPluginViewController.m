//
//  DummyPluginViewController.m
//  DummyMCSMPlugin
//
//  Created by Vladislav Korotnev on 3/7/13.
//  Copyright (c) 2013 Vladislav Korotnev. All rights reserved.
//

#import "DummyPluginViewController.h"

@interface DummyPluginViewController ()

@end

@implementation DummyPluginViewController
static SMAppDelegate<SMAppDelegatePluginsAllowedProtocol>*del=nil;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [nibBundleOrNil loadNibNamed:nibNameOrNil owner:self topLevelObjects:nil];
        // Initialization code here.
    }
    
    return self;
}

- (NSString*)pluginName {
    return @"Dummy plugin";
}
- (NSView*)settingsView {
    self = [self initWithNibName:@"DummyPluginViewController" bundle:[NSBundle bundleForClass:self.class]];
    return self.view;
}
- (void) onLoad:(SMAppDelegate<SMAppDelegatePluginsAllowedProtocol>*)delegate {
    [delegate _log:@"== Dummy plugin onLoad event\n"];
    del=delegate;
}
- (void) onSettingShow{
    [del _log:@"== Dummy plugin onSettingsShow\n"];
}
- (void) onServerStart:(SMServer<SMServerPluginsAllowedMethodsProtocol>*)server {
    [del _log:@"== Dummy plugin onStart\n"];
}
- (void) onServerStop:(SMServer<SMServerPluginsAllowedMethodsProtocol>*)server{
    [del _log:@"== Dummy plugin onStop\n"];
}
- (void) onServerMessage: (NSString*)msg{}

@end
