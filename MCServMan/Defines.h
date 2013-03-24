//
//  Defines.h
//  MCServMan
//
//  Created by Vladislav Korotnev on 3/5/13.
//  Copyright (c) 2013 Vladislav Korotnev. All rights reserved.
//

#ifndef MCServMan_Defines_h
#define MCServMan_Defines_h
#define PREFS [NSUserDefaults standardUserDefaults]
#define MCSERVER_URL @"https://s3.amazonaws.com/MinecraftDownload/launcher/minecraft_server.jar"
#define MCFORGE_URL @"http://files.minecraftforge.net/minecraftforge/minecraftforge-universal-latest.zip"
#define MCFORGE_AD_URL @"http://adf.ly/673885/http://minecraftforge.net/"
#define XCT_URL @"http://vladkorotnev.github.com/soft/mcsm/xcode-mcsm.zip"
#define OUR_FOLDER [@"~/Library/Application Support/MinecraftServer" stringByExpandingTildeInPath]
#define DONATE_URL @"https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=PRFB5XABQMJ94"
#define FM [NSFileManager defaultManager]
#define SERVER_JAR [OUR_FOLDER stringByAppendingPathComponent:@"minecraft_server.jar"] 
#define FORGE_ZIP [OUR_FOLDER stringByAppendingPathComponent:@"forge.zip"] 
#define CURWORLD [OUR_FOLDER stringByAppendingPathComponent:@"world"]

#define STARTSERVTAG 1
#define STOPSERVTAG 2
#define CONFSERVTAG 3
#define REDOWNTAG 4
#define SERVFOLDERTAG 5
#endif

static bool isChecked(NSButton* chk){ return (chk.state ==1 ) ? YES : NO;}

// some things for easier coding