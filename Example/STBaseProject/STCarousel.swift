//
//  STCarousel.swift
//  STBaseProject_Example
//
//  Created by stack on 2019/7/8.
//  Copyright © 2019 STBaseProject. All rights reserved.
//

import UIKit

public enum STCarouselOption {
    case STCarouselOptionWrap
    case STCarouselOptionShowBackfaces
    case STCarouselOptionOffsetMultiplier
    case STCarouselOptionVisibleItems
    case STCarouselOptionCount
    case STCarouselOptionArc
    case STCarouselOptionAngle
    case STCarouselOptionRadius
    case STCarouselOptionTilt
    case STCarouselOptionSpacing
    case STCarouselOptionFadeMin
    case STCarouselOptionFadeMax
    case STCarouselOptionFadeRange
    case STCarouselOptionFadeMinAlpha
}

public protocol STCarouselDataSource: NSObjectProtocol {
    func st_numberOfItemsIn(carousel: STCarousel) -> NSInteger
    func st_carouselViewForItem(in viewForItemAtIndex: STCarousel, at index: NSInteger) -> UIView
    
    func st_numberOfItemsPlaceholdersIn(carousel: STCarousel) -> NSInteger
    func st_carouselPlaceholdersViewForItem(in viewForItemAtIndex: STCarousel, at index: NSInteger) -> UIView
}

extension STCarouselDataSource {
    func st_numberOfItemsPlaceholdersIn(carousel: STCarousel) -> NSInteger {
        return 0
    }
    
    func st_carouselPlaceholdersViewForItem(in viewForItemAtIndex: STCarousel, at index: NSInteger) -> UIView {
        return UIView()
    }
}

public protocol STCarouselDelegate: NSObjectProtocol {
    func st_carouselWillBeginScrollingAnimation(carousel: STCarousel) -> Void
    func st_carouselDidEndScrollingAnimation(carousel: STCarousel) -> Void
    func st_carouselDidEndDecelerating(carousel: STCarousel) -> Void
    func st_carouselItemWidth(carousel: STCarousel) -> CGFloat
    func st_carousel(carousel: STCarousel, valueFor option: STCarouselOption, default value: CGFloat) -> CGFloat
}

extension STCarouselDelegate {
    func st_carouselItemWidth(carousel: STCarousel) -> CGFloat {
        return 0.0
    }
    
    func st_carousel(carousel: STCarousel, valueFor option: STCarouselOption, default value: CGFloat) -> CGFloat {
        return value
    }
}

open class STCarousel: UIView {
    
    private let max_visible_items: NSInteger = 30
    private let float_error_margin: CGFloat = 0.4
    private let max_toggle_duration: CGFloat = 0.4
    private let min_toggle_duration: CGFloat = 0.2
    private let scroll_duration: TimeInterval = 0.4

    private var itemWidth: CGFloat = 0.0
    private var endOffset: CGFloat = 0.0
    private var autoscroll: CGFloat = 0.0
    private var startOffset: CGFloat = 0.0
    private var startVelocity: CGFloat = 0.0
    private var lastTime: TimeInterval = 0.0
    private var startTime: TimeInterval = 0.0
    private var toggleTime: TimeInterval = 0.0
    private var scrollDuration: TimeInterval = 0.0

    private var contentView: UIView!
    private var itemViewPool: NSMutableSet!
    private var itemViews: NSMutableDictionary!
    private var placeholderViewPool: NSMutableSet!

    open weak var delegate: STCarouselDelegate?
    open weak var dataSource: STCarouselDataSource?

    public var numberOfItems: NSInteger = 0
    public var numberOfPlaceholders: NSInteger = 0
    public var numberOfVisibleItems: NSInteger = 0
    public var numberOfPlaceholdersToShow: NSInteger = 0

    private var toggle: CGFloat = 1.0
    private var scrollSpeed: CGFloat = 1.0
    private var scrollOffset: CGFloat = 0.0
    private var bounceDistance: CGFloat = 1.0
    private var offsetMultiplier: CGFloat = 1.0
    private var decelerationRate: CGFloat = 0.95
    private var perspective: CGFloat = -1.0 / 500.0
    private var previousItemIndex: NSInteger = 0
    private var previousScrollOffset: CGFloat = 0.0

    private var contentOffset: CGSize = CGSize.zero
    private var viewpointOffset: CGSize = CGSize.zero
    
    private var bounces: Bool = true
    private var didDrag: Bool = false
    private var dragging: Bool = false
    private var scrolling: Bool = false
    private var wrapEnabled: Bool = false
    private var decelerating: Bool = false
    private var scrollEnabled: Bool = true
    private var stopAtItemBoundary: Bool = true
    private var scrollToItemBoundary: Bool = true
    private var centerItemWhenSelected: Bool = true
    private var ignorePerpendicularSwipes: Bool = true
    
    private var timer: Timer?
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.setUp()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setUp() -> Void {
        
        itemViewPool = NSMutableSet.init()
        itemViews = NSMutableDictionary()

        self.createContentView()
        
        //set up accessibility
        self.accessibilityTraits = UIAccessibilityTraits.allowsDirectInteraction
        self.isAccessibilityElement = true
    }
    
    public func st_reloadData() {
        guard dataSource != nil else { return }
        self.reloadData()
    }

    private func createContentView() -> Void {
        contentView = UIView.init(frame: self.bounds)
        contentView.autoresizingMask = UIView.AutoresizingMask(rawValue: UIView.AutoresizingMask.flexibleWidth.rawValue | UIView.AutoresizingMask.flexibleHeight.rawValue)
        self.addSubview(contentView)
        
        //add pan gesture recogniser
        let panGesture: UIPanGestureRecognizer = UIPanGestureRecognizer.init(target: self, action: #selector(didPan(panGesture:)))
        panGesture.delegate = self
        contentView.addGestureRecognizer(panGesture)
        
        //add tap gesture recogniser
        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(didTap(tapGesture:)))
        tapGesture.delegate = self
        contentView.addGestureRecognizer(tapGesture)
    }
}

extension STCarousel: UIGestureRecognizerDelegate {
    
    @objc func didPan(panGesture: UIPanGestureRecognizer) -> Void {
        
    }
    
    @objc func didTap(tapGesture: UITapGestureRecognizer) -> Void {
        
    }
}

