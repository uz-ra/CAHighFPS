#define CHECK_TARGET

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
//#import <PSHeader/PS.h>

NSMutableDictionary *prefs;

@interface CAMetalLayer (Private)
@property (assign) CGFloat drawableTimeoutSeconds;
@end

static BOOL customFpsEnabled;

static NSInteger maxFPS = -1;

static NSInteger getMaxFPS() {

//if ([prefs[@"customFpsEnabled"]boolValue]){
if(customFpsEnabled){
    if (maxFPS == -1)
        maxFPS = [prefs[@"customFPS"]doubleValue];
}else {

    if (maxFPS == -1)
        maxFPS = [UIScreen mainScreen].maximumFramesPerSecond;
}
    return maxFPS;
}
/*
static BOOL shouldEnableForBundleIdentifier(NSString *bundleIdentifier) {
    NSDictionary *prefs = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.ps.cahighfps"];
    NSArray <NSString *> *value = [prefs objectForKey:@"App"];
    return ![value containsObject:bundleIdentifier];
}
*/

static BOOL isEnabledApp(){
	NSString* bundleIdentifier=[[NSBundle mainBundle] bundleIdentifier];
    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/jb/var/mobile/Library/Preferences/com.ps.cahighfps.plist"];
    return [prefs[@"App"] containsObject:bundleIdentifier];
}


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
    CGFloat max = getMaxFPS();
    range.minimum = 30;
    range.preferred = max;
    range.maximum = max;
    %orig;
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

//fpsindicator
enum FPSMode{
	kModeAverage=1,
	kModePerSecond
};
static enum FPSMode fpsMode;

static dispatch_source_t _timer;
static UILabel *fpsLabel;

static void loadPref(){
	NSLog(@"loadPref..........");
	NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/jb/var/mobile/Library/Preferences/com.ps.cahighfps.plist"];
customFpsEnabled=prefs[@"customFpsEnabled"]?[prefs[@"customFpsEnabled"] boolValue]:YES;
	fpsMode=prefs[@"fpsMode"]?[prefs[@"fpsMode"] intValue]:0;
	if(fpsMode==0) fpsMode++; //0.0.2 compatibility 

//	NSString *colorString = @"#FF5062"; 
UIColor *color = [UIColor redColor];

	[fpsLabel setTextColor:color];

}

double FPSavg = 0;
double FPSPerSecond = 0;

static void startRefreshTimer(){
	_timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_timer(_timer, dispatch_walltime(NULL, 0), (1.0/5.0) * NSEC_PER_SEC, 0);

    dispatch_source_set_event_handler(_timer, ^{
    	switch(fpsMode){
		    case kModeAverage:
		    	[fpsLabel setText:[NSString stringWithFormat:@"%.1lf / %f",FPSavg, getMaxFPS]];
		    	break;
		    case kModePerSecond:
		    	[fpsLabel setText:[NSString stringWithFormat:@"%.1lf / ",FPSPerSecond, getMaxFPS]];
		    	break;
		    default:
		    	break;
    	}

    	NSLog(@"%.1lf %.1lf",FPSavg,FPSPerSecond);

    });
    dispatch_resume(_timer); 
}

#pragma mark ui
#define kFPSLabelWidth 100
#define kFPSLabelHeight 20
%group ui
%hook UIWindow
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
	static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        CGRect bounds=[self bounds];
        CGFloat safeOffsetY=0;
        CGFloat safeOffsetX=0;
        if(@available(iOS 11.0,*)) {
            if(self.frame.size.width<self.frame.size.height){
                safeOffsetY=self.safeAreaInsets.top;    
            }
            else{
                safeOffsetX=self.safeAreaInsets.right;
            }
            
        }
        fpsLabel= [[UILabel alloc] initWithFrame:CGRectMake(bounds.size.width-kFPSLabelWidth-5.-safeOffsetX, safeOffsetY, kFPSLabelWidth, kFPSLabelHeight)];
        fpsLabel.font=[UIFont fontWithName:@"Helvetica-Bold" size:16];
        fpsLabel.textAlignment=NSTextAlignmentRight;
        fpsLabel.userInteractionEnabled=NO;
        
        [self addSubview:fpsLabel];
        loadPref();
        startRefreshTimer();
    });
	return %orig;
}
%end
%end//ui

// credits to https://github.com/masagrator/NX-FPS/blob/master/source/main.cpp#L64
void frameTick(){
	static double FPS_temp = 0;
	static double starttick = 0;
	static double endtick = 0;
	static double deltatick = 0;
	static double frameend = 0;
	static double framedelta = 0;
	static double frameavg = 0;
	
	if (starttick == 0) starttick = CACurrentMediaTime()*1000.0;
	endtick = CACurrentMediaTime()*1000.0;
	framedelta = endtick - frameend;
	frameavg = ((9*frameavg) + framedelta) / 10;
	FPSavg = 1000.0f / (double)frameavg;
	frameend = endtick;
	
	FPS_temp++;
	deltatick = endtick - starttick;
	if (deltatick >= 1000.0f) {
		starttick = CACurrentMediaTime()*1000.0;
		FPSPerSecond = FPS_temp - 1;
		FPS_temp = 0;
	}
	
	return;
}

#pragma mark gl
%group gl
%hook EAGLContext 
- (BOOL)presentRenderbuffer:(NSUInteger)target{
	BOOL ret=%orig;
	frameTick();
	return ret;
}
%end
%end//gl

#pragma mark metal
%group metal
%hook CAMetalDrawable
- (void)present{
	%orig;
	frameTick();
}
- (void)presentAfterMinimumDuration:(CFTimeInterval)duration{
	%orig;
	frameTick();
}
- (void)presentAtTime:(CFTimeInterval)presentationTime{
	%orig;
	frameTick();
}
%end //CAMetalDrawable
%end//metal




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
	%init(ui);
	%init(gl);
	%init(metal);
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
/*
	int token = 0;
	notify_register_dispatch("com.ps.cahighfps/loadPref", &token, dispatch_get_main_queue(), ^(int token) {
		loadPref();
	});
*/
}