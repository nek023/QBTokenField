/*
 Copyright (c) 2013 Katsuma Tanaka
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@class QBTokenField;
@class QBTokenView;
@class QBToken;

@protocol QBTokenFieldDelegate <NSObject>

@optional
- (BOOL)tokenField:(QBTokenField *)tokenField shouldChangeHeight:(CGFloat)height;

@end

@interface QBTokenField : UIView <UITextFieldDelegate>

@property (nonatomic, assign) id<QBTokenFieldDelegate> delegate;
@property (nonatomic, copy) NSString *text;

- (NSUInteger)numberOfTokens;
- (void)addToken:(QBToken *)token animated:(BOOL)animated;
- (void)insertToken:(QBToken *)token atIndex:(NSUInteger)index animated:(BOOL)animated;
- (void)removeTokenAtIndex:(NSUInteger)index;
- (void)removeToken:(QBToken *)token;
- (NSInteger)indexForToken:(QBToken *)token;
- (QBToken *)tokenAtIndex:(NSUInteger)index;
- (QBTokenView *)tokenViewAtIndex:(NSUInteger)index;
- (void)scrollToToken:(QBToken *)token;
- (void)scrollToTokenAtIndex:(NSUInteger)index;

- (UITextField *)textField;

@end
