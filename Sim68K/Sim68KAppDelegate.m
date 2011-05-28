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

@synthesize window, panelIO, panelMemory, panelStack, panelHardware, simIOView, errorOutput;
@synthesize file;
@synthesize simulator;
@synthesize stackDisplayLoc;

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
    // Global delegate reference (ick), necessary for simulator functions to reference GUI
    appDelegate = self;
    
    [self initListfileView];             // Set up listfile view
    [self initMemoryScrollers];
    [self initStackScrollers];
    [simulator initSim];                 // Initialize simulator
    
    memDisplayLength = 1024;             // Set up memory browser values
    [self setMemDisplayStart:0x1000];
    [self updateMemDisplay];
    int selStack = [stackSelectMenu indexOfSelectedItem];
    [self setStackDisplayLoc:A[selStack]];
    [self updateStackDisplay];
    [errorOutput clearText];
    
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
                              [scriptView setFont:CONSOLE_FONT];
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
    if (!trapInput) {
        NSOperationQueue *queue = [[[NSOperationQueue alloc] init] autorelease];
        NSOperation *simLoop = [[[NSInvocationOperation alloc] 
                                 initWithTarget:simulator
                                 selector:@selector(step)
                                 object:nil] autorelease];
        [queue addOperation:simLoop];
    }
}

// -----------------------------------------------------------------
// trace
// Tells the simulator to trace into the next instruction
// -----------------------------------------------------------------
- (IBAction)trace:(id)sender {
    if (!trapInput) {
        NSOperationQueue *queue = [[[NSOperationQueue alloc] init] autorelease];
        NSOperation *simLoop = [[[NSInvocationOperation alloc] 
                                 initWithTarget:simulator
                                 selector:@selector(trace)
                                 object:nil] autorelease];
        [queue addOperation:simLoop];
    }
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
    [simulator runToCursor:[scriptView selectedPC]];
}

// -----------------------------------------------------------------
// reload
// Tells the simulator to reload the program entirely.
// -----------------------------------------------------------------
- (IBAction)reload:(id)sender {
    [simulator loadProgram:[self file]];
}

// -----------------------------------------------------------------
// initListFileView
// initializes the main scroll view with some basic properties
// for viewing listfiles. sets up the line number/breakpoint view
// -----------------------------------------------------------------
- (void)initListfileView {
    const float LargeNumberForText = 1.0e7;

    // Initialize the NSTextView with the NoodleLineNumberView
    lineNumberView = [[[MarkerLineNumberView alloc] initWithScrollView:scrollView] autorelease];
    [scrollView setVerticalRulerView:lineNumberView];
    [scrollView setHasHorizontalRuler:NO];
    [scrollView setHasVerticalRuler:YES];
    [scrollView setRulersVisible:YES];
    [scriptView setFont:CONSOLE_FONT];
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
    
    //
}

// -----------------------------------------------------------------
// initMemoryScrollers
// initializes the synchronized memory scroll views
// -----------------------------------------------------------------
- (void)initMemoryScrollers {
    NSRect addressRect = [[memAddressScroll contentView] documentRect];
    NSRect valueRect   = [[memValueScroll contentView] documentRect];
    NSRect contentRect = [[memContentsScroll contentView] documentRect];
    [memAddressScroll setLastScrollPoint:addressRect.origin];
    [memAddressScroll setAcceptsScrollWheel:NO];
    [memAddressScroll setName:@"memAddress"];
    [memValueScroll setLastScrollPoint:valueRect.origin];
    [memValueScroll setAcceptsScrollWheel:YES];
    [memValueScroll setName:@"memValue"];
    [memContentsScroll setLastScrollPoint:contentRect.origin];
    [memContentsScroll setAcceptsScrollWheel:NO];
    [memContentsScroll setName:@"memContents"];
    mBrowser = [[SynchronizedScrollController alloc] init];
    [mBrowser registerScrollView:memAddressScroll];
    [mBrowser registerScrollView:memValueScroll];
    [mBrowser registerScrollView:memContentsScroll];
}

