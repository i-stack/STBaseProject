//
//  iCarousel.m
//
//  Version 1.8.3
//
//  Created by Nick Lockwood on 01/04/2011.
//  Copyright 2011 Charcoal Design
//

#import "iCarousel.h"
#import <objc/message.h>
#import <tgmath.h>
#import <Availability.h>
#if !__has_feature(objc_arc)
#error This class requires automatic reference counting
#endif

#if !defined(__has_warning) || __has_warning("-Wreceiver-is-weak")
# pragma GCC diagnostic ignored "-Wreceiver-is-weak"
#endif
#pragma clang diagnostic ignored "-Warc-repeated-use-of-weak"
#pragma clang diagnostic ignored "-Wobjc-missing-property-synthesis"
#pragma clang diagnostic ignored "-Wdirect-ivar-access"
#pragma clang diagnostic ignored "-Wunused-macros"
#pragma clang diagnostic ignored "-Wconversion"
#pragma clang diagnostic ignored "-Wformat-nonliteral"
#pragma clang diagnostic ignored "-Wpartial-availability"
#pragma clang diagnostic ignored "-Wdouble-promotion"
#pragma clang diagnostic ignored "-Wselector"
#pragma clang diagnostic ignored "-Wgnu"

#define MIN_TOGGLE_DURATION 0.2
#define MAX_TOGGLE_DURATION 0.4
#define SCROLL_DURATION 0.4
#define INSERT_DURATION 0.4
#define DECELERATE_THRESHOLD 0.1
#define SCROLL_SPEED_THRESHOLD 2.0
#define SCROLL_DISTANCE_THRESHOLD 0.1
#define DECELERATION_MULTIPLIER 30.0
#define FLOAT_ERROR_MARGIN 0.000001

#ifdef ICAROUSEL_MACOS
#define MAX_VISIBLE_ITEMS 50
#else
#define MAX_VISIBLE_ITEMS 3
#endif

@implementation NSObject (iCarousel)

- (NSUInteger)numberOfPlaceholdersInCarousel:(__unused iCarousel *)carousel { return 0; }
- (void)carouselWillBeginScrollingAnimation:(__unused iCarousel *)carousel {}
- (void)carouselDidEndScrollingAnimation:(__unused iCarousel *)carousel {}
- (void)carouselDidScroll:(__unused iCarousel *)carousel {}

- (void)carouselCurrentItemIndexDidChange:(__unused iCarousel *)carousel {}
- (void)carouselWillBeginDragging:(__unused iCarousel *)carousel {}
- (void)carouselDidEndDragging:(__unused iCarousel *)carousel willDecelerate:(__unused BOOL)decelerate {}
- (void)carouselWillBeginDecelerating:(__unused iCarousel *)carousel {}
- (void)carouselDidEndDecelerating:(__unused iCarousel *)carousel {}

- (BOOL)carousel:(__unused iCarousel *)carousel shouldSelectItemAtIndex:(__unused NSInteger)index { return YES; }
- (void)carousel:(__unused iCarousel *)carousel didSelectItemAtIndex:(__unused NSInteger)index {}

- (CGFloat)carouselItemWidth:(__unused iCarousel *)carousel { return 0; }
- (CATransform3D)carousel:(__unused iCarousel *)carousel
   itemTransformForOffset:(__unused CGFloat)offset
            baseTransform:(CATransform3D)transform { return transform; }
- (CGFloat)carousel:(__unused iCarousel *)carousel
     valueForOption:(__unused iCarouselOption)option
        withDefault:(CGFloat)value { return value; }

@end

@interface iCarousel ()

@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) NSMutableDictionary *itemViews;
@property (nonatomic, strong) NSMutableSet *itemViewPool;
//@property (nonatomic, strong) NSMutableSet *placeholderViewPool;
@property (nonatomic, assign) CGFloat previousScrollOffset;
@property (nonatomic, assign) NSInteger previousItemIndex;
//@property (nonatomic, assign) NSInteger numberOfPlaceholdersToShow;
@property (nonatomic, assign) NSInteger numberOfVisibleItems;
@property (nonatomic, assign) CGFloat itemWidth;
@property (nonatomic, assign) CGFloat offsetMultiplier;
@property (nonatomic, assign) CGFloat startOffset;
@property (nonatomic, assign) CGFloat endOffset;
@property (nonatomic, assign) NSTimeInterval scrollDuration;
@property (nonatomic, assign, getter = isScrolling) BOOL scrolling;
@property (nonatomic, assign) NSTimeInterval startTime;
@property (nonatomic, assign) NSTimeInterval lastTime;
@property (nonatomic, assign) CGFloat startVelocity;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign, getter = isDecelerating) BOOL decelerating;
@property (nonatomic, assign) CGFloat previousTranslation;
@property (nonatomic, assign, getter = isWrapEnabled) BOOL wrapEnabled;
@property (nonatomic, assign, getter = isDragging) BOOL dragging;
@property (nonatomic, assign) BOOL didDrag;
@property (nonatomic, assign) NSTimeInterval toggleTime;

NSComparisonResult compareViewDepth(UIView *view1, UIView *view2, iCarousel *self);

@end

@implementation iCarousel

