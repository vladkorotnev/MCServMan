//
//  TuneCraftMain.h
//  TuneCraft
//
//  Created by Vladislav Korotnev on 3/5/13.
//  Copyright (c) 2013 Vladislav Korotnev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "iTunes.h"
#import <ScriptingBridge/ScriptingBridge.h>
#import "MCServManPlugin.h"

@interface TuneCraftMain : NSObject<MCServManPlugin>
- (NSString*)pluginName;
- (NSView*)settingsView;
- (void) onLoad:(SMAppDelegate<SMAppDelegatePluginsAllowedProtocol>*)delegate; //on plugin load
- (void) onSettingShow; //on open settings of plugin
- (void) onServerStart:(SMServer<SMServerPluginsAllowedMethodsProtocol>*)server; //on server start
- (void) onServerStop:(SMServer<SMServerPluginsAllowedMethodsProtocol>*)server; //on server stop
- (void) onServerMessage: (NSString*)msg; //on new line in console
@end

