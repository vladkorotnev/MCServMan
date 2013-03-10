//
//  SMAppDelegate.m
//  MCServMan
//
//  Created by Vladislav Korotnev on 3/4/13.
//  Copyright (c) 2013 Vladislav Korotnev. All rights reserved.
//

#import "SMAppDelegate.h"
#import "SMMinecraftConfiguratorPanel.h"
@interface NSString (Substr)

- (BOOL)contains:(NSString *)string;

@end

@implementation NSString (Substr)

- (BOOL)contains:(NSString *)string {
    NSRange rng = [self rangeOfString:string options:0];
    return rng.location != NSNotFound;
}


@end

@implementation SMAppDelegate
static bool mustTerminate;
static bool isTimerTicking;
static int remainMinutes;
static bool didLaunchServerForWorldCreation;
#pragma mark -Server delegate
- (void) MinecraftServerDidStart:(SMServer*)server{
    //server start, better disable most buttons
    [self.chkForge setEnabled:false];
    [self.startBtn setEnabled:false];
    [self.stopBtn setEnabled:true];
    [self.configBrn setEnabled:false];
    [self.commandField setEnabled:true];
    [self.worldList setEnabled:false];
    [self.reinstBtn setEnabled:false];
    [self.worldAddBtn setEnabled:false];
    [self.worldDelBtn setEnabled:false];
    //tell the user and all the plugins
    [self _log:@"=== Starting server\n"];
    isTimerTicking=false;
    if (self.plugins.state == 1) {
        for (NSObject<MCServManPlugin>*plug in loadedPlugins) {
            if ([plug respondsToSelector:@selector(onServerStart:)]) {
                [self _log:[NSString stringWithFormat:@"=== Telling plugin %@ about it\n",[plug pluginName]]];
                [plug onServerStart:serverConnection];
            }
        }}
}
- (void) MinecraftServer:(SMServer*)server didGetOutput:(NSString*)line{
    [self _log:line]; //output from server console into this console
    if ([line contains:@"Done"] && [line contains:@"For help"]) {
        if (didLaunchServerForWorldCreation ) {
            [serverConnection sendServerMessage:@"stop"]; //if the sole purpose was to create the world and it's done, then stop it and proceed
            return;
        }
        NSLog(@"OnDone");
        NSBeep();
        if (self.plugins.state == 1) {
            for (NSObject<MCServManPlugin>*plug in loadedPlugins) { //tell plugins about the Done
                if ([plug respondsToSelector:@selector(onServerDoneLoading:)]) {
                    [plug onServerDoneLoading:serverConnection];
                }
            }
        }
        return;
    }
    if (self.plugins.state == 1) {
        for (NSObject<MCServManPlugin>*plug in loadedPlugins) { //tell plugins about the new line
            if ([plug respondsToSelector:@selector(onServerMessage:)]) {
                [plug onServerMessage:line];
            }
        }
    }
    
}
- (void) MinecraftServerDidStop:(SMServer*)server{
    //server stopped
    if (didLaunchServerForWorldCreation) {
        [self _panelUnpop:self.tskPnl];
        didLaunchServerForWorldCreation = false; //finish world creation if it was started
    }
    [self _freshWorlds]; //repopulate the world list
    [self.configBrn setEnabled:true]; //enable all the UI
    [self.chkForge setEnabled:true];
    [self.startBtn setEnabled:true];
    [self.stopBtn setEnabled:false];
    [self.commandField setEnabled:false];
    [self.worldList setEnabled:true];
    [self.worldAddBtn setEnabled:true];
    [self.worldDelBtn setEnabled:true];
    [self.reinstBtn setEnabled:true];
    [currentConfig reloadConfigFromFile]; //reload config file
    [self _log:@"=== Stopped server\n"]; // tell the user
    if (self.plugins.state == 1) { //and the plugins
        for (NSObject<MCServManPlugin>*plug in loadedPlugins) {
            if ([plug respondsToSelector:@selector(onServerStop:)]) {
                [self _log:[NSString stringWithFormat:@"=== Telling plugin %@ about it\n",[plug pluginName]]];
                [plug onServerStop:serverConnection];
            }
        }}
    if(mustTerminate)[[NSApplication sharedApplication]terminate:self];
}

