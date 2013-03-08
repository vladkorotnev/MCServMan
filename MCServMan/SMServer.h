//
//  SMServer.h
//  MCServMan
//
//  Created by Vladislav Korotnev on 3/5/13.
//  Copyright (c) 2013 Vladislav Korotnev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MFTask.h"
#import "Defines.h"
#import "MCServManPlugin.h"
@protocol MinecraftServerDelegate;

// Primary Server management class

@interface SMServer : NSObject <MFTaskDelegateProtocol,SMServerPluginsAllowedMethodsProtocol>{
    id<MinecraftServerDelegate> delegate;
    MFTask* serverTask;
    NSString* jarFile;
    bool isRunning;
}
@property (nonatomic,retain) id<MinecraftServerDelegate>delegate;
@property (nonatomic,retain)     NSString* jarFile;
@property (nonatomic) bool isRunning;
- (void) startServer; 
- (void) stopServer;
- (void) sendServerMessage:(NSString*)mess;
- (SMServer*)initWithJarFile:(NSString*)jar delegate:(id<MinecraftServerDelegate>)del;

@end

@protocol MinecraftServerDelegate <NSObject>

@optional
- (void) MinecraftServerDidStart:(SMServer*)server;
- (void) MinecraftServer:(SMServer*)server didGetOutput:(NSString*)line;
- (void) MinecraftServerDidStop:(SMServer*)server;

@end