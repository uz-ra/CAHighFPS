#import "CAHighFPSRootListController.h"

@implementation CAHighFPSRootListController
- (NSArray *)specifiers {

       _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
	
	return _specifiers;
}

@end