// -----------------------------------------------------------------
// initStackScrollers
// initializes the synchronized stack scroll views
// -----------------------------------------------------------------
- (void)initStackScrollers {
    NSRect addressRect = [[stackAddressScroll contentView] documentRect];
    NSRect valueRect   = [[stackValueScroll contentView] documentRect];
    [stackAddressScroll setLastScrollPoint:addressRect.origin];
    [stackAddressScroll setAcceptsScrollWheel:NO];
    [stackValueScroll setLastScrollPoint:valueRect.origin];
    [stackValueScroll setAcceptsScrollWheel:YES];
    sBrowser = [[SynchronizedScrollController alloc] init];
    [sBrowser registerScrollView:stackAddressScroll];
    [sBrowser registerScrollView:stackValueScroll];
}

// -----------------------------------------------------------------
// isInstruction
// Checks the simulator to see whether a supplied line of text
// contains a valid instruction
// -----------------------------------------------------------------
- (BOOL)isInstruction:(NSString *)line {
    return [simulator isInstruction:line];
}

// -----------------------------------------------------------------
// highlightCurrentInstruction
// Highlights the current instruction if source debugging is enabled
// -----------------------------------------------------------------
- (void)highlightCurrentInstruction {
    [scriptView highlightCurrentInstruction];
}

// -----------------------------------------------------------------
// changeMemLength
// changes the number of bytes the memory display will show
// -----------------------------------------------------------------
- (IBAction)changeMemLength:(id)sender {
    if ([sender isKindOfClass:[NSPopUpButton class]]) {
        NSString *lengthStr = [sender titleOfSelectedItem];
        memDisplayLength = [lengthStr intValue];
        [self updateMemDisplay];
    }
}

// -----------------------------------------------------------------
// memDisplayStart
// gets the starting address for memory display
// -----------------------------------------------------------------
-(unsigned int)memDisplayStart {
    return memDisplayStart;
}

// -----------------------------------------------------------------
// setMemDisplayStart
// sets the starting address for memory display and then updates 
// the memory display
// -----------------------------------------------------------------
-(void)setMemDisplayStart:(unsigned int)newStart {
    if (newStart < 0x0) newStart = 0x00000001;
    if (newStart > 0x00FFFFF0) newStart = 0x00FFFFF1;
    if ((newStart & 0x0000000F) > 0) {
        newStart &= (unsigned int)0xFFFFFFF0;
        [self setMemDisplayStart:newStart];
    }
    memDisplayStart = newStart;
    [self updateMemDisplay];
}

// -----------------------------------------------------------------
// memPageChange
// Changes the currently visible memory page
// -----------------------------------------------------------------
-(IBAction)memPageChange:(id)sender {
    NSSegmentedControl *pager = sender;
    int selection = [pager selectedSegment];
    switch (selection) {
        case 0:
            [self setMemDisplayStart:(memDisplayStart - memDisplayLength)];
            break;
        case 1:
            [self setMemDisplayStart:(memDisplayStart + memDisplayLength)];
            break;
        default:
            break;
    }
}

// -----------------------------------------------------------------
// stackPageChange
// Changes the currently visible memory page
// -----------------------------------------------------------------
-(IBAction)stackPageChange:(id)sender {
    NSStepper *pager = sender;
    int direction = [pager intValue];
    int stackDisplayLength = 256;
    switch (direction) {
        case 1:
            [self setStackDisplayLoc:(stackDisplayLoc - stackDisplayLength/2)];
            break;
        case -1:
            [self setStackDisplayLoc:(stackDisplayLoc + stackDisplayLength/2)];
            break;
        default:
            break;
    }
    [self updateStackDisplay];
    [pager setDoubleValue:0.0];
}

// -----------------------------------------------------------------
// stackSelect
// Called when the stack selection dropdown is changed
// -----------------------------------------------------------------
- (IBAction)stackSelect:(id)sender {
    NSPopUpButton *sMenu = (NSPopUpButton *)sender;
    int selStack = [sMenu indexOfSelectedItem];
    [self setStackDisplayLoc:A[selStack]];
    [self updateStackDisplay];
}

