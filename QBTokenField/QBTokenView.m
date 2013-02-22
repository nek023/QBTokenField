/*
 Copyright (c) 2013 Katsuma Tanaka
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "QBTokenView.h"

#import "QBTokenField.h"
#import "QBToken.h"

@interface QBTokenView ()

@property (nonatomic, retain) UILabel *textLabel;

@end

@implementation QBTokenView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:CGRectMake(frame.origin.x, frame.origin.y, 25, 25)];
    
    if(self) {
        // ビューの設定
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;
        self.clearsContextBeforeDrawing = YES;
        
        // titleLabel
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(9, 4, 25 - 9 * 2, 25 - 4 * 2)];
        titleLabel.textColor = [UIColor blackColor];
        titleLabel.highlightedTextColor = [UIColor whiteColor];
        titleLabel.font = [UIFont systemFontOfSize:14];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
        
        [self addSubview:titleLabel];
        self.textLabel = titleLabel;
        [titleLabel release];
    }
    
    return self;
}

- (void)setToken:(QBToken *)token
{
    _token = [token retain];
    
    // ラベルを更新
    self.textLabel.text = token.text;
}

- (void)setHighlighted:(BOOL)highlighted
{
    _highlighted = highlighted;
    
    // ラベルをハイライトする
    self.textLabel.highlighted = highlighted;
}

- (CGSize)sizeThatFits:(CGSize)size
{
    // テキストのサイズを取得
    CGSize textSize = [self.token.text sizeWithFont:self.textLabel.font];
    
    return CGSizeMake(MAX(textSize.width + 9 * 2, 25), 25);
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGSize size = self.bounds.size;
    CGFloat cornerRadius = 12;
    
    // 線
    CGMutablePathRef borderPath = CGPathCreateMutable();
    
    CGPathMoveToPoint(borderPath, NULL, 0, cornerRadius);
    CGPathAddArcToPoint(borderPath, NULL, 0, 0, cornerRadius, 0, cornerRadius);
    
    CGPathAddLineToPoint(borderPath, NULL, size.width - cornerRadius, 0);
    CGPathAddArcToPoint(borderPath, NULL, size.width, 0, size.width, cornerRadius, cornerRadius);
    
    CGPathAddLineToPoint(borderPath, NULL, size.width, size.height - cornerRadius);
    CGPathAddArcToPoint(borderPath, NULL, size.width, size.height, size.width - cornerRadius, size.height, cornerRadius);
    
    CGPathAddLineToPoint(borderPath, NULL, cornerRadius, size.height);
    CGPathAddArcToPoint(borderPath, NULL, 0, size.height, 0, size.height - cornerRadius, cornerRadius);
    
    CGPathCloseSubpath(borderPath);
    
    // 線のグラデーション
    CGContextAddPath(context, borderPath);
    CGContextClip(context);
    
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGFloat components[8];
    if(self.highlighted) {
        components[0] = 0.204; components[1] = 0.455; components[2] = 0.867; components[3] = 1.0;
        components[4] = 0.094; components[5] = 0.267; components[6] = 0.863; components[7] = 1.0;
    } else {
        components[0] = 0.643; components[1] = 0.741; components[2] = 0.910; components[3] = 1.0;
        components[4] = 0.475; components[5] = 0.529; components[6] = 0.831; components[7] = 1.0;
    }
    size_t count = sizeof(components) / (sizeof(CGFloat) * 4);
    
    CGGradientRef gradientRef = CGGradientCreateWithColorComponents(colorSpaceRef, components, NULL, count);
    
    CGPoint startPoint = CGPointMake(0, 0);
    CGPoint endPoint = CGPointMake(0, size.height);
    
    CGContextDrawLinearGradient(context, gradientRef, startPoint, endPoint, kCGGradientDrawsAfterEndLocation);
    
    CGGradientRelease(gradientRef);
    CGColorSpaceRelease(colorSpaceRef);
    
    CGPathRelease(borderPath);
    
    // 表面
    CGMutablePathRef bodyPath = CGPathCreateMutable();
    
    CGPathMoveToPoint(bodyPath, NULL, 1, cornerRadius);
    CGPathAddArcToPoint(bodyPath, NULL, 1, 1, cornerRadius, 1, cornerRadius - 1);
    
    CGPathAddLineToPoint(bodyPath, NULL, size.width - cornerRadius, 1);
    CGPathAddArcToPoint(bodyPath, NULL, size.width - 1, 1, size.width - 1, cornerRadius, cornerRadius - 1);
    
    CGPathAddLineToPoint(bodyPath, NULL, size.width - 1, size.height - cornerRadius);
    CGPathAddArcToPoint(bodyPath, NULL, size.width - 1, size.height - 1, size.width - cornerRadius, size.height - 1, cornerRadius - 1);
    
    CGPathAddLineToPoint(bodyPath, NULL, cornerRadius, size.height - 1);
    CGPathAddArcToPoint(bodyPath, NULL, 1, size.height - 1, 1, size.height - cornerRadius, cornerRadius - 1);
    
    CGPathCloseSubpath(bodyPath);
    
    // 表面のグラデーション
    CGContextAddPath(context, bodyPath);
    CGContextClip(context);
    
    CGColorSpaceRef bodyColorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGFloat bodyComponents[8];
    if(self.highlighted) {
        bodyComponents[0] = 0.322; bodyComponents[1] = 0.573; bodyComponents[2] = 0.988; bodyComponents[3] = 1.0;
        bodyComponents[4] = 0.212; bodyComponents[5] = 0.384; bodyComponents[6] = 0.984; bodyComponents[7] = 1.0;
    } else {
        bodyComponents[0] = 0.867; bodyComponents[1] = 0.906; bodyComponents[2] = 0.969; bodyComponents[3] = 1.0;
        bodyComponents[4] = 0.745; bodyComponents[5] = 0.816; bodyComponents[6] = 0.941; bodyComponents[7] = 1.0;
    }
    size_t bodyCount = sizeof(bodyComponents) / (sizeof(CGFloat) * 4);
    
    CGGradientRef bodyGradientRef = CGGradientCreateWithColorComponents(bodyColorSpaceRef, bodyComponents, NULL, bodyCount);
    
    CGPoint bodyStartPoint = CGPointMake(0, 1);
    CGPoint bodyEndPoint = CGPointMake(0, size.height - 1);
    
    CGContextDrawLinearGradient(context, bodyGradientRef, bodyStartPoint, bodyEndPoint, kCGGradientDrawsAfterEndLocation);
    
    CGGradientRelease(bodyGradientRef);
    CGColorSpaceRelease(bodyColorSpaceRef);
    
    CGPathRelease(bodyPath);
}

- (void)dealloc
{
    [_token release];
    [_textLabel release];
    
    [super dealloc];
}


#pragma mark - UIResponder

- (BOOL)becomeFirstResponder
{
    // ハイライト
    self.highlighted = YES;
    
    // 再描画
    [self setNeedsDisplay];
    
    // スクロール
    [self.tokenField scrollToToken:self.token];
    
    return [super becomeFirstResponder];
}

- (BOOL)resignFirstResponder
{
    // ハイライトを解除
    self.highlighted = NO;
    
    // 再描画
    [self setNeedsDisplay];
    
    return [super resignFirstResponder];
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (UIResponder *)nextResponder
{
    NSUInteger index = [self.tokenField indexForToken:self.token];
    
    if(index < ([self.tokenField numberOfTokens] - 1)) {
        QBTokenView *tokenView = [self.tokenField tokenViewAtIndex:(index + 1)];
        
        return tokenView;
    } else {
        return [self.tokenField textField];
    }
}


#pragma mark - UIKeyInput

- (void)insertText:(NSString *)text
{
    // タブキーが押されたかどうか
    if([text isEqualToString:@"\t"]) {
        // 次のコントロールにフォーカスを移す
        [[self nextResponder] becomeFirstResponder];
    } else {
        // 自分を削除する
        [self.tokenField removeToken:self.token];
        
        // テキストをセット
        self.tokenField.text = text;
    }
    
    return;
}

- (void)deleteBackward
{
    // 自分を削除する
    [self.tokenField removeToken:self.token];
}

- (BOOL)hasText
{
    return NO;
}

@end
