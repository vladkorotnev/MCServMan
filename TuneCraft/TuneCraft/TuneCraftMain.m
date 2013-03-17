//
//  TuneCraftMain.m
//  TuneCraft
//
//  Created by Vladislav Korotnev on 3/5/13.
//  Copyright (c) 2013 Vladislav Korotnev. All rights reserved.
//
#import "TuneCraftSettingViewController.h"
#import "TuneCraftMain.h"

// Easier work with strings
@interface NSString (Substr)

- (BOOL)contains:(NSString *)string;

@end

@implementation NSString (Substr)

- (BOOL)contains:(NSString *)string {
    NSRange rng = [self rangeOfString:string options:0];
    return rng.location != NSNotFound;
}


@end
@implementation TuneCraftMain
static SMAppDelegate<SMAppDelegatePluginsAllowedProtocol>* app; //the server gui app
static SMServer<SMServerPluginsAllowedMethodsProtocol>* serv; // the server connection
static NSMutableDictionary *prefDict; //prefs
static NSString * username; //user
static TuneCraftSettingViewController*set=nil; //setting controller
static NSMutableArray*res; //result of search
static bool postNowplaying=false; //auto nowplaying
static bool isReady=false;

- (void)readSettings {
    if (!prefDict) { // load setting into dict
        if ([[NSFileManager defaultManager]fileExistsAtPath:[@"~/Library/Preferences/com.vladkorotnev.Tunecraft.plist" stringByExpandingTildeInPath]]) {
            prefDict = [NSMutableDictionary dictionaryWithContentsOfFile:[@"~/Library/Preferences/com.vladkorotnev.Tunecraft.plist" stringByExpandingTildeInPath]];
        } else
            prefDict = [NSMutableDictionary new];
    
    }
    // load into vars
    postNowplaying = [[prefDict objectForKey:@"auto"]integerValue];
    username = [prefDict objectForKey:@"user"];
    [username retain];
    [prefDict retain];
}

-(void) sendPM:(NSString*)pm{
    [serv sendServerMessage:[NSString stringWithFormat:@"msg %@ %@",username,pm]]; //function to PM admin
}
-(void) sendChat:(NSString*)pm{
    [serv sendServerMessage:[NSString stringWithFormat:@"say %@",pm]]; // function to send to chat
}
-(void) sendMe:(NSString*)pm{
    [serv sendServerMessage:[NSString stringWithFormat:@"me %@",pm]]; // send /me to chat
}
- (void) onSettingShow{
    [set loadSetting]; // tell settings UI to load setting from file
}
- (NSString*) pluginName { // pluginName from MCServManPlugin proto
    return @"TuneCraft - iTunes control for Minecraft server";
}

- (void) onLoad:(SMAppDelegate<SMAppDelegatePluginsAllowedProtocol>*)delegate{
    app = delegate;
    res=[NSMutableArray new];
    [self readSettings];
}

- (void) onServerStart:(SMServer<SMServerPluginsAllowedMethodsProtocol>*)server{
    serv = server;
    [self readSettings];
    
    if (postNowplaying) {
        NSLog(@"Subscribed to iTunes");
        [[NSDistributedNotificationCenter defaultCenter]addObserver:self selector:@selector(_postNowPlaying) name:@"com.apple.iTunes.playerInfo" object:nil]; //auto nowplaying
    }
}

- (void) onServerStop:(SMServer<SMServerPluginsAllowedMethodsProtocol>*)server{
    isReady=false;
     if (postNowplaying) 
    [[NSDistributedNotificationCenter defaultCenter]removeObserver:self];
}
- (void) onServerDoneLoading:(SMServer<SMServerPluginsAllowedMethodsProtocol>*)server {
    isReady=true;
    [app _log:[NSString stringWithFormat:@"== Tunecraft is ready to rock for %@\n",username]];
}

-(void)_postNowPlaying {
    iTunesApplication*app = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
    if(![app isRunning]){
       [serv sendServerMessage:[NSString stringWithFormat:@"msg %@ iTunes is not running",username]];
        return;
    }
    if([app playerState] == iTunesEPlSStopped){
        [serv sendServerMessage:[NSString stringWithFormat:@"msg %@ iTunes is stopped",username]];
        return;
    }
    if ([app playerState] == iTunesEPlSPaused) {
        return;
    }
    [serv sendServerMessage:[NSString stringWithFormat:@"say Now playing: %@ by %@",[app currentTrack].name,[app currentTrack].artist]];
}


