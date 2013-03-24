//
//  SMMinecraftConfiguratorPanel.m
//  MCServMan
//
//  Created by Vladislav Korotnev on 3/6/13.
//  Copyright (c) 2013 Vladislav Korotnev. All rights reserved.
//

#import "SMMinecraftConfiguratorPanel.h"
@interface SMMinecraftConfiguratorPanel ()

@end

@implementation SMMinecraftConfiguratorPanel

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[NSBundle mainBundle]loadNibNamed:@"SMMinecraftConfiguratorPanel" owner:self topLevelObjects:nil];
        // Initialization code here.
    }
    
    return self;
}

-(NSPanel*)primary{
    return self.paneItself;
}

- (SMMinecraftConfiguratorPanel*)initWithConfig:(SMMinecraftConfig*)file {
    self = [self initWithNibName:@"SMMinecraftConfiguratorPanel.nib" bundle:[NSBundle mainBundle]];
    curConfigFile = file;
    [curConfigFile retain];
    // load panel and config
    [self.currentList setDelegate:self];
    [self.currentList setDataSource:self];
    // prepare for presenting
    [self _someRetains]; //donno why but crashes w/o them
    return self ;
}

- (id)     tableView:(NSTableView *) aTableView
objectValueForTableColumn:(NSTableColumn *) aTableColumn
                 row:(NSInteger ) rowIndex
{
    if (aTableView == self.editorList) {
        return [[curConfigFile allPossibleKeys]objectAtIndex:rowIndex]; //all possible keys list
    }else
        
        return ([[aTableColumn.headerCell title]isEqualToString:@"Value"])? [curConfigFile readSetting:[[curConfigFile allKeys]objectAtIndex:rowIndex]] : [[curConfigFile allKeys] objectAtIndex:rowIndex]; //table of keys we have in config, mindbreaking lol
}

// just returns the number of items we have.
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return (aTableView.tag == 1111)? [curConfigFile allKeys].count : [curConfigFile allPossibleKeys].count;
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row {
    if (tableView == self.editorList) {
        [self.addDescrippy setStringValue:[curConfigFile descriptionForKey:[[curConfigFile allPossibleKeys]objectAtIndex:row]]]; //show help text for config key
        return YES;
    }
    
    return YES;
    
    
}

- (BOOL)tableView:(NSTableView *)aTableView
shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    if (aTableView == self.editorList) {
        return NO;
    }
    
    // open editor
    [self editProperty:[[curConfigFile allKeys]objectAtIndex:rowIndex] fromAdd:false];
    
       return NO; //no edit
}

// -------------------- drop-in shitcode for ease of coding
- (BOOL)textView:(NSTextView *)aTextView shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString *)replacementString { return NO; }
- (BOOL)textView:(NSTextView *)textView shouldChangeTextInRanges:(NSArray *)affectedRanges replacementStrings:(NSArray *)replacementStrings { return NO; }
- (void)_panelPop:(NSPanel*)panel{
    SMAppDelegate*a = (SMAppDelegate*)[[NSApplication sharedApplication]delegate];
    [a _panelPop:panel];
}

-(void)_panelUnpop:(NSPanel*)panel{
    SMAppDelegate*a = (SMAppDelegate*)[[NSApplication sharedApplication]delegate];
    [a _panelUnpop:panel];
}
-(void)replacePanel:(NSPanel*)p withPanel:(NSPanel*)a{
    [self _panelUnpop:p];
    [self _someRetains];
    [self _panelPop:a];
}

-(void)_someRetains {
    [self.paneItself retain];
    [self.addPanel retain];
    [self.editPanel retain];
    [self.boolEditorPanel retain];
    [self.strofEditorPanel retain];
    //donno why
}
// ---------------------------- drop-in end


- (IBAction)doAdd:(id)sender { //open Add Key panel
    [self replacePanel:self.paneItself withPanel:self.addPanel];
}

