//
//  SSRollingButtonScrollView.m
//  RollingScrollView
//
//  Created by Shawn Seals on 12/27/13.
//  Copyright (c) 2013 Shawn Seals. All rights reserved.
//

#import "RollingScrollView.h"

#define SCREENWIDTH [[UIScreen mainScreen] bounds].size.width
#define SLIDE_INTERVAL 3.5f

@interface RollingScrollView()
{
    BOOL _viewsInitialLoad;

    NSInteger _rightMostVisibleButtonIndex;
    NSInteger _leftMostVisibleButtonIndex;

    NSInteger _topMostVisibleButtonIndex;
    NSInteger _bottomMostVisibleButtonIndex;

    NSInteger _scrollViewSelectedIndex;
    CGPoint _lastOffset;
    NSTimeInterval _lastTimeCapture;
    CGFloat _scrollVelocity;
}
@property (nonatomic, strong) UIButton *leftbutton;
@property (nonatomic, strong) UIButton *centerbutton;
@property (nonatomic, strong) UIButton *rightbutton;

@property (nonatomic, strong) NSMutableArray *buttons;
@property (nonatomic, strong) NSMutableArray *buttonTitles;
@property (nonatomic, strong) NSMutableArray *visibleButtons;
@property (nonatomic, strong) UIView *containerView;

@property (nonatomic, assign) NSTimer *timer;

@end

@implementation RollingScrollView

#pragma mark - lifecycle