//MARK:- reloadData
extension STCarousel {
    private func reloadData() -> Void {
        for item in itemViews.allValues {
            let view = item as! UIView
            if let superView = view.superview {
                superView.removeFromSuperview()
            }
        }
        
        guard let newDataSource = dataSource, let _ = contentView.superview else {
            return
        }
        
        //get number of items and placeholders
        numberOfVisibleItems = 0
        numberOfItems = newDataSource.st_numberOfItemsIn(carousel: self)
        numberOfPlaceholders = newDataSource.st_numberOfItemsPlaceholdersIn(carousel: self)
        
        //reset view pools
        self.itemViews.removeAllObjects()
        self.itemViewPool.removeAllObjects()
        
        self.placeholderViewPool = NSMutableSet.init(capacity: numberOfPlaceholders)
    
        //layout views
        self.setNeedsLayout()
        
        //fix scroll offset
        if numberOfItems > 0, scrollOffset < 0.0 {
            self.scrollToItemAt(index: 0, animated: numberOfPlaceholders > 0)
        }
        
        self.layOutItemViews()
    }
    
    private func scrollToItemAt(index: NSInteger, animated: Bool) -> Void {
        self.scrollToItemAt(index: index, duration: animated == true ? scroll_duration : 0)
    }
    
    private func scrollToItemAt(index: NSInteger, duration: TimeInterval) -> Void {
        self.scrollTo(offset: CGFloat(index), duration: duration)
    }
    
    private func scrollTo(offset: CGFloat, duration: TimeInterval) -> Void {
        self.scrollBy(offset: offset, duration: duration)
    }
    
    private func scrollBy(offset: CGFloat, duration: TimeInterval) -> Void {
        if duration > 0.0 {
            decelerating = false
            scrolling = true
            startTime = CACurrentMediaTime()
            startOffset = scrollOffset
            scrollDuration = duration
            endOffset = startOffset + offset
            if (!wrapEnabled) {
                endOffset = self.clamped(offset: endOffset)
            }
            if let newDelegate = delegate {
                newDelegate.st_carouselWillBeginScrollingAnimation(carousel: self)
            }
            self.startAnimation()
        }
        else {
            self.scrollOffset += offset
        }
    }
    
    private func minScrollDistance(fromIndex: NSInteger, toIndex: NSInteger) -> NSInteger {
        let directDistance: NSInteger = toIndex - fromIndex
        if wrapEnabled {
            var wrappedDistance: NSInteger = min(toIndex, fromIndex) + numberOfItems - max(toIndex, fromIndex)
            if fromIndex < toIndex {
                wrappedDistance = -wrappedDistance
            }
            return (abs(directDistance) <= abs(wrappedDistance)) ? directDistance: wrappedDistance
        }
        return directDistance
    }
    
    private func minScrollDistance(fromOffset: CGFloat, toOffset: CGFloat) -> CGFloat {
        let directDistance: CGFloat = toOffset - fromOffset
        if wrapEnabled {
            var wrappedDistance: CGFloat = min(toOffset, fromOffset) + CGFloat(numberOfItems) - max(toOffset, fromOffset)
            if fromOffset < toOffset {
                wrappedDistance = -wrappedDistance
            }
            return (abs(directDistance) <= abs(wrappedDistance)) ? directDistance: wrappedDistance
        }
        return directDistance
    }
    
    private func clamped(offset: CGFloat) -> CGFloat {
        if numberOfItems == 0 {
            return -1.0
        } else if wrapEnabled {
            return offset - floor(offset / CGFloat(numberOfItems)) * CGFloat(numberOfItems)
        } else {
            return min(max(0.0, offset), max(0.0, CGFloat(numberOfItems) - 1.0))
        }
    }
    
    private func clamped(index: NSInteger) -> NSInteger {
        if numberOfItems == 0 {
            return -1
        } else if wrapEnabled {
            return index - NSInteger(floor(Double(index / numberOfItems))) * numberOfItems
        } else {
            return min(max(0, index), max(0, numberOfItems - 1))
        }
    }
    