#pragma mark -Plugin mgr
// just returns the plugin for the right row
- (id)     tableView:(NSTableView *) aTableView
objectValueForTableColumn:(NSTableColumn *) aTableColumn
                 row:(NSInteger ) rowIndex
{
    
    
    return [[loadedPlugins objectAtIndex:rowIndex]pluginName    ];
}

// just returns the number of plugins we have.
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    
    return [loadedPlugins count];
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row {
    
    NSObject<MCServManPlugin>*plug = [loadedPlugins objectAtIndex:row]; //find selected plugin
    if ([plug respondsToSelector:@selector(settingsView)]) { //it has a view
        for (NSView*b in [self.pluginSettingFrame subviews]) {
            [b removeFromSuperview]; // kill all old views
        }
        NSView*v = [plug settingsView]; // put in the new one
        [v setFrame:self.pluginSettingFrame.frame];
        [self.pluginSettingFrame addSubview:v];
        if ([plug respondsToSelector:@selector(onSettingShow)]) {
            [plug onSettingShow]; //and send the event, if implemented
        }
        return YES;
    }
    return NO;
}

#pragma mark -App
- (void)_timerCallback { // shutdown timer
    if(!isTimerTicking)return;
    remainMinutes--;
    if (remainMinutes > 0) {
        if (remainMinutes > 10) {
            if(remainMinutes % 5 == 0){ // each 5min if > 10min
                [serverConnection sendServerMessage:[NSString stringWithFormat:@"say [AUTO] Shutdown in %i min!",remainMinutes]];
            }
        } else [serverConnection sendServerMessage:[NSString stringWithFormat:@"say [AUTO] Shutdown in %i min!",remainMinutes]]; //send each minute
        
        [self performSelector:@selector(_timerCallback) withObject:nil afterDelay:60]; // requeue
    } else {
        [serverConnection stopServer];
        isTimerTicking = false;
        
    }
}
- (BOOL)textView:(NSTextView *)aTextView shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString *)replacementString { return NO; }
- (BOOL)textView:(NSTextView *)textView shouldChangeTextInRanges:(NSArray *)affectedRanges replacementStrings:(NSArray *)replacementStrings { return NO; }

-(void)_freshWorlds{
    NSMenu *yourMenu = [[NSMenu alloc] init];
    NSError*e=nil;
    for (NSString*world in [FM contentsOfDirectoryAtPath:OUR_FOLDER error:&e]) {
        if(![[world lowercaseString]isEqualToString:@".ds_store"]&&[[FM contentsOfDirectoryAtPath:[OUR_FOLDER stringByAppendingPathComponent:world] error:nil]containsObject:@"level.dat"]){
            //worlds are only those who aren't DSStore and have level.dat inside
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:world action:nil keyEquivalent:@""];
            [yourMenu insertItem:menuItem atIndex:0];
        }
    }
    if (e != nil) {
        NSAlert* msgBox = [[[NSAlert alloc] init] autorelease];
        [msgBox setMessageText:e.localizedDescription];
        [msgBox addButtonWithTitle: @"OK"];
        [msgBox runModal];
    }
    [self.worldList setMenu:yourMenu];
    [self.worldList selectItemWithTitle:[currentConfig readSetting:@"level-name"]];
}
- (void)_log:(NSString*)what{ //logging to console method (plugin allowed)
    NSClipView* cv = self.logField.enclosingScrollView.contentView;
    BOOL scroll = (NSMaxY(cv.documentVisibleRect) >= NSMaxY(cv.documentRect));
    [self.logField setString:[self.logField.string stringByAppendingString: what]];
    if (scroll)
        [self.logField scrollRangeToVisible: NSMakeRange(self.logField.string.length, 0)];
}