// -----------------------------------------------------------------
// updateStackDisplay
// Updates the contents of the stack window
// -----------------------------------------------------------------
- (void)updateStackDisplay {
    
    int             selectedStack, stackDisplayLength;
    unsigned int    stackStart, stackDisplayStart, diff, curAddr, stackAddr;
    NSString        *address;
    NSLayoutManager *layoutManager;
    NSTextStorage   *curStore;
    NSRange         lastRange;
    
    // Clear current contents of stack window
    [stackAddressColumn clearText];
    [stackValueColumn clearText];
    
    // Don't do anything if 68K Memory is not initialized
    if (!memory) return;
    
    // Enforce some bounds
    selectedStack       = [stackSelectMenu indexOfSelectedItem];
    stackAddr           = A[selectedStack];
    stackStart          = [self stackDisplayLoc];
    stackDisplayLength  = 256;
    stackDisplayStart   = (stackStart - stackDisplayLength/2);
    
    if ((int)stackDisplayStart < 0) {
        diff = (stackDisplayLength/2) - stackStart;
        stackDisplayStart = MEMSIZE - diff;
    }
    
    if (stackDisplayStart > MEMSIZE) return;
    
    // Loop through memory
    for (int i=0,j=0; i < stackDisplayLength; i+=0x4,j+=0x4) {
        
        // Initial bounds checking
        curAddr = j + stackDisplayStart;
        if (curAddr >= MEMSIZE ) {
            stackDisplayStart = 0x0;
            curAddr = 0x0;
            j = 0;
        }
            
        // Print out address
        address = [NSString stringWithFormat:@"%08X",curAddr];
        [stackAddressColumn appendString:address
                                withFont:CONSOLE_FONT];
        
        // Highlight stack pointer address so it stands out
        if (curAddr == stackAddr) {
            layoutManager   = [stackAddressColumn layoutManager];
            curStore        = [stackAddressColumn textStorage];
            lastRange       = NSMakeRange([curStore length]-8, 8);
            [layoutManager addTemporaryAttribute:NSBackgroundColorAttributeName 
                                           value:[NSColor selectedTextBackgroundColor]
                               forCharacterRange:lastRange];
        }
        
        // Loop 4 bytes
        for (int k = 0; k < 0x4; k++) {
            if (curAddr >= MEMSIZE) break;
            unsigned char memByte = memory[curAddr];
            NSString *byteStr = [NSString stringWithFormat:@"%02X ",(unsigned int)memByte];
            [stackValueColumn appendString:byteStr
                                  withFont:CONSOLE_FONT];
            curAddr++;
        }
        
        // Newline if necessary
        if ((i + 0x4) < stackDisplayLength) {
            [stackAddressColumn appendString:@"\n"
                                    withFont:CONSOLE_FONT];
            [stackValueColumn appendString:@"\n"
                                  withFont:CONSOLE_FONT];
        }
    }

    
    
}

// -----------------------------------------------------------------
// updateMemDisplay
// Updates the memory display window 
// -----------------------------------------------------------------
- (void)updateMemDisplay {
    if (!memory) return;
    
    // Clear current contents of memory window
    [memAddressColumn clearText];
    [memContentsColumn clearText];
    [memValueColumn clearText];
    
    // Enforce some bounds
    int memLength = memDisplayStart + memDisplayLength;             
    if (memLength > MEMSIZE) 
        memLength = memDisplayStart + (MEMSIZE - memDisplayStart);
    
    // Loop through requested memory
    for (int i = memDisplayStart; i < memLength; i+=0x10) {
        
        // Print out address
        NSString *address = [NSString stringWithFormat:@"%08X",i];
        [memAddressColumn appendString:address
                              withFont:CONSOLE_FONT];
        
        // More bounds checking
        int jMax = 0x10;                                            
        if (i + jMax >= MEMSIZE) jMax = (MEMSIZE - i);
        
        // Loop 16 bytes
        for (int j = 0; j < jMax; j++) {
            unsigned char memByte = memory[i+j];
            // Print out value and character
            NSString *byteStr = [NSString stringWithFormat:@"%02X ",(unsigned int)memByte];
            NSString *charStr = [NSString stringWithFormat:@"%c",memByte];
            if (iscntrl(memByte)) charStr = [NSString stringWithFormat:@"-"];
            [memValueColumn appendString:byteStr
                                withFont:CONSOLE_FONT];
            [memContentsColumn appendString:charStr
                                   withFont:CONSOLE_FONT];
        }
        
        // New lines
        if (i+0x10 < memLength) {
            [memAddressColumn appendString:[NSString stringWithFormat:@"\n"]
                                  withFont:CONSOLE_FONT];
            [memValueColumn appendString:[NSString stringWithFormat:@"\n"]
                                withFont:CONSOLE_FONT];
            [memContentsColumn appendString:[NSString stringWithFormat:@"\n"]
                                   withFont:CONSOLE_FONT];
        }
    }
    
}


@end
