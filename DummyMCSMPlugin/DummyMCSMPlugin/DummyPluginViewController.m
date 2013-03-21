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
static SMServer<SMServerPluginsAllowedMethodsProtocol>*srv = nil;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [nibBundleOrNil loadNibNamed:nibNameOrNil owner:self topLevelObjects:nil];
        // Initialization code here.
    }
    
    return self;
}

+ (NSString*)pluginName {
    return @"Sample Plugin";
}
- (NSView*)settingsView {
    self = [self initWithNibName:@"DummyPluginViewController" bundle:[NSBundle bundleForClass:self.class]];
    return self.view;
}
- (void) onLoad:(SMAppDelegate<SMAppDelegatePluginsAllowedProtocol>*)delegate {
    [delegate plugin:@"Dummy Plugin" log:@"Example onLoad event"];
    del=delegate;
}
- (void) onSettingShow{
    [del plugin:@"Dummy Plugin" log:@"Example onSettingsShow"];
}
- (void) onServerStart:(SMServer<SMServerPluginsAllowedMethodsProtocol>*)server {
    srv=server;
    [del plugin:@"Dummy Plugin" log:@"Example onStart"];
}
- (void) onServerStop:(SMServer<SMServerPluginsAllowedMethodsProtocol>*)server{
    srv=nil;
    [del plugin:@"Dummy Plugin" log:@"Example onStop"];
}
- (void) onServerMessage: (NSString*)msg{}

-(void)onUserJoined:(NSString*)name {
    [srv sendServerMessage:[NSString stringWithFormat:@"say Greetings %@",name]];
}
-(void)onUserLeft:(NSString *)username {
    [srv sendServerMessage:[NSString stringWithFormat:@"say See you later %@",username]];
}
-(void)onChat:(NSString *)message sentBy:(NSString *)user {
 //  [del plugin:@"Dummy Plugin" log:[NSString stringWithFormat:@"\"%@\", said %@",message,user]];
}
@end
