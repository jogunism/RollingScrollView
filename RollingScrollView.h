//
//  SSRollingButtonScrollView.h
//  RollingScrollView
//
//  Created by Shawn Seals on 12/27/13.
//  Copyright (c) 2013 Shawn Seals. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RollingScrollView;

@protocol RollingScrollViewDelegate <NSObject>

// RollingScrollViewDelegate specific methods.
@optional
- (void)rollingScrollViewButtonPushed:(UIButton *)button RollingScrollView:(RollingScrollView *)rollingButtonScrollView;
- (void)rollingScrollViewButtonIsInCenter:(UIButton *)button RollingScrollView:(RollingScrollView *)rollingButtonScrollView;

// UIScrollViewDelegate override methods.
@optional
- (void)rollingScrollViewDidScroll:(UIScrollView *)scrollview;
- (void)rollingScrollViewWillBeginDragging:(UIScrollView *)scrollView;
- (void)rollingScrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset;
- (void)rollingScrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate;
- (void)rollingScrollViewWillBeginDecelerating:(UIScrollView *)scrollView;
- (void)rollingScrollViewDidEndDecelerating:(UIScrollView *)scrollView;
- (void)rollingScrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView;

@end

@interface RollingScrollView : UIScrollView <UIScrollViewDelegate>


@property (nonatomic, weak) id <RollingScrollViewDelegate> RollingScrollViewDelegate;
@property (nonatomic, strong) UIFont *buttonNotCenterFont;
@property (nonatomic, strong) UIFont *buttonCenterFont;
@property (nonatomic) CGFloat fixedButtonWidth;
@property (nonatomic) CGFloat fixedButtonHeight;
@property (nonatomic) CGFloat spacingBetweenButtons;
@property (nonatomic, strong) UIColor *notCenterButtonTextColor;
@property (nonatomic, strong) UIColor *centerButtonTextColor;
@property (nonatomic, strong) UIColor *notCenterButtonBackgroundColor;
@property (nonatomic, strong) UIColor *centerButtonBackgroundColor;
@property (nonatomic, strong) UIImage *notCenterButtonBackgroundImage;
@property (nonatomic, strong) UIImage *centerButtonBackgroundImage;
@property (nonatomic) BOOL stopOnCenter;
@property (nonatomic) BOOL centerPushedButtons;
@property (nonatomic, assign) int selectedIndex;

- (id)initWithDelegate:(id<RollingScrollViewDelegate>)delegate frame:(CGRect)frame;

- (void)createButtonArrayWithButtonTitles:(NSArray *)titles;
- (void)createButtonArraywithImageUrls:(NSArray *)urls;
- (void)goRight;
- (void)goLeft;
- (void)slideshowStart;
- (void)slideshowStop;


@end