- (id)initWithDelegate:(id<RollingScrollViewDelegate>)delegate  frame:(CGRect)frame
{
    if (self = [super init])
    {
        _viewsInitialLoad = YES;

        self.frame = frame;
        self.contentSize = CGSizeMake(self.frame.size.width, self.frame.size.height);

        self.buttons = [NSMutableArray array];
        self.buttonTitles = [NSMutableArray array];
        self.visibleButtons = [NSMutableArray array];
        self.containerView = [[UIView alloc] init];
        self.centerbutton = [[UIButton alloc] init];

        self.fixedButtonWidth = SCREENWIDTH/3;
        self.fixedButtonHeight = self.frame.size.height;
        self.spacingBetweenButtons = 0.0f;
        self.notCenterButtonBackgroundColor = [UIColor clearColor];
        self.centerButtonBackgroundColor = [UIColor clearColor];
        self.notCenterButtonBackgroundImage = nil;
        self.centerButtonBackgroundImage = nil;
        self.buttonNotCenterFont = [UIFont systemFontOfSize:16];
        self.buttonCenterFont = [UIFont boldSystemFontOfSize:20];
        self.notCenterButtonTextColor = [UIColor grayColor];
        self.centerButtonTextColor = [UIColor orangeColor];
        self.stopOnCenter = YES;
        self.centerPushedButtons = YES;

        [self setShowsHorizontalScrollIndicator:NO];
        [self setShowsVerticalScrollIndicator:NO];

        self.RollingScrollViewDelegate = delegate;

        self.delegate = self;
        self.scrollEnabled = YES;
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if ([self.buttonTitles count] > 1)
    {
        [self recenterIfNecessary];
        [self tileContentInVisibleBounds];
        [self configureCenterButton:[self getCenterButton]];

        if (_viewsInitialLoad)
        {
            [self configureCenterButton:self.buttons[self.selectedIndex]];
            [self moveButtonToViewCenter:self.centerbutton animated:NO];
            [self tileContentInVisibleBounds];
            _viewsInitialLoad = NO;
        }
    }
}


#pragma mark - public method

- (void)createButtonArrayWithButtonTitles:(NSArray *)titles
{
    self.buttonTitles = [NSMutableArray arrayWithArray:titles];
    self.buttons = [NSMutableArray array];

    [self setContentSizeAndButtonContainerViewFrame];

    if(titles.count > 1)
    {
        CGFloat x = 0.0f;
        while (x <= self.frame.size.width * 2)
        {
            for(int i = 0; i<titles.count; i++)
            {
                UIButton *button = [self createAndConfigureNewButtonWithTitle:titles[i]];
                [button setFrame:CGRectMake(x, 0, self.fixedButtonWidth, self.fixedButtonHeight)];
                [button addTarget:self action:@selector(scrollViewButtonPushed:) forControlEvents:UIControlEventTouchUpInside];
                [button setTag:i];
                [self.buttons addObject:button];

                x += self.fixedButtonWidth + self.spacingBetweenButtons;
            }
        }
        self.centerbutton = self.buttons[0];
        [self addSubview:self.containerView];
        [self moveButtonToViewCenter:self.centerbutton animated:YES];
    }
    else
    {
        self.scrollEnabled = NO;

        UIButton *button = [self createAndConfigureNewButtonWithTitle:titles[0]];
        [button setFrame:CGRectMake(0, 0, self.fixedButtonWidth, self.fixedButtonHeight)];
        [button addTarget:self action:@selector(scrollViewButtonPushed:) forControlEvents:UIControlEventTouchUpInside];

        [self.containerView addSubview:button];
        [self addSubview:self.containerView];
    }
}

- (void)createButtonArraywithImageUrls:(NSArray *)urls
{
    self.buttonTitles = [NSMutableArray arrayWithArray:urls];
    self.buttons = [NSMutableArray array];

    [self setContentSizeAndButtonContainerViewFrame];

    if(urls.count > 1)
    {
        CGFloat x = 0.0f;
        while (x <= self.frame.size.width * 2)
        {
            for(int i = 0; i<urls.count; i++)
            {
                UIButton *button = [self createAndConfigureNewButtonWithUrl:urls[i]];
                [button setFrame:CGRectMake(x, 0, self.fixedButtonWidth, self.fixedButtonHeight)];
                [button addTarget:self action:@selector(scrollViewButtonPushed:) forControlEvents:UIControlEventTouchUpInside];
                [button setTag:i];
                [self.buttons addObject:button];

                x += self.fixedButtonWidth + self.spacingBetweenButtons;
            }
        }
        [self addSubview:self.containerView];
        [self moveButtonToViewCenter:self.centerbutton animated:YES];
    }
    else
    {
        self.scrollEnabled = NO;

        UIButton *button = [self createAndConfigureNewButtonWithUrl:urls[0]];
        [button setFrame:CGRectMake(0, 0, self.fixedButtonWidth, self.fixedButtonHeight)];
        [button addTarget:self action:@selector(scrollViewButtonPushed:) forControlEvents:UIControlEventTouchUpInside];
        [self.containerView addSubview:button];
        [self addSubview:self.containerView];
    }
}

- (void)goRight
{
    if(self.rightbutton)
        [self scrollViewButtonPushed:self.rightbutton isSideButton:YES];
}

- (void)goLeft
{
    if(self.leftbutton)
        [self scrollViewButtonPushed:self.leftbutton isSideButton:YES];
}

- (void)slideshowStart
{
    if(self.buttonTitles.count > 1)
        self.timer = [NSTimer scheduledTimerWithTimeInterval:SLIDE_INTERVAL target:self selector:@selector(goLeft) userInfo:nil repeats:YES];
}

- (void)slideshowStop
{
    [self.timer invalidate];
    self.timer = nil;
}

- (void)setSelectedIndex:(int)selectedIndex
{
    if (self.buttons.count < 1)
        return;
    
    [self configureCenterButton:self.buttons[selectedIndex]];
    [self moveButtonToViewCenter:self.buttons[selectedIndex] animated:NO];
}


#pragma mark - private method

- (void)setContentSizeAndButtonContainerViewFrame
{
    if(self.buttonTitles.count < 2)
    {
        self.contentSize = CGSizeMake(self.fixedButtonWidth, self.frame.size.height);
        self.scrollEnabled = NO;
    }
    else
        self.contentSize = CGSizeMake(5000, self.frame.size.height);
    self.containerView.frame = CGRectMake(0, 0, self.contentSize.width, self.contentSize.height);

    [self addSubview:self.containerView];
}

- (UIButton *)createAndConfigureNewButtonWithTitle:(NSString *)buttonTitle
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];

    [button setTitle:buttonTitle forState:UIControlStateNormal];
    button.titleLabel.font = self.buttonNotCenterFont;
    [button setTitleColor:self.notCenterButtonTextColor forState:UIControlStateNormal];
    [button setTitleColor:self.centerButtonTextColor forState:UIControlStateHighlighted];
    [button setBackgroundColor:self.notCenterButtonBackgroundColor];
    
    if (self.notCenterButtonBackgroundImage != nil)
        [button setBackgroundImage:self.notCenterButtonBackgroundImage forState:UIControlStateNormal];

    return button;
}

