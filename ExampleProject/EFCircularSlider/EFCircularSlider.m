//
//  EFCircularSlider.m
//  Awake
//
//  Created by Eliot Fowler on 12/3/13.
//  Copyright (c) 2013 Eliot Fowler. All rights reserved.
//

#import "EFCircularSlider.h"
#import <QuartzCore/QuartzCore.h>
#import <CoreImage/CoreImage.h>

#define ToRad(deg) 		( (M_PI * (deg)) / 180.0 )
#define ToDeg(rad)		( (180.0 * (rad)) / M_PI )
#define SQR(x)			( (x) * (x) )

@implementation EFCircularSlider {
    CGFloat radius;
    int angle;
    int fixedAngle;
    NSMutableDictionary* labelsWithPercents;
    NSArray* labelsEvenSpacing;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Defaults
        _maximumValue = 100.0f;
        _minimumValue = 0.0f;
        _currentValue = 0.0f;
        _lineWidth = 5;
        _unfilledColor = [UIColor blackColor];
        _filledColor = [UIColor redColor];
        _handleColor = _filledColor;
        _labelFont = [UIFont systemFontOfSize:10.0f];
        _snapToLabels = NO;
        _handleType = semiTransparentWhiteCircle;
        _labelColor = [UIColor redColor];
        
        angle = 0;
        radius = self.frame.size.width/2 - _lineWidth/2 - 10;
        
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}


- (void)setPercent:(double)percent
{
    _percent = percent;
    //angle = [45~-45]
    //根据比例计算angle即可
   angle =  45 - 90 * percent;
//    angle = 360 - 90 - currentAngle;
    [self setNeedsDisplay];
}

#pragma mark - drawing methods

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    //Draw the unfilled circle 画黑色线
    CGContextAddArc(ctx, self.frame.size.width/2, self.frame.size.width/2, radius, M_PI *1.25, M_PI *1.75, 0);
    [_unfilledColor setStroke];
    CGContextSetLineWidth(ctx, _lineWidth);
    CGContextSetLineCap(ctx, kCGLineCapButt);
    CGContextDrawPath(ctx, kCGPathStroke);
    
    
    //Draw the filled circle
//    if((_handleType == doubleCircleWithClosedCenter || _handleType == doubleCircleWithOpenCenter) && fixedAngle > 5) {
//        CGContextAddArc(ctx, self.frame.size.width/2  , self.frame.size.height/2, radius, 3*M_PI/2, 3*M_PI/2-ToRad(angle+3), 0);
//    } else {
    //根据旋转的角度画旋转线
    NSLog(@"%d--%f",angle,(45-angle)/90.0f);
    
    if (angle > 45 || angle < - 45) {
        [self drawHandle:ctx];
        return;
    }
    
#warning 此项目里angle为最上侧＝0开始的，瞬时针递减，计量单位不变为派。，一派  ＝ 180度 ＝ 半周
    //45度为初始，－45度为末
    
    
    //获取结束的angle
    CGFloat endPint = (angle ==0)?M_PI*1.5:3*M_PI/2-ToRad(angle);
        CGContextAddArc(ctx, self.frame.size.width/2  , self.frame.size.width/2, radius, M_PI*1.25,endPint, 0);
//    }
    [_filledColor setStroke];
    CGContextSetLineWidth(ctx, _lineWidth);
    CGContextSetLineCap(ctx, kCGLineCapButt);
    CGContextDrawPath(ctx, kCGPathStroke);
    
    //Add the labels (if necessary)
    if(labelsEvenSpacing != nil) {
        [self drawLabels:ctx];
    }
    
    //The draggable part
    [self drawHandle:ctx];
}

