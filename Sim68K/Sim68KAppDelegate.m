//
//  Sim68KAppDelegate.m
//  Sim68K
//
//  Created by Robert Bartlett-Schneider on 2/27/11.
//

#import "Sim68KAppDelegate.h"
#import "NoodleLineNumberView.h"
#import "NoodleLineNumberMarker.h"
#import "MarkerLineNumberView.h"
#import "Simulator.h"
#import "IntHexStringTransformer.h"
#import "UShortHexStringTransformer.h"
#import "UShortBinaryStringTransformer.h"

#include "extern.h"

//#import <BWToolkitFramework/BWToolkitFramework.h>

@implementation Sim68KAppDelegate

@synthesize window, panelIO, panelMemory, panelStack, panelHardware, simIOView;
@synthesize file;
@synthesize simulator;

// -----------------------------------------------------------------
// initialize
// -----------------------------------------------------------------
+ (void) initialize {
    NSValueTransformer *intHexStr = [[IntHexStringTransformer alloc] init];
    [NSValueTransformer setValueTransformer:intHexStr
                                    forName:@"IntHexStringTransformer"];
    NSValueTransformer *shortHexStr = [[UShortHexStringTransformer alloc] init];
    [NSValueTransformer setValueTransformer:shortHexStr
                                    forName:@"UShortHexStringTransfomer"];
    NSValueTransformer *shortBinStr = [[UShortBinaryStringTransformer alloc] init];
    [NSValueTransformer setValueTransformer:shortBinStr
                                    forName:@"UShortBinaryStringTransformer"];
    [intHexStr autorelease];
    [shortHexStr autorelease];
    [shortBinStr autorelease];
}


// -----------------------------------------------------------------
// applicationDidFinishLaunching
// This runs (usually before the NIB loads) but as soon as the 
// application has finished launching.
// -----------------------------------------------------------------
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {}

// -----------------------------------------------------------------
// awakeFromNib
// Runs when the NIB file has been loaded.
// -----------------------------------------------------------------
- (void)awakeFromNib {
    const float LargeNumberForText = 1.0e7;
    
    // Global delegate reference (ick), necessary for simulator functions to reference GUI
    appDelegate = self;
    
    // Initialize the NSTextView with the NoodleLineNumberView
    lineNumberView = [[[MarkerLineNumberView alloc] initWithScrollView:scrollView] autorelease];
    [scrollView setVerticalRulerView:lineNumberView];
    [scrollView setHasHorizontalRuler:NO];
    [scrollView setHasVerticalRuler:YES];
    [scrollView setRulersVisible:YES];
    [scriptView setFont:[NSFont fontWithName:@"Courier" size:11]];
    [scriptView setEditable:NO];
    
    // Make the scroll view non-wrapping
    [scrollView setHasVerticalScroller:YES];
    [scrollView setHasHorizontalScroller:YES];
    [scrollView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
    NSTextContainer *textContainer = [scriptView textContainer];
    [textContainer setContainerSize:NSMakeSize(LargeNumberForText, LargeNumberForText)];
    [textContainer setWidthTracksTextView:NO];
    [textContainer setHeightTracksTextView:NO];
    [scriptView setMaxSize:NSMakeSize(LargeNumberForText, LargeNumberForText)];
    [scriptView setHorizontallyResizable:YES];
    [scriptView setVerticallyResizable:YES];
    [scriptView setAutoresizingMask:NSViewNotSizable];
    
    // Initialize the simulator
    [simulator initSim];
    
    [window makeKeyAndOrderFront:self];
}

// -----------------------------------------------------------------
// openDocument
// Load an sRecord file from the disk to begin simulation.
// -----------------------------------------------------------------
- (IBAction)openDocument:(id)sender {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setAllowedFileTypes:[NSArray arrayWithObject:@"s68"]];
    [openPanel beginSheetModalForWindow:window 
                      completionHandler:^(NSInteger result) {
                          if (result == NSFileHandlingPanelOKButton) {
                              [simulator loadProgram:[[openPanel URL] path]];
                              [scriptView setFont:[NSFont fontWithName:@"Courier" size:11]];
                              [scriptView setEditable:NO];
                              [self setFile:[[openPanel URL] path]];
                              [window setTitleWithRepresentedFilename:file];
                          }
                      }];
}

// -----------------------------------------------------------------
// runProg
// Tells the simulator to run the program normally
// -----------------------------------------------------------------
- (IBAction)runProg:(id)sender {
    [simulator runProg];
}

// -----------------------------------------------------------------
// step
// Tells the simulator to step through the next instruction
// -----------------------------------------------------------------
- (IBAction)step:(id)sender {
    [simulator step];
}

// -----------------------------------------------------------------
// trace
// Tells the simulator to trace into the next instruction
// -----------------------------------------------------------------
- (IBAction)trace:(id)sender {
    [simulator trace];
}

// -----------------------------------------------------------------
// pause
// Tells the simulator to pause program execution
// -----------------------------------------------------------------
- (IBAction)pause:(id)sender {
    [simulator pause];
}

// -----------------------------------------------------------------
// rewindProg
// Tells the simulator to rewind the program loaded
// -----------------------------------------------------------------
- (IBAction)rewindProg:(id)sender {
    [simulator rewind];
}

// -----------------------------------------------------------------
// runToCursor
// Tells the simulator to rewind the program loaded
// -----------------------------------------------------------------
- (IBAction)runToCursor:(id)sender {
    // TODO: Get cursor location from listFile, then use this as execute location
    // long runToAddr = [self getAddressFromSelectedLine];
    // [simulator runToCursor:location];
    [simulator runToCursor:0x00000000];
}

// -----------------------------------------------------------------
// reload
// Tells the simulator to reload the program entirely.
// -----------------------------------------------------------------
- (IBAction)reload:(id)sender {
    [simulator loadProgram:[self file]];
}

@end
