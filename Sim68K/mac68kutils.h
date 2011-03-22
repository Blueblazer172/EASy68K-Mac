/***************************** 68000 SIMULATOR ****************************
 
 File Name: mac68kutils.h
 Version: 1.0 (Mac OS X)
 
 This file contains various routines and defines used in the Mac OS X port 
 of EASy68K.
 
 The routines are:
 memDistance
 
 Created:  2011-03-17
           Robert Bartlett-Schneider
 
 ***************************************************************************/

#define DISPATCH_MAIN_THREAD \
if (![NSThread isMainThread]) {\
    [self performSelectorOnMainThread:@selector(displayReg)\
                           withObject:nil\
                        waitUntilDone:NO];\
    return;\
}

#define WORD68K 16

#define CHARSET_HEX [[NSCharacterSet characterSetWithCharactersInString:@"0123456789ABCDEFabcdef"] invertedSet]
#define CHARSET_BIN [[NSCharacterSet characterSetWithCharactersInString:@"01"] invertedSet]

long memDistance(void *max, void *min, long size);

NSString* binaryStringForValue(unsigned short value);
NSNumber* binaryStringToValue(NSString *input);