-(void) drawHandle:(CGContextRef)ctx{
    //画滑块
    CGContextSaveGState(ctx);
#warning important 后续自定义的slider的位置就是他
    CGPoint handleCenter =  [self pointFromAngle: angle];
    if(_handleType == semiTransparentWhiteCircle) {
        [[UIColor colorWithWhite:1.0 alpha:0.7] set];
        CGContextFillEllipseInRect(ctx, CGRectMake(handleCenter.x, handleCenter.y, _lineWidth, _lineWidth));
    } else if(_handleType == semiTransparentBlackCircle) {
        [[UIColor colorWithWhite:0.0 alpha:0.7] set];
        CGContextFillEllipseInRect(ctx, CGRectMake(handleCenter.x, handleCenter.y, _lineWidth, _lineWidth));
    } else if(_handleType == doubleCircleWithClosedCenter) {
        [_handleColor set];
        CGContextAddArc(ctx, handleCenter.x + (_lineWidth)/2, handleCenter.y + (_lineWidth)/2, _lineWidth, 0, M_PI *2, 0);
        CGContextSetLineWidth(ctx, 7);
        CGContextSetLineCap(ctx, kCGLineCapButt);
        CGContextDrawPath(ctx, kCGPathStroke);
        CGContextFillEllipseInRect(ctx, CGRectMake(handleCenter.x, handleCenter.y, _lineWidth-1, _lineWidth-1));
    } else if(_handleType == doubleCircleWithOpenCenter) {
        [_handleColor set];
        //外圈
        //原点坐标，角度.
        CGContextAddArc(ctx, handleCenter.x + (_lineWidth)/2, handleCenter.y + (_lineWidth)/2, 8, 0, M_PI *2, 0);
        CGContextSetLineWidth(ctx, 4);
        CGContextSetLineCap(ctx, kCGLineCapButt);
        CGContextDrawPath(ctx, kCGPathStroke);
        
        //内圈
        CGContextAddArc(ctx, handleCenter.x + _lineWidth/2, handleCenter.y + _lineWidth/2, _lineWidth/2, 0, M_PI *2, 0);
        CGContextSetLineWidth(ctx, 2);
        CGContextSetLineCap(ctx, kCGLineCapButt);
        CGContextDrawPath(ctx, kCGPathStroke);
    } else if(_handleType == bigCircle) {
        [_handleColor set];
        CGContextFillEllipseInRect(ctx, CGRectMake(handleCenter.x-2.5, handleCenter.y-2.5, _lineWidth+5, _lineWidth+5));
    }
    
    CGContextRestoreGState(ctx);
}

-(void) drawLabels:(CGContextRef)ctx {
    if(labelsEvenSpacing == nil || [labelsEvenSpacing count] == 0) {
        return;
    } else {
        NSDictionary *attributes = @{ NSFontAttributeName: _labelFont,
                                      NSForegroundColorAttributeName: _labelColor};
        int distanceToMove = -15;
        
        for (int i=0; i<[labelsEvenSpacing count]; i++) {
            NSString* label = [labelsEvenSpacing objectAtIndex:[labelsEvenSpacing count] - i - 1];
            CGFloat percentageAlongCircle = i/(float)[labelsEvenSpacing count];
            CGFloat degreesForLabel = percentageAlongCircle * 360;
            CGPoint closestPointOnCircleToLabel = [self pointFromAngle:degreesForLabel];
            
            CGRect labelLocation = CGRectMake(closestPointOnCircleToLabel.x, closestPointOnCircleToLabel.y, [self widthOfString:label withFont:_labelFont], [self heightOfString:label withFont:_labelFont]);
            
            CGPoint centerPoint = CGPointMake(self.frame.size.width/2, self.frame.size.width/2);
            float radiansTowardsCenter = ToRad(AngleFromNorth(centerPoint, closestPointOnCircleToLabel, NO));
            labelLocation.origin.x =  (labelLocation.origin.x + distanceToMove * cos(radiansTowardsCenter)) - labelLocation.size.width/4;
            labelLocation.origin.y = (labelLocation.origin.y + distanceToMove * sin(radiansTowardsCenter))- labelLocation.size.height/4;
            [label drawInRect:labelLocation withAttributes:attributes];
        }
    }
}

#pragma mark - UIControl functions

