//
//  AssemblyFile.m
//  Edit68K
//
//  Created by Robert Bartlett-Schneider on 1/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AssemblyFile.h"

@implementation AssemblyFile

@synthesize textStorage;

//--------------------------------------------------------
// init()
//--------------------------------------------------------
- (id)init
{
    self = [super init];
    if (self) {
        
        [self initTextStorage];
    
        listFlag = true;
        objFlag = true;
    }
    return self;
}

//--------------------------------------------------------
// textStorage() getter for textStorage variable
//--------------------------------------------------------
- (NSTextStorage *)textStorage {
    return [[textStorage retain] autorelease];
}

//--------------------------------------------------------
// setTextStorage() setter for textStorage variable
//--------------------------------------------------------
- (void) setTextStorage:(NSTextStorage *)value {
    if (textStorage != value) {
        if (textStorage) [textStorage release];
        textStorage = [value copy];
    }
}

/* Initializes the textStorage which will be loaded with the template file */
- (void)initTextStorage {
    NSError *error;
    // For now, the template is stored in a file, may move it into memory.
    textStorage = [[NSTextStorage alloc] initWithURL:[[NSBundle mainBundle] URLForResource:@"template" withExtension:@"x68"] 
                                             options:nil 
                                  documentAttributes:NULL 
                                               error:&error];
    
    // For the moment, terminate if there's an error and the file is not loaded.
    if (!textStorage) {
        [NSApp presentError:error];
        [NSApp terminate:self];
    }    
    
    [textStorage setFont:[NSFont fontWithName:@"Courier" size:11]];
}

- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"AssemblyFile";
}

//--------------------------------------------------------
// windowControllerDidLoadNib()
//--------------------------------------------------------
- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
}

//--------------------------------------------------------
// dataOfType() used to write files to disk
//--------------------------------------------------------
- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    NSData *data;
    [self setTextStorage:[textView textStorage]];
    NSMutableDictionary *dict = [NSDictionary dictionaryWithObject:NSPlainTextDocumentType
                                                            forKey:NSDocumentTypeDocumentAttribute];
    [textView breakUndoCoalescing];
    data = [[self textStorage] dataFromRange:NSMakeRange(0, [[self textStorage] length])
                     documentAttributes:dict error:outError];
    

    
    return data;
}

//--------------------------------------------------------
// readFromData() used to open files from disk
//--------------------------------------------------------
- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    BOOL readSuccess = NO;
    NSTextStorage* fileContents = [[NSTextStorage alloc]
                                  initWithData:data options:NULL documentAttributes:NULL error:outError];
    
    if (fileContents) {
        readSuccess = YES;
        [self setTextStorage:fileContents];
        [fileContents release];
    }
    return readSuccess;
}

//--------------------------------------------------------
// assemble() assemble's the current document
//--------------------------------------------------------
- (IBAction)assemble:(id)sender {

// TODO: Test to see if file has been saved to disk yet. 
    //At the moment, this REQUIRES that the file has been previously saved     
    
    char inputFile[256];
    char tempFile[256];
    
    NSString *path = [[self fileURL] path];
    const char *cPath = [path cStringUsingEncoding:NSASCIIStringEncoding];
    
    sprintf(inputFile, "%s", cPath);
    strcpy(tempFile, "edit68k-XXXXXX");
    
    if (mktemp(tempFile) == NULL) {
        NSLog(@"%@",@"Error creating temporary file via mkstemp()");
    } else {
        assembleFile(inputFile, tempFile, inputFile);
    }
}


//--------------------------------------------------------
// dealloc() 
//--------------------------------------------------------
- (void)dealloc {
    [textStorage release];
    [super dealloc];
}

@end