- (void) onServerMessage: (NSString*)messg{
    if (![messg contains:@"[Minecraft-Server] "]) {
        return; //not chat, no interest for us
    }
    if (!isReady) {
        return; //dont spam the console because of the server debug msgs
    }
    iTunesApplication*app = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
    if(![app isRunning]){ //No iTunes running here
        return;
    }
    [self readSettings];
    NSString*msg = [[messg componentsSeparatedByString:@"[Minecraft-Server] "]objectAtIndex:1]; //strip time and shit
    if ([msg contains:@"itunes"]&& [msg contains:[NSString stringWithFormat:@"<%@>",username]] ) {
        //user help
        [serv sendServerMessage:@"say Usage:" ];
        [serv sendServerMessage:@"say - itunes for help"];
         [serv sendServerMessage:@"say - whatnow for nowplaying"];
        [serv sendServerMessage:@"say - ilists for listing of playlists"];
         [serv sendServerMessage:@"say - ilist:<playlist> to play playlists"];
        [serv sendServerMessage:@"say - isong:<songname> to play a song"];
         [serv sendServerMessage:@"say - ifind:<query> to find a song"];
        [serv sendServerMessage:@"say - ifound:<number> to play a song by search result"];
       
    }
    if ([msg contains:@"whatnow"] && [msg contains:[NSString stringWithFormat:@"<%@>",username]]) { 
        [self _postNowPlaying];
        // nowplaying on-demand
    }
    if ([msg contains:@"ilists"] && [msg contains:[NSString stringWithFormat:@"<%@>",username]]) {
        [self sendPM:@"Playlists:"];
        iTunesApplication*app = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
        NSArray*findings = [[[app sources]objectAtIndex:0]userPlaylists];
        // list all user playlists
        for (iTunesUserPlaylist*pl in findings) {
            [self sendPM:[NSString stringWithFormat:@"> %@",[pl name]]];
        }
        
    }
    if ([msg contains:@"ilist:"] && [msg contains:[NSString stringWithFormat:@"<%@>",username]]) {
        NSString*playlist = [[msg componentsSeparatedByString:@":"]objectAtIndex:1];
        [self sendPM:[NSString stringWithFormat:@"Trying to play playlist %@",playlist]];
        NSString*scr = [NSString stringWithFormat:@"tell application \"iTunes\" to play user playlist \"%@\"",[playlist stringByReplacingOccurrencesOfString:@"\n" withString:@""]];
        // play user playlist
        [[[NSAppleScript alloc]initWithSource:scr]executeAndReturnError:nil];
        
    }
    if ([msg contains:@"isong:"] && [msg contains:[NSString stringWithFormat:@"<%@>",username]]) {
        NSString*song = [[msg componentsSeparatedByString:@":"]objectAtIndex:1];
        [self sendPM:[NSString stringWithFormat:@"Trying to play song %@",song]];
        NSString*scr = [NSString stringWithFormat:@"tell application \"iTunes\" to play (every track of library playlist 1 whose name is \"%@\")",[song stringByReplacingOccurrencesOfString:@"\n" withString:@""]];
        // play song by name
        [[[NSAppleScript alloc]initWithSource:scr]executeAndReturnError:nil];
        
    }
    if ([msg contains:@"ifind:"]&& [msg contains:[NSString stringWithFormat:@"<%@>",username]]) {
        NSString*params = [[msg componentsSeparatedByString:@":"]objectAtIndex:1];
        NSString*cmdargs = [params stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        [self sendPM:[NSString stringWithFormat:@"Trying to find %@",cmdargs]];
         iTunesApplication*app = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
        NSArray*findings = [[[[[app sources]objectAtIndex:0]playlists]objectAtIndex:0]searchFor:cmdargs only:iTunesESrAAll];
        [res removeAllObjects];
        int i = 0;
        // list numbered search results
        for (iTunesTrack*t in findings) {
            [self sendPM:[NSString stringWithFormat:@"[%i] %@ by %@",i,t.name,t.artist]];
            [res addObject:t];
            i++;
        }
        [res retain];
    }
    if ([msg contains:@"ifound:"]&& [msg contains:[NSString stringWithFormat:@"<%@>",username]]) {
        username = [NSString stringWithContentsOfFile:[@"~/Library/Preferences/TuneCraftUser" stringByExpandingTildeInPath] encoding:NSUTF8StringEncoding error:nil];
        [username retain];
        NSString*params = [[msg componentsSeparatedByString:@":"]objectAtIndex:1];
        NSString*cmdargs = [params stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        [self sendPM:[NSString stringWithFormat:@"Trying to find %@",cmdargs]];
    iTunesApplication*app = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
        iTunesTrack*trk = [res objectAtIndex:[cmdargs integerValue]];
        if (trk != nil) {
            [trk playOnce:false];
           // play the search result by number
        } else {
            [self sendPM:@"Are you sure this track was found?"];
        }
        
    }
        

}
- (NSView*)settingsView {
    if (set == nil) { //load setting view if not yer
        set = [[TuneCraftSettingViewController alloc]initWithNibName:@"TuneCraftSettingViewController" bundle:[NSBundle bundleForClass:self.class]];
    }
    return set.view; //give it to the app
}
@end