#pragma mark -
#pragma mark Initialisation
- (void)setUp
{
    _decelerationRate = 0.0;
    _scrollEnabled = YES;
    _bounces = YES;
    _offsetMultiplier = 1.0;
    _perspective = -1.0/500.0;
    _contentOffset = CGSizeZero;
    _viewpointOffset = CGSizeZero;
    _scrollSpeed = 1.0;
    _bounceDistance = 1.0;
    _stopAtItemBoundary = YES;
    _scrollToItemBoundary = YES;
    _ignorePerpendicularSwipes = YES;
    _centerItemWhenSelected = YES;
    
    _contentView = [[UIView alloc] initWithFrame:self.bounds];
    _contentView.backgroundColor = [UIColor blackColor];
    _contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPan:)];
    panGesture.delegate = (id <UIGestureRecognizerDelegate>)self;
    [_contentView addGestureRecognizer:panGesture];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTap:)];
    tapGesture.delegate = (id <UIGestureRecognizerDelegate>)self;
    [_contentView addGestureRecognizer:tapGesture];
    
    self.accessibilityTraits = UIAccessibilityTraitAllowsDirectInteraction;
    self.isAccessibilityElement = YES;
    [self addSubview:_contentView];
    if (_dataSource) {
        [self reloadData];
    }
}

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        [self setUp];
    }
    return self;
}

- (void)dealloc
{
    [self stopAnimation];
}

- (void)setDataSource:(id<iCarouselDataSource>)dataSource
{
    if (_dataSource != dataSource) {
        _dataSource = dataSource;
        if (_dataSource) {
            [self reloadData];
            [self layOutItemViews];
        }
    }
}

- (void)setDelegate:(id<iCarouselDelegate>)delegate
{
    if (_delegate != delegate) {
        _delegate = delegate;
        if (_delegate && _dataSource) {
            [self setNeedsLayout];
        }
    }
}

- (void)setScrollOffset:(CGFloat)scrollOffset
{
    _scrolling = NO;
    _decelerating = NO;
    _startOffset = scrollOffset;
    _endOffset = scrollOffset;
    
    if (fabs(_scrollOffset - scrollOffset) > 0.0) {
        _scrollOffset = scrollOffset;
        [self depthSortViews];
        [self didScroll];
    }
}

- (void)setCurrentItemIndex:(NSInteger)currentItemIndex
{
    [self setScrollOffset:currentItemIndex];
}

- (void)setPerspective:(CGFloat)perspective
{
    _perspective = perspective;
    [self transformItemViews];
}

- (void)setViewpointOffset:(CGSize)viewpointOffset
{
    if (!CGSizeEqualToSize(_viewpointOffset, viewpointOffset)) {
        _viewpointOffset = viewpointOffset;
        [self transformItemViews];
    }
}

- (void)setContentOffset:(CGSize)contentOffset
{
    if (!CGSizeEqualToSize(_contentOffset, contentOffset)) {
        _contentOffset = contentOffset;
        [self layOutItemViews];
    }
}

- (void)setAutoscroll:(CGFloat)autoscroll
{
    _autoscroll = autoscroll;
    if (autoscroll != 0.0) [self startAnimation];
}

- (void)pushAnimationState:(BOOL)enabled
{
    [CATransaction begin];
    [CATransaction setDisableActions:!enabled];
}

- (void)popAnimationState
{
    [CATransaction commit];
}

#pragma mark -
#pragma mark View management
- (NSArray *)indexesForVisibleItems
{
    return [[_itemViews allKeys] sortedArrayUsingSelector:@selector(compare:)];
}

- (NSArray *)visibleItemViews
{
    NSArray *indexes = [self indexesForVisibleItems];
    return [_itemViews objectsForKeys:indexes notFoundMarker:[NSNull null]];
}

- (UIView *)itemViewAtIndex:(NSInteger)index
{
    return _itemViews[@(index)];
}

- (UIView *)currentItemView
{
    return [self itemViewAtIndex:self.currentItemIndex];
}

- (NSInteger)indexOfItemView:(UIView *)view
{
    NSInteger index = [[_itemViews allValues] indexOfObject:view];
    if (index != NSNotFound) {
        return [[_itemViews allKeys][index] integerValue];
    }
    return NSNotFound;
}

- (NSInteger)indexOfItemViewOrSubview:(UIView *)view
{
    NSInteger index = [self indexOfItemView:view];
    if (index == NSNotFound && view.superview && view != _contentView) {
        return [self indexOfItemViewOrSubview:(UIView *__nonnull)view.superview];
    }
    return index;
}

- (UIView *)itemViewAtPoint:(CGPoint)point
{
    for (UIView *view in [[[_itemViews allValues] sortedArrayUsingFunction:(NSInteger (*)(id, id, void *))compareViewDepth context:(__bridge void *)self] reverseObjectEnumerator]) {
        if ([view.superview.layer hitTest:point]) {
            return view;
        }
    }
    return nil;
}

- (void)setItemView:(UIView *)view forIndex:(NSInteger)index
{
    _itemViews[@(index)] = view;
}

- (void)removeViewAtIndex:(NSInteger)index
{
    NSMutableDictionary *newItemViews = [NSMutableDictionary dictionaryWithCapacity:[_itemViews count] - 1];
    for (NSNumber *number in [self indexesForVisibleItems]) {
        NSInteger i = [number integerValue];
        if (i < index) {
            newItemViews[number] = _itemViews[number];
        } else if (i > index) {
            newItemViews[@(i - 1)] = _itemViews[number];
        }
    }
    self.itemViews = newItemViews;
}

- (void)insertView:(UIView *)view atIndex:(NSInteger)index
{
    NSMutableDictionary *newItemViews = [NSMutableDictionary dictionaryWithCapacity:[_itemViews count] + 1];
    for (NSNumber *number in [self indexesForVisibleItems]) {
        NSInteger i = [number integerValue];
        if (i < index) {
            newItemViews[number] = _itemViews[number];
        } else {
            newItemViews[@(i + 1)] = _itemViews[number];
        }
    }
    if (view) {
        [self setItemView:view forIndex:index];
    }
    self.itemViews = newItemViews;
}

