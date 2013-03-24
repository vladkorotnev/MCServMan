
#import "DoNotGive.h"
#import "DGPreferencesViewController.h"

@interface NSString (Substr)

- (BOOL)contains:(NSString *)string;

@end

@implementation NSString (Substr)

- (BOOL)contains:(NSString *)string {
    NSRange rng = [self rangeOfString:string options:0];
    return rng.location != NSNotFound;
}


@end

@interface DoNotGive ()

@end

@implementation DoNotGive
static bool shouldKick=false;
static bool shouldClear=false;
static bool isReady=false;
static SMAppDelegate<SMAppDelegatePluginsAllowedProtocol>*del=nil;
static SMServer<SMServerPluginsAllowedMethodsProtocol>*srv = nil;
static DGPreferencesViewController*prefs=nil;
+ (NSString*)pluginName {
    /* place plugin name */
    return @"DoNotGive";
}
/* override to support settings view */
 - (NSView*)settingsView {
     if (prefs == nil) {
         prefs = [[DGPreferencesViewController alloc]initWithNibName:@"DGPreferencesViewController" bundle:[NSBundle bundleForClass:self.class]];
     }
    return prefs.view;
} 

- (void) onLoad:(SMAppDelegate<SMAppDelegatePluginsAllowedProtocol>*)delegate {
	/* place onLoad here */
    del=delegate; //store the delegate for further use
}
- (void) onSettingShow{
	/* better prepare your viewcontroller to reflect the actual plugin state here */
	/* called exactly before -settingsView */

    [prefs refresh];
}
- (void) onServerStart:(SMServer<SMServerPluginsAllowedMethodsProtocol>*)server {
	/* the server is now available */
    srv=server; //keep the server connection for further use
    shouldKick = [[NSUserDefaults standardUserDefaults]boolForKey:@"DONOTGIVE_kick"];
    shouldClear = [[NSUserDefaults standardUserDefaults]boolForKey:@"DONOTGIVE_denyGive"];
}
- (void) onServerStop:(SMServer<SMServerPluginsAllowedMethodsProtocol>*)server{
	/* the server is destroyed */
    srv=nil; //no server exists
    isReady=false;
}
- (void) onServerDoneLoading:(SMServer<SMServerPluginsAllowedMethodsProtocol>*)server{
    //on server Done loading
    isReady=true;
}
- (void) onServerMessage: (NSString*)msg{
	/* place code to manually parse server log lines */
    if(!isReady)return;
    if ([msg contains:@"Stopping the server"]) {
        isReady=false;
        return;
    }
    if (![msg contains:@"Given"]&&![msg contains:@"to"]) {
        return;
    }
    NSString*event=nil;
    NSArray*split=nil;
    if ([msg contains:@"[Minecraft-Server]"]) {
        // Parse the Forge line
        split = [msg componentsSeparatedByString:@"]"];
        event = split[2];
    } else {
        // Parse the Vanilla line
       split = [msg componentsSeparatedByString:@"]"];
        event = split[1];
    }
    
    // get the bad player
     NSString*badPlayer = [event componentsSeparatedByString:@" to "][1];
    if (shouldClear) {
        [srv sendServerMessage:[NSString stringWithFormat:@"clear %@",badPlayer]];
        if (shouldKick)
            [srv sendServerMessage:[NSString stringWithFormat:@"kick %@ No giving here please",badPlayer]];
        else
            [srv sendServerMessage:[NSString stringWithFormat:@"say Shame on you, %@",badPlayer]];
    }
   

}

@end

	
