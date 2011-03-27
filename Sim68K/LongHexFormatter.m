//
//  LongHexFormatter.m
//  Sim68K
//
//  Created by Robert Bartlett-Schneider on 3/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "LongHexFormatter.h"
#include "extern.h"

@implementation LongHexFormatter

// -----------------------------------------------------------------
// stringForObjectValue
// Gets the final string that'll be used to represent the formatted
// number
// -----------------------------------------------------------------
- (NSString *)stringForObjectValue:(id)obj { 
    NSString *result = @"00000000";                                         // Default value if invalid
    
    if([obj isKindOfClass:[NSNumber class]]) {                              // Formatting number already
        result = [NSString stringWithFormat:@"%08X", (int)[obj intValue]];  // Print hex to string
    } else if ([obj isKindOfClass:[NSString class]]) {                      // Formatting a string
        NSScanner *temp = [NSScanner scannerWithString:obj];                
        unsigned int value = 0;
        if ([temp scanHexInt:&value])                                       // Scan for hex value in string
            result = [NSString stringWithFormat:@"%08X",value];
    }    
    return result; 
} 

// -----------------------------------------------------------------
// getObjectValue
// Gets an NSNumber represented by the string supplied.
// -----------------------------------------------------------------
- (BOOL)getObjectValue:(id *)obj forString:(NSString *)string 
      errorDescription:(NSString **)error  
{ 
    NSNumber *hexValue;
    BOOL success = NO;
    
    NSScanner *temp = [NSScanner scannerWithString:(NSString *)string];
    unsigned int result = 0;
    
    if ([temp scanHexInt:&result]) {                                        // Scan for hex value in string
        hexValue = [NSNumber numberWithInt:result];
        success = YES;
    } else {
        hexValue = [NSNumber numberWithInt:0];                              // Default to 0 if scan failure
    }    
    
    *obj = hexValue;
    
    return success; 
} 

// -----------------------------------------------------------------
// isPartialStringValid
// Checks that characters are valid as they are typed in
// -----------------------------------------------------------------
//- (BOOL)isPartialStringValid:(NSString *)partialString 
//            newEditingString:(NSString **)newString 
//            errorDescription:(NSString **)error 
//{
//    // Result always NO until enter is pressed to confirm
//    BOOL result = NO;
//    
//    NSMutableString *tempString = [NSMutableString stringWithString:partialString];
//    NSCharacterSet *illegalCharacters = CHARSET_HEX;
//    NSRange illegalCharacterRange = [tempString rangeOfCharacterFromSet:illegalCharacters];
//    
//    while (illegalCharacterRange.location != NSNotFound)                                    // Remove non hex chars
//    {
//        [tempString deleteCharactersInRange:illegalCharacterRange];
//        illegalCharacterRange = [tempString rangeOfCharacterFromSet:illegalCharacters];
//    }
//    
//    *newString = tempString;                                                                // Pass clean string
//    
//    return result;
//}

// -----------------------------------------------------------------
// isPartialStringValid
// Checks that characters are valid as they are typed in
// -----------------------------------------------------------------
- (BOOL)isPartialStringValid:(NSString **)partialStringPtr 
       proposedSelectedRange:(NSRange *)proposedSelRangePtr 
              originalString:(NSString *)origString 
       originalSelectedRange:(NSRange)origSelRange 
            errorDescription:(NSString **)error
{
    NSMutableString *tempString = [NSMutableString stringWithString:*partialStringPtr];

    NSCharacterSet *illegalCharacters = CHARSET_HEX;
    NSRange illegalCharacterRange = [tempString rangeOfCharacterFromSet:illegalCharacters];
    if (illegalCharacterRange.location != NSNotFound)                                       // Illegal chars
        return NO;
    
    int lengthDif = [origString length] - [*partialStringPtr length];
    
    if (lengthDif == [origString length]) {                                                 // Empty String
        *partialStringPtr = @"00000000";    
    } 
    
    else if (lengthDif < 0) {                                                               // Longer String
        if (origSelRange.location == [origString length])
            return NO;
        
        if (lengthDif == -1) {                                                              // Single character
            NSRange delRange = NSMakeRange(origSelRange.location+1, 1);
            [tempString deleteCharactersInRange:delRange];
            *partialStringPtr = tempString;
            if (delRange.location == [origString length]) delRange.location--;
            *proposedSelRangePtr = delRange;
        }
        
        if (lengthDif == -8) {                                                              // Pasting full string
            if (origSelRange.location == 0) {                                               // Only accept at index 0
                *partialStringPtr = [tempString substringToIndex:8];
                proposedSelRangePtr->location = 0;
                proposedSelRangePtr->length = 8;
            }
        }
    }
    
    else if (lengthDif > 0) {                                                               // Shorter String
        int selDif = [origString length]-origSelRange.length+1;
        if (selDif == [*partialStringPtr length]) {
            NSRange replaceRange = NSMakeRange(0, proposedSelRangePtr->location);
            tempString = [NSMutableString stringWithString:origString];
            NSString *newStart = [*partialStringPtr substringToIndex:proposedSelRangePtr->location];
            [tempString replaceCharactersInRange:replaceRange withString:newStart];
            *partialStringPtr = tempString;
            proposedSelRangePtr->length++;
        }
    }
    
    if (lengthDif == 0) {                                                                   // Same length
        proposedSelRangePtr->length++;
        *partialStringPtr = tempString;
    }
    
    return NO;
}

@end