- (void)editProperty:(NSString*)propName fromAdd:(bool)add{ //edit property
    NSString* propertyProperties = [curConfigFile typeAndLimitsFor:propName]; //the var name, i know lol
    if ([propertyProperties isEqualToString:@"bool"]) {
        // open the boolean value editor
        [self.boolKeyname setStringValue:propName];
        [self.boolValue setState: ([curConfigFile readSetting:propName] == nil) ? false : [curConfigFile readSetting:propName].boolValue];
        [self replacePanel:(add == true) ? self.addPanel : self.paneItself  withPanel:self.boolEditorPanel];
        return;
    }
    NSArray* kind = [propertyProperties componentsSeparatedByString:@";"];
    if ([[kind objectAtIndex:0]isEqualToString:@"int"] || [[kind objectAtIndex:0]isEqualToString:@"str"]) {
        //open generic editor
        self.editKeyname.stringValue = propName;
        self.editValue.stringValue = ([curConfigFile readSetting:propName] == nil) ? @"" : [curConfigFile readSetting:propName];
        [self replacePanel:(add == true) ? self.addPanel : self.paneItself  withPanel:self.editPanel];
    }
    if ([[kind objectAtIndex:0]isEqualToString:@"strof"]) {
        // open choice editor
        self.strofKeyname.stringValue = propName;
        NSMenu *yourMenu = [[NSMenu alloc] init];
        // populate its menu with possible choices
        for (NSString*string in kind) {
            if(![string isEqualToString:@"strof"]){
                NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:string action:nil keyEquivalent:@""];
                [yourMenu insertItem:menuItem atIndex:0];
            }
        }
        [self.strofList setMenu:yourMenu];
        if([curConfigFile readSetting:propName] != nil) [self.strofList selectItemWithTitle:[curConfigFile readSetting:propName]];
        
        [self replacePanel:(add == true) ? self.addPanel : self.paneItself  withPanel:self.strofEditorPanel];
    }
}

- (IBAction)strofDone:(id)sender {
    [curConfigFile writeSetting:self.strofList.selectedItem.title forKey:self.strofKeyname.stringValue];
    [self replacePanel:self.strofEditorPanel withPanel:self.paneItself];
    // save the choice
}

- (IBAction)strofCancel:(id)sender {
    [self replacePanel:self.strofEditorPanel withPanel:self.paneItself]; //cancel strOf editor
}


- (IBAction)doDone:(id)sender {
    [self _panelUnpop:self.paneItself]; //unpop ourselves
}

- (IBAction)boolPerformSave:(id)sender {
    [curConfigFile writeSetting:(self.boolValue.state == 1) ? @"true" : @"false" forKey:self.boolKeyname.stringValue]; //write bool value
    [self replacePanel:self.boolEditorPanel withPanel:self.paneItself];
}

- (IBAction)boolCancel:(id)sender {
    [self replacePanel:self.boolEditorPanel withPanel:self.paneItself]; // close bool editor
}
- (IBAction)editSave:(id)sender {
    //generic save
    NSString* propertyProperties = [curConfigFile typeAndLimitsFor:self.editKeyname.stringValue]; //i know lol 
    NSArray* kind = [propertyProperties componentsSeparatedByString:@";"];
    if ([[kind objectAtIndex:0]isEqualToString:@"int"] && ![[kind objectAtIndex:1]isEqualToString:@""]) {
        //we are integer
        NSArray* uplow = [[kind objectAtIndex:1]componentsSeparatedByString:@"-"];
        if (!(self.editValue.integerValue <= [[uplow objectAtIndex:1]integerValue]) || !(self.editValue.integerValue >= [[uplow objectAtIndex:0]integerValue])) {
            //we're out of limits
            NSAlert* msgBox = [[[NSAlert alloc] init] autorelease];
            [msgBox setMessageText: NSLocalizedString(@"Invalid value",@"Invalid value")];
            [msgBox setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"Must be between %li and %li",@"Must be between %li and %li"),[[uplow objectAtIndex:0]integerValue],[[uplow objectAtIndex:1]integerValue]]];
            
            [msgBox addButtonWithTitle: NSLocalizedString(@"OK",@"OK")];
            [msgBox runModal];
            return;
        }
        
    }
    //save it
    [curConfigFile writeSetting:self.editValue.stringValue forKey:self.editKeyname.stringValue];
    [self replacePanel:self.editPanel withPanel:self.paneItself];
}

- (IBAction)editCancel:(id)sender { //close generic editor
    [self replacePanel:self.editPanel withPanel:self.paneItself];
}
- (IBAction)performAdd:(id)sender {
    // add key to config
    [self editProperty:[[curConfigFile allPossibleKeys]objectAtIndex:[self.editorList selectedRow] ]fromAdd:true];
    
}
- (IBAction)performCancel:(id)sender { //close the add panel
    [self replacePanel:self.addPanel withPanel:self.paneItself];
}
@end