- (UIButton *)createAndConfigureNewButtonWithUrl:(NSString *)url
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    NSData *data = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:url]];
    [button setImage:[UIImage imageWithData:data] forState:UIControlStateNormal];
    [button setImage:[UIImage imageWithData:data] forState:UIControlStateHighlighted];

    return button;
}

- (void)tileContentInVisibleBounds
{
    CGRect visibleBounds = [self convertRect:[self bounds] toView:self.containerView];
    
    CGFloat minimumVisibleX = CGRectGetMinX(visibleBounds);
    CGFloat maximumVisibleX = CGRectGetMaxX(visibleBounds);
    [self tileButtonsFromMinX:minimumVisibleX toMaxX:maximumVisibleX];
}

- (void)configureCenterButton:(UIButton *)centerButton
{
    if (centerButton != self.centerbutton)
    {
        self.centerbutton = centerButton;
        [self setOtherButtons];

        for (UIButton *button in self.visibleButtons)
        {
            [button setBackgroundColor:self.notCenterButtonBackgroundColor];
            [button setBackgroundImage:self.notCenterButtonBackgroundImage forState:UIControlStateNormal];
            button.titleLabel.font = self.buttonNotCenterFont;
            [button setTitleColor:self.notCenterButtonTextColor forState:UIControlStateNormal];
        }
        [centerButton setBackgroundColor:self.centerButtonBackgroundColor];
        [centerButton setBackgroundImage:self.centerButtonBackgroundImage forState:UIControlStateNormal];
        centerButton.titleLabel.font = self.buttonCenterFont;
        centerButton.titleLabel.textColor = self.centerButtonTextColor;
        [centerButton setTitleColor:self.centerButtonTextColor forState:UIControlStateNormal];
    }
}

- (void)setOtherButtons
{
    int index = 0;
    for(int i = 0; i<self.buttons.count; i++)
    {
        UIButton *button = (UIButton *)self.buttons[i];
        if(self.centerbutton == button)
        {
            index = i;
            break;
        }
    }
    int prev = index == 0 ? self.buttons.count - 1 : index - 1;
    int next = index == self.buttons.count - 1 ? 0 : index + 1;

    self.leftbutton = (UIButton *)self.buttons[prev];
    self.rightbutton = (UIButton *)self.buttons[next];
}

- (UIButton *)getCenterButton
{
    UIButton *centerButton = [[UIButton alloc] init];
    CGFloat buttonMinimumDistanceFromCenter = 5000.0f;
    CGFloat currentButtonDistanceFromCenter = 5000.0f;
    
    for (UIButton *button in self.visibleButtons)
    {
        currentButtonDistanceFromCenter = fabs([self buttonDistanceFromCenter:button]);

        if (currentButtonDistanceFromCenter < buttonMinimumDistanceFromCenter)
        {
            buttonMinimumDistanceFromCenter = currentButtonDistanceFromCenter;
            centerButton = button;
        }
    }
    return centerButton;
}

- (CGFloat)buttonDistanceFromCenter:(UIButton *)button
{
    CGFloat visibleContentCenterX = self.contentOffset.x + [self bounds].size.width / 2.0f;
    CGFloat distanceFromCenter = visibleContentCenterX - button.center.x;
    return distanceFromCenter;
}

- (void)moveButtonToViewCenter:(UIButton *)button animated:(BOOL)animated
{
    CGPoint currentOffset = self.contentOffset;
    CGFloat distanceFromCenter = [self buttonDistanceFromCenter:button];

    CGPoint targetOffset = CGPointMake(currentOffset.x - distanceFromCenter, 0.0f);
    [self setContentOffset:targetOffset animated:animated];
}

