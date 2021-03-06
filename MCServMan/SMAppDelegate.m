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
static bool isDisplayingForge=false;
static int remainMinutes;
static bool didLaunchServerForWorldCreation;
static bool mustStartAfterForgeDL=false;
#pragma mark -Server delegate
- (void) MinecraftServerDidStart:(SMServer*)server{
    //server start, better disable most buttons
    [self.chkForge setEnabled:false];
    [self.commandField setEnabled:true];
    [self.worldList setEnabled:false];
    [self.worldAddBtn setEnabled:false];
    [self.worldDelBtn setEnabled:false];
    //tell the user and all the plugins
    //[self _log:NSLocalizedString(@"=== Starting server\n",@"=== Starting server\n")];
    [self notify:NSLocalizedString(@"Starting up..",@"Starting up..")];
    isTimerTicking=false;
    [self.toolbar validateVisibleItems];
    if (self.plugins.state == 1) {
        for (NSObject<MCServManPlugin>*plug in loadedPlugins) {
            if ([plug respondsToSelector:@selector(onServerStart:)]) {
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
        NSBeep();
        [self notify:NSLocalizedString(@"Started with success",@"Started with success")];
        if (self.plugins.state == 1) {
            for (NSObject<MCServManPlugin>*plug in loadedPlugins) { //tell plugins about the Done
                if ([plug respondsToSelector:@selector(onServerDoneLoading:)]) {
                    [plug onServerDoneLoading:serverConnection];
                }
            }
        }
        return;
    }

    if ([line contains:@"logged in with entity id"]) {
        NSString*userl = isChecked(self.chkForge) ? [line componentsSeparatedByString:@"]"][2] : [line componentsSeparatedByString:@"]"][1];
        NSString*name =[ [userl componentsSeparatedByString:@"["][0] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
        [self notify:[NSString stringWithFormat:NSLocalizedString(@"%@ has logged in",@"%@ has logged in"),name]];
        if (self.plugins.state == 1) {
            for (NSObject<MCServManPlugin>*plug in loadedPlugins) { //tell plugins about the new line
                if ([plug respondsToSelector:@selector(onUserJoined:)]) {
                    [plug onUserJoined:name];
                }
            }
        }
    return;
    }

if ([line contains:@"<"] && [line contains:@">"]) {
 
    NSString*name =[ [line componentsSeparatedByString:@"<"][1] componentsSeparatedByString:@">"][0];
    NSString*msg = [line componentsSeparatedByString:@">"][1];
    msg = [msg stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" \n"]];
    [self notify:[NSString stringWithFormat:@"%@: %@",name,msg]];
    if (self.plugins.state == 1) {
        for (NSObject<MCServManPlugin>*plug in loadedPlugins) { //tell plugins about the new line
            if ([plug respondsToSelector:@selector(onChat:sentBy:)]) {
                [plug onChat:msg sentBy:name];
            }
        }
    }
    return;
}
    
    if ([line contains:@"lost connection"] && ![line contains:@"/"]) {
        NSString*userl = isChecked(self.chkForge) ? [line componentsSeparatedByString:@"]"][2] : [line componentsSeparatedByString:@"]"][1];
        NSString*name =[ [userl componentsSeparatedByString:@" lost connection"][0] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
        [self notify:[NSString stringWithFormat:NSLocalizedString(@"%@ has logged off",@"%@ has logged off"),name]];
        if (self.plugins.state == 1) {
            for (NSObject<MCServManPlugin>*plug in loadedPlugins) { //tell plugins about the new line
                if ([plug respondsToSelector:@selector(onUserLeft:)]) {
                    [plug onUserLeft:name];
                }
            }
        }
        return;
    }
    if ([line contains:@"crash report has been saved to"]) {
        NSAlert* msgBox = [[[NSAlert alloc] init] autorelease];
        [msgBox setMessageText: NSLocalizedString(@"It seems the server has crashed!",@"It seems the server has crashed!")];
        [msgBox setInformativeText:NSLocalizedString(@"Would you like to kill it?",@"Would you like to kill it?")];
        [msgBox addButtonWithTitle: NSLocalizedString(@"Yes",@"Yes")];
        [msgBox addButtonWithTitle:NSLocalizedString(@"No",@"No")];
        NSInteger rCode = [msgBox runModal];
        if (rCode == NSAlertFirstButtonReturn) {
            [serverConnection killServer];
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
    
    [self.toolbar validateVisibleItems];
}
- (void) MinecraftServerDidStop:(SMServer*)server{
    //server stopped
    if (didLaunchServerForWorldCreation) {
        [self _panelUnpop:self.tskPnl];
        didLaunchServerForWorldCreation = false; //finish world creation if it was started
    }
    [self.toolbar validateVisibleItems];
    [self _freshWorlds]; //repopulate the world list
    [self.chkForge setEnabled:true];
    [self.commandField setEnabled:false];
    [self.worldList setEnabled:true];
    [self.worldAddBtn setEnabled:true];
    [self.worldDelBtn setEnabled:true];
    [currentConfig reloadConfigFromFile]; //reload config file
    //[self _log:@"=== Stopped server\n"]; // tell the user
   if(!mustTerminate) [self notify:NSLocalizedString(@"Stopped",@"Stopped")];
    if (self.plugins.state == 1) { //and the plugins
        for (NSObject<MCServManPlugin>*plug in loadedPlugins) {
            if ([plug respondsToSelector:@selector(onServerStop:)]) {
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
    NSString *s = nil;
    s = [[[loadedPlugins objectAtIndex:rowIndex]class]pluginName];
    if (s == nil || [s isEqualToString:@""]) {
        return NSLocalizedString(@"< flawed plugin >",@"< flawed plugin >");
    }
    
    return s;
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
                [self notify:[NSString stringWithFormat:NSLocalizedString(@"Shutdown in %i min",@"Shutdown in %i min"),remainMinutes]];
            }
        } else {[serverConnection sendServerMessage:[NSString stringWithFormat:@"say [AUTO] Shutdown in %i min!",remainMinutes]]; //send each minute
            [self notify:[NSString stringWithFormat:NSLocalizedString(@"Shutdown in %i min",@"Shutdown in %i min"),remainMinutes]];
        }
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

- (void) plugin:(NSString*)plugin log:(NSString*)mess {
 
    [self _log:[NSString stringWithFormat:@"== %@ == %@ == \n",plugin,mess]];
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
    if (!isDisplayingForge) {
        [[NSApplication sharedApplication] stopModal];
    }
    [panel orderOut:self];
    [ NSApp endSheet:panel returnCode:0 ] ;
}
- (void)dealloc
{
    [super dealloc];
}
- (void)handleURLEvent:(NSAppleEventDescriptor*)event withReplyEvent:(NSAppleEventDescriptor*)replyEvent
{
    NSString* url = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
    if ([url.lastPathComponent isEqualToString:@"donated"]) {
        NSAlert* msgBox = [[[NSAlert alloc] init] autorelease];
        [msgBox setMessageText: NSLocalizedString(@"Thank you!",@"Thank you!")];
        [msgBox setInformativeText:NSLocalizedString(@"Thanks for the donation! Glad you liked MCSM  :)",@"Thanks for the donation! Glad you liked MCSM  :)")];
        [msgBox addButtonWithTitle: @"OK"];
        [msgBox runModal];
        [[NSUserDefaults standardUserDefaults]setBool:true forKey:@"donated"];
        [self.donator setHidden:true];
    }
    if ([url.lastPathComponent isEqualToString:@"cancelled"]) {
        NSAlert* msgBox = [[[NSAlert alloc] init] autorelease];
        [msgBox setMessageText: NSLocalizedString(@"Oh",@"Oh")];
        [msgBox setInformativeText:NSLocalizedString(@"Well.. maybe later",@"Well.. maybe later")];
        [msgBox addButtonWithTitle: @"OK"];
        [msgBox runModal];
    }
}
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    SUUpdater*u= [SUUpdater sharedUpdater];
    [self.toolbar setAllowsUserCustomization:false];
    [u setFeedURL:[NSURL URLWithString:@"http://vladkorotnev.github.com/soft/mcsm/sparkle.xml"]];
   [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(handleURLEvent:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
    // Load plugins
    NSBundle *appBundle;
    NSString *plugInsPath;
    if ([[NSUserDefaults standardUserDefaults]boolForKey:@"donated"]) {
         [self.donator setHidden:true];
    }
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
        [self.downloaderTitle setStringValue:NSLocalizedString(@"Downloading latest Minecraft server...",@"Downloading latest Minecraft server...")];
        [currentDownload startAsynchronous];
    }
    
    if ([PREFS objectForKey:@"xms"] == nil) { //defaults
        [PREFS setObject:@"1G" forKey:@"xms"];
    }
    if ([PREFS objectForKey:@"xmx"] == nil) { //defaults
        [PREFS setObject:@"1G" forKey:@"xmx"];
    }
    [self.folderBtn setImage:[NSImage imageNamed:NSImageNameFolder]];
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
        [self _showForgeAd];
    }
    
    if ([request.url.absoluteString isEqualToString:MCFORGE_URL] && mustStartAfterForgeDL) {
       // FFS NO [self startSrv:self];
        mustStartAfterForgeDL=false;
    }
}
- (void)requestFailed:(ASIHTTPRequest *)request {
    [self _panelUnpop:self.downloaderPanel];
    // error :p
    NSAlert* msgBox = [[[NSAlert alloc] init] autorelease];
    [msgBox setMessageText:NSLocalizedString(@"Failed to download!",@"Failed to download!")];
    [msgBox setInformativeText: [request.error localizedDescription]];
    [msgBox addButtonWithTitle: NSLocalizedString(@"Oh no",@"Oh no")];
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
        [self _showForgeAd];
    }
}
- (void) _showForgeAd {
    isDisplayingForge=true;
  
     [self.forgeAdWeb setFrameLoadDelegate:self];
    [[self.forgeAdWeb mainFrame]loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:MCFORGE_AD_URL]]];
          [[NSApplication sharedApplication]runModalForWindow:self.forgeAdPanel];
   
}
- (void)webView:(WebView *)sender didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *)frame {
    NSLog(@"%@",error.localizedDescription);
}
- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame {
   if(frame==self.forgeAdWeb.mainFrame) [self.forgeAdSpin startAnimation:self];
    if (frame == self.forgeAdWeb.mainFrame && (![frame.provisionalDataSource.request.URL.absoluteString contains:@"adf.ly"])) {
        isDisplayingForge=false;
        [self.forgeAdDone setEnabled:true];
        [self.forgeAdSpin setHidden:true];
        [self.forgeAdTick setHidden:false];
    }
}
- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame {
    NSLog(@"didFail:%@",error.localizedDescription);
    if (frame == self.forgeAdWeb.mainFrame) {
        NSAlert* msgBox = [[[NSAlert alloc] init] autorelease];
        [msgBox setMessageText: NSLocalizedString(@"Error loading ad",@"Error loading ad")];
        [msgBox setInformativeText:error.localizedDescription];
        [msgBox addButtonWithTitle: @"OK"];
        [msgBox runModal];
    }
}
- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
    if(frame==self.forgeAdWeb.mainFrame) [self.forgeAdSpin stopAnimation:self];
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
    if (![FM fileExistsAtPath:FORGE_ZIP]&&isChecked(self.chkForge)) {
        
        [self _showForgeAd];
       // mustStartAfterForgeDL=true;
    }
    [serverConnection startServer];
}

- (IBAction)stopSrv:(id)sender { //show stop window
    if (isTimerTicking) { //ui goodies
        self.reschBtn.title = NSLocalizedString(@"Reschedule",@"Reschedule");
      self.afterTimeField.stringValue = [NSString stringWithFormat:@"%i",remainMinutes];
    }else {
        self.reschBtn.title = NSLocalizedString(@"Done",@"Done");
    }
    [self _panelPop:self.stopper];
}

- (IBAction)reDown:(id)sender { //redownload
    if (![FM fileExistsAtPath:OUR_FOLDER]) {
        NSError*error=nil;
        [FM createDirectoryAtPath:OUR_FOLDER withIntermediateDirectories:YES attributes:nil error:&error];
        if(error!=nil){
            NSAlert* msgBox = [[[NSAlert alloc] init] autorelease];
            [msgBox setMessageText: [error localizedDescription]];
            [msgBox addButtonWithTitle: NSLocalizedString(@"Oh no",@"Oh no")];
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
            [msgBox addButtonWithTitle: NSLocalizedString(@"Oh no",@"Oh no")];
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
            [msgBox addButtonWithTitle: NSLocalizedString(@"Oh no",@"Oh no")];
            [msgBox runModal];
            return;
        }}
    // and redownload them
    currentDownload = [[ASIHTTPRequest alloc]initWithURL:[NSURL URLWithString:MCSERVER_URL]];
    [currentDownload setDelegate:self];
    [currentDownload setDownloadDestinationPath:[OUR_FOLDER stringByAppendingPathComponent:@"minecraft_server.jar"] ];
    [self.downloaderTitle setStringValue:NSLocalizedString(@"Downloading latest Minecraft server...",@"Downloading latest Minecraft server...")];
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
        [msgBox setMessageText: NSLocalizedString(@"This world already exists.",@"This world already exists.")];
        [msgBox setInformativeText:NSLocalizedString(@"Please select a different name.",@"Please select a different name.")];
        [msgBox addButtonWithTitle: @"OK"];
        [msgBox runModal];
        return;
    }
    
    [self _panelUnpop:self.worldPanel];
    [self.tskPrg setIndeterminate:true];
    [self.tskPrg startAnimation:self];
    [self.tskTtl setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Creating world %@...",@"Creating world %@..."),self.worldText.stringValue]];
    
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
    if (serverConnection.isRunning) {
        mustTerminate=true;
        [serverConnection stopServer];
        return NSTerminateLater;
    }
    return NSTerminateNow;
}
-(void) notify:(NSString*)wat {
    if (NSClassFromString(@"NSUserNotification") == nil || NSClassFromString(@"NSUserNotificationCenter") == nil ) {
        return;
    }
    //Initalize new notification
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    //Set the title of the notification
    [notification setTitle:@"Minecraft Server"];
    //Set the text of the notification
    [notification setInformativeText:wat];
    //Set the time and date on which the nofication will be deliverd (for example 20 secons later than the current date and time)
    [notification setDeliveryDate:[NSDate dateWithTimeInterval:0.1 sinceDate:[NSDate date]]];
    //Set the sound, this can be either nil for no sound, NSUserNotificationDefaultSoundName for the default sound (tri-tone) and a string of a .caf file that is in the bundle (filname and extension)
    [notification setSoundName:nil];
    
    //Get the default notification center
    NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
    //Scheldule our NSUserNotification
    [center scheduleNotification:notification];
}
- (IBAction)delWorld:(id)sender {
    // kill world
    NSAlert* msgBox = [[[NSAlert alloc] init] autorelease];
    [msgBox setMessageText: NSLocalizedString(@"Really delete this world?",@"Really delete this world?")];
    [msgBox addButtonWithTitle: NSLocalizedString(@"Yes",@"Yes")];
    [msgBox addButtonWithTitle:NSLocalizedString(@"No",@"No")];
    if ([msgBox runModal] == NSAlertFirstButtonReturn) {
        NSError *error=nil;
        
        
        [FM removeItemAtPath:[OUR_FOLDER stringByAppendingPathComponent:self.worldList.selectedItem.title] error:&error];
        if(error!=nil){
            [self _panelUnpop:self.tskPnl];
            NSAlert* msgBox = [[[NSAlert alloc] init] autorelease];
            [msgBox setMessageText: [error localizedDescription]];
            [msgBox addButtonWithTitle: NSLocalizedString(@"Oh no",@"Oh no")];
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
            [msgBox addButtonWithTitle: NSLocalizedString(@"Oh no",@"Oh no")];
            [msgBox runModal];
            return;
        }
    }
    system([[NSString stringWithFormat:@"open '%@'",plugInsPath]UTF8String]);
}

- (IBAction)XCTemplate:(id)sender {
    [[NSWorkspace sharedWorkspace]openURL:[NSURL URLWithString:XCT_URL]  ];
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
-(BOOL)validateToolbarItem:(NSToolbarItem *)toolbarItem {
    switch (toolbarItem.tag) {
        case STARTSERVTAG:
            return ((!serverConnection.isRunning) && [FM fileExistsAtPath:SERVER_JAR]);
            break;
            
        case STOPSERVTAG:
            return serverConnection.isRunning;
            break;
            
        case KILLTAG:
            return serverConnection.isRunning;
            break;
        
        case REDOWNTAG:
            return !serverConnection.isRunning;
            break;
            
        case CONFSERVTAG:
            return !serverConnection.isRunning;
            break;
            
        case SERVFOLDERTAG:
            return YES;
            break;
            
        default:
             return NO;
            break;
    }
    
    
   
}
- (IBAction)closeForgePanel:(id)sender {
    isDisplayingForge=false;
    [[NSApplication sharedApplication]stopModal];
    [self.forgeAdPanel orderOut:self];
    currentDownload = [[ASIHTTPRequest alloc]initWithURL:[NSURL URLWithString:MCFORGE_URL]];
    [currentDownload setDelegate:self];
    [currentDownload setDownloadDestinationPath:FORGE_ZIP ];
    
    [self.downloaderTitle setStringValue:NSLocalizedString(@"Downloading latest version of Forge...",@"Downloading latest version of Forge...")];
    [currentDownload startAsynchronous];
}
- (IBAction)performKill:(id)sender {
    NSAlert* msgBox = [[[NSAlert alloc] init] autorelease];
    [msgBox setMessageText: @"Are you sure to force kill server?"];
    [msgBox setInformativeText:@"You may lose world data."];
    [msgBox addButtonWithTitle: NSLocalizedString(@"Yes",@"Yes")];
    [msgBox addButtonWithTitle:NSLocalizedString(@"No",@"No")];
    NSInteger rCode = [msgBox runModal];
    if (rCode == NSAlertFirstButtonReturn) {
        [serverConnection killServer];
    }
}

- (IBAction)donate:(id)sender {
    [[NSWorkspace sharedWorkspace]openURL:[NSURL URLWithString:DONATE_URL]  ];
}
@end