#pragma mark -
#pragma mark View layout
- (CGFloat)alphaForItemWithOffset:(CGFloat)offset
{
    CGFloat fadeMin = (CGFloat)-INFINITY;
    CGFloat fadeMax = (CGFloat)INFINITY;
    CGFloat fadeRange = 1.0;
    CGFloat fadeMinAlpha = 0.0;
    fadeMin = [self valueForOption:iCarouselOptionFadeMin withDefault:fadeMin];
    fadeMax = [self valueForOption:iCarouselOptionFadeMax withDefault:fadeMax];
    fadeRange = [self valueForOption:iCarouselOptionFadeRange withDefault:fadeRange];
    fadeMinAlpha = [self valueForOption:iCarouselOptionFadeMinAlpha withDefault:fadeMinAlpha];
    CGFloat factor = 0.0;
    if (offset > fadeMax) {
        factor = offset - fadeMax;
    } else if (offset < fadeMin) {
        factor = fadeMin - offset;
    }
    return 1.0 - MIN(factor, fadeRange) / fadeRange * (1.0 - fadeMinAlpha);
}

- (CGFloat)valueForOption:(iCarouselOption)option withDefault:(CGFloat)value
{
    return _delegate? [_delegate carousel:self valueForOption:option withDefault:value]: value;
}

- (CATransform3D)transformForItemViewWithOffset:(CGFloat)offset
{
    //set up base transform
    CATransform3D transform = CATransform3DIdentity;
    transform.m34 = _perspective;
    transform = CATransform3DTranslate(transform, -_viewpointOffset.width, -_viewpointOffset.height, 0.0);
    CGFloat tilt = [self valueForOption:iCarouselOptionTilt withDefault:0.3];
    CGFloat spacing = [self valueForOption:iCarouselOptionSpacing withDefault:1.0];
    tilt = -tilt;
    offset = -offset;
    return CATransform3DTranslate(transform, fabs(offset) * 30, offset * 100 * tilt, offset * 50 * spacing);
}

NSComparisonResult compareViewDepth(UIView *view1, UIView *view2, iCarousel *self)
{
    //compare depths
    CATransform3D t1 = view1.superview.layer.transform;
    CATransform3D t2 = view2.superview.layer.transform;
    CGFloat z1 = t1.m13 + t1.m23 + t1.m33 + t1.m43;
    CGFloat z2 = t2.m13 + t2.m23 + t2.m33 + t2.m43;
    CGFloat difference = z1 - z2;
    
    //if depths are equal, compare distance from current view
    if (difference == 0.0) {
        CATransform3D t3 = [self currentItemView].superview.layer.transform;
        CGFloat y1 = t1.m12 + t1.m22 + t1.m32 + t1.m42;
        CGFloat y2 = t2.m12 + t2.m22 + t2.m32 + t2.m42;
        CGFloat y3 = t3.m12 + t3.m22 + t3.m32 + t3.m42;
        difference = fabs(y2 - y3) - fabs(y1 - y3);
    }
    return (difference < 0.0)? NSOrderedAscending: NSOrderedDescending;
}

- (void)depthSortViews
{
    for (UIView *view in [[_itemViews allValues] sortedArrayUsingFunction:(NSInteger (*)(id, id, void *))compareViewDepth context:(__bridge void *)self]) {
        [_contentView bringSubviewToFront:(UIView *__nonnull)view.superview];
    }
}

- (CGFloat)offsetForItemAtIndex:(NSInteger)index
{
    //calculate relative position
    CGFloat offset = index - _scrollOffset;
    if (_wrapEnabled) {
        if (offset > _numberOfItems / 2.0) {
            offset -= _numberOfItems;
        } else if (offset < -_numberOfItems / 2.0)  {
            offset += _numberOfItems;
        }
    }
    return offset;
}

- (UIView *)containView:(UIView *)view
{
    if (!_itemWidth) {
        _itemWidth = view.bounds.size.height;
    }
//    CGRect frame = view.bounds;
//    frame.size.width = frame.size.width;
//    frame.size.height = _itemWidth;
    UIView *containerView = [[UIView alloc] initWithFrame:_contentView.bounds];
    [containerView addSubview:view];
    containerView.layer.opacity = 0;
    
    return containerView;
}

- (void)transformItemView:(UIView *)view atIndex:(NSInteger)index
{
    CGFloat offset = [self offsetForItemAtIndex:index];
    view.superview.layer.opacity = [self alphaForItemWithOffset:offset];
    view.superview.layer.rasterizationScale = [UIScreen mainScreen].scale;
    [view layoutIfNeeded];

    CGFloat clampedOffset = MAX(-1.0, MIN(1.0, offset));
    if (_decelerating || (_scrolling && !_dragging && !_didDrag) ||
        (_autoscroll && !_dragging) ||
        (!_wrapEnabled && (_scrollOffset < 0 || _scrollOffset >= _numberOfItems - 1))) {
        if (offset > 0) {
            _toggle = (offset <= 0.5)? -clampedOffset: (1.0 - clampedOffset);
        } else {
            _toggle = (offset > -0.5)? -clampedOffset: (- 1.0 - clampedOffset);
        }
    }
    
    CATransform3D transform = [self transformForItemViewWithOffset:offset];
    view.superview.layer.transform = transform;
    BOOL showBackfaces = view.layer.doubleSided;
    if (showBackfaces) {
        showBackfaces = YES;
    }
    showBackfaces = !![self valueForOption:iCarouselOptionShowBackfaces withDefault:showBackfaces];
    view.superview.hidden = !(showBackfaces ?: (transform.m33 > 0.0));
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    _contentView.frame = self.bounds;
    [self layOutItemViews];
}