- (void)recenterIfNecessary
{
    CGPoint currentOffset = [self contentOffset];
    CGFloat contentWidth = [self contentSize].width;
    CGFloat centerOffsetX = (contentWidth - [self bounds].size.width) / 2.0;
    CGFloat distanceFromCenter = fabs(currentOffset.x - centerOffsetX);

    if (distanceFromCenter > (contentWidth / 4.0))
    {
        self.contentOffset = CGPointMake(centerOffsetX, currentOffset.y);

        // move content by the same amount so it appears to stay still
        for (UIButton *button in self.buttons)
        {
            CGPoint center = [self.containerView convertPoint:button.center toView:self];
            center.x += (centerOffsetX - currentOffset.x);
            button.center = [self convertPoint:center toView:self.containerView];
        }
    }
}

- (void)scrollViewButtonIsInCenter:(UIButton *)sender
{
    if ([self.RollingScrollViewDelegate respondsToSelector:@selector(rollingScrollViewButtonIsInCenter:RollingScrollView:)])
        [self.RollingScrollViewDelegate rollingScrollViewButtonIsInCenter:sender RollingScrollView:self];
}

- (void)scrollViewButtonPushed:(UIButton *)sender
{
    [self scrollViewButtonPushed:sender isSideButton:NO];
}

- (void)scrollViewButtonPushed:(UIButton *)sender isSideButton:(BOOL)isSideButton
{
    if (_centerPushedButtons)
        [self moveButtonToViewCenter:sender animated:YES];

    if (!isSideButton && [self.RollingScrollViewDelegate respondsToSelector:@selector(rollingScrollViewButtonPushed:RollingScrollView:)])
        [self.RollingScrollViewDelegate rollingScrollViewButtonPushed:sender RollingScrollView:self];
}


#pragma mark - Label Tiling

- (CGFloat)placeNewButtonOnRight:(CGFloat)rightEdge
{
    _rightMostVisibleButtonIndex++;
    if (_rightMostVisibleButtonIndex == [self.buttons count])
        _rightMostVisibleButtonIndex = 0;
    
    UIButton *button = self.buttons[_rightMostVisibleButtonIndex];
    [self.containerView addSubview:button];
    [self.visibleButtons addObject:button]; // add rightmost label at the end of the array
    
    CGRect frame = [button frame];
    frame.origin.x = rightEdge;
    frame.origin.y = ([self.containerView bounds].size.height - frame.size.height) / 2.0f;
    [button setFrame:frame];
    return CGRectGetMaxX(frame);
}

- (CGFloat)placeNewButtonOnLeft:(CGFloat)leftEdge
{
    _leftMostVisibleButtonIndex--;
    if (_leftMostVisibleButtonIndex < 0)
        _leftMostVisibleButtonIndex = [self.buttons count] - 1;
    
    UIButton *button = self.buttons[_leftMostVisibleButtonIndex];
    [self.containerView addSubview:button];
    [self.visibleButtons insertObject:button atIndex:0]; // add leftmost label at the beginning of the array
    
    CGRect frame = [button frame];
    frame.origin.x = leftEdge - frame.size.width;
    frame.origin.y = ([self.containerView bounds].size.height - frame.size.height) / 2.0f;
    [button setFrame:frame];

    return CGRectGetMinX(frame);
}