-(BOOL) beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    [super beginTrackingWithTouch:touch withEvent:event];
    
    return YES;
}

-(BOOL) continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    [super continueTrackingWithTouch:touch withEvent:event];
    
    //根据move的点来转角度.这样就不用担心点击不在线上的位置的坐标来移动了。
    
    CGPoint lastPoint = [touch locationInView:self];
    [self moveHandle:lastPoint];
    [self sendActionsForControlEvents:UIControlEventValueChanged];
    
    return YES;
}

-(void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event{
    [super endTrackingWithTouch:touch withEvent:event];
    if(_snapToLabels && labelsEvenSpacing != nil) {
        CGPoint bestGuessPoint;
        float minDist = 360;
        for (int i=0; i<[labelsEvenSpacing count]; i++) {
            CGFloat percentageAlongCircle = i/(float)[labelsEvenSpacing count];
            CGFloat degreesForLabel = percentageAlongCircle * 360;
            if(abs(fixedAngle - degreesForLabel) < minDist) {
                minDist = abs(fixedAngle - degreesForLabel);
                bestGuessPoint = [self pointFromAngle:degreesForLabel + 90 + 180];
            }
        }
        CGPoint centerPoint = CGPointMake(self.frame.size.width/2, self.frame.size.width/2);
        angle = floor(AngleFromNorth(centerPoint, bestGuessPoint, NO));
        _currentValue = [self valueFromAngle];
        [self setNeedsDisplay];
    }
}

-(void)moveHandle:(CGPoint)point {
    CGPoint centerPoint = CGPointMake(self.frame.size.width/2, self.frame.size.width/2);
    int currentAngle = floor(AngleFromNorth(centerPoint, point, NO));
    angle = 360 - 90 - currentAngle;
    _currentValue = [self valueFromAngle];
    if (angle > 45 || angle < - 45) {
      
        return;
    }

    [self setNeedsDisplay];
}

#pragma mark - helper functions
#warning 根据原点及转的角度来确定环的中心坐标，很有用处
-(CGPoint)pointFromAngle:(int)angleInt{
    
    //Define the Circle center
    CGPoint centerPoint = CGPointMake(self.frame.size.width/2 - _lineWidth/2, self.frame.size.width/2 - _lineWidth/2);
    
    //Define The point position on the circumference
    CGPoint result;
    //根据圆心点转22度后的坐标
    result.y = round(centerPoint.y + radius * sin(ToRad(-angleInt-90))) ;
    result.x = round(centerPoint.x + radius * cos(ToRad(-angleInt-90)));
    
    return result;
}

//根据点击的点和圆点确认角度
#warning import---- 角度为这个项目里定制转化的。
static inline float AngleFromNorth(CGPoint p1, CGPoint p2, BOOL flipped) {
    CGPoint v = CGPointMake(p2.x-p1.x,p2.y-p1.y);
    float vmag = sqrt(SQR(v.x) + SQR(v.y)), result = 0;
    v.x /= vmag;
    v.y /= vmag;
    double radians = atan2(v.y,v.x);
    result = ToDeg(radians);
    return (result >=0  ? result : result + 360.0);
}

//根据角度获取"比例值"
-(float) valueFromAngle {
    if(angle < 0) {
        _currentValue = -angle;
    } else {
        _currentValue = 270 - angle + 90;
    }
    fixedAngle = _currentValue;
    return (_currentValue*(_maximumValue - _minimumValue))/360.0f;
}

- (CGFloat) widthOfString:(NSString *)string withFont:(UIFont*)font {
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, nil];
    return [[[NSAttributedString alloc] initWithString:string attributes:attributes] size].width;
}

- (CGFloat) heightOfString:(NSString *)string withFont:(UIFont*)font {
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, nil];
    return [[[NSAttributedString alloc] initWithString:string attributes:attributes] size].height;
}

#pragma mark - public methods
-(void)setInnerMarkingLabels:(NSArray*)labels{
    labelsEvenSpacing = labels;
    [self setNeedsDisplay];
}

@end
