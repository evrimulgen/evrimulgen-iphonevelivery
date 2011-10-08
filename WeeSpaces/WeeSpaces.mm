#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/CALayer.h>
#import "BBWeeAppController-Protocol.h"
#include <objc/runtime.h>
#import <dispatch/dispatch.h>

#import "needed-stuff.h"

#define SCALE 3.0
#define kReportHeight (320.0 / SCALE)
#define kPageWidth (320.0 / SCALE)

@interface WeeSpacesView : UIView {
}
-(void)gotoPage:(unsigned)n;
-(id)initWithPage:(unsigned)page;
@end

@interface WeeAppView : UIView {
	SBApplication *appl;
	UIImage *snapshot;
}
-(id)initWithApplication:(SBApplication *)app;
@end

@interface WeeSpacesController : NSObject <BBWeeAppController, UIScrollViewDelegate> {
	UIScrollView *scrollView;
    UIView *_view;
}

+ (void)initialize;
- (UIView *)view;
@end

@implementation WeeSpacesController
+ (void)initialize {
}

- (void)dealloc {
    [_view release];
	[super dealloc];
}

-(BOOL)loadPage:(unsigned)n atIndex:(int)index {
	WeeSpacesView *v = [[WeeSpacesView alloc] initWithPage:n];
	if (v == nil) return NO;

	dispatch_async(dispatch_get_main_queue(), ^{
			CGRect r = v.frame;
			r.origin.x = index * kPageWidth;
			v.frame = r;
			[scrollView addSubview:v];
			[scrollView setContentSize:CGSizeMake((index + 1) * kPageWidth, kReportHeight)];
			[scrollView setNeedsDisplay];
	});	
	[v release];
	return YES;
}

-(BOOL)loadApplication:(SBApplication *)app atIndex:(int)index {
	WeeAppView *v = [[WeeAppView alloc] initWithApplication:app];
	if (v == nil) return NO;

	dispatch_async(dispatch_get_main_queue(), ^{
			CGRect r = v.frame;
			r.origin.x = index * kPageWidth;
			v.frame = r;
			[v setNeedsDisplay];
			[scrollView addSubview:v];
			[scrollView setContentSize:CGSizeMake((index + 1) * kPageWidth, kReportHeight)];
			[scrollView setNeedsDisplay];
	});
	[v release];
	return YES;	
}

-(void)viewWillAppear {
	// get a list of running app
	NSArray *runningApplications = 
		[[[objc_getClass("SBApplicationController") sharedInstance] allApplications]
					filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id obj, NSDictionary *d) {
							SBApplication *a = (SBApplication *)obj;
							return a.process != nil;
					}
				]
		];

	// populate the scrollview with snapshots
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			int i = 0;

			// first the snapshots of running apps
			for (SBApplication *a in [runningApplications reverseObjectEnumerator]) {
				if ([self loadApplication:a atIndex:i]) 
					i++;
			}
			// display the last snapshot
			dispatch_async(dispatch_get_main_queue(), ^{
				[scrollView setContentOffset:CGPointMake((i - 1) * kPageWidth, 0) animated:YES];
				[scrollView setNeedsDisplay];
			});

			// then the springboard pages
			int page = 0;
			while ([self loadPage:page++ atIndex:i++]) ;
	});
}

- (void)viewDidDisappear {
	for (UIView *v in scrollView.subviews)  
		[v removeFromSuperview];
}


- (UIView *)view {
    if (_view == nil)
    {
        _view = [[UIView alloc] initWithFrame:CGRectMake(2, 0, 316, kReportHeight)];
        
		scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, 316, kReportHeight)];

		scrollView.scrollEnabled = YES;
		scrollView.pagingEnabled = NO;
		[scrollView setCanCancelContentTouches:NO];
		scrollView.showsHorizontalScrollIndicator = NO;
		scrollView.opaque = NO;
		scrollView.delegate = self;

		scrollView.userInteractionEnabled = YES;
		_view.userInteractionEnabled = YES;
		_view.opaque = NO;
		[_view addSubview:scrollView];
		
		_view.userInteractionEnabled = YES;
		_view.opaque = NO;
		[_view addSubview:scrollView];
	}
    
    return _view;
}

- (float)viewHeight {
    return kReportHeight;
}

@end

@implementation WeeSpacesView

-(void)onTouch:(UIControl*)view {
	[view setSelected:YES];
	[self gotoPage:self.tag];
}