- (void)_panelPop:(NSPanel*)panel{ //drop-in for easy code
    [[NSApplication sharedApplication] beginSheet:panel
                                   modalForWindow:self.window
                                    modalDelegate:self
                                   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
                                      contextInfo:nil];
}
- (BOOL)tableView:(NSTableView *)aTableView
shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
    return NO; //no edit
}
-(void)_panelUnpop:(NSPanel*)panel{ //drop-in
    [[NSApplication sharedApplication] stopModal];
    [panel orderOut:self];
    [ NSApp endSheet:panel returnCode:0 ] ;
}
- (void)dealloc
{
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    SUUpdater*u= [SUUpdater sharedUpdater];
    
    [u setFeedURL:[NSURL URLWithString:@"http://vladkorotnev.github.com/soft/mcsm/sparkle.xml"]];
   
    // Load plugins
    NSBundle *appBundle;
    NSString *plugInsPath;
    
    appBundle = [NSBundle mainBundle];
    plugInsPath = [appBundle builtInPlugInsPath];
    if (![FM fileExistsAtPath:plugInsPath]) {
        NSError *e=nil;
        [FM createDirectoryAtPath:plugInsPath withIntermediateDirectories:true attributes:nil error:&e];
    }
    loadedPlugins = [[NSMutableArray alloc]init];
    for (NSString*fullPath in [FM contentsOfDirectoryAtPath:plugInsPath error:nil]) { //cycle through all
        NSLog(@"Plugin enum %@",fullPath);
        if (![fullPath isEqualToString:@".DS_Store"]) { //not you DSStore
            NSBundle *bundle;
            Class principalClass;
            NSString*p = [plugInsPath stringByAppendingPathComponent:fullPath];
            bundle = [NSBundle bundleWithPath:p];
            [bundle load]; //load the bundle
            NSLog(@"Load %@",fullPath);
            principalClass = [bundle principalClass]; //get the class
            NSObject<MCServManPlugin>* loadedBundle = [[principalClass alloc]init];
            if ([loadedBundle respondsToSelector:@selector(onLoad:)]) { //tell it it's home
                [loadedBundle onLoad:self];
            }
            [loadedPlugins addObject:[loadedBundle retain]]; //and save it
            
        }
        
    }
    [loadedPlugins retain];
    
    currentConfig = [[SMMinecraftConfig alloc]initFromFile:[OUR_FOLDER stringByAppendingPathComponent:@"server.properties"]]; //load config
    [currentConfig retain];
    self.chkForge.state = [PREFS boolForKey:@"useForge"]; //Forge stuff
    serverConnection = [[SMServer alloc]initWithJarFile:(isChecked(self.chkForge) ? FORGE_ZIP : SERVER_JAR) delegate:self]; //make a server connection
    [serverConnection retain];
    
    if(![FM fileExistsAtPath:[OUR_FOLDER stringByAppendingPathComponent:@"minecraft_server.jar"]]){
        //No minecraft found? download it
        currentDownload = [[ASIHTTPRequest alloc]initWithURL:[NSURL URLWithString:MCSERVER_URL]];
        [currentDownload setDelegate:self];
        [currentDownload setDownloadDestinationPath:[OUR_FOLDER stringByAppendingPathComponent:@"minecraft_server.jar"] ];
        [self.downloaderTitle setStringValue:@"Downloading latest Minecraft server..."];
        [currentDownload startAsynchronous];
    }
    
    if ([PREFS objectForKey:@"xms"] == nil) { //defaults
        [PREFS setObject:@"1G" forKey:@"xms"];
    }
    if ([PREFS objectForKey:@"xmx"] == nil) { //defaults
        [PREFS setObject:@"1G" forKey:@"xmx"];
    }
    
    [self _freshWorlds]; //populate world list
    
}
- (void)requestStarted:(ASIHTTPRequest *)request { //asi stuff
    [request setDownloadProgressDelegate:self.downloaderProcess];
    [self _panelPop:self.downloaderPanel]; //show progress
}
- (void)requestFinished:(ASIHTTPRequest *)request{ //done download
    [self _panelUnpop:self.downloaderPanel];
    [currentDownload release]; //hide panel
    currentDownload = nil;
    if (isChecked(self.chkForge) && ![FM fileExistsAtPath:FORGE_ZIP]) { //no forge but wanted?
        // then download it as well
        currentDownload = [[ASIHTTPRequest alloc]initWithURL:[NSURL URLWithString:MCFORGE_URL]];
        [currentDownload setDelegate:self];
        [currentDownload setDownloadDestinationPath:FORGE_ZIP ];
        [self.downloaderTitle setStringValue:@"Downloading latest version of Forge..."];
        [currentDownload startAsynchronous];
        [[NSWorkspace sharedWorkspace]openURL:[NSURL URLWithString:MCFORGE_AD_URL]  ];
        NSAlert* msgBox = [[[NSAlert alloc] init] autorelease];
        [msgBox setMessageText: @"Please check the ad in the browser, it will support the Forge developers!"]; // we dont wanna steal from them
        [msgBox addButtonWithTitle: @"OK"];
        [msgBox runModal];
    }
}
- (void)requestFailed:(ASIHTTPRequest *)request {
    [self _panelUnpop:self.downloaderPanel];
    // error :p
    NSAlert* msgBox = [[[NSAlert alloc] init] autorelease];
    [msgBox setMessageText:@"Failed to download!"];
    [msgBox setInformativeText: [request.error localizedDescription]];
    [msgBox addButtonWithTitle: @"Oh no"];
    [msgBox runModal];
    [currentDownload release];
    currentDownload = nil;
}

