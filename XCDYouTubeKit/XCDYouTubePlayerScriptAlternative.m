//
//  XCDYouTubePlayerScriptAlternative.m
//  XCDYouTubeKit
//
//  Created by Hiroki Kumamoto on 4/7/15.
//  Copyright (c) 2015 Cédric Luthi. All rights reserved.
//

#import "XCDYouTubePlayerScript.h"
#import <JavaScriptCore/JavaScriptCore.h>
#import <Availability.h>
#if (defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_7_0) || \
     (defined(__MAC_OS_X_VERSION_MIN_REQUIRED) && __MAC_OS_X_VERSION_MIN_REQUIRED >= __MAC_10_9)

@interface XCDYouTubePlayerScript ()
@property (nonatomic, retain) JSContext *context;
@property (nonatomic, retain) JSValue *signatureFunction;
@end

@implementation XCDYouTubePlayerScript

- (void)dealloc
{
	_context = nil;
	_signatureFunction = nil;
}


- (instancetype) initWithString:(NSString *)string
{
	if (!(self = [super init]))
		return nil;

	NSString *script = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	static NSString *jsPrologue = @"(function()";
	static NSString *jsEpilogue = @")();";
	if ([script hasPrefix:jsPrologue] && [script hasSuffix:jsEpilogue])
		script = [script substringWithRange:NSMakeRange(jsPrologue.length, script.length - (jsPrologue.length + jsEpilogue.length))];
	JSContext* __context = [[JSContext alloc] init];
	_context = __context;

	for (NSString *propertyName in @[ @"window", @"document", @"navigator" ])
	{
		NSObject *globalObject = [[NSObject alloc] init];
		[_context setObject:globalObject forKeyedSubscript:propertyName];
	}

	[_context evaluateScript:script];

	NSRegularExpression *signatureRegularExpression = [NSRegularExpression regularExpressionWithPattern:@"[\"']signature[\"']\\s*,\\s*([^\\(]+)" options:NSRegularExpressionCaseInsensitive error:NULL];
	NSTextCheckingResult *result = [signatureRegularExpression firstMatchInString:script options:(NSMatchingOptions)0 range:NSMakeRange(0, script.length)];
	NSString *signatureFunctionName = result.numberOfRanges > 1 ? [script substringWithRange:[result rangeAtIndex:1]] : nil;

	if (signatureFunctionName)
	{
		JSValue* signatureFunction = [_context evaluateScript:signatureFunctionName];

		if ([signatureFunction isObject]) {
			_signatureFunction = signatureFunction;
		}
	}
	return self;
}

- (NSString *) unscrambleSignature:(NSString *)scrambledSignature
{
	if (!self.signatureFunction || !scrambledSignature)
		return nil;

	NSArray *args = [[NSArray alloc] initWithObjects:scrambledSignature, nil];
	JSValue *unscrambledSignatureValue = [self.signatureFunction callWithArguments:args];
	if ([unscrambledSignatureValue isString]) {
		return unscrambledSignatureValue.toString;
	}
	return nil;
}

@end

#endif