- (void)tileButtonsFromMinX:(CGFloat)minimumVisibleX toMaxX:(CGFloat)maximumVisibleX
{
    // the upcoming tiling logic depends on there already being at least one label in the visibleLabels array, so
    // to kick off the tiling we need to make sure there's at least one label
    if ([self.visibleButtons count] == 0)
    {
        _rightMostVisibleButtonIndex = -1;
        _leftMostVisibleButtonIndex = 0;
        [self placeNewButtonOnRight:minimumVisibleX];
    }
    
    // add labels that are missing on right side
    UIButton *lastButton = [self.visibleButtons lastObject];
    CGFloat rightEdge = CGRectGetMaxX([lastButton frame]);
    
    while (rightEdge < maximumVisibleX)
    {
        rightEdge += self.spacingBetweenButtons;
        rightEdge = [self placeNewButtonOnRight:rightEdge];
    }
    
    // add labels that are missing on left side
    UIButton *firstButton = self.visibleButtons[0];
    CGFloat leftEdge = CGRectGetMinX([firstButton frame]);
    while (leftEdge > minimumVisibleX)
    {
        leftEdge -= self.spacingBetweenButtons;
        leftEdge = [self placeNewButtonOnLeft:leftEdge];
    }
    
    // remove labels that have fallen off right edge
    lastButton = [self.visibleButtons lastObject];
    while ([lastButton frame].origin.x > maximumVisibleX)
    {
        [lastButton removeFromSuperview];
        [self.visibleButtons removeLastObject];
        lastButton = [self.visibleButtons lastObject];

        _rightMostVisibleButtonIndex--;
        if (_rightMostVisibleButtonIndex < 0)
            _rightMostVisibleButtonIndex = [self.buttons count] - 1;
    }
    
    // remove labels that have fallen off left edge
    firstButton = self.visibleButtons[0];
    while (CGRectGetMaxX([firstButton frame]) < minimumVisibleX)
    {
        [firstButton removeFromSuperview];
        [self.visibleButtons removeObjectAtIndex:0];
        firstButton = self.visibleButtons[0];

        _leftMostVisibleButtonIndex++;
        if (_leftMostVisibleButtonIndex == [self.buttons count])
            _leftMostVisibleButtonIndex = 0;
    }
}

- (CGFloat)placeNewButtonOnBottom:(CGFloat)bottomEdge
{
    _bottomMostVisibleButtonIndex++;
    if (_bottomMostVisibleButtonIndex == [self.buttons count])
        _bottomMostVisibleButtonIndex = 0;
    
    UIButton *button = self.buttons[_bottomMostVisibleButtonIndex];
    [self.containerView addSubview:button];
    [self.visibleButtons addObject:button]; // add bottommost label at the end of the array
    
    CGRect frame = [button frame];
    frame.origin.y = bottomEdge;
    frame.origin.x = ([self.containerView bounds].size.width - frame.size.width) / 2.0f;
    [button setFrame:frame];
    return CGRectGetMaxY(frame);
}

- (CGFloat)placeNewButtonOnTop:(CGFloat)topEdge
{
    _topMostVisibleButtonIndex--;
    if (_topMostVisibleButtonIndex < 0)
        _topMostVisibleButtonIndex = [self.buttons count] - 1;
    
    UIButton *button = self.buttons[_topMostVisibleButtonIndex];
    [self.containerView addSubview:button];
    [self.visibleButtons insertObject:button atIndex:0]; // add leftmost label at the beginning of the array
    
    CGRect frame = [button frame];
    frame.origin.y = topEdge - frame.size.height;
    frame.origin.x = ([self.containerView bounds].size.width - frame.size.width) / 2.0f;
    [button setFrame:frame];

    return CGRectGetMinY(frame);
}