    private func startAnimation() -> Void {
        guard let _ = timer else {
            timer = Timer.init(timeInterval: 1.0 / 60.0, target: self, selector: #selector(step), userInfo: nil, repeats: true)
            RunLoop.main.add(timer!, forMode: RunLoop.Mode.default)
            return
        }
    }
    
    private func stopAnimation() -> Void {
        if let newTimer = timer, newTimer.isValid {
            newTimer.invalidate()
        }
    }
    
    @objc func step() -> Void {
        self.pushAnimationState(enabled: true)
        let currentTime = CACurrentMediaTime()
        var delta = currentTime - lastTime
        lastTime = currentTime
        if scrolling, dragging {
            let time = min(1.0, (currentTime - startTime) / scrollDuration)
            delta = Double(self.easeInOut(time: CGFloat(time)))
            scrollOffset = startOffset + (endOffset - startOffset) * CGFloat(delta)
            self.didScroll()
            if time >= 1.0 {
                scrolling = false
                self.depthSortViews()
                self.pushAnimationState(enabled: true)
                if let newDelegate = delegate {
                    newDelegate.st_carouselDidEndScrollingAnimation(carousel: self)
                }
                self.popAnimationState()
            }
        } else if decelerating {
            let time: CGFloat = CGFloat(min(scrollDuration, currentTime - startTime))
            let acceleration: CGFloat = -startVelocity / CGFloat(scrollDuration)
            let distance: CGFloat = startVelocity * time + 0.5 * acceleration * pow(time, 2.0)
            scrollOffset = startOffset + distance
            self.didScroll()
            if abs(time - CGFloat(scrollDuration)) < float_error_margin {
                decelerating = false
                self.pushAnimationState(enabled: true)
                if let newDelegate = delegate {
                    newDelegate.st_carouselDidEndDecelerating(carousel: self)
                }
                self.popAnimationState()
                if ((scrollToItemBoundary || abs(scrollOffset - self.clamped(offset: scrollOffset)) > float_error_margin) && autoscroll != 0) {
                    if (abs(scrollOffset - CGFloat(self.currentItemIndex())) < float_error_margin) {
                        self.scrollToItemAt(index: self.currentItemIndex(), duration: 0.01)
                    } else {
                        self.scrollToItemAt(index: self.currentItemIndex(), animated: true)
                    }
                } else {
                    var difference: CGFloat = round(scrollOffset) - scrollOffset
                    if (difference > 0.5) {
                        difference = difference - 1.0
                    } else if (difference < -0.5) {
                        difference = 1.0 + difference
                    }
                    toggleTime = currentTime - Double(max_toggle_duration * abs(difference))
                    toggle = max(-1.0, min(1.0, -difference))
                }
            }
        } else if autoscroll != 0, dragging {
            self.scrollOffset = self.clamped(offset: scrollOffset - CGFloat(delta) * autoscroll)
        } else if abs(toggle) > float_error_margin {
            var toggleDuration: CGFloat = startVelocity != 0.0 ? CGFloat(min(1.0, max(0.0, 1.0 / abs(startVelocity)))): 1.0
            toggleDuration = min_toggle_duration + (max_toggle_duration - min_toggle_duration) * toggleDuration
            let time: CGFloat = CGFloat(min(1.0, (currentTime - toggleTime))) / toggleDuration
            delta = Double(self.easeInOut(time: time))
            toggle = CGFloat((toggle < 0.0) ? (delta - 1.0) : (1.0 - delta))
            self.didScroll()
        } else if autoscroll != 0 {
            self.stopAnimation()
        }
        self.popAnimationState()
    }

    private func pushAnimationState(enabled: Bool) -> Void {
        CATransaction.begin()
        CATransaction.setDisableActions(!enabled)
    }
    
    private func popAnimationState() -> Void {
        CATransaction.commit()
    }

    private func easeInOut(time: CGFloat) -> CGFloat {
        return (time < 0.5) ? 0.5 * pow(time * 2.0, 3.0): 0.5 * pow(time * 2.0 - 2.0, 3.0) + 1.0
    }

    private func didScroll() -> Void {
        if wrapEnabled || bounces {
            scrollOffset = self.clamped(offset: scrollOffset)
        } else {
            let minValue: CGFloat = -bounceDistance
            let maxValue: CGFloat = CGFloat(max(numberOfItems - 1, 0)) + bounceDistance
            if scrollOffset < minValue {
                scrollOffset = minValue
                startVelocity = 0.0
            } else if scrollOffset > maxValue {
                scrollOffset = maxValue
                startVelocity = 0.0
            }
        }
        
        //check if index has changed
        let difference: NSInteger = self.minScrollDistance(fromIndex: self.currentItemIndex(), toIndex: self.previousItemIndex)
        if difference != 0 {
            toggleTime = CACurrentMediaTime()
            toggle = CGFloat(max(-1, min(1, difference)))
            self.startAnimation()
        }
        self.loadUnloadViews()
    }

    private func depthSortViews() -> Void {
        var newItemViews: NSArray = itemViews.allValues as NSArray
        newItemViews = newItemViews.sortedArray(using: #selector(compareViewDepth(view1:view2:carousel:))) as NSArray
        if newItemViews.count > 0 {
            for item in newItemViews {
                let view: UIView = item as! UIView
                if let superView = view.superview {
                    contentView.bringSubviewToFront(superView)
                }
            }
        }
    }

    private func currentItemIndex() -> NSInteger {
        return self.clamped(index: NSInteger(round(scrollOffset)))
    }

    private func loadUnloadViews() -> Void {
        self.updateItemWidth()
        
        //update number of visible items
        self.updateNumberOfVisibleItems()
        
        //calculate visible view indices
        let visibleIndices: NSMutableSet = NSMutableSet.init(capacity: numberOfVisibleItems)
        let minValue: NSInteger = -NSInteger((ceil(CGFloat(numberOfPlaceholdersToShow) / 2.0)));
        let maxValue: NSInteger = numberOfItems - 1 + numberOfPlaceholdersToShow / 2;
        var offset: NSInteger = self.currentItemIndex() - numberOfVisibleItems / 2;
        if (!wrapEnabled) {
            offset = max(minValue, min(maxValue - numberOfVisibleItems + 1, offset));
        }
        
        for i in 0...numberOfVisibleItems - 1 {
            var index = i + offset
            if wrapEnabled {
                index = self.clamped(index: index)
            }
            let alpha = self.alphaForItemWith(offset: self.offsetForItemAt(index: index))
            if alpha > 0 {
                visibleIndices.add(NSNumber.init(value: index))
            }
        }
        
        for i in itemViews.allKeys {
            let index = i as! NSNumber
            if visibleIndices.contains(index) == false {
                let view: UIView = itemViews[index] as! UIView
                if index.intValue < 0 || index.intValue >= numberOfItems {
                    self.queuePlaceholder(view: view)
                } else {
                    self.queueItem(view: view)
                }
                view.superview?.removeFromSuperview()
                itemViews.removeObject(forKey: index)
            }
        }
        
        //add onscreen views
        for i in visibleIndices {
            let index = i as! NSNumber
            let view: UIView = itemViews.object(forKey: index) as! UIView
            if view.subviews.count > 0 {
                _ = self.loadViewAt(index: index.intValue)
            }
        }
    }
    
    private func updateItemWidth() -> Void {
        if let newDelegate = delegate {
            itemWidth = newDelegate.st_carouselItemWidth(carousel: self) != 0 ? 0 : itemWidth
        }
        
        if numberOfItems > 0 {
            if itemViews.count == 0 {
                _ = self.loadViewAt(index: 0)
            }
        }
        else if numberOfPlaceholders > 0 {
            if itemViews.count == 0 {
                _ = self.loadViewAt(index: -1)
            }
        }
    }
    
    private func loadView(index: NSInteger, containerView: UIView) -> UIView {
        self.pushAnimationState(enabled: false)
        var view: UIView?
        if let newDataSource = dataSource {
            if index < 0 {
                view = newDataSource.st_carouselPlaceholdersViewForItem(in: self, at: (NSInteger)(ceil(CGFloat(numberOfPlaceholdersToShow) / 2.0)) + index)
            }
            else if index >= numberOfItems {
                view = newDataSource.st_carouselPlaceholdersViewForItem(in: self, at: numberOfPlaceholdersToShow / 2 + index - numberOfItems)
            }
            else {
                view = newDataSource.st_carouselViewForItem(in: self, at: index)
            }
        }
        if view == nil {
            view = UIView()
        }
        self.setItemView(view: view!, index: index)
        if containerView.subviews.count > 0 {
            //get old item view
            let oldItemView: UIView = containerView.subviews.last!
            if index < 0 || index >= numberOfItems {
                self.queuePlaceholder(view: oldItemView)
            } else {
                self.queueItem(view: oldItemView)
            }
            
            //set container frame
            var frame: CGRect = containerView.bounds
            frame.size.width = view!.frame.size.width
            frame.size.height = min(itemWidth, view!.frame.size.height)
            
            containerView.bounds = frame
            
            //set view frame
            frame = view!.frame
            frame.origin.x = (containerView.bounds.size.width - frame.size.width) / 2.0
            frame.origin.y = (containerView.bounds.size.height - frame.size.height) / 2.0
            view!.frame = frame

            //switch views
            oldItemView.removeFromSuperview()
            containerView.addSubview(view!)
        } else {
            contentView.addSubview(self.contain(view: view!))
        }
        view!.superview!.layer.opacity = 0.0
        self.transformItem(view: view!, at: index)
        self.popAnimationState()
        return view!
    }
   
    private func loadViewAt(index: NSInteger) -> UIView {
        return self.loadView(index: index, containerView: UIView())
    }
    
    private func setItemView(view: UIView, index: NSInteger) -> Void {
        itemViews.setObject(view, forKey: NSNumber.init(value: index))
    }
    
    private func itemViewAt(index: NSInteger) -> UIView {
        if index < itemViews.count {
            return itemViews[NSNumber.init(value: index)] as! UIView
        }
        return UIView()
    }

    private func queueItem(view: UIView) -> Void {
        if view.subviews.count > 0 {
            itemViewPool.add(view)
        }
    }

    private func queuePlaceholder(view: UIView) -> Void {
        if view.subviews.count > 0 {
            placeholderViewPool.add(view)
        }
    }

    private func dequeueItemView() -> UIView {
        let view: UIView? = itemViewPool.anyObject() as? UIView
        if view != nil {
            itemViewPool.remove(view!)
        }
        return view ?? UIView()
    }

    private func dequeuePlaceholderView() -> UIView {
        let view: UIView? = placeholderViewPool.anyObject() as? UIView
        if view != nil {
            placeholderViewPool.remove(view!)
        }
        return view ?? UIView()
    }
    
    private func layOutItemViews() -> Void {
        guard let _ = dataSource, let _ = contentView else { return }
        wrapEnabled = false
        let result = self.valueFor(option: .STCarouselOptionWrap, default: CGFloat(NSNumber.init(value: wrapEnabled).floatValue))
        if result == 1 {
            wrapEnabled = true
        }
        //no placeholders on wrapped carousels
        numberOfPlaceholdersToShow = (wrapEnabled == true ? 0 : numberOfPlaceholders)
        
        //set item width
        self.updateItemWidth()
        
        //update number of visible items
        self.updateNumberOfVisibleItems()
        
        //prevent false index changed event
        previousScrollOffset = self.scrollOffset
    
        //update offset multiplier
        offsetMultiplier = self.valueFor(option: .STCarouselOptionOffsetMultiplier, default: offsetMultiplier)
    
        //align
        if !scrolling, !decelerating, autoscroll != 0 {
            if scrollToItemBoundary, self.currentItemIndex() != -1 {
                self.scrollToItemAt(index: self.currentItemIndex(), animated: true)
            } else {
                scrollOffset = self.clamped(offset: scrollOffset)
            }
        }
        
        //update views
        self.didScroll()
    }
    
    private func updateNumberOfVisibleItems() -> Void {
        numberOfVisibleItems = max_visible_items;
        numberOfVisibleItems = min(max_visible_items, numberOfVisibleItems);
        numberOfVisibleItems = max(0, min(numberOfVisibleItems, numberOfItems + numberOfPlaceholdersToShow));
    }
    
    private func contain(view: UIView) -> UIView {
        //set item width
        if itemWidth != 0 {
            itemWidth = view.bounds.size.height
        }
        
        //set container frame
        var frame: CGRect = view.bounds
        frame.size.width = frame.size.width
        frame.size.height = itemWidth
        
        let containerView: UIView = UIView.init(frame: frame)

        //set view frame
        frame = view.frame
        frame.origin.x = (containerView.bounds.size.width - frame.size.width) / 2.0
        frame.origin.y = (containerView.bounds.size.height - frame.size.height) / 2.0
        view.frame = frame
        containerView.addSubview(view)
        containerView.layer.opacity = 0

        return containerView
    }
    
    private func offsetForItemAt(index: NSInteger) -> CGFloat {
        var offset: CGFloat = CGFloat(index) - scrollOffset
        if wrapEnabled {
            if offset > CGFloat(numberOfItems) / 2.0 {
                offset -= CGFloat(numberOfItems)
            } else if offset < -CGFloat(numberOfItems) / 2.0 {
                offset += CGFloat(numberOfItems)
            }
        }
        offset = -offset
        return offset
    }
    
    private func alphaForItemWith(offset: CGFloat) -> CGFloat {
        var fadeMin: CGFloat = 0.0
        var fadeMax: CGFloat = CGFloat(Double.infinity)
        var fadeRange: CGFloat = 1.0;
        var fadeMinAlpha: CGFloat = 0.0;
        fadeMin = self.valueFor(option: .STCarouselOptionFadeMin, default: fadeMin)
        fadeMax = self.valueFor(option: .STCarouselOptionFadeMax, default: fadeMax)
        fadeRange = self.valueFor(option: .STCarouselOptionFadeRange, default: fadeRange)
        fadeMinAlpha = self.valueFor(option: .STCarouselOptionFadeMinAlpha, default: fadeMinAlpha)
        var factor: CGFloat = 0.0;
        if offset > fadeMax {
            factor = offset - fadeMax;
        } else if offset < fadeMin {
            factor = fadeMin - offset;
        }
        return 1.0 - min(factor, fadeRange) / fadeRange * (1.0 - fadeMinAlpha);
    }
    
    private func transformForItemViewWith(offset: CGFloat) -> CATransform3D {
        var transform: CATransform3D = CATransform3DIdentity
        transform.m34 = perspective
        transform = CATransform3DTranslate(transform, -viewpointOffset.width, -viewpointOffset.height, 0.0)
        var tilt: CGFloat = self.valueFor(option: .STCarouselOptionTilt, default: 0.3)
        let spacing: CGFloat = self.valueFor(option: .STCarouselOptionSpacing, default: 1.0)
        tilt = -tilt;
        let newOffset = -offset
        return CATransform3DTranslate(transform, 0.0, offset * itemWidth * tilt, newOffset * itemWidth * spacing)
    }
    
    private func transformItem(view: UIView, at index: NSInteger) -> Void {
        
        let offset: CGFloat = self.offsetForItemAt(index: index)
        view.superview?.layer.opacity = Float(self.alphaForItemWith(offset: offset))
        view.superview?.center = CGPoint.init(x: self.bounds.size.width / 2.0 + contentOffset.width, y: self.bounds.size.height / 2.0 + contentOffset.height)
        view.superview?.isUserInteractionEnabled = (index == self.currentItemIndex())
        view.superview?.layer.rasterizationScale = UIScreen.main.scale
        view.layoutIfNeeded()

        let clampedOffset: CGFloat = max(-1.0, min(1.0, offset))
        if (decelerating || (scrolling && !dragging && !didDrag) || (autoscroll != 0 && !dragging) || (!wrapEnabled && (scrollOffset < 0 || Int(scrollOffset) >= numberOfItems - 1))) {
            if offset > 0 {
                toggle = (offset <= 0.5) ? (-clampedOffset) : (1.0 - clampedOffset)
            } else {
                toggle = (offset > -0.5) ? (-clampedOffset) : (-1.0 - clampedOffset)
            }
        }

        let transform: CATransform3D = self.transformForItemViewWith(offset: offset)
        view.superview?.layer.transform = transform;
        let showBackfaces = view.layer.isDoubleSided;
        if showBackfaces == false {
            view.superview?.isHidden = !(transform.m33 > 0.0)
        }
    }

    private func valueFor(option: STCarouselOption, default value: CGFloat) -> CGFloat {
        if let newDelegate = delegate {
            return newDelegate.st_carousel(carousel: self, valueFor: option, default: value)
        }
        return 0.0
    }
    
    @objc private func compareViewDepth(view1: UIView, view2: UIView, carousel : STCarousel) -> ComparisonResult {
        
        //compare depths
        let t1: CATransform3D = view1.superview?.layer.transform ?? CATransform3D.init()
        let t2: CATransform3D = view2.superview?.layer.transform ?? CATransform3D.init()
        let z1:CGFloat = t1.m13 + t1.m23 + t1.m33 + t1.m43;
        let z2:CGFloat = t2.m13 + t2.m23 + t2.m33 + t2.m43;
        var difference:CGFloat = z1 - z2;
            
        if difference == 0.0 {
            let t3: CATransform3D = self.currentItemView().superview?.layer.transform ?? CATransform3D.init()
            let y1: CGFloat = t1.m12 + t1.m22 + t1.m32 + t1.m42;
            let y2: CGFloat = t2.m12 + t2.m22 + t2.m32 + t2.m42;
            let y3: CGFloat = t3.m12 + t3.m22 + t3.m32 + t3.m42;
            difference = abs(y2 - y3) - abs(y1 - y3);
        }
        return (difference < 0.0) ? ComparisonResult.orderedAscending: ComparisonResult.orderedDescending;
    }

    private func currentItemView() -> UIView {
        return self.itemViewAt(index: self.currentItemIndex())
    }
}

//public enum STCardDirection {
//    case up, left, down, right
//}
//
//public protocol STCarouselDelegate: AnyObject {
//    func st_didClick(cardView: STCarousel, with index: Int)
//    func st_remove(cardView: STCarousel, item: STCardItem, with index: Int)
//    func st_revoke(cardView: STCarousel, item: STCardItem, with index: Int)
//}
//
//protocol STCarouselDataSource: AnyObject {
//    func st_numberOfItems(`in` cardView: STCarousel) -> Int
//    func st_cardItem(_ cardView: STCarousel, cellForItemAt Index: Int) -> STCardItem
//    func st_cardItem(_ cardView: STCarousel, sizeForItemAt index: Int) -> CGSize
//}
//
//extension STCarouselDataSource {
//    func st_cardItem(_ cardView: STCarousel, sizeForItemAt index: Int) -> CGSize {
//        return CGSize.init(width: 335, height: 188)
//    }
//}
//
//open class STCarousel: UIView {
//
//    weak var delegate: STCarouselDelegate?
//    weak var dataSource: STCarouselDataSource?
//
//    public var offsetY: CGFloat = 0.0
//    public var offsetX: CGFloat = 20.0
//
//    private let duration: TimeInterval = 1.0 // 动画持续时间
//    private let shortDuration: TimeInterval = 0.5
//
//    private var firSTCarousel: STCardItem!
//    private var secondCardView: STCardItem!
//    private var thirdCardView: STCardItem!
//
//    private var cardCount: Int = 0 // 卡片总量
//    private var currentIndex: Int = 0 // 当前index
//    private var showCardsNumber: Int = 3 // 展示的卡片数
//    public var sizePercent: CGFloat = 0.05 // 顶部卡片拖动中，底部卡片缩放系数
//    private var oldCenter: CGPoint = CGPoint.zero
//    private var alphaList: Array<CGFloat> = Array<CGFloat>() // 可视卡片透明度数组
//    private var cards: Array<STCardItem> = Array<STCardItem>() // 卡片内容数组
//
//    public override init(frame: CGRect) {
//        super.init(frame: frame)
////        self.createShowCardView()
//    }
//
//    public init(frame: CGRect, showCardsNumber: Int) {
//        super.init(frame: frame)
//        self.backgroundColor = UIColor.purple
//        self.showCardsNumber = showCardsNumber
////        self.createShowCardView()
//    }
//
//    required public init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    public func st_reloadData() {
//        guard let dataSource = dataSource else { return }
//        cardCount = dataSource.st_numberOfItems(in: self)
//        for index in 0..<cardCount {
//            let item = createItem(with: index)
//            cards.append(item)
//        }
//        self.alphaList = self.alphaArray()
//    }
//
//    open override func layoutSubviews() {
//        super.layoutSubviews()
//        self.createShowCardView()
//        self.addCardViewsToShow()
//    }
//
//    private func createItem(with index: Int) -> STCardItem {
//        let size = itemSize(at: index)
//        let item = itemView(at: index)
//        item.layer.cornerRadius = 10
////        item.delegate = self
////        item.frame = CGRect(x: frame.width * 0.5 - size.width * 0.5 + CGFloat(index * 20), y: frame.height * 0.5 - size.height * 0.5 + CGFloat(index * 20), width: size.width, height: size.height)
////        item.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
//        return item
//    }
//
//    private func itemSize(at index: Int) -> CGSize {
//        guard let dataSource = dataSource, index < cardCount else {
//            return frame.size
//        }
//
//        var size = dataSource.st_cardItem(self, sizeForItemAt: index)
//        if size.width > frame.width || size.width == 0 {
//            print("wraning: item.width == 0")
//            size.width = frame.width
//        }
//        if size.height > frame.height || size.height == 0 {
//            print("wraning: item.height == 0")
//            size.height = frame.height
//        }
//        return size
//    }
//
//    private func itemView(at index: Int) -> STCardItem {
//        guard let dataSource = dataSource else {
//            return STCardItem()
//        }
//        return dataSource.st_cardItem(self, cellForItemAt: index)
//    }
//
//    private func addCardViewsToShow() -> Void {
//        if self.cards.count == 0 {
//            // nothing
//        } else {
//            if cardCount < showCardsNumber {
//                let removeNum = showCardsNumber - cardCount
//                showCardsNumber = cardCount
//                for _ in 0...removeNum - 1 {
//                    self.alphaList.remove(at: 0)
//                }
//                if cardCount == 1 {
//                    addFirstViewToShowCardView()
//                } else if cardCount == 2 {
//                    addFirstViewToShowCardView()
//                    addSecondViewToShowCardView()
//                }
//            } else {
//                addFirstViewToShowCardView()
//                addSecondViewToShowCardView()
//                addThirdViewToShowCardView()
//            }
//        }
//    }
//
//    private func addFirstViewToShowCardView() -> Void {
//        let firstView = self.cards[0]
//        firSTCarousel.addSubview(firstView)
//        firstView.snp.makeConstraints { (make) in
//            make.top.left.right.bottom.equalToSuperview()
//        }
//    }
//
//    private func addSecondViewToShowCardView() -> Void {
//        let secondView = self.cards[1]
//        secondCardView.addSubview(secondView)
//        secondView.snp.makeConstraints { (make) in
//            make.top.left.right.bottom.equalToSuperview()
//        }
//    }
//
//    private func addThirdViewToShowCardView() -> Void {
//        let thirdView = self.cards[2]
//        thirdCardView.addSubview(thirdView)
//        thirdView.snp.makeConstraints { (make) in
//            make.top.left.right.bottom.equalToSuperview()
//        }
//    }
//
//    private func alphaArray() -> Array<CGFloat> {
//        var array: Array<CGFloat> = Array<CGFloat>()
//        let interval: CGFloat = CGFloat((showCardsNumber - 1) / 10)
//        for index in 0...showCardsNumber - 1 {
//            if index == 0 {
//                array.append(0.0)
//                continue
//            }
//            if index == showCardsNumber - 1 {
//                array.append(1.0)
//                break
//            }
//            array.append(CGFloat(index) * interval + 0.2)
//        }
//        return array
//    }
//
//    private func createShowCardView() -> Void {
//        let size = itemSize(at: 0)
//
//        firSTCarousel = cardView()
//        firSTCarousel.cartItemIdentifier = .one
//        firSTCarousel.frame = CGRect(x: 80, y: 0, width: size.width, height: 188)
//        firSTCarousel.originCenter = firSTCarousel.center
//        insertSubview(firSTCarousel, at: 0)
////        firSTCarousel.snp.makeConstraints { (make) in
////            make.top.equalTo(5)
////            make.left.equalTo(40)
////            make.right.equalTo(0)
////            make.height.equalTo(188)
////        }
//
//        secondCardView = cardView()
//        secondCardView.cartItemIdentifier = .two
//        secondCardView.frame = CGRect(x: 100, y: 20, width: size.width, height: 188)
//        secondCardView.originCenter = secondCardView.center
//        insertSubview(secondCardView, at: 0)
////        secondCardView.snp.makeConstraints { (make) in
////            make.top.equalTo(18)
////            make.left.equalTo(73)
////            make.right.equalTo(0)
////            make.height.equalTo(188)
////        }
//
//        thirdCardView = cardView()
//        thirdCardView.cartItemIdentifier = .three
//        thirdCardView.frame = CGRect(x: 120, y: 40, width: size.width, height: 188)
//        thirdCardView.originCenter = thirdCardView.center
//        insertSubview(thirdCardView, at: 0)
////        thirdCardView.snp.makeConstraints { (make) in
////            make.top.equalTo(31)
////            make.left.equalTo(108)
////            make.right.equalTo(0)
////            make.height.equalTo(188)
////        }
//    }
//
//    private func cardView() -> STCardItem {
//        let view: STCardItem = STCardItem()
////        view.backgroundColor = UIColor.white
////        view.layer.cornerRadius = 10
//        view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handleGesture(_:))))
//        return view
//    }
//
////    /// 返回上一张卡片.
////    public func revokeCard() {
////        if let topItem = subviews.last as? STCardItem {
////            let index = topItem.tag - tagMark - 1
////            guard index >= 0, let lastFrame = self.lastFrames[index] else {
////                print("no item to revoke")
////                return
////            }
////            let item = createItem(with: index)
////            addSubview(item)
////            item.isHidden = true
////            UIView.animate(withDuration: 0.01, animations: {
////                item.transform = CGAffineTransform(translationX: lastFrame.origin.x, y: lastFrame.origin.y)
////            }, completion: { (_) in
////                item.isHidden = false
////                UIView.animate(withDuration: 0.25, animations: { [weak self] in
////                    item.transform = CGAffineTransform.identity
////                    self?.relayoutItem(isRevoke: true)
////                    }, completion: { [weak self] (_) in
////                        if self != nil {
////                            self?.delegate?.st_revoke(cardView: self!, item: item, with: index)
////                        }
////                })
////            })
////        }
////    }
////
////    private func relayoutItem(isRevoke: Bool = false) {
////        for (index, item) in subviews.reversed().enumerated() {
////            if index == 0 {
////                item.isUserInteractionEnabled = true
////                if isRevoke { continue }
////            }
////            if !isOverlap {
////                UIView.animate(withDuration: 0.1, animations: {
////                    let scale = 1 - 0.05 * CGFloat(index)
////                    UIView.animate(withDuration: 0.1, animations: {
////                        let transform = CGAffineTransform(scaleX: scale, y: scale).translatedBy(x: 0, y: 25 * CGFloat(index))
////                        item.transform = transform
////                    })
////                })
////            }
////        }
////    }
//}
//
////extension STCarousel: STCardItemDelegate {
////    func st_removeFromSuperView(item: STCardItem) {
//////        let index = item.tag - tagMark
//////        lastFrames[index] = item.frame
//////        if count > 0 {
//////            count -= 1
//////        }
//////        relayoutItem()
//////        delegate?.st_remove(cardView: self, item: item, with: index)
////    }
////}
//
////MARK:- handle UITapGestureRecognizer
//extension STCarousel {
//    @objc private func handleGesture(_ pan: UIPanGestureRecognizer) {
//        let tempView: STCardItem = pan.view as! STCardItem
//        let velocity: CGPoint = pan.velocity(in: UIApplication.shared.keyWindow)
//        if pan.state == .began {
//            self.oldCenter = tempView.center
//        } else if pan.state == .changed {
//            let movePoint = pan.translation(in: tempView)
//            let absX = abs(movePoint.x)
//            let absY = abs(movePoint.y)
//            // 设置滑动有效距离
//            if max(absX, absY) < 10 {
//                return
//            }
//
//            if absX > absY {
//                if movePoint.x < 0 {
//                    print("向左滑动")
//                } else {
//                    print("向右滑动")
//                }
//                // do nothing
//            } else if absY > absX {
//                let translation: CGPoint = pan.translation(in: tempView)
//                if (movePoint.y < 0) {
//                    print("向上滑动")
////                    cardView.center = CGPoint.init(x: cardView.center.x, y: cardView.center.y + translation.y)
//                    tempView.center = CGPoint.init(x: tempView.center.x, y: tempView.center.y + translation.y)
//                } else {
//                    print("向下滑动")
//                    if self.currentIndex == 0 {
//                        // 说明当前是第一张卡片
//                        tempView.center = CGPoint.init(x: tempView.center.x, y: tempView.center.y + translation.y)
//
//                    } else if self.currentIndex > 0, self.currentIndex < self.cards.count {
//                        // 返回上一张卡片
//                        let lastCard: STCardItem = self.cards[self.currentIndex - 1]
//                        UIView.animate(withDuration: self.duration, animations: {
//                            lastCard.center = self.oldCenter
//                        }) { (done) in
//
//                        }
//                    }
//                }
//            }
//            // 偏移系数
////            let xOffPercent: CGFloat = (cardView.center.x - self.center.x) / self.center.x
////            let rotation: CGFloat = CGFloat(Double.pi / 2 / 10.5) * xOffPercent
////            cardView.transform = CGAffineTransform(rotationAngle: -rotation)
//            pan.setTranslation(CGPoint.zero, in: tempView)
//            // 给其余底部视图添加缩放动画
////            self.animationBlowView(xOffPercent: xOffPercent)
//            self.reLayoutThreeShowCardView(currentView: tempView)
//
//        } else if pan.state == .ended {
//            // 移除拖动视图逻辑
//            UIView.animate(withDuration: self.duration, animations: {
//                tempView.center = CGPoint.init(x: tempView.center.x, y: -1000)
//            }) { (done) in
//                self.remove(card: tempView)
//                // 下面两个view位置变化： 1 -> 0, 2 -> 1，移除的view 位置变化： 0->2
////                self.reLayoutThreeShowCardView(currentView: tempView)
//            }
//            if (sqrt(pow(velocity.x, 2) + pow(velocity.y, 2)) < 1100.0) {
//                // 移动区域半径大于120pt
//                if ((sqrt(pow(self.oldCenter.x - tempView.center.x, 2) + pow(self.oldCenter.y - tempView.center.y,2))) > 120) {
//
////                    UIView.animate(withDuration: 0.6) {
////                        let window = UIApplication.shared.keyWindow
////                        let rect: CGRect = cardView.convert(cardView.bounds, to: window)
////                        cardView.center = CGPoint.init(x: cardView.center.x, y: cardView.center.y - rect.origin.y - 50)
////                        cardView.center = CGPoint.init(x: cardView.center.x, y: -1000)
////
////                    }
//
////                    UIView.animate(withDuration: self.duration, animations: {
////                        tempView.center = CGPoint.init(x: tempView.center.x, y: -1000)
////                    }) { (done) in
////                        self.remove(card: tempView)
////                        // 下面两个view位置变化： 1 -> 0, 2 -> 1，移除的view 位置变化： 0->2
////                        self.reLayoutThreeShowCardView(currentView: tempView)
////                    }
//                } else {
////                    UIView.animate(withDuration: self.shortDuration) {
////                        tempView.center = self.oldCenter
////                        tempView.transform = CGAffineTransform(rotationAngle: 0)
////                    }
//                }
//            } else {
//                // 移除，以手势速度飞出
////                UIView.animate(withDuration: self.shortDuration, animations: {
////                    tempView.center = velocity
////                }) { (done) in
////                    self.remove(card: tempView)
////                }
//            }
//
//            // 加速度 小于 1100points/second
////            if (sqrt(pow(velocity.x, 2) + pow(velocity.y, 2)) < 1100.0) {
////                // 移动区域半径大于120pt
////                if ((sqrt(pow(self.oldCenter.x - cardView.center.x, 2) + pow(self.oldCenter.y - cardView.center.y,2))) > 120) {
////
////                    // 移除，自然垂落
////                    UIView.animate(withDuration: 0.6) {
////                        let window = UIApplication.shared.keyWindow
////                        let rect: CGRect = cardView.convert(cardView.bounds, to: window)
////                        cardView.center = CGPoint.init(x: cardView.center.x, y: cardView.center.y - rect.origin.y - 50)
////                    }
//////                    self.animationBlowView(xOffPercent: 1)
////                    self.perform(#selector(remove(card:)), with: nil, afterDelay: 1)
////                } else {
////                    UIView.animate(withDuration: 0.6) {
////                        cardView.center = self.oldCenter
////                        cardView.transform = CGAffineTransform(rotationAngle: 0)
//////                        self.animationBlowView(xOffPercent: 0)
////                    }
////                }
////            } else {
////
////                // 移除，以手势速度飞出
////                UIView.animate(withDuration: 0.5, animations: {
////                    cardView.center = velocity
////                }) { (done) in }
//////                self.animationBlowView(xOffPercent: 1)
////                self.perform(#selector(remove(card:)), with: nil, afterDelay: 0.25)
////            }
//        }
//    }
//
//    private func animationBlowView(xOffPercent: CGFloat) -> Void {
//        for i in 0...showCardsNumber - 1 {
//            var index = self.currentIndex - i - 1
//            if index < 0 {
//                index = self.cardCount + index
//            }
//
//            let otherView: STCardItem = self.cards[index]
//            // 透明度
////            let alpha: CGFloat = self.alphaList[showCardsNumber - i - 2] + (self.alphaList[showCardsNumber - i - 1] - self.alphaList[showCardsNumber - i - 2]) * xOffPercent
////            otherView.alpha = alpha
//
//            // 中心
//            let point: CGPoint = CGPoint.init(x: self.center.x + self.offsetX * CGFloat(i + 1) - self.offsetX * xOffPercent - self.frame.origin.x, y: self.center.y + self.offsetY * CGFloat(i + 1) - self.offsetY * xOffPercent - self.frame.origin.y)
//            otherView.center = point
//
//            // 缩放大小
//            let scale: CGFloat = 1.0 - sizePercent * CGFloat(i + 1) + xOffPercent * sizePercent
//            otherView.transform = CGAffineTransform(scaleX: scale, y: scale)
//        }
//    }
//
//    @objc func remove(card: STCardItem) -> Void {
////        if card != nil {
////            card.removeGestureRecognizer(<#UIGestureRecognizer#>)
////            card.removeFromSuperview()
////        }
//        //card.removeFromSuperview()
//        // "移除"当前view，并添加第 showCardsNumber + 1 到view
//        self.currentIndex += 1
////        self.currentIndex -= 1
////        if self.currentIndex < 0 {
////            self.currentIndex = self.cardCount - 1
////        }
//
//        if self.currentIndex == cardCount {
//            self.currentIndex = 0//cardCount - 1
//        }
//    }
//
//    private func reLayoutThreeShowCardView(currentView: STCardItem) -> Void {
//        let size = itemSize(at: 0)
////        firSTCarousel.center = self.oldCenter
////        secondCardView.center = self.oldCenter
////        thirdCardView.center = self.oldCenter
//
//        if currentView.cartItemIdentifier == .one {
//            self.sendSubviewToBack(firSTCarousel)
//            secondCardView.frame = CGRect.init(x: secondCardView.frame.origin.x, y: secondCardView.frame.origin.y - 13, width: secondCardView.frame.size.width, height: secondCardView.frame.size.height)
////            secondCardView.center = CGPoint.init(x: secondCardView.center.x, y: secondCardView.center.y + 13.0)
////            secondCardView.snp.updateConstraints { (make) in
////                make.top.equalTo(5)
////                make.left.equalTo(40)
////                make.right.equalTo(0)
////                make.height.equalTo(188)
////            }
//
////            thirdCardView.center = CGPoint.init(x: thirdCardView.center.x, y: thirdCardView.center.y + 26.0)
//
////            thirdCardView.snp.updateConstraints { (make) in
////                make.top.equalTo(18)
////                make.left.equalTo(73)
////                make.right.equalTo(0)
////                make.height.equalTo(188)
////            }
//
//            thirdCardView.frame = CGRect.init(x: thirdCardView.frame.origin.x, y: thirdCardView.frame.origin.y - 26, width: thirdCardView.frame.size.width, height: thirdCardView.frame.size.height)
//
//            UIView.animate(withDuration: 2, animations: {
//                self.firSTCarousel.frame = CGRect.init(x: self.firSTCarousel.frame.origin.x, y: self.firSTCarousel.frame.origin.y - 1000, width: self.firSTCarousel.frame.size.width, height: self.firSTCarousel.frame.size.height)
//            }) { (done) in
//                self.firSTCarousel.frame = CGRect.init(x: self.firSTCarousel.frame.origin.x, y: self.secondCardView.frame.origin.y - 26, width: self.firSTCarousel.frame.size.width, height: self.firSTCarousel.frame.size.height)
//            }
//
//
////            firSTCarousel.center = CGPoint.init(x: firSTCarousel.center.x, y: self.center.y + 18.0)
//
////            firSTCarousel.snp.updateConstraints { (make) in
////                make.top.equalTo(31)
////                make.left.equalTo(108)
////                make.right.equalTo(0)
////                make.height.equalTo(188)
////            }
////            secondCardView.frame = CGRect(x: frame.width * 0.5 - size.width * 0.5, y: frame.height * 0.5 - size.height * 0.5, width: size.width, height: size.height)
////            thirdCardView.frame = CGRect(x: frame.width * 0.5 - size.width * 0.5 + CGFloat(1 * 20), y: frame.height * 0.5 - size.height * 0.5 + CGFloat(1 * 20), width: size.width, height: size.height)
//
////            for subview in firSTCarousel.subviews {
////                subview.removeFromSuperview()
////            }
//
////            firSTCarousel.frame = CGRect(x: frame.width * 0.5 - size.width * 0.5 + CGFloat(2 * 20), y: frame.height * 0.5 - size.height * 0.5 + CGFloat(2 * 20), width: size.width, height: size.height)
//        } else if currentView.cartItemIdentifier == .two {
//            self.sendSubviewToBack(secondCardView)
//            thirdCardView.snp.updateConstraints { (make) in
//                make.top.equalTo(5)
//                make.left.equalTo(40)
//                make.right.equalTo(0)
//                make.height.equalTo(188)
//            }
//
//            firSTCarousel.snp.updateConstraints { (make) in
//                make.top.equalTo(18)
//                make.left.equalTo(73)
//                make.right.equalTo(0)
//                make.height.equalTo(188)
//            }
//
//            secondCardView.snp.updateConstraints { (make) in
//                make.top.equalTo(31)
//                make.left.equalTo(108)
//                make.right.equalTo(0)
//                make.height.equalTo(188)
//            }
////            thirdCardView.frame = CGRect(x: frame.width * 0.5 - size.width * 0.5, y: frame.height * 0.5 - size.height * 0.5, width: size.width, height: size.height)
////            firSTCarousel.frame = CGRect(x: frame.width * 0.5 - size.width * 0.5 + CGFloat(1 * 20), y: frame.height * 0.5 - size.height * 0.5 + CGFloat(1 * 20), width: size.width, height: size.height)
////            secondCardView.frame = CGRect(x: frame.width * 0.5 - size.width * 0.5 + CGFloat(2 * 20), y: frame.height * 0.5 - size.height * 0.5 + CGFloat(2 * 20), width: size.width, height: size.height)
//        } else if currentView.cartItemIdentifier == .three {
//
//            firSTCarousel.snp.updateConstraints { (make) in
//                make.top.equalTo(5)
//                make.left.equalTo(40)
//                make.right.equalTo(0)
//                make.height.equalTo(188)
//            }
//
//            secondCardView.snp.updateConstraints { (make) in
//                make.top.equalTo(18)
//                make.left.equalTo(73)
//                make.right.equalTo(0)
//                make.height.equalTo(188)
//            }
//
//            thirdCardView.snp.updateConstraints { (make) in
//                make.top.equalTo(31)
//                make.left.equalTo(108)
//                make.right.equalTo(0)
//                make.height.equalTo(188)
//            }
//
////            self.sendSubviewToBack(thirdCardView)
////            firSTCarousel.frame = CGRect(x: frame.width * 0.5 - size.width * 0.5, y: frame.height * 0.5 - size.height * 0.5, width: size.width, height: size.height)
////            secondCardView.frame = CGRect(x: frame.width * 0.5 - size.width * 0.5 + CGFloat(1 * 20), y: frame.height * 0.5 - size.height * 0.5 + CGFloat(1 * 20), width: size.width, height: size.height)
////            thirdCardView.frame = CGRect(x: frame.width * 0.5 - size.width * 0.5 + CGFloat(2 * 20), y: frame.height * 0.5 - size.height * 0.5 + CGFloat(2 * 20), width: size.width, height: size.height)
//        }
//        self.layoutIfNeeded()
//    }
//
////    firSTCarousel.frame = CGRect(x: frame.width * 0.5 - size.width * 0.5, y: frame.height * 0.5 - size.height * 0.5, width: size.width, height: size.height)
////    secondCardView.frame = CGRect(x: frame.width * 0.5 - size.width * 0.5 + CGFloat(1 * 20), y: frame.height * 0.5 - size.height * 0.5 + CGFloat(1 * 20), width: size.width, height: size.height)
////    thirdCardView.frame = CGRect(x: frame.width * 0.5 - size.width * 0.5 + CGFloat(2 * 20), y: frame.height * 0.5 - size.height * 0.5 + CGFloat(2 * 20), width: size.width, height: size.height)
//
////    firSTCarousel.frame = CGRect(x: 80, y: 0, width: size.width - 80, height: 188)
////    secondCardView.frame = CGRect(x: 100, y: 20, width: size.width, height: 188)
////    thirdCardView.frame = CGRect(x: 120, y: 40, width: size.width, height: 188)
//
////    firSTCarousel.snp.makeConstraints { (make) in
////    make.top.right.equalTo(0)
////    make.left.equalTo(40)
////    make.height.equalTo(188)
////    }
////
////    thirdCardView.snp.makeConstraints { (make) in
////    make.top.equalTo(26)
////    make.left.equalTo(40)
////    make.right.equalTo(108)
////    make.height.equalTo(188)
////    }
////
////    secondCardView.snp.makeConstraints { (make) in
////    make.top.equalTo(13)
////    make.left.equalTo(40)
////    make.right.equalTo(73)
////    make.height.equalTo(188)
////    }
//}