- (IBAction)worldSelectionChanged:(id)sender {
    [currentConfig writeSetting:self.worldList.selectedItem.title forKey:@"level-name"]; //chg world
}
- (IBAction)downloaderMustStop:(id)sender { //cancel download
    if ([[[currentDownload url]absoluteString]isEqualToString:MCFORGE_URL]) {
        [self.chkForge setState:0]; 
    }
    [currentDownload cancel];
}
- (IBAction)forgeChanged:(id)sender { //forge checkbox
    [PREFS setBool:isChecked(sender) forKey:@"useForge"]; //save
    [serverConnection release];
    serverConnection = nil;
    serverConnection = [[SMServer alloc]initWithJarFile:(isChecked(self.chkForge) ? FORGE_ZIP : SERVER_JAR) delegate:self]; //new server conn
    [serverConnection retain];
    if (isChecked(sender) && ![FM fileExistsAtPath:FORGE_ZIP]) {//download if missing
        currentDownload = [[ASIHTTPRequest alloc]initWithURL:[NSURL URLWithString:FORGE_ZIP]];
        [currentDownload setDelegate:self];
        [currentDownload setDownloadDestinationPath:FORGE_ZIP ];
        [self.downloaderTitle setStringValue:@"Downloading Forge..."];
        [currentDownload startAsynchronous];
        [[NSWorkspace sharedWorkspace]openURL:[NSURL URLWithString:MCFORGE_AD_URL]  ];
        NSAlert* msgBox = [[[NSAlert alloc] init] autorelease];
        [msgBox setMessageText: @"Please check the ad in the browser, it will support the Forge developers!"];
        [msgBox addButtonWithTitle: @"OK"];
        [msgBox runModal];
    }
}
- (IBAction)runPluginsChg:(id)sender {
//reserved
}

- (IBAction)pluginMgr:(id)sender {
    [self _panelPop:self.plugMgr]; //plugin manager
}
- (IBAction)cmdField:(id)sender { //command into server
    if (![self.commandField.stringValue isEqualToString:@""]) {
        [serverConnection sendServerMessage:self.commandField.stringValue];
        self.commandField.stringValue = @"";
    }
}
- (IBAction)srvDir:(id)sender { //open server folder
    system([[NSString stringWithFormat:@"open '%@'",OUR_FOLDER]UTF8String]);
}
- (IBAction)startSrv:(id)sender { //start server
    if(self.worldList.selectedItem == nil)return; //not if no world tho
    if ([self.worldList.selectedItem.title isEqualToString:@""]) return;
    [serverConnection startServer];
}

- (IBAction)stopSrv:(id)sender { //show stop window
    if (isTimerTicking) { //ui goodies
        self.reschBtn.title = @"Reschedule";
      self.afterTimeField.stringValue = [NSString stringWithFormat:@"%i",remainMinutes];
    }else {
        self.reschBtn.title = @"Done";
    }
    [self _panelPop:self.stopper];
}