- (void)tileButtonsFromMinY:(CGFloat)minimumVisibleY toMaxY:(CGFloat)maximumVisibleY
{
    // the upcoming tiling logic depends on there already being at least one label in the visibleLabels array, so
    // to kick off the tiling we need to make sure there's at least one label
    if ([self.visibleButtons count] == 0)
    {
        _bottomMostVisibleButtonIndex = -1;
        _topMostVisibleButtonIndex = 0;
        [self placeNewButtonOnBottom:minimumVisibleY];
    }
    
    // add labels that are missing on right side
    UIButton *lastButton = [self.visibleButtons lastObject];
    CGFloat bottomEdge = CGRectGetMaxY([lastButton frame]);
    
    while (bottomEdge < maximumVisibleY)
    {
        bottomEdge += self.spacingBetweenButtons;
        bottomEdge = [self placeNewButtonOnBottom:bottomEdge];
    }
    
    // add labels that are missing on left side
    UIButton *firstButton = self.visibleButtons[0];
    CGFloat topEdge = CGRectGetMinY([firstButton frame]);
    while (topEdge > minimumVisibleY)
    {
        topEdge -= self.spacingBetweenButtons;
        topEdge = [self placeNewButtonOnTop:topEdge];
    }
    
    // remove labels that have fallen off right edge
    lastButton = [self.visibleButtons lastObject];
    while ([lastButton frame].origin.y > maximumVisibleY)
    {
        [lastButton removeFromSuperview];
        [self.visibleButtons removeLastObject];
        lastButton = [self.visibleButtons lastObject];
        
        _bottomMostVisibleButtonIndex--;
        if (_bottomMostVisibleButtonIndex < 0)
            _bottomMostVisibleButtonIndex = [self.buttons count] - 1;
    }

    // remove labels that have fallen off left edge
    firstButton = self.visibleButtons[0];
    while (CGRectGetMaxY([firstButton frame]) < minimumVisibleY)
    {
        [firstButton removeFromSuperview];
        [self.visibleButtons removeObjectAtIndex:0];
        firstButton = self.visibleButtons[0];
        
        _topMostVisibleButtonIndex++;
        if (_topMostVisibleButtonIndex == [self.buttons count]) {
            _topMostVisibleButtonIndex = 0;
        }
    }
}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.stopOnCenter)
    {

        CGPoint currentOffset = self.contentOffset;
        NSTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate];
        NSTimeInterval timeChange = currentTime - _lastTimeCapture;
        CGFloat distanceChange = currentOffset.x - _lastOffset.x;
        _scrollVelocity = distanceChange / timeChange;

        if (scrollView.decelerating)
        {
            if (fabsf(_scrollVelocity) < 150)
                [self moveButtonToViewCenter:self.centerbutton animated:YES];
        }
        _lastOffset = currentOffset;
        _lastTimeCapture = currentTime;
    }

    if ([self.RollingScrollViewDelegate respondsToSelector:@selector(rollingScrollViewDidScroll:)])
        [self.RollingScrollViewDelegate rollingScrollViewDidScroll:scrollView];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if ([self.RollingScrollViewDelegate respondsToSelector:@selector(rollingScrollViewWillBeginDragging:)])
        [self.RollingScrollViewDelegate rollingScrollViewWillBeginDragging:scrollView];
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    if ([self.RollingScrollViewDelegate respondsToSelector:@selector(rollingScrollViewWillEndDragging:withVelocity:targetContentOffset:)])
        [self.RollingScrollViewDelegate rollingScrollViewWillEndDragging:scrollView withVelocity:velocity targetContentOffset:targetContentOffset];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (self.stopOnCenter)
    {
        if (!decelerate)
        {
            [self moveButtonToViewCenter:self.centerbutton animated:YES];
            [self scrollViewButtonIsInCenter:[self getCenterButton]];
        }
    }
    
    if ([self.RollingScrollViewDelegate respondsToSelector:@selector(rollingScrollViewDidEndDragging:willDecelerate:)])
        [self.RollingScrollViewDelegate rollingScrollViewDidEndDragging:scrollView willDecelerate:decelerate];
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView
{
    if ([self.RollingScrollViewDelegate respondsToSelector:@selector(rollingScrollViewWillBeginDecelerating:)])
        [self.RollingScrollViewDelegate rollingScrollViewWillBeginDecelerating:scrollView];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self scrollViewButtonIsInCenter:[self getCenterButton]];

    if ([self.RollingScrollViewDelegate respondsToSelector:@selector(rollingScrollViewDidEndDecelerating:)])
        [self.RollingScrollViewDelegate rollingScrollViewDidEndDecelerating:scrollView];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    if ([self.RollingScrollViewDelegate respondsToSelector:@selector(rollingScrollViewDidEndScrollingAnimation:)])
        [self.RollingScrollViewDelegate rollingScrollViewDidEndScrollingAnimation:scrollView];
}

- (void)dealloc
{
    self.delegate = nil;
}

@end
