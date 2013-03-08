//
//  DummyPluginViewController.h
//  DummyMCSMPlugin
//
//  Created by Vladislav Korotnev on 3/7/13.
//  Copyright (c) 2013 Vladislav Korotnev. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MCServManPlugin.h"
@interface DummyPluginViewController : NSViewController
- (NSString*)pluginName; // visible name
- (NSView*)settingsView; //settings view
- (void) onLoad:(SMAppDelegate<SMAppDelegatePluginsAllowedProtocol>*)delegate; //on plugin load
- (void) onSettingShow; //on open settings of plugin
- (void) onServerStart:(SMServer<SMServerPluginsAllowedMethodsProtocol>*)server; //on server start
- (void) onServerStop:(SMServer<SMServerPluginsAllowedMethodsProtocol>*)server; //on server stop
- (void) onServerMessage: (NSString*)msg; //on new line in console
@end
