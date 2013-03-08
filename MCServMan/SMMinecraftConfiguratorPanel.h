//
//  SMMinecraftConfiguratorPanel.h
//  MCServMan
//
//  Created by Vladislav Korotnev on 3/6/13.
//  Copyright (c) 2013 Vladislav Korotnev. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SMMinecraftConfig.h"
#import "SMAppDelegate.h"
#define CURRENT_LIST_TAG 1111
#define ADD_LIST_TAG 2222
@interface SMMinecraftConfiguratorPanel  : NSViewController<NSTableViewDataSource,NSTableViewDelegate> {
    SMMinecraftConfig* curConfigFile;
}
@property (assign) IBOutlet NSTextField *strofKeyname;
@property (assign) IBOutlet NSPanel *paneItself;
@property (assign) IBOutlet NSPopUpButton *strofList;
@property (assign) IBOutlet NSTableView *currentList;
@property (assign) IBOutlet NSButton *addKey;
- (IBAction)doAdd:(id)sender;
- (IBAction)strofDone:(id)sender;
- (IBAction)strofCancel:(id)sender;
- (IBAction)doDel:(id)sender;
- (IBAction)doDone:(id)sender;
@property (assign) IBOutlet NSPanel *boolEditorPanel;
@property (assign) IBOutlet NSTextField *boolKeyname;
@property (assign) IBOutlet NSPanel *strofEditorPanel;
@property (assign) IBOutlet NSButton *boolValue;
- (IBAction)boolPerformSave:(id)sender;
- (IBAction)boolCancel:(id)sender;
@property (assign) IBOutlet NSPanel *editPanel;
@property (assign) IBOutlet NSTextField *editValue;
@property (assign) IBOutlet NSTextField *editKeyname;
- (IBAction)editSave:(id)sender;
- (IBAction)editCancel:(id)sender;
@property (assign) IBOutlet NSPanel *addPanel;
- (IBAction)performAdd:(id)sender;
@property (assign) IBOutlet NSTextField *addDescrippy;
- (IBAction)performCancel:(id)sender;
@property (assign) IBOutlet NSTableView *editorList;
-(NSPanel*) primary;
- (SMMinecraftConfiguratorPanel*)initWithConfig:(SMMinecraftConfig*)file;
@end
