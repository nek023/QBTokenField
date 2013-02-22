/*
 Copyright (c) 2013 Katsuma Tanaka
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "QBTokenField.h"

#import "QBTokenView.h"
#import "QBToken.h"

NSString * const zeroWidthSpace = @"\u200B";
NSString * const zeroWidthJoiner = @"\u200D";

@interface QBTokenField ()

@property (nonatomic, retain) UIScrollView *scrollView;
@property (nonatomic, retain) UITextField *textField;

@property (nonatomic, retain) NSMutableArray *tokenViews;
@property (nonatomic, retain) NSMutableArray *tokenViewFrames;

@property (nonatomic, assign) CGPoint origin;
@property (nonatomic, assign) NSUInteger insertionIndex;

- (void)updateAnimated:(BOOL)animated;
- (NSInteger)indexForInsertionPoint:(CGPoint)point;

- (void)handleTap:(UITapGestureRecognizer *)gestureRecognizer;
- (void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer;

@end

@implementation QBTokenField

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, 43)];
    
    if(self) {
        // プロパティの設定
        self.tokenViews = [NSMutableArray array];
        self.tokenViewFrames = [NSMutableArray array];
        
        // ビューの設定
        self.backgroundColor = [UIColor whiteColor];
        self.clipsToBounds = NO;
        
        // scrollView
        UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
        scrollView.contentSize = self.bounds.size;
        scrollView.backgroundColor = [UIColor whiteColor];
        scrollView.clipsToBounds = NO;
        scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        [self addSubview:scrollView];
        self.scrollView = scrollView;
        [scrollView release];
        
        // textField
        UITextField *textField = [[UITextField alloc] initWithFrame:self.bounds];
        textField.delegate = self;
        textField.text = zeroWidthSpace;
        textField.font = [UIFont systemFontOfSize:14];
        textField.backgroundColor = [UIColor clearColor];
        textField.autoresizingMask = UIViewAutoresizingNone;
        [textField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
        
        [self.scrollView addSubview:textField];
        self.textField = textField;
        [textField release];
        
        // ビューを再配置
        [self updateAnimated:NO];
    }
    
    return self;
}

- (NSString *)text
{
    return self.textField.text;
}

- (void)setText:(NSString *)text
{
    self.textField.text = [zeroWidthSpace stringByAppendingString:text];
}

- (void)dealloc
{
    [_scrollView release];
    [_textField release];
    [_tokenViews release];
    [_tokenViewFrames release];
    
    [super dealloc];
}


#pragma mark - Private Methods

- (void)updateAnimated:(BOOL)animated
{
    // 矩形情報を全て削除
    [self.tokenViewFrames removeAllObjects];
    
    // 位置を計算して再配置
    CGPoint offset = CGPointMake(16, 0);
    
    for(QBTokenView *tokenView in self.tokenViews) {
        CGSize sizeThatFits = [tokenView sizeThatFits:CGSizeZero];
        CGRect tokenViewFrame;
        
        if(offset.x + sizeThatFits.width > self.bounds.size.width - 16 * 2) {
            offset = CGPointMake(16, offset.y + (25 + 5 * 2));
        }
        
        tokenViewFrame = CGRectMake(offset.x, offset.y + (43 - sizeThatFits.height) / 2, MIN(sizeThatFits.width, self.bounds.size.width - 16 * 2), sizeThatFits.height);
        offset.x = offset.x + sizeThatFits.width + 6;
        
        [self.tokenViewFrames addObject:[NSValue valueWithCGRect:tokenViewFrame]];
        
        if(!tokenView.dragging) {
            CGFloat duration = (animated) ? 0.2 : 0;
            
            [UIView animateWithDuration:duration animations:^{
                tokenView.frame = tokenViewFrame;
            }];
        }
    }
    
    // テキストフィールドを再配置
    CGSize textFieldSize = CGSizeMake(MAX(60, self.bounds.size.width - offset.x - 16), self.textField.font.lineHeight);
    
    if(offset.x + textFieldSize.width > self.bounds.size.width - 16) {
        textFieldSize.width = self.bounds.size.width - 16 * 2;
        offset = CGPointMake(16, offset.y + (25 + 5 * 2));
    }
    
    self.textField.frame = CGRectMake(offset.x, offset.y + (43 - textFieldSize.height) / 2, textFieldSize.width, textFieldSize.height);
    
    // 自分をリサイズ
    CGRect frame = self.frame;
    frame.size.height = offset.y + 43;
    
    if([self.delegate respondsToSelector:@selector(tokenField:shouldChangeHeight:)]) {
        if([self.delegate tokenField:self shouldChangeHeight:frame.size.height]) {
            self.frame = frame;
        }
    } else {
        self.frame = frame;
    }
    
    // contentSizeを変更
    self.scrollView.contentSize = CGSizeMake(self.bounds.size.width, offset.y + 43);
    
    // テキストフィールドの場所までスクロール
    [self.scrollView scrollRectToVisible:CGRectMake(0, offset.y, self.bounds.size.width, 43) animated:YES];
}

- (NSInteger)indexForInsertionPoint:(CGPoint)point
{
    NSInteger index = 0;
    
    // 初期最小距離
    CGRect firstTokenViewFrame = [[self.tokenViewFrames objectAtIndex:index] CGRectValue];
    CGFloat minimumDistance = sqrt(pow(firstTokenViewFrame.origin.x - point.x, 2) + pow(firstTokenViewFrame.origin.y - point.y, 2));
    
    // 一番近いトークンとの位置関係で挿入先インデックスを決定
    for(NSUInteger i = 0; i < self.tokenViewFrames.count; i++) {
        CGRect tokenViewFrame = [[self.tokenViewFrames objectAtIndex:i] CGRectValue];
        
        CGFloat distance = sqrt(pow(tokenViewFrame.origin.x - point.x, 2) + pow(tokenViewFrame.origin.y - point.y, 2));
        
        if(distance < minimumDistance) {
            minimumDistance = distance;
            
            CGPoint center = CGPointMake(CGRectGetMidX(tokenViewFrame), CGRectGetMidY(tokenViewFrame));
            
            index = (point.x < center.x) ? i : i + 1;
        }
    }
    
    return index;
}


#pragma mark - Gestures

- (void)handleTap:(UITapGestureRecognizer *)gestureRecognizer
{
    QBTokenView *tokenView = (QBTokenView *)gestureRecognizer.view;
    
    [tokenView becomeFirstResponder];
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
    CGPoint point = [gestureRecognizer locationInView:self];
    QBTokenView *tokenView = (QBTokenView *)gestureRecognizer.view;
    
    switch(gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
        {
            tokenView.dragging = YES;
            
            // ビューを最前面にする
            [self.scrollView bringSubviewToFront:tokenView];
            
            // タッチ位置を保存する
            CGPoint pointInTokenView = [gestureRecognizer locationInView:tokenView];
            self.origin = pointInTokenView;
            self.insertionIndex = [self indexForToken:tokenView.token];
            
            // フォーカスを移す
            [tokenView becomeFirstResponder];
            
            // 影をつける
            tokenView.layer.shadowOpacity = 0.5;
            tokenView.layer.shadowOffset = CGSizeMake(0, 3);
            tokenView.layer.shadowColor = [[UIColor blackColor] CGColor];
            tokenView.layer.shadowRadius = 3;
            
            // アニメーション
            [UIView animateWithDuration:0.2 animations:^{
                tokenView.transform = CGAffineTransformMakeScale(1.3, 1.3);
                tokenView.alpha = 0.8;
            }];
        }
            break;
        case UIGestureRecognizerStateChanged:
        {
            // ビューを移動する
            CGRect frame = tokenView.frame;
            frame.origin.x = point.x - self.origin.x;
            frame.origin.y = point.y - self.origin.y;
            tokenView.frame = frame;
            
            NSInteger insertionIndex = [self indexForInsertionPoint:point];
            
            if(self.insertionIndex != insertionIndex) {
                self.insertionIndex = insertionIndex;
                
                // すぐに入れ替えのアニメーションを開始すると動きがおかしくなるので, 少し遅れて開始するようにする
                double delayInSeconds = 0.2;
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
                    // 配列の要素の順番を入れ替える
                    NSUInteger index = [self indexForToken:tokenView.token];
                    NSUInteger newIndex = (index < insertionIndex) ? (insertionIndex - 1) : insertionIndex;
                    
                    [self.tokenViews removeObjectAtIndex:index];
                    [self.tokenViews insertObject:tokenView atIndex:newIndex];
                    
                    CGRect tokenViewFrame = [[self.tokenViewFrames objectAtIndex:index] CGRectValue];
                    [self.tokenViewFrames removeObjectAtIndex:index];
                    [self.tokenViewFrames insertObject:[NSValue valueWithCGRect:tokenViewFrame] atIndex:newIndex];
                    
                    // 再配置
                    [self updateAnimated:YES];
                });
            }
        }
            break;
        case UIGestureRecognizerStateEnded:
        {
            tokenView.dragging = NO;
            
            // 影を消す
            tokenView.layer.shadowOpacity = 0;
            
            // アニメーション
            [UIView animateWithDuration:0.2 animations:^{
                tokenView.transform = CGAffineTransformIdentity;
                tokenView.alpha = 1.0;
                
                tokenView.frame = [[self.tokenViewFrames objectAtIndex:[self indexForToken:tokenView.token]] CGRectValue];
            } completion:^(BOOL finished) {
                // テキストフィールドにフォーカスを移す
                [self.textField becomeFirstResponder];
            }];
        }
            break;
        default:
            break;
    }
}


#pragma mark - Token Management

- (NSUInteger)numberOfTokens
{
    return self.tokenViews.count;
}

- (void)addToken:(QBToken *)token animated:(BOOL)animated
{
    [self insertToken:token atIndex:self.tokenViews.count animated:animated];
}

- (void)insertToken:(QBToken *)token atIndex:(NSUInteger)index animated:(BOOL)animated
{
    // アイテムを追加
    QBTokenView *tokenView = [[QBTokenView alloc] initWithFrame:CGRectMake(0, 0, 25, 25)];
    tokenView.token = token;
    tokenView.tokenField = self;
    
    if(animated) {
        tokenView.alpha = 0;
    }
    
    // ジェスチャーを設定
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [tokenView addGestureRecognizer:tapGestureRecognizer];
    [tapGestureRecognizer release];
    
    UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    longPressGestureRecognizer.minimumPressDuration = 0.2;
    [tokenView addGestureRecognizer:longPressGestureRecognizer];
    [longPressGestureRecognizer release];
    
    // ビューに追加
    [self.scrollView addSubview:tokenView];
    [self.tokenViews insertObject:tokenView atIndex:index];
    [tokenView release];
    
    // 再配置
    [self updateAnimated:NO];
    
    // アニメーション
    if(animated) {
        [UIView animateWithDuration:0.2 animations:^{
            tokenView.alpha = 1;
        }];
    }
}

- (void)removeTokenAtIndex:(NSUInteger)index
{
    // ビューから削除
    QBTokenView *tokenView = [self.tokenViews objectAtIndex:index];
    [tokenView removeFromSuperview];
    
    // 配列から削除
    [self.tokenViews removeObjectAtIndex:index];
    
    // 再配置
    [self updateAnimated:NO];
    
    // テキストフィールドにフォーカスを移す
    [self.textField becomeFirstResponder];
}

- (void)removeToken:(QBToken *)token
{
    [self removeTokenAtIndex:[self indexForToken:token]];
}

- (NSInteger)indexForToken:(QBToken *)token
{
    NSInteger index = -1;
    
    for(NSUInteger i = 0; i < self.tokenViews.count; i++) {
        QBTokenView *tokenView = [self.tokenViews objectAtIndex:i];
        
        if([token isEqual:tokenView.token]) {
            index = i;
            
            break;
        }
    }
    
    return index;
}

- (QBToken *)tokenAtIndex:(NSUInteger)index
{
    QBTokenView *tokenView = [self.tokenViews objectAtIndex:index];
    
    return tokenView.token;
}

- (QBTokenView *)tokenViewAtIndex:(NSUInteger)index
{
    QBTokenView *tokenView = [self.tokenViews objectAtIndex:index];
    
    return tokenView;
}

- (void)scrollToToken:(QBToken *)token
{
    [self scrollToTokenAtIndex:[self indexForToken:token]];
}

- (void)scrollToTokenAtIndex:(NSUInteger)index
{
    QBTokenView *tokenView = [self.tokenViews objectAtIndex:index];
    
    // テキストフィールドの場所までスクロール
    [self.scrollView scrollRectToVisible:CGRectMake(0, tokenView.frame.origin.y - 9, self.bounds.size.width, 43) animated:YES];
}

- (UITextField *)textField
{
    return _textField;
}


#pragma mark - UITextFieldDelegate

- (void)textFieldDidChange:(UITextField *)textField
{
    if(![textField.text hasPrefix:zeroWidthSpace]) {
        textField.text = [zeroWidthSpace stringByAppendingString:textField.text];
        
        if(self.tokenViews.count > 0) {
            // トークンにフォーカスを移す
            QBTokenView *tokenView = (QBTokenView *)[self.tokenViews lastObject];
            [tokenView becomeFirstResponder];
        }
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSString *text = [textField.text substringFromIndex:1];
    textField.text = zeroWidthSpace;
    
    if(text.length > 0) {
        // トークンを追加
        QBToken *token = [QBToken tokenWithText:text];
        
        [self addToken:token animated:YES];
    }
    
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    NSString *text = [textField.text substringFromIndex:1];
    textField.text = zeroWidthSpace;
    
    if(text.length > 0) {
        // トークンを追加
        QBToken *token = [QBToken tokenWithText:text];
        
        [self addToken:token animated:YES];
    }
}

@end
