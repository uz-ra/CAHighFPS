#define CHECK_TARGET

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
//#import <PSHeader/PS.h>

NSMutableDictionary *prefs;

@interface CAMetalLayer (Private)
@property (assign) CGFloat drawableTimeoutSeconds;
@end

static NSInteger maxFPS = -1;

static NSInteger getMaxFPS() {
if ([prefs[@"customFpsEnabled"]boolValue]){
        maxFPS = [prefs[@"customFPS"]doubleValue];
}else {
    if (maxFPS == -1)
        maxFPS = [UIScreen mainScreen].maximumFramesPerSecond;
}
    return maxFPS;
}
/*
static BOOL shouldEnableForBundleIdentifier(NSString *bundleIdentifier) {

    NSArray <NSString *> *value = [prefs objectForKey:@"App"];
    return ![value containsObject:bundleIdentifier];
}
*/

#pragma mark - CADisplayLink

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability-new"
%group 1
%hook CADisplayLink

- (void)setFrameInterval:(NSInteger)interval {
    %orig(1);
    if ([self respondsToSelector:@selector(setPreferredFramesPerSecond:)])
        self.preferredFramesPerSecond = 0;
}

- (void)setPreferredFramesPerSecond:(NSInteger)fps {
    %orig(0);
}

- (void)setPreferredFrameRateRange:(CAFrameRateRange)range {
    %orig;
    CGFloat max = getMaxFPS();
    range.minimum = 30;
    range.preferred = max;
    range.maximum = max;
}
}

%end
%end //1

#pragma clang diagnostic pop

#pragma mark - CAMetalLayer
%group 2
%hook CAMetalLayer

- (NSUInteger)maximumDrawableCount {
    return 2;
}

- (void)setMaximumDrawableCount:(NSUInteger)count {
    %orig(2);
}

%end
%end //2
#pragma mark - Metal Advanced Hack
%group 3
%hook CAMetalDrawable

- (void)presentAfterMinimumDuration:(CFTimeInterval)duration {
	%orig(1.0 / getMaxFPS());
}

%end

%hook MTLCommandBuffer

- (void)presentDrawable:(id)drawable afterMinimumDuration:(CFTimeInterval)minimumDuration {
    %orig(drawable, 1.0 / getMaxFPS());
}

%end
%end //group3
// #pragma mark - UIKit

// BOOL (*_UIUpdateCycleSchedulerEnabled)(void);

// %group UIKit

// %hookf(BOOL, _UIUpdateCycleSchedulerEnabled) {
//     return YES;
// }

// %end

static BOOL isEnabledApp(){
	NSString* bundleIdentifier=[[NSBundle mainBundle] bundleIdentifier];
    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/jb/var/mobile/Library/Preferences/com.ps.cahighfps.plist"];
    return [prefs[@"App"] containsObject:bundleIdentifier];
}

%ctor {
if(isEnabledApp()) {
//    if (isTarget(TargetTypeApps) && shouldEnableForBundleIdentifier(NSBundle.mainBundle.bundleIdentifier)) {
        // if (IS_IOS_OR_NEWER(iOS_15_0)) { // iOS 15.0 only?
//             MSImageRef ref = MSGetImageByName("/System/Library/PrivateFrameworks/UIKitCore.framework/UIKitCore");
        //     _UIUpdateCycleSchedulerEnabled = (BOOL (*)(void))MSFindSymbol(ref, "__UIUpdateCycleSchedulerEnabled");
        //     if (_UIUpdateCycleSchedulerEnabled) {
        //         %init(UIKit);
        //     }
        // }
        %init(1);
        %init(2);
        %init(3);
    }
  NSString *settingsPath = @"/var/jb/var/mobile/Library/Preferences/com.ps.cahighfps.plist";
  NSDictionary *defaults = @{
    @"customFpsEnabled": @NO,
    @"customFPS": @60,
  };
  prefs = [NSMutableDictionary dictionaryWithContentsOfFile:settingsPath];
  if (!prefs) {
    [defaults writeToFile:settingsPath atomically:YES];
    prefs = [NSMutableDictionary dictionaryWithContentsOfFile:settingsPath]; 
  }
  for (NSString *key in defaults.allKeys)
    if (!prefs[key])
      prefs[key] = defaults[key];
}