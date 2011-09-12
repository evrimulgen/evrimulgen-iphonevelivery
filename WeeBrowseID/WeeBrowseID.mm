#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "BBWeeAppController-Protocol.h"

#import "Date+extra.h"
#import "Localizer.h"

extern "C" {
#import "database.h"
}

static void CGContextAddRoundRect(CGContextRef context, CGRect rect, float radius) {
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, rect.origin.x, rect.origin.y + radius);
    CGContextAddLineToPoint(context, rect.origin.x, rect.origin.y + rect.size.height - radius);
    CGContextAddArc(context, rect.origin.x + radius, rect.origin.y + rect.size.height - radius, 
        radius, M_PI, M_PI / 2, 1);
    CGContextAddLineToPoint(context, rect.origin.x + rect.size.width - radius, 
        rect.origin.y + rect.size.height);
    CGContextAddArc(context, rect.origin.x + rect.size.width - radius, 
        rect.origin.y + rect.size.height - radius, radius, M_PI / 2, 0.0f, 1);
    CGContextAddLineToPoint(context, rect.origin.x + rect.size.width, rect.origin.y + radius);
    CGContextAddArc(context, rect.origin.x + rect.size.width - radius, rect.origin.y + radius, 
        radius, 0.0f, -M_PI / 2, 1);
    CGContextAddLineToPoint(context, rect.origin.x + radius, rect.origin.y);
    CGContextAddArc(context, rect.origin.x + radius, rect.origin.y + radius, radius, 
        -M_PI / 2, M_PI, 1);
}

@interface WeeBrowseIDView : UIView {
	NSString *title;
	NSString *text1;
	NSString *text2;
	UIFont *titleFont, *labelFont;
	UIColor *titleColor, *labelColor, *borderColor;
}
-(id)initWithROWID:(int)rowid;
@end;

#define kReportWidth 200.0f
#define kReportHeight 71.0f
#define kMaxVisibleReports 100

@interface WeeBrowseIDController : NSObject <BBWeeAppController, UIScrollViewDelegate> {
	UIScrollView *scrollView;
    UIView *_view;
	uint32_t reportsIndex[kMaxVisibleReports];
	int numberOfReports;
}

+ (void)initialize;
- (UIView *)view;
-(void) loadVisibleReports;
-(void)loadReport:(int)n;

@end

@implementation WeeBrowseIDController
-(void)viewWillAppear {
	NSLog(@"%s", __FUNCTION__);
	numberOfReports = get_list_of_rowids(kMaxVisibleReports, reportsIndex);
	[self loadVisibleReports];
	[scrollView setContentSize:CGSizeMake(numberOfReports * kReportWidth, [scrollView bounds].size.height)];
	scrollView.contentOffset = CGPointMake(0.0, 0.0);

}
- (void)viewDidDisappear {
	NSLog(@"%s", __FUNCTION__);
	for (UIView *v in scrollView.subviews)  {
		[v removeFromSuperview];
	}
	numberOfReports = 0;
}

- (void)layoutScrollImages {
	WeeBrowseIDView *view = nil;
	NSArray *subviews = [scrollView subviews];
	CGFloat totalWidth = 0.0;

	// reposition all image subviews in a horizontal serial fashion
	CGFloat curXLoc = 0;
	for (view in subviews) {
		if ([view isKindOfClass:[WeeBrowseIDView class]]) {
			CGRect frame = view.frame;
			frame.origin = CGPointMake(curXLoc, 0);
			view.frame = frame;
			
			curXLoc += frame.size.width;
			totalWidth += frame.size.width;
		}
	}
	
	// set the content size so it can be scrollable
	[scrollView setContentSize:CGSizeMake(totalWidth, [scrollView bounds].size.height)];
}

+ (void)initialize {
}

- (void)dealloc {
    [_view release];
    [super dealloc];
}

- (UIView *)view {
    if (_view == nil)
    {
        _view = [[UIView alloc] initWithFrame:CGRectMake(2, 0, 316, kReportHeight)];
        
        UIImage *bg = [[UIImage imageWithContentsOfFile:@"/System/Library/WeeAppPlugins/WeeBrowseID.bundle/WeeAppBackground.png"] stretchableImageWithLeftCapWidth:5 topCapHeight:71];
        UIImageView *bgView = [[UIImageView alloc] initWithImage:bg];
        bgView.frame = CGRectMake(0, 0, 316, 71);
        [_view addSubview:bgView];
        [bgView release];

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
	}
    
    return _view;
}

- (float)viewHeight {
    return kReportHeight;
}

-(void)loadReport:(int)n {
	if (n < 0 || n >= numberOfReports) return;

	uint32_t rowid = reportsIndex[n];
	WeeBrowseIDView *v = (WeeBrowseIDView *)[scrollView viewWithTag:rowid];

	if (v == nil) {
		v = [[WeeBrowseIDView alloc] initWithROWID:rowid];
		[scrollView addSubview:v];

		CGRect frame = v.frame;
		frame.origin = CGPointMake(kReportWidth * n, 0);
		v.frame = frame;
		[v release];
	}
}

-(void) loadVisibleReports {
	int n = scrollView.contentOffset.x / kReportWidth;

	[self loadReport:n - 2];
	[self loadReport:n - 1];
	[self loadReport:n];
	[self loadReport:n + 1];
	[self loadReport:n + 2];
}

