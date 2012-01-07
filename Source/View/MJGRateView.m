//
//  MJGRateView.m
//  MJGFoundation
//
//  Created by Matt Galloway on 03/01/2012
//  Copyright 2012 Matt Galloway. All rights reserved.
//

#import "MJGRateView.h"

@interface MJGRateView ()
@property (nonatomic, strong) UIImage *onImage;
@property (nonatomic, strong) UIImage *halfImage;
@property (nonatomic, strong) UIImage *offImage;

- (void)setupInstance;

- (UIImage*)createMaskForRect:(CGRect)rect cutLeftSide:(BOOL)cutLeftSide;
- (void)drawHalfImage:(UIImage*)lhs otherImage:(UIImage*)rhs atRect:(CGRect)drawRect;

- (CGFloat)getTappedBucket:(CGPoint)touchPoint;
- (void)handleTapEventAtLocation:(CGPoint)location;
@end

@implementation MJGRateView

@synthesize max, value, allowEditing, delegate;
@synthesize onImage, halfImage, offImage;

#pragma mark - Custom Accessors

- (void)setMax:(NSInteger)inMax {
    if (inMax != max) {
        max = inMax;
        value = MIN(value, (CGFloat)max);
        [self setNeedsDisplay];
    }
}

- (void)setValue:(CGFloat)inValue {
    value = inValue;
    [self setNeedsDisplay];
}

- (void)setAllowEditing:(BOOL)inAllowEditing {
    allowEditing = inAllowEditing;
    self.userInteractionEnabled = allowEditing;
}

- (void)setOnImage:(UIImage*)inOnImage offImage:(UIImage*)inOffImage {
    self.onImage = inOnImage;
    self.offImage = inOffImage;
    [self setNeedsDisplay];
}

- (void)setOnImage:(UIImage*)inOnImage halfImage:(UIImage*)inHalfImage offImage:(UIImage*)inOffImage {
    self.onImage = inOnImage;
    self.halfImage = inHalfImage;
    self.offImage = inOffImage;
    [self setNeedsDisplay];
}


#pragma mark -

- (void)setupInstance {
    onImage = [UIImage imageNamed:@"star_on.png"];
    halfImage = nil;
    offImage = [UIImage imageNamed:@"star_off.png"];
    
    max = 5;
    value = 1.0;
    allowEditing = YES;
    
    self.userInteractionEnabled = YES;
    self.backgroundColor = [UIColor clearColor];
}

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self setupInstance];
    }
    return self;
}

- (void)awakeFromNib {
    [self setupInstance];
}


#pragma mark - Drawing Code

- (UIImage*)createMaskForRect:(CGRect)rect cutLeftSide:(BOOL)cutLeftSide {
    CGFloat w = rect.size.width;
    CGFloat h = rect.size.height;
    
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
	CGContextRef context = CGBitmapContextCreate(NULL, 
                                                 w, 
                                                 h, 
                                                 8, 
                                                 0, 
                                                 colorSpace, 
                                                 kCGImageAlphaNone);
	
	CGContextTranslateCTM(context, 0, h);
	CGContextScaleCTM(context, 1, -1);
	
	if(cutLeftSide) {
        CGContextSetRGBFillColor(context, 0, 0, 0, 1);
    } else {
        CGContextSetRGBFillColor(context, 1, 1, 1, 1);
    }
	CGContextFillRect(context, CGRectMake(0, 0, w/2.0f, h));
	
	if(cutLeftSide) {
        CGContextSetRGBFillColor(context, 1, 1, 1, 1);
    } else {
        CGContextSetRGBFillColor(context, 0, 0, 0, 1);
    }
	CGContextFillRect(context, CGRectMake(w/2.0f, 0, w/2.0f, h));
	
	CGImageRef theCGImage = CGBitmapContextCreateImage(context);
	CGContextRelease(context);
	CGColorSpaceRelease(colorSpace);
	
    UIImage *retImage = [UIImage imageWithCGImage:theCGImage];
    CFRelease(theCGImage);
    
	return retImage;
}

- (void)drawHalfImage:(UIImage*)lhs otherImage:(UIImage*)rhs atRect:(CGRect)drawRect {
	UIImage *rightSideMask = [self createMaskForRect:drawRect cutLeftSide:YES];
	UIImage *leftSideMask  = [self createMaskForRect:drawRect cutLeftSide:NO];
	
	CGImageRef cuttedLeftImage  = CGImageCreateWithMask(lhs.CGImage, leftSideMask.CGImage);
	CGImageRef cuttedRightImage = CGImageCreateWithMask(rhs.CGImage, rightSideMask.CGImage);
	
	[[UIImage imageWithCGImage:cuttedLeftImage] drawInRect:drawRect];
	[[UIImage imageWithCGImage:cuttedRightImage] drawInRect:drawRect];
    
    CFRelease(cuttedLeftImage);
    CFRelease(cuttedRightImage);
}

- (void)drawRect:(CGRect)rect {
    CGSize imageSize = onImage.size;
    CGFloat cellWidth = rect.size.width / (CGFloat)max;
    CGFloat cellHeight = rect.size.height;
    CGFloat cellAspect = imageSize.width / imageSize.height;
    
    CGFloat cellWidthFromAspect = cellHeight * cellAspect;
    CGFloat cellHeightFromAspect = cellWidth / cellAspect;
    
    CGFloat imgWidth, imgHeight;
    if (cellWidth <= cellWidthFromAspect) {
        imgWidth = cellWidth;
        imgHeight = cellHeightFromAspect;
    } else {
        imgWidth = cellWidthFromAspect;
        imgHeight = cellHeight;
    }
    
    for (int i=0; i<max; i++) {
        int x = (int)( floorf((cellWidth * (CGFloat)i) + ((cellWidth - imgWidth) / 2.0f)) );
        int y = (int)( floorf((cellHeight - imgHeight) / 2.0f) );
        
        CGRect starRect = CGRectMake(x, y, imgWidth, imgHeight);
        if (CGRectIntersectsRect(starRect, rect)) {
            if (value >= (i+1)) {
                [onImage drawInRect:starRect];
            } else if ((value+0.5) >= (i+1)) {
                if (halfImage) {
                    [halfImage drawInRect:starRect];
                } else {
                    [self drawHalfImage:onImage otherImage:offImage atRect:starRect];
                }
            } else {
                [offImage drawInRect:starRect];
            }
        }
    }
}


#pragma mark - Touch Handling

- (CGFloat)getTappedBucket:(CGPoint)touchPoint {
    float fraction = (touchPoint.x / self.frame.size.width);
    int bucket = (fraction * max * 2) + 1;
    CGFloat ret = (float)bucket / 2.0;
    ret = MIN(ret, (CGFloat)max);
    ret = MAX(ret, 0.0f);
    return ret;
}

- (void)handleTapEventAtLocation:(CGPoint)location {
    if (!allowEditing) {
        return;
    }
    
    CGFloat newValue = [self getTappedBucket:location];
    if (value == newValue) {
        return;
    }
    
    value = newValue;
    [self setNeedsDisplay];
    
    if ([delegate respondsToSelector:@selector(rateView:changedValueTo:)]) {
        [delegate rateView:self changedValueTo:newValue];
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint lastLocation = [touch locationInView:self];
    [self handleTapEventAtLocation:lastLocation];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint lastLocation = [touch locationInView:self];
    [self handleTapEventAtLocation:lastLocation];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint lastLocation = [touch locationInView:self];
    [self handleTapEventAtLocation:lastLocation];
}

@end