- (void)transformItemViews
{
    for (NSNumber *number in _itemViews) {
        NSInteger index = [number integerValue];
        UIView *view = _itemViews[number];
        [self transformItemView:view atIndex:index];
    }
}

- (void)updateItemWidth
{
    _itemWidth = [_delegate carouselItemWidth:self] ?: _itemWidth;
    if (_numberOfItems > 0) {
        if ([_itemViews count] == 0){
            [self loadViewAtIndex:0];
        }
    }
}

- (void)updateNumberOfVisibleItems
{
    _numberOfVisibleItems = MAX_VISIBLE_ITEMS;
    _numberOfVisibleItems = [self valueForOption:iCarouselOptionVisibleItems withDefault:_numberOfVisibleItems];
    _numberOfVisibleItems = MAX(0, MIN(_numberOfVisibleItems, _numberOfItems));
}

- (NSInteger)circularCarouselItemCount
{
    return _numberOfItems;
}

- (void)layOutItemViews
{
    if (!_dataSource || !_contentView) {
        return;
    }
    _wrapEnabled = NO;
    _wrapEnabled = !![self valueForOption:iCarouselOptionWrap withDefault:_wrapEnabled];
    [self updateItemWidth];
    [self updateNumberOfVisibleItems];
    _previousScrollOffset = self.scrollOffset;
    
    _offsetMultiplier = 1.0;
    _offsetMultiplier = [self valueForOption:iCarouselOptionOffsetMultiplier withDefault:_offsetMultiplier];
    
    if (!_scrolling && !_decelerating && !_autoscroll) {
        if (_scrollToItemBoundary && self.currentItemIndex != -1) {
            [self scrollToItemAtIndex:self.currentItemIndex animated:YES];
        } else {
            _scrollOffset = [self clampedOffset:_scrollOffset];
        }
    }
    [self didScroll];
}

#pragma mark -
#pragma mark View queing
- (void)queueItemView:(UIView *)view
{
    if (view) {
        [_itemViewPool addObject:view];
    }
}

- (UIView *)dequeueItemView
{
    UIView *view = [_itemViewPool anyObject];
    if (view) {
        [_itemViewPool removeObject:view];
    }
    return view;
}

#pragma mark -
#pragma mark View loading
- (UIView *)loadViewAtIndex:(NSInteger)index withContainerView:(UIView *)containerView
{
    [self pushAnimationState:NO];
    
    UIView *view = nil;
    if (index >= 0 && index < _numberOfItems) {
        view = [_dataSource carousel:self viewForItemAtIndex:index reusingView:[self dequeueItemView]];
    }
    
    if (view == nil) {
        view = [[UIView alloc] init];
    }
    
    [self setItemView:view forIndex:index];
    if (containerView) {
        UIView *oldItemView = [containerView.subviews lastObject];
        if (index >= 0 && index < _numberOfItems) {
            [self queueItemView:oldItemView];
        }
        CGRect frame = containerView.bounds;
        frame.size.width = view.frame.size.width;
        frame.size.height = MIN(_itemWidth, view.frame.size.height);
        containerView.bounds = frame;
        frame = view.frame;
        frame.origin.x = (containerView.bounds.size.width - frame.size.width) / 2.0;
        frame.origin.y = (containerView.bounds.size.height - frame.size.height) / 2.0;
        view.frame = frame;
        [oldItemView removeFromSuperview];
        [containerView addSubview:view];
    } else {
//        [_contentView addSubview:[self containView:view]];
        [_contentView addSubview:view];
    }
    view.superview.layer.opacity = 0.0;
    [self popAnimationState];
    return view;
}

- (UIView *)loadViewAtIndex:(NSInteger)index
{
    return [self loadViewAtIndex:index withContainerView:nil];
}

- (void)loadUnloadViews
{
    [self updateItemWidth];
    [self updateNumberOfVisibleItems];
    
    NSMutableSet *visibleIndices = [NSMutableSet setWithCapacity:_numberOfVisibleItems];
    NSInteger min = -(NSInteger)(ceil((CGFloat)0/2.0));
    NSInteger max = _numberOfItems - 1;
    NSInteger offset = self.currentItemIndex - _numberOfVisibleItems/2;
    if (!_wrapEnabled) {
        offset = MAX(min, MIN(max - _numberOfVisibleItems + 1, offset));
    }
    for (NSInteger i = 0; i < _numberOfVisibleItems; i++) {
        NSInteger index = i + offset;
        if (_wrapEnabled) {
            index = [self clampedIndex:index];
        }
        CGFloat alpha = [self alphaForItemWithOffset:[self offsetForItemAtIndex:index]];
        if (alpha) {
            [visibleIndices addObject:@(index)];
        }
    }
    
    for (NSNumber *number in [_itemViews allKeys]) {
        if (![visibleIndices containsObject:number]) {
            UIView *view = _itemViews[number];
            if ([number integerValue] >= 0 && [number integerValue] < _numberOfItems) {
                [self queueItemView:view];
            }
            [view.superview removeFromSuperview];
            [(NSMutableDictionary *)_itemViews removeObjectForKey:number];
        }
    }
    
    for (NSNumber *number in visibleIndices) {
        UIView *view = _itemViews[number];
        if (view == nil) {
            [self loadViewAtIndex:[number integerValue]];
        }
    }
}

- (void)reloadData
{
//    for (UIView *view in [_itemViews allValues]) {
//        [view.superview removeFromSuperview];
//    }
    
    if (!_dataSource || !_contentView) {
        return;
    }
    
    _numberOfVisibleItems = 0;
    _numberOfItems = [_dataSource numberOfItemsInCarousel:self];
    
    self.itemViews = [NSMutableDictionary dictionary];
    self.itemViewPool = [NSMutableSet set];
    
    [self setNeedsLayout];
    
    if (_numberOfItems > 0 && _scrollOffset < 0.0) {
        [self scrollToItemAtIndex:0 animated:NO];
    }
}

#pragma mark -
#pragma mark Scrolling
- (NSInteger)clampedIndex:(NSInteger)index
{
    if (_numberOfItems == 0) {
        return -1;
    } else if (_wrapEnabled) {
        return index - floor((CGFloat)index / (CGFloat)_numberOfItems) * _numberOfItems;
    } else {
        return MIN(MAX(0, index), MAX(0, _numberOfItems - 1));
    }
}

- (CGFloat)clampedOffset:(CGFloat)offset
{
    if (_numberOfItems == 0) {
        return -1.0;
    } else if (_wrapEnabled) {
        return offset - floor(offset / (CGFloat)_numberOfItems) * _numberOfItems;
    } else {
        return MIN(MAX(0.0, offset), MAX(0.0, (CGFloat)_numberOfItems - 1.0));
    }
}

- (NSInteger)currentItemIndex
{
    return [self clampedIndex:round(_scrollOffset)];
}

- (NSInteger)minScrollDistanceFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex
{
    NSInteger directDistance = toIndex - fromIndex;
    if (_wrapEnabled) {
        NSInteger wrappedDistance = MIN(toIndex, fromIndex) + _numberOfItems - MAX(toIndex, fromIndex);
        if (fromIndex < toIndex) {
            wrappedDistance = -wrappedDistance;
        }
        return (ABS(directDistance) <= ABS(wrappedDistance))? directDistance: wrappedDistance;
    }
    return directDistance;
}

- (CGFloat)minScrollDistanceFromOffset:(CGFloat)fromOffset toOffset:(CGFloat)toOffset
{
    CGFloat directDistance = toOffset - fromOffset;
    if (_wrapEnabled) {
        CGFloat wrappedDistance = MIN(toOffset, fromOffset) + _numberOfItems - MAX(toOffset, fromOffset);
        if (fromOffset < toOffset) {
            wrappedDistance = -wrappedDistance;
        }
        return (fabs(directDistance) <= fabs(wrappedDistance))? directDistance: wrappedDistance;
    }
    return directDistance;
}

- (void)scrollByOffset:(CGFloat)offset duration:(NSTimeInterval)duration
{
    if (duration > 0.0) {
        _decelerating = NO;
        _scrolling = YES;
        _startTime = CACurrentMediaTime();
        _startOffset = _scrollOffset;
        _scrollDuration = duration;
        _endOffset = _startOffset + offset;
        if (!_wrapEnabled) {
            _endOffset = [self clampedOffset:_endOffset];
        }
        [_delegate carouselWillBeginScrollingAnimation:self];
        [self startAnimation];
    } else {
        self.scrollOffset += offset;
    }
}

- (void)scrollToOffset:(CGFloat)offset duration:(NSTimeInterval)duration
{
    [self scrollByOffset:[self minScrollDistanceFromOffset:_scrollOffset toOffset:offset] duration:duration];
}

- (void)scrollByNumberOfItems:(NSInteger)itemCount duration:(NSTimeInterval)duration
{
    if (duration > 0.0) {
        CGFloat offset = 0.0;
        if (itemCount > 0) {
            offset = (floor(_scrollOffset) + itemCount) - _scrollOffset;
        } else if (itemCount < 0) {
            offset = (ceil(_scrollOffset) + itemCount) - _scrollOffset;
        } else {
            offset = round(_scrollOffset) - _scrollOffset;
        }
        [self scrollByOffset:offset duration:duration];
    } else {
        self.scrollOffset = [self clampedIndex:_previousItemIndex + itemCount];
    }
}

- (void)scrollToItemAtIndex:(NSInteger)index duration:(NSTimeInterval)duration
{
    [self scrollToOffset:index duration:duration];
}

- (void)scrollToItemAtIndex:(NSInteger)index animated:(BOOL)animated
{
    [self scrollToItemAtIndex:index duration:animated? SCROLL_DURATION: 0];
}

- (void)reloadItemAtIndex:(NSInteger)index animated:(BOOL)animated
{
    UIView *containerView = [[self itemViewAtIndex:index] superview];
    if (containerView) {
        if (animated){
            CATransition *transition = [CATransition animation];
            transition.duration = INSERT_DURATION;
            transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            transition.type = kCATransitionFade;
            [containerView.layer addAnimation:transition forKey:nil];
        }
        [self loadViewAtIndex:index withContainerView:containerView];
    }
}

#pragma mark -
#pragma mark Animation
- (void)startAnimation
{
    if (!_timer) {
        self.timer = [NSTimer timerWithTimeInterval:1.0/60.0
                                             target:self
                                           selector:@selector(step)
                                           userInfo:nil
                                            repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSDefaultRunLoopMode];
#ifdef ICAROUSEL_IOS
        [[NSRunLoop mainRunLoop] addTimer:_timer forMode:UITrackingRunLoopMode];
#endif
    }
}

- (void)stopAnimation
{
    [_timer invalidate];
    _timer = nil;
}

- (CGFloat)decelerationDistance
{
    CGFloat acceleration = -_startVelocity * DECELERATION_MULTIPLIER * (1.0 - _decelerationRate);
    return -pow(_startVelocity, 2.0) / (2.0 * acceleration);
}

- (BOOL)shouldDecelerate
{
    return (fabs(_startVelocity) > SCROLL_SPEED_THRESHOLD) &&
    (fabs([self decelerationDistance]) > DECELERATE_THRESHOLD);
}

