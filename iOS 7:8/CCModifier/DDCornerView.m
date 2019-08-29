//
//  DD_NoAlphaChangeImageView.m
//  
//
//  Created by David Klopp on 08.03.14.
//
//
#define kCornerRadius 4.0

#import "DDCornerView.h"
#import <QuartzCore/QuartzCore.h>

@implementation DDCornerView

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetRGBFillColor(context, 0, 0, 0, 1);
    
    // Bottom left corner
    CGContextMoveToPoint(context, rect.origin.x, rect.origin.y + rect.size.height);
    CGContextAddArc(context, rect.origin.x + kCornerRadius, rect.origin.y + rect.size.height - kCornerRadius, kCornerRadius, M_PI, M_PI / 2, 1); //STS fixed
    
    // Bottom right corner
    CGContextMoveToPoint(context, rect.origin.x + rect.size.width, rect.origin.y + rect.size.height);
    CGContextAddArc(context, rect.origin.x + rect.size.width - kCornerRadius, rect.origin.y + rect.size.height - kCornerRadius, kCornerRadius, M_PI / 2, 0.0f, 1);
    
    // Top right corner
    CGContextMoveToPoint(context, rect.origin.x + rect.size.width, rect.origin.y);
    CGContextAddArc(context, rect.origin.x + rect.size.width - kCornerRadius, rect.origin.y + kCornerRadius, kCornerRadius, 0.0f, -M_PI / 2, 1);
    
    // Top left corner
    CGContextMoveToPoint(context, rect.origin.x, rect.origin.y);
    CGContextAddArc(context, rect.origin.x + kCornerRadius, rect.origin.y + kCornerRadius, kCornerRadius, -M_PI / 2, M_PI, 1);
    
    CGContextFillPath(context);
}

@end
