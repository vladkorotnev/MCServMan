//
//  SMAppDelegate.h
//  MCServMan
//
//  Created by Vladislav Korotnev on 3/4/13.
//  Copyright (c) 2013 Vladislav Korotnev. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Defines.h"
#import "ASIHTTPRequest.h"
#import "SMServer.h"
#import "MCServManPlugin.h"
#import "SMMinecraftConfig.h"
#import "Sparkle.framework/Headers/Sparkle.h"
#import <WebKit/WebKit.h>
@interface SMAppDelegate : NSObject <NSApplicationDelegate,ASIHTTPRequestDelegate,MinecraftServerDelegate,SMAppDelegatePluginsAllowedProtocol>{
    ASIHTTPRequest*currentDownload;
    NSMutableArray*loadedPlugins;
    SMMinecraftConfig* currentConfig;
    SMServer* serverConnection;
}
- (IBAction)donate:(id)sender;
@property (assign) IBOutlet NSButton *donator;
@property (assign) IBOutlet NSImageView *forgeAdTick;
@property (assign) IBOutlet NSProgressIndicator *forgeAdSpin;
@property (assign) IBOutlet WebView *forgeAdWeb;
- (IBAction)closeForgePanel:(id)sender;
@property (assign) IBOutlet NSButton *forgeAdDone;
@property (assign) IBOutlet NSPanel *forgeAdPanel;
@property (assign) IBOutlet NSToolbarItem *folderBtn;
@property (assign) IBOutlet NSToolbar *toolbar;
@property (assign) IBOutlet NSTextFieldCell *argField;
@property (assign) IBOutlet NSPanel *mallocPanel;
- (IBAction)prefsShow:(id)sender;
@property (assign) IBOutlet NSTextField *XmxField;
@property (assign) IBOutlet NSTextField *XmsField;
- (IBAction)SaveMemalloc:(id)sender;
@property (assign) IBOutlet NSToolbarItem *configBrn;
- (IBAction)chgRadioOnStopper:(id)sender;
- (IBAction)chgRadioOnAfter:(id)sender;
- (IBAction)clearLog:(id)sender;
@property (assign) IBOutlet NSTextField *afterTimeField;
- (IBAction)pluginDir:(id)sender;
- (IBAction)XCTemplate:(id)sender;
@property (assign) IBOutlet NSButtonCell *stopAfter;
@property (assign) IBOutlet NSButtonCell *stopRightNow;
- (IBAction)unpopCfg:(id)sender;
- (IBAction)delWorld:(id)sender;
@property (assign) IBOutlet NSPanel *stopper;
- (IBAction)dontStop:(id)sender;
- (IBAction)doStop:(id)sender;
@property (assign) IBOutlet NSButton *reschBtn;
@property (assign) IBOutlet NSPanel *plugMgr;
- (IBAction)closePlugMgr:(id)sender;
@property (assign) IBOutlet NSView *pluginSettingFrame;

- (IBAction)newWorld:(id)sender;
@property (assign) IBOutlet NSButton *worldAddBtn;
@property (assign) IBOutlet NSButton *worldDelBtn;

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSPopUpButton *worldList;
- (IBAction)worldSelectionChanged:(id)sender;
@property (assign) IBOutlet NSPanel *downloaderPanel;
@property (assign) IBOutlet NSProgressIndicator *downloaderProcess;
@property (assign) IBOutlet NSTextField *downloaderTitle;
- (IBAction)downloaderMustStop:(id)sender;
@property (assign) IBOutlet NSPanel *tskPnl;
@property (assign) IBOutlet NSTextField *tskTtl;
@property (assign) IBOutlet NSProgressIndicator *tskPrg;
@property (assign) IBOutlet NSButton *chkForge;
- (IBAction)forgeChanged:(id)sender;
@property (assign) IBOutlet NSButton *plugins;
- (IBAction)runPluginsChg:(id)sender;
- (IBAction)pluginMgr:(id)sender;
- (IBAction)cmdField:(id)sender;
@property (assign) IBOutlet NSTextView *logField;
- (IBAction)srvDir:(id)sender;
@property (assign) IBOutlet NSToolbarItem *startBtn;
- (IBAction)startSrv:(id)sender;
- (IBAction)stopSrv:(id)sender;
@property (assign) IBOutlet NSToolbarItem *stopBtn;
- (IBAction)playerList:(id)sender;
- (IBAction)reDown:(id)sender;
- (IBAction)config:(id)sender;
- (IBAction)modsDir:(id)sender;
- (IBAction)mkWorld:(id)sender;
- (IBAction)unpopWorldName:(id)sender;
@property (assign) IBOutlet NSPanel *worldPanel;
@property (assign) IBOutlet NSTextField *worldText;
@property (assign) IBOutlet NSTextField *commandField;
@property (assign) IBOutlet NSToolbarItem *reinstBtn;

@end