- (IBAction)reDown:(id)sender { //redownload
    if (![FM fileExistsAtPath:OUR_FOLDER isDirectory:true]) {
        NSError*error=nil;
        [FM createDirectoryAtPath:OUR_FOLDER withIntermediateDirectories:YES attributes:nil error:&error];
        if(error!=nil){
            NSAlert* msgBox = [[[NSAlert alloc] init] autorelease];
            [msgBox setMessageText: [error localizedDescription]];
            [msgBox addButtonWithTitle: @"Oh no"];
            [msgBox runModal];
            return;
        }
    }
    // kill all files
    if([FM fileExistsAtPath:[OUR_FOLDER stringByAppendingPathComponent:@"forge.zip"]]){
        NSError *error=nil;
        [FM removeItemAtPath:[OUR_FOLDER stringByAppendingPathComponent:@"forge.zip"] error:&error];
        if(error!=nil){
            NSAlert* msgBox = [[[NSAlert alloc] init] autorelease];
            [msgBox setMessageText: [error localizedDescription]];
            [msgBox addButtonWithTitle: @"Oh no"];
            [msgBox runModal];
            return;
        }
    }
    
    if([FM fileExistsAtPath:[OUR_FOLDER stringByAppendingPathComponent:@"minecraft_server.jar"]]){
        NSError *error=nil;
        [FM removeItemAtPath:[OUR_FOLDER stringByAppendingPathComponent:@"minecraft_server.jar"] error:&error];
        if(error!=nil){
            NSAlert* msgBox = [[[NSAlert alloc] init] autorelease];
            [msgBox setMessageText: [error localizedDescription]];
            [msgBox addButtonWithTitle: @"Oh no"];
            [msgBox runModal];
            return;
        }}
    // and redownload them
    currentDownload = [[ASIHTTPRequest alloc]initWithURL:[NSURL URLWithString:MCSERVER_URL]];
    [currentDownload setDelegate:self];
    [currentDownload setDownloadDestinationPath:[OUR_FOLDER stringByAppendingPathComponent:@"minecraft_server.jar"] ];
    [self.downloaderTitle setStringValue:@"Downloading latest Minecraft server..."];
    [currentDownload startAsynchronous];
}

- (IBAction)config:(id)sender { // config panel
    [currentConfig reloadConfigFromFile];
    SMMinecraftConfiguratorPanel*p = [[SMMinecraftConfiguratorPanel alloc]initWithConfig:currentConfig];
    [self _panelPop:[p primary]];
}

- (IBAction)modsDir:(id)sender { //reserved
    system([[NSString stringWithFormat:@"open '%@'",[OUR_FOLDER stringByAppendingPathComponent:@"mods"]]UTF8String]);
}

- (IBAction)mkWorld:(id)sender { //new world maker
    if([FM fileExistsAtPath:[OUR_FOLDER stringByAppendingPathComponent:self.worldText.stringValue]]){
        NSAlert* msgBox = [[[NSAlert alloc] init] autorelease];
        [msgBox setMessageText: @"This world already exists."];
        [msgBox setInformativeText:@"Please select a different name."];
        [msgBox addButtonWithTitle: @"OK"];
        [msgBox runModal];
        return;
    }
    
    [self _panelUnpop:self.worldPanel];
    [self.tskPrg setIndeterminate:true];
    [self.tskPrg startAnimation:self];
    [self.tskTtl setStringValue:[NSString stringWithFormat:@"Creating world %@...",self.worldText.stringValue]];
    
    [self _panelPop:self.tskPnl];
    
    
    [currentConfig writeSetting:self.worldText.stringValue forKey:@"level-name"];
    didLaunchServerForWorldCreation=true;
    [serverConnection startServer];
    self.worldText.stringValue = @"";
}

- (IBAction)unpopWorldName:(id)sender {//cancel world maker
    [self _panelUnpop:self.worldPanel];
}

- (void) sheetDidEnd:(NSWindow *) sheet returnCode:(int)returnCode contextInfo:(void *) contextInfo {
} //reserved