- (BOOL)shouldScroll
{
    return (fabs(_startVelocity) > SCROLL_SPEED_THRESHOLD) &&
    (fabs(_scrollOffset - self.currentItemIndex) > SCROLL_DISTANCE_THRESHOLD);
}

- (void)startDecelerating
{
    CGFloat distance = [self decelerationDistance];
    _startOffset = _scrollOffset;
    _endOffset = _startOffset + distance;
    if (_pagingEnabled) {
        if (distance > 0.0) {
            _endOffset = ceil(_startOffset);
        } else {
            _endOffset = floor(_startOffset);
        }
    } else if (_stopAtItemBoundary) {
        if (distance > 0.0) {
            _endOffset = ceil(_endOffset);
        } else {
            _endOffset = floor(_endOffset);
        }
    }
    if (!_wrapEnabled) {
        if (_bounces) {
            _endOffset = MAX(-_bounceDistance, MIN(_numberOfItems - 1.0 + _bounceDistance, _endOffset));
        } else {
            _endOffset = [self clampedOffset:_endOffset];
        }
    }
    distance = _endOffset - _startOffset;
    
    _startTime = CACurrentMediaTime();
    _scrollDuration = fabs(distance) / fabs(0.5 * _startVelocity);
    
    if (distance != 0.0) {
        _decelerating = YES;
        [self startAnimation];
    }
}

- (CGFloat)easeInOut:(CGFloat)time
{
    return (time < 0.5)? 0.5 * pow(time * 2.0, 3.0): 0.5 * pow(time * 2.0 - 2.0, 3.0) + 1.0;
}

- (void)step
{
    [self pushAnimationState:NO];
    NSTimeInterval currentTime = CACurrentMediaTime();
    double delta = currentTime - _lastTime;
    _lastTime = currentTime;
    
    if (_scrolling && !_dragging) {
        NSTimeInterval time = MIN(1.0, (currentTime - _startTime) / _scrollDuration);
        delta = [self easeInOut:time];
        _scrollOffset = _startOffset + (_endOffset - _startOffset) * delta;
        [self didScroll];
        if (time >= 1.0) {
            _scrolling = NO;
            [self depthSortViews];
            [self pushAnimationState:YES];
            [_delegate carouselDidEndScrollingAnimation:self];
            [self popAnimationState];
        }
    } else if (_decelerating) {
        CGFloat time = MIN(_scrollDuration, currentTime - _startTime);
        CGFloat acceleration = -_startVelocity/_scrollDuration;
        CGFloat distance = _startVelocity * time + 0.5 * acceleration * pow(time, 2.0);
        _scrollOffset = _startOffset + distance;
        [self didScroll];
        if (fabs(time - _scrollDuration) < FLOAT_ERROR_MARGIN) {
            _decelerating = NO;
            [self pushAnimationState:YES];
            [_delegate carouselDidEndDecelerating:self];
            [self popAnimationState];
            if ((_scrollToItemBoundary || fabs(_scrollOffset - [self clampedOffset:_scrollOffset]) > FLOAT_ERROR_MARGIN) && !_autoscroll) {
                if (fabs(_scrollOffset - self.currentItemIndex) < FLOAT_ERROR_MARGIN) {
                    [self scrollToItemAtIndex:self.currentItemIndex duration:0.01];
                } else {
                    [self scrollToItemAtIndex:self.currentItemIndex animated:YES];
                }
            }
            else {
                CGFloat difference = round(_scrollOffset) - _scrollOffset;
                if (difference > 0.5) {
                    difference = difference - 1.0;
                } else if (difference < -0.5) {
                    difference = 1.0 + difference;
                }
                _toggleTime = currentTime - MAX_TOGGLE_DURATION * fabs(difference);
                _toggle = MAX(-1.0, MIN(1.0, -difference));
            }
        }
    } else if (_autoscroll && !_dragging) {
        self.scrollOffset = [self clampedOffset:_scrollOffset - delta * _autoscroll];
    } else if (fabs(_toggle) > FLOAT_ERROR_MARGIN) {
        NSTimeInterval toggleDuration = _startVelocity? MIN(1.0, MAX(0.0, 1.0 / fabs(_startVelocity))): 1.0;
        toggleDuration = MIN_TOGGLE_DURATION + (MAX_TOGGLE_DURATION - MIN_TOGGLE_DURATION) * toggleDuration;
        NSTimeInterval time = MIN(1.0, (currentTime - _toggleTime) / toggleDuration);
        delta = [self easeInOut:time];
        _toggle = (_toggle < 0.0)? (delta - 1.0): (1.0 - delta);
        [self didScroll];
    } else if (!_autoscroll) {
        [self stopAnimation];
    }
    
    [self popAnimationState];
}

- (void)didMoveToSuperview
{
    if (self.superview)
    {
        [self startAnimation];
    } else {
        [self stopAnimation];
    }
}

- (void)didScroll
{
    if (_wrapEnabled || !_bounces) {
        _scrollOffset = [self clampedOffset:_scrollOffset];
    } else {
        CGFloat min = -_bounceDistance;
        CGFloat max = MAX(_numberOfItems - 1, 0.0) + _bounceDistance;
        if (_scrollOffset < min) {
            _scrollOffset = min;
            _startVelocity = 0.0;
        } else if (_scrollOffset > max) {
            _scrollOffset = max;
            _startVelocity = 0.0;
        }
    }
    
    //check if index has changed
    NSInteger difference = [self minScrollDistanceFromIndex:self.currentItemIndex toIndex:self.previousItemIndex];
    if (difference) {
        _toggleTime = CACurrentMediaTime();
        _toggle = MAX(-1, MIN(1, difference));
        [self startAnimation];
    }
    
    [self loadUnloadViews];
    [self transformItemViews];
    
    //notify delegate of offset change
    if (fabs(_scrollOffset - _previousScrollOffset) > FLOAT_ERROR_MARGIN) {
        [self pushAnimationState:YES];
        [_delegate carouselDidScroll:self];
        [self popAnimationState];
    }
    
    //notify delegate of index change
    if (_previousItemIndex != self.currentItemIndex) {
        [self pushAnimationState:YES];
        [_delegate carouselCurrentItemIndexDidChange:self];
        [self popAnimationState];
    }
    
    //update previous index
    _previousScrollOffset = _scrollOffset;
    _previousItemIndex = self.currentItemIndex;
}

