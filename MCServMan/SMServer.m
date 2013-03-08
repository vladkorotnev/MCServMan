//
//  SMServer.m
//  MCServMan
//
//  Created by Vladislav Korotnev on 3/5/13.
//  Copyright (c) 2013 Vladislav Korotnev. All rights reserved.
//

#import "SMServer.h"

@implementation SMServer
@synthesize delegate=_delegate;
@synthesize jarFile, isRunning;
- (SMServer*)initWithJarFile:(NSString*)jar delegate:(id<MinecraftServerDelegate>)del {
    // Creates a new SMServer with the specified JAR path and delegate
    [self init];
    if (self) {
        jarFile = jar;
        [jarFile retain];
        self.delegate = del;
        [self.delegate retain];
        isRunning=false;
    }
    return self ;
}
- (void) startServer { // start the server asynchronously
    serverTask = [[MFTask alloc]init]; // New MFTASK
    [serverTask setDelegate:self];
    [serverTask setLaunchPath:@"/usr/bin/java"];
    [serverTask setCurrentDirectoryPath:[jarFile stringByDeletingLastPathComponent]];
    NSMutableArray* args = [@[[NSString stringWithFormat:@"-Xms%@",[PREFS objectForKey:@"xms"]],[NSString stringWithFormat:@"-Xmx%@",[PREFS objectForKey:@"xmx"]],@"-jar",jarFile,@"nogui"] mutableCopy];
    if ([PREFS objectForKey:@"args"] != nil ||![[PREFS objectForKey:@"args"]isEqualToString:@""]) {
        for (NSString *arg in [[PREFS objectForKey:@"args"]componentsSeparatedByString:@" "]) {
            [args addObject:arg];
        }
    }
    [serverTask setArguments:args];
    [serverTask setStandardInput: [NSPipe pipe]];
    [serverTask launch];
    isRunning=true;
}
- (void) stopServer {
    if(isRunning)[self sendServerMessage:@"stop"];
}
- (void) sendServerMessage:(NSString*)mess { //plugin allowed
    if(isRunning)[[[serverTask standardInput] fileHandleForWriting] writeData: [[mess stringByAppendingString:@"\n"] dataUsingEncoding:NSASCIIStringEncoding ]];
}
#pragma mark -Delegates for Task
// we'll just forward them up to the delegate of ours

- (void) taskDidRecieveData:(NSData*) theData fromTask:(MFTask*)task{
    
    if ([self.delegate respondsToSelector:@selector(MinecraftServer:didGetOutput:)]) {
        [self.delegate MinecraftServer:self didGetOutput:[[NSString alloc]initWithData:theData encoding:NSUTF8StringEncoding]];
    }
}
- (void) taskDidRecieveErrorData:(NSData*) theData fromTask:(MFTask*)task{
    if ([self.delegate respondsToSelector:@selector(MinecraftServer:didGetOutput:)]) {
        [self.delegate MinecraftServer:self didGetOutput:[[NSString alloc]initWithData:theData encoding:NSASCIIStringEncoding]];
    }
}
- (void) taskDidTerminate:(MFTask*) theTask{
    if ([self.delegate respondsToSelector:@selector(MinecraftServerDidStop:)]) {
        [self.delegate MinecraftServerDidStop:self];
    }
    isRunning=false;
}
- (void) taskDidRecieveInvalidate:(MFTask*) theTask{
    
}
- (void) taskDidLaunch:(MFTask*) theTask{
    if ([self.delegate respondsToSelector:@selector(MinecraftServerDidStart:)]) {
        [self.delegate MinecraftServerDidStart:self];
    }
    isRunning=true;
}

@end