- (IBAction)newWorld:(id)sender { //show world maker
    [self _panelPop:self.worldPanel];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    // server is running, better cleanup...
    if ([self.stopBtn isEnabled]) {
        mustTerminate=true;
        [serverConnection stopServer];
        return NSTerminateLater;
    }
    return NSTerminateNow;
}
- (IBAction)delWorld:(id)sender {
    // kill world
    NSAlert* msgBox = [[[NSAlert alloc] init] autorelease];
    [msgBox setMessageText: @"Really delete this world?"];
    [msgBox addButtonWithTitle: @"Yes"];
    [msgBox addButtonWithTitle:@"No"];
    if ([msgBox runModal] == NSAlertFirstButtonReturn) {
        NSError *error=nil;
        
        
        [FM removeItemAtPath:[OUR_FOLDER stringByAppendingPathComponent:self.worldList.selectedItem.title] error:&error];
        if(error!=nil){
            [self _panelUnpop:self.tskPnl];
            NSAlert* msgBox = [[[NSAlert alloc] init] autorelease];
            [msgBox setMessageText: [error localizedDescription]];
            [msgBox addButtonWithTitle: @"Oh no"];
            [msgBox runModal];
            return;
        }
        [currentConfig writeSetting:@"" forKey:@"level-name"];
        [self.worldList selectItemWithTitle:@""];
        [self performSelector:@selector(_freshWorlds) withObject:nil afterDelay:0.1];
    }
}
- (IBAction)dontStop:(id)sender { //cancel timer/popup
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_timerCallback) object:nil];
    isTimerTicking=false;
    [self _panelUnpop:self.stopper];
}

- (IBAction)doStop:(id)sender { //stop window ok button
    if (self.stopRightNow.state == 1) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_timerCallback) object:nil];
        [serverConnection stopServer];
    } else {
        isTimerTicking = true;
        remainMinutes = [self.afterTimeField.stringValue intValue];
          [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_timerCallback) object:nil];
        [self performSelector:@selector(_timerCallback) withObject:nil afterDelay:60];
        [serverConnection sendServerMessage:[NSString stringWithFormat:@"say [AUTO] Shutdown in %i min!",remainMinutes]];
    }
    [self _panelUnpop:self.stopper];
}
- (IBAction)chgRadioOnStopper:(id)sender { // ui goodie
    [self.afterTimeField setEnabled:false];
}

- (IBAction)chgRadioOnAfter:(id)sender { // more ui goodies
    [self.afterTimeField setEnabled:true];
}

- (IBAction)clearLog:(id)sender {
    [self.logField setString:@""];
}
- (IBAction)closePlugMgr:(id)sender { //close plugin manager
    [self _panelUnpop:self.plugMgr];
}
- (IBAction)pluginDir:(id)sender { //open plugin folder
    NSBundle *appBundle;
    NSString *plugInsPath;
    
    appBundle = [NSBundle mainBundle];
    plugInsPath = [appBundle builtInPlugInsPath];
    if (![FM fileExistsAtPath:plugInsPath]) {
        NSError *e=nil;
        [FM createDirectoryAtPath:plugInsPath withIntermediateDirectories:true attributes:nil error:&e];
        if(e!=nil){
            NSAlert* msgBox = [[[NSAlert alloc] init] autorelease];
            [msgBox setMessageText: [e localizedDescription]];
            [msgBox addButtonWithTitle: @"Oh no"];
            [msgBox runModal];
            return;
        }
    }
    system([[NSString stringWithFormat:@"open '%@'",plugInsPath]UTF8String]);
}
- (IBAction)SaveMemalloc:(id)sender { //save prefs
    [PREFS setObject:self.XmsField.stringValue forKey:@"xms"];
    [PREFS setObject:self.XmxField.stringValue forKey:@"xmx"];
    [PREFS setObject:self.argField.stringValue forKey:@"args"];
    [self _panelUnpop:self.mallocPanel];
}
- (IBAction)prefsShow:(id)sender { //open prefs window
    NSLog(@"Xms %@, Xmx %@, Arg %@",[PREFS objectForKey:@"xms"],[PREFS objectForKey:@"xmx"],[PREFS objectForKey:@"args"]);
    self.XmsField.stringValue = [PREFS objectForKey:@"xms"];
    self.XmxField.stringValue = [PREFS objectForKey:@"xmx"];
    if ([PREFS objectForKey:@"args"]!= nil && ![[PREFS objectForKey:@"args"]isEqualToString:@""]) {
        self.argField.stringValue = [PREFS objectForKey:@"args"];
    }
    [self _panelPop:self.mallocPanel];
}
@end
