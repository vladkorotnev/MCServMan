//
//  MCServManPlugin.h
//  MCServMan
//
//  Created by Vladislav Korotnev on 3/5/13.
//  Copyright (c) 2013 Vladislav Korotnev. All rights reserved.
//

#ifndef MCServMan_MCServManPlugin_h
#define MCServMan_MCServManPlugin_h
@class SMServer,SMAppDelegate;
@protocol SMServerPluginsAllowedMethodsProtocol
- (void) sendServerMessage:(NSString*)mess; //only this allowed for plugins

@end

@protocol SMAppDelegatePluginsAllowedProtocol
- (void) pluginLog:(NSString*)mess; //only this allowed for plugins
@end

@protocol MCServManPlugin <NSObject>
@required
+ (NSString*)pluginName; // visible name
- (NSView*)settingsView; //settings view
@optional
- (void) onLoad:(SMAppDelegate<SMAppDelegatePluginsAllowedProtocol>*)delegate; //on plugin load
- (void) onSettingShow; //on open settings of plugin
- (void) onServerStart:(SMServer<SMServerPluginsAllowedMethodsProtocol>*)server; //on server start
- (void) onServerStop:(SMServer<SMServerPluginsAllowedMethodsProtocol>*)server; //on server stop
- (void) onServerMessage: (NSString*)msg; //on new line in console
- (void) onServerDoneLoading:(SMServer<SMServerPluginsAllowedMethodsProtocol>*)server; //on server Done loading
- (void) onUserJoined:(NSString*)username;
- (void) onUserLeft: (NSString*)username;
- (void) onChat:(NSString*)message sentBy:(NSString*)user;

@end




#endif