-(id)initWithPage:(unsigned)page {
	CGFloat x, y, width, height, margin;

	width = 320 / SCALE;
	height = 320 / SCALE;
	margin = 4;

	NSArray *icons = [[[objc_getClass("SBIconController") sharedInstance] rootIconListAtIndex:page] icons];

	if ([icons count] == 0) {
		[self release];
		return nil;
	}

	self = [super initWithFrame:CGRectMake(width * page, 0.0, width, height)];

	x = y = 0;
	UIImageView *back = [[UIImageView alloc] initWithFrame:CGRectMake(x + 2 , y, width - 4 , height)];
	NSBundle *b = [NSBundle bundleWithIdentifier:@"com.guilleme.WeeSpaces"];
	NSLog(@"%@", [b bundlePath]);
	back.image = [[UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/WeeAppBackground.png", [b bundlePath]]]
				  stretchableImageWithLeftCapWidth:5 
									  topCapHeight:5]; 
	[self addSubview:back];
	[back release];

	x = y = margin / 2;
	for (SBApplicationIcon *icon in icons) {
		UIImageView *v = [[UIImageView alloc] 
								initWithFrame:CGRectMake(x, y, width / 4 - margin * 2, height / 4 - margin * 2)];
		if ([icon class] == [objc_getClass("SBFolderIcon")  class] ||
			[icon class] == [objc_getClass("SBNewsstandIcon") class])
			v.backgroundColor = [UIColor blackColor];
		v.image = [icon generateIconImage:2];
		[self addSubview:v];
		[v release];

		x += width / 4;
		if (x >= width) {
			x = margin;
			y += height / 4;
		}
	}

	self.tag = page;

	UIControl *cntrl = [[UIControl alloc] initWithFrame:CGRectMake(0 , 0, width, height)];
	cntrl.userInteractionEnabled = YES;

	[cntrl addTarget:self action:@selector(onTouch:) forControlEvents:UIControlEventTouchDown];
	[self addSubview:cntrl];
	return self;
}

-(void)gotoPage:(unsigned)page {
	UIScrollView *sv = [[objc_getClass("SBIconController") sharedInstance] scrollView];
	CGPoint offset = sv.contentOffset;

	offset.x = 320.0 * (1 + page);

	[[objc_getClass("SBBulletinListController") sharedInstance] hideListViewAnimated:YES];

	// first simulate a click menu
	if (![[objc_getClass("SBUserAgent") sharedUserAgent] springBoardIsActive])
		[[objc_getClass("SBUIController") sharedInstance] clickedMenuButton];

	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10000000), dispatch_get_current_queue(), 
					^{ 
						[sv setContentOffset:offset animated:YES];
					});

}
@end

@implementation WeeAppView 
-(void)onTouch:(UIControl*)view {
	[view setSelected:YES];

	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10000000), dispatch_get_current_queue(), 
		^{ 
			[[objc_getClass("SBUIController") sharedInstance] activateApplicationFromSwitcher:appl];
		});
}

-(id)initWithApplication:(SBApplication *)app{
	BOOL b1 = NO ;
	int o1, o2;
	snapshot = [app defaultImage:&b1 
				   preferredScale:1.0 / SCALE
			  originalOrientation:&o1 
			   currentOrientation:&o2
				  canUseIOSurface:YES];

	NSLog(@"%@ b = %d o1 = %d o2 = %d ref = %d", snapshot, b1, o1, o2, [snapshot retainCount]);

	appl = [app retain];

	CGFloat width, height;

	width = 320 / SCALE;
	height = 320 / SCALE;

	self = [super initWithFrame:CGRectMake(0.0, 0.0, width, height)];

	UIControl *cntrl = [[UIControl alloc] initWithFrame:CGRectMake(0 , 0, width, height)];
	cntrl.userInteractionEnabled = YES;

	[cntrl addTarget:self action:@selector(onTouch:) forControlEvents:UIControlEventTouchDown];
	[self addSubview:cntrl];
	[cntrl release];
	return self;
}

-(void)dealloc {
	[appl release];
	[super dealloc];
}

-(void)drawRect:(CGRect)rect {
	CGRect r = CGRectInset(self.bounds, 8, 8);
	[snapshot drawInRect:CGRectOffset(r, 4, 8)];
	[[UIColor whiteColor] set];
	UIFont *f  = [UIFont systemFontOfSize:10];
	CGSize size = [[appl displayName] sizeWithFont:f];
	CGFloat x = (CGRectGetWidth(self.frame) - size.width) / 2.0;

	[[appl displayName] drawInRect:CGRectMake(x, 0, self.frame.size.width, 10) 
						  withFont:f];
}
@end