- (void)scrollViewDidScroll:(UIScrollView *)sv {
	[self loadVisibleReports];
}
@end

@implementation WeeBrowseIDView

-(void)loadReport {
	int rowid = self.tag;
	char name[64], surname[64];
    Localizer *localizer = [Localizer sharedInstance];

	NSString *number = get_address_for_rowid(rowid);
    if (convert_num_to_name([number UTF8String], name, surname) && (name[0] || surname[0])) {
        title = [[localizer getTitle:[NSString stringWithUTF8String:name]
                           surname:[NSString stringWithUTF8String:surname]] retain];
    }

	int ref, delay, status;
	time_t date;
	if (0 == get_delivery_info_for_rowid(rowid, &ref, &date, &delay, &status)) {
		NSDate *sdate = [NSDate dateWithTimeIntervalSince1970:date];
    	NSString *s = [localizer getString:@"SUBMIT"];

    	s = [s stringByReplacingOccurrencesOfString:@"%DATESPEC%" 
								withString:[localizer formatDate:sdate style:NSDateFormatterMediumStyle]];
    	s = [s stringByReplacingOccurrencesOfString:@"%TIMESPEC%" 
								withString:[localizer formatTime:sdate style:NSDateFormatterMediumStyle]];
		text1 = [s retain];

		if (status == 0) {
			NSDate *rdate = [NSDate dateWithTimeIntervalSince1970:date+delay];
    		NSString *s = [localizer getString:@"DELIVERED"];
			bool sameday = [rdate isSameDayAs:sdate];

    		s = [s stringByReplacingOccurrencesOfString:@"%DATESPEC%" 
				withString:sameday?@"":[localizer formatDate:rdate style:NSDateFormatterMediumStyle]];

    		s = [s stringByReplacingOccurrencesOfString:@"%TIMESPEC%" 
				withString:[localizer formatTime:rdate style:NSDateFormatterMediumStyle]];

			text2 = [s retain];
			borderColor = [[UIColor greenColor] retain];
		}
		else {
			NSString *s = [NSString stringWithFormat:@"STATUS_%d",status];
			s = [localizer getString:s];
			if (s == nil) {
				s = [localizer getString:@"STATUS"];
				if (s != nil) {
    				s = [s stringByReplacingOccurrencesOfString:@"%STATUS%" 
						withString:[NSString stringWithFormat:@"%d",status]];
				}
			}
			
			text2 = [s retain];
			if (status < 64)
				borderColor = [[UIColor redColor] retain];
			else
				borderColor = [[UIColor grayColor] retain];
		}
	}
}

-(void)scheduleUnload {
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5000000000LL), dispatch_get_main_queue(), ^{
			// check if view is visible
			CGRect r1 = self.frame;
			CGRect r2 = self.superview.bounds;

			if (!CGRectIntersectsRect(r1, r2)) {
				//NSLog(@"remove view with rowid %d", self.tag);
				[self removeFromSuperview];
			}
			else
				[self scheduleUnload];
		});
}

-(id) initWithROWID:(int)_rowid {
	self = [super initWithFrame:CGRectMake(0, 0, kReportWidth, kReportHeight)];
	
	self.tag = _rowid;
	[self loadReport];

	titleFont = [[UIFont systemFontOfSize:18.0] retain];
	labelFont = [[UIFont systemFontOfSize:11.0] retain];
	titleColor = [[UIColor whiteColor] retain];
	labelColor = [[UIColor yellowColor] retain];
	
	self.opaque = NO;
	[self scheduleUnload];
	return self;
}

-(void) dealloc {
	[titleColor release];
	[titleFont release];
	[labelColor release];
	[labelFont release];
	[borderColor release];
	
	[title release];
	[text1 release];
	[text2 release];

	[super dealloc];
}

-(void)drawRect:(CGRect)r {

    CGRect rect = self.bounds;
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextAddRoundRect(context, CGRectInset(self.bounds, 2.0, 2.0), 6.0);
	CGContextSetLineWidth(context, 2.0);
    CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
    CGContextSetStrokeColorWithColor(context, borderColor.CGColor);
    CGContextDrawPath(context, kCGPathFillStroke);

	CGFloat width = self.bounds.size.width;
	CGFloat margin = 4.0;

    // Draw the text
	[titleColor set];
	CGSize titleSize = [title sizeWithFont:titleFont];
    [title drawInRect:CGRectMake(margin, margin, width, titleSize.height)  
		     withFont:titleFont 
	    lineBreakMode:UILineBreakModeWordWrap 
		    alignment:UITextAlignmentCenter];

	[labelColor set];
	CGSize label1Size = [text1 sizeWithFont:labelFont];
    [text1 drawInRect:CGRectMake(margin*2, self.bounds.size.height - margin - label1Size.height * 2, width, label1Size.height)  
		     withFont:labelFont 
	    lineBreakMode:UILineBreakModeWordWrap 
		    alignment:UITextAlignmentLeft];

	CGSize label2Size = [text2 sizeWithFont:labelFont];
    [text2 drawInRect:CGRectMake(margin*2, self.bounds.size.height - margin - label1Size.height, width, label2Size.height)  
		     withFont:labelFont 
	    lineBreakMode:UILineBreakModeWordWrap 
		    alignment:UITextAlignmentLeft];
}
@end