//
//  IntHexStringTransformer.m
//  Sim68K
//
//  Created by Robert Bartlett-Schneider on 3/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "IntHexStringTransformer.h"

@implementation IntHexStringTransformer

// -----------------------------------------------------------------
// transformedValueClass
// returns the class of the transformed value
// -----------------------------------------------------------------
+ (Class)transformedValueClass {
    return [NSString class];
}

// -----------------------------------------------------------------
// allowReverseTransformation
// Determines whether the transformer allows reverse transformation
// -----------------------------------------------------------------
+ (BOOL)allowsReverseTransformation {
    return YES;
}

// -----------------------------------------------------------------
// transformedValue
// -----------------------------------------------------------------
- (id)transformedValue:(id)value {
    return [NSString stringWithFormat:@"%08X",[value intValue]];
}

// -----------------------------------------------------------------
// reverseTransformedValue
// -----------------------------------------------------------------
- (id)reverseTransformedValue:(id)value {
    NSScanner *temp = [NSScanner scannerWithString:(NSString *)value];
    unsigned int result = 0;
    if ([temp scanHexInt:&result]) {
        return (id)result;
    } else {
        return 0;
    }
}

@end