#ifdef ICAROUSEL_IOS
#pragma mark -
#pragma mark Gestures and taps
- (NSInteger)viewOrSuperviewIndex:(UIView *)view
{
    if (view == nil || view == _contentView) {
        return NSNotFound;
    }
    NSInteger index = [self indexOfItemView:view];
    if (index == NSNotFound) {
        return [self viewOrSuperviewIndex:view.superview];
    }
    return index;
}

- (BOOL)viewOrSuperview:(UIView *)view implementsSelector:(SEL)selector
{
    if (!view || view == self.contentView) {
        return NO;
    }
    
    Class viewClass = [view class];
    while (viewClass && viewClass != [UIView class]) {
        unsigned int numberOfMethods;
        Method *methods = class_copyMethodList(viewClass, &numberOfMethods);
        for (unsigned int i = 0; i < numberOfMethods; i++) {
            if (method_getName(methods[i]) == selector) {
                free(methods);
                return YES;
            }
        }
        if (methods) free(methods);
        viewClass = [viewClass superclass];
    }
    
    return [self viewOrSuperview:view.superview implementsSelector:selector];
}

- (id)viewOrSuperview:(UIView *)view ofClass:(Class)class
{
    if (!view || view == self.contentView) {
        return nil;
    } else if ([view isKindOfClass:class]) {
        return view;
    }
    return [self viewOrSuperview:view.superview ofClass:class];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gesture shouldReceiveTouch:(UITouch *)touch
{
    if (_scrollEnabled) {
        _dragging = NO;
        _scrolling = NO;
        _decelerating = NO;
    }
    
    if ([gesture isKindOfClass:[UITapGestureRecognizer class]]) {
        //handle tap
        NSInteger index = [self viewOrSuperviewIndex:touch.view];
        if (index == NSNotFound && _centerItemWhenSelected) {
            //view is a container view
            index = [self viewOrSuperviewIndex:[touch.view.subviews lastObject]];
        }
        if (index != NSNotFound) {
            if ([self viewOrSuperview:touch.view implementsSelector:@selector(touchesBegan:withEvent:)]) {
                return NO;
            }
        }
    } else if ([gesture isKindOfClass:[UIPanGestureRecognizer class]]) {
        if (!_scrollEnabled) {
            return NO;
        } else if ([self viewOrSuperview:touch.view implementsSelector:@selector(touchesMoved:withEvent:)]) {
            UIScrollView *scrollView = [self viewOrSuperview:touch.view ofClass:[UIScrollView class]];
            if (scrollView) {
                return !scrollView.scrollEnabled ||
                (scrollView.contentSize.height <= scrollView.frame.size.height);
            }
            if ([self viewOrSuperview:touch.view ofClass:[UIButton class]] ||
                [self viewOrSuperview:touch.view ofClass:[UIBarButtonItem class]]) {
                return YES;
            }
            return NO;
        }
    }
    return YES;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gesture
{
    if ([gesture isKindOfClass:[UIPanGestureRecognizer class]]) {
        //ignore vertical swipes
        UIPanGestureRecognizer *panGesture = (UIPanGestureRecognizer *)gesture;
        CGPoint translation = [panGesture translationInView:self];
        if (_ignorePerpendicularSwipes) {
            return fabs(translation.x) <= fabs(translation.y);
        }
    }
    return YES;
}

- (void)didTap:(UITapGestureRecognizer *)tapGesture
{
    //check for tapped view
    UIView *itemView = [self itemViewAtPoint:[tapGesture locationInView:_contentView]];
    NSInteger index = itemView? [self indexOfItemView:itemView]: NSNotFound;
    if (index != NSNotFound) {
        if (!_delegate || [_delegate carousel:self shouldSelectItemAtIndex:index]) {
            if ((index != self.currentItemIndex && _centerItemWhenSelected) ||
                (index == self.currentItemIndex && _scrollToItemBoundary)) {
                [self scrollToItemAtIndex:index animated:YES];
            }
            [_delegate carousel:self didSelectItemAtIndex:index];
        } else if (_scrollEnabled && _scrollToItemBoundary && _autoscroll) {
            [self scrollToItemAtIndex:self.currentItemIndex animated:YES];
        }
    } else {
        [self scrollToItemAtIndex:self.currentItemIndex animated:YES];
    }
}

- (void)didPan:(UIPanGestureRecognizer *)panGesture
{
    if (_scrollEnabled && _numberOfItems) {
        switch (panGesture.state) {
            case UIGestureRecognizerStateBegan: {
                _dragging = YES;
                _scrolling = NO;
                _decelerating = NO;
                _previousTranslation = [panGesture translationInView:self].y;
#if defined(USING_CHAMELEON) && USING_CHAMELEON
                _previousTranslation = -_previousTranslation;
#endif
                [_delegate carouselWillBeginDragging:self];
                break;
            }
            case UIGestureRecognizerStateEnded:
            case UIGestureRecognizerStateCancelled:
            case UIGestureRecognizerStateFailed: {
                _dragging = NO;
                _didDrag = YES;
                if ([self shouldDecelerate]) {
                    _didDrag = NO;
                    [self startDecelerating];
                }
                
                [self pushAnimationState:YES];
                [_delegate carouselDidEndDragging:self willDecelerate:_decelerating];
                [self popAnimationState];
                
                if (!_decelerating) {
                    if ((_scrollToItemBoundary || fabs(_scrollOffset - [self clampedOffset:_scrollOffset]) > FLOAT_ERROR_MARGIN) && !_autoscroll) {
                        if (fabs(_scrollOffset - self.currentItemIndex) < FLOAT_ERROR_MARGIN) {
                            //call scroll to trigger events for legacy support reasons
                            //even though technically we don't need to scroll at all
                            [self scrollToItemAtIndex:self.currentItemIndex duration:0.01];
                        } else if ([self shouldScroll]) {
                            NSInteger direction = (int)(_startVelocity / fabs(_startVelocity));
                            [self scrollToItemAtIndex:self.currentItemIndex + direction animated:YES];
                        } else {
                            [self scrollToItemAtIndex:self.currentItemIndex animated:YES];
                        }
                    } else {
                        [self depthSortViews];
                    }
                } else {
                    [self pushAnimationState:YES];
                    [_delegate carouselWillBeginDecelerating:self];
                    [self popAnimationState];
                }
                break;
            }
            case UIGestureRecognizerStateChanged: {
                CGFloat translation = [panGesture translationInView:self].y;
                CGFloat velocity = [panGesture velocityInView:self].y;
#if defined(USING_CHAMELEON) && USING_CHAMELEON
                translation = -translation;
                velocity = -velocity;
#endif
                CGFloat factor = 1.0;
                if (!_wrapEnabled && _bounces) {
                    factor = 1.0 - MIN(fabs(_scrollOffset - [self clampedOffset:_scrollOffset]),
                                       _bounceDistance) / _bounceDistance;
                }
                _startVelocity = -velocity * factor * _scrollSpeed / _itemWidth;
                _scrollOffset -= (translation - _previousTranslation) * factor * _offsetMultiplier / _itemWidth;
                _previousTranslation = translation;
                [self didScroll];
                break;
            }
            case UIGestureRecognizerStatePossible: {
                //do nothing
                break;
            }
        }
    }
}
#else

#pragma mark -
#pragma mark Mouse control
- (void)mouseDown:(__unused NSEvent *)theEvent
{
    _didDrag = NO;
    _startVelocity = 0.0;
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    _didDrag = YES;
    if (_scrollEnabled) {
        if (!_dragging) {
            _dragging = YES;
            [_delegate carouselWillBeginDragging:self];
        }
        _scrolling = NO;
        _decelerating = NO;
        
        CGFloat translation = _vertical? [theEvent deltaY]: [theEvent deltaX];
        CGFloat factor = 1.0;
        if (!_wrapEnabled && _bounces) {
            factor = 1.0 - MIN(fabs(_scrollOffset - [self clampedOffset:_scrollOffset]), _bounceDistance) / _bounceDistance;
        }
        
        NSTimeInterval thisTime = [theEvent timestamp];
        _startVelocity = -(translation / (thisTime - _startTime)) * factor * _scrollSpeed / _itemWidth;
        _startTime = thisTime;
        
        _scrollOffset -= translation * factor * _offsetMultiplier / _itemWidth;
        [self pushAnimationState:NO];
        [self didScroll];
        [self popAnimationState];
    }
}

- (void)mouseUp:(NSEvent *)theEvent
{
    if (!_didDrag) {
        //convert position to view
        CGPoint position = [theEvent locationInWindow];
        position = [self convertPoint:position fromView:self.window.contentView];
        
        //check for tapped view
        UIView *itemView = [self itemViewAtPoint:position];
        NSInteger index = itemView? [self indexOfItemView: itemView]: NSNotFound;
        if (index != NSNotFound) {
            if (_centerItemWhenSelected && index != self.currentItemIndex) {
                [self scrollToItemAtIndex:index animated:YES];
            }
            if (!_delegate || [_delegate carousel:self shouldSelectItemAtIndex:index]) {
                [self pushAnimationState:YES];
                [_delegate carousel:self didSelectItemAtIndex:index];
                [self popAnimationState];
            }
        }
    } else if (_scrollEnabled) {
        _dragging = NO;
        if ([self shouldDecelerate]) {
            _didDrag = NO;
            [self startDecelerating];
        }
        
        [self pushAnimationState:YES];
        [_delegate carouselDidEndDragging:self willDecelerate:_decelerating];
        [self popAnimationState];
        
        if (!_decelerating && !_autoscroll) {
            if ([self shouldScroll]) {
                NSInteger direction = (int)(_startVelocity / fabs(_startVelocity));
                [self scrollToItemAtIndex:self.currentItemIndex + direction animated:YES];
            } else {
                [self scrollToItemAtIndex:self.currentItemIndex animated:YES];
            }
        } else {
            [self pushAnimationState:YES];
            [_delegate carouselWillBeginDecelerating:self];
            [self popAnimationState];
        }
    }
}

#pragma mark -
#pragma mark Keyboard control
- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (void)keyDown:(NSEvent *)theEvent
{
    NSString *characters = [theEvent charactersIgnoringModifiers];
    if (_scrollEnabled && !_scrolling && [characters length]) {
        switch ([characters characterAtIndex:0]) {
            case NSUpArrowFunctionKey: {
                [self scrollToItemAtIndex:self.currentItemIndex-1 animated:YES];
                break;
            }
            case NSDownArrowFunctionKey: {
                [self scrollToItemAtIndex:self.currentItemIndex+1 animated:YES];
                break;
            }
        }
    }
}
#endif
@end
