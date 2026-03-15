//
//  STIBInspectable.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2017/02/24.
//

import UIKit

// MARK: - 约束适配类型
public enum STConstraintAdaptType {
    case width           // 用于宽度约束
    case height          // 高用于高度约束
    case both            // 宽高都适配，通常用于尺寸约束
    case spacing         // 间距适配 - 用于元素之间的距离
    case margin          // 边距适配 - 用于视图与父视图边缘的距离
    case fontSize        // 字体大小适配
    case custom(CGFloat) // 自定义比例适配
}

extension NSLayoutConstraint {
    
    private struct AssociatedKeys {
        static var autoConstantKey: UInt8 = 0
        static var adaptTypeKey: UInt8 = 1
        static var originalConstantKey: UInt8 = 2
        static var isAdaptedKey: UInt8 = 3
    }
    
    /// 是否启用自动适配
    private var _autoConstant: Bool {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.autoConstantKey) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.autoConstantKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// 适配类型
    private var _adaptType: STConstraintAdaptType {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.adaptTypeKey) as? STConstraintAdaptType ?? .both
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.adaptTypeKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// 原始约束值
    private var _originalConstant: CGFloat {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.originalConstantKey) as? CGFloat ?? self.constant
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.originalConstantKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// 是否已经适配过
    private var _isAdapted: Bool {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.isAdaptedKey) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.isAdaptedKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    // MARK: - IBInspectable 属性
    
    /// 是否启用自动适配（IBInspectable）
    @IBInspectable open var autoConstant: Bool {
        set {
            _autoConstant = newValue
            if newValue && !_isAdapted {
                _originalConstant = self.constant
                self.adaptConstraintIfNeeded()
            } else if !newValue && _isAdapted {
                self.constant = _originalConstant
                _isAdapted = false
            }
        }
        get {
            return _autoConstant
        }
    }
    
    /// 适配类型（IBInspectable）
    @IBInspectable open var adaptType: Int {
        set {
            let type: STConstraintAdaptType
            switch newValue {
            case 0: type = .width
            case 1: type = .height
            case 2: type = .both
            case 3: type = .spacing
            case 4: type = .margin
            case 5: type = .fontSize
            default: type = .both
            }
            _adaptType = type
            if _autoConstant && !_isAdapted {
                self.adaptConstraintIfNeeded()
            }
        }
        get {
            switch _adaptType {
            case .width: return 0
            case .height: return 1
            case .both: return 2
            case .spacing: return 3
            case .margin: return 4
            case .fontSize: return 5
            case .custom: return 2
            }
        }
    }
    
    /// 自定义适配比例（IBInspectable）
    @IBInspectable open var customAdaptRatio: CGFloat {
        set {
            _adaptType = .custom(newValue)
            
            if _autoConstant && !_isAdapted {
                self.adaptConstraintIfNeeded()
            }
        }
        get {
            if case .custom(let ratio) = _adaptType {
                return ratio
            }
            return 1.0
        }
    }
    
    // MARK: - 适配方法
    
    /// 执行约束适配
    private func adaptConstraintIfNeeded() {
        guard _autoConstant && !_isAdapted else { return }
        let originalValue = _originalConstant
        let adaptedValue: CGFloat
        switch _adaptType {
        case .width:
            adaptedValue = STDeviceAdapter.scaledWidth(originalValue)
        case .height:
            adaptedValue = STDeviceAdapter.scaledHeight(originalValue)
        case .both:
            adaptedValue = STDeviceAdapter.scaledValue(originalValue)
        case .spacing:
            adaptedValue = STDeviceAdapter.scaledSpacing(originalValue)
        case .margin:
            adaptedValue = STDeviceAdapter.scaledSpacing(originalValue)
        case .fontSize:
            adaptedValue = STDeviceAdapter.scaledFontSize(originalValue)
        case .custom(let ratio):
            adaptedValue = originalValue * ratio * STDeviceAdapter.widthScale
        }
        
        self.constant = adaptedValue
        _isAdapted = true
    }
    
    /// 手动触发适配
    public func applyAdaptiveConstant() {
        if _autoConstant {
            _isAdapted = false
            self.adaptConstraintIfNeeded()
        }
    }
    
    /// 重置为原始值
    public func resetAdaptiveConstant() {
        if _isAdapted {
            self.constant = _originalConstant
            _isAdapted = false
        }
    }
    
    /// 获取原始约束值
    public var originalConstant: CGFloat {
        return _originalConstant
    }
    
    /// 获取适配后的约束值
    public var adaptedConstant: CGFloat {
        self.constant
    }
    
    /// 检查是否已适配
    public var hasAdaptiveConstantApplied: Bool {
        _isAdapted
    }
    
    // MARK: - 生命周期方法
    open override func awakeFromNib() {
        super.awakeFromNib()
        if _autoConstant && !_isAdapted {
            _originalConstant = self.constant
            self.adaptConstraintIfNeeded()
        }
    }
}

// MARK: - 批量约束适配工具
public struct STConstraintAdapter {
    
    /// 批量适配约束
    /// - Parameter constraints: 约束数组
    public static func adaptConstraints(_ constraints: [NSLayoutConstraint]) {
        for constraint in constraints {
            constraint.applyAdaptiveConstant()
        }
    }
    
    /// 批量重置约束
    /// - Parameter constraints: 约束数组
    public static func resetConstraints(_ constraints: [NSLayoutConstraint]) {
        for constraint in constraints {
            constraint.resetAdaptiveConstant()
        }
    }
    
    /// 获取所有已适配的约束
    /// - Parameter constraints: 约束数组
    /// - Returns: 已适配的约束数组
    public static func adaptedConstraints(from constraints: [NSLayoutConstraint]) -> [NSLayoutConstraint] {
        return constraints.filter(\.hasAdaptiveConstantApplied)
    }
    
    /// 获取所有未适配的约束
    /// - Parameter constraints: 约束数组
    /// - Returns: 未适配的约束数组
    public static func unadaptedConstraints(from constraints: [NSLayoutConstraint]) -> [NSLayoutConstraint] {
        return constraints.filter { !$0.hasAdaptiveConstantApplied }
    }
}

// MARK: - UIView 约束适配扩展
public extension UIView {
    func adaptAllConstraints() {
        self.adaptConstraintsRecursively(in: self)
    }
    
    /// 适配约束
    private func adaptConstraintsRecursively(in view: UIView) {
        for constraint in view.constraints {
            constraint.applyAdaptiveConstant()
        }
        
        for subview in view.subviews {
            self.adaptConstraintsRecursively(in: subview)
        }
    }
    
    /// 重置所有子视图的约束
    func resetAllConstraints() {
        self.resetConstraintsRecursively(in: self)
    }
    
    /// 重置约束
    private func resetConstraintsRecursively(in view: UIView) {
        for constraint in view.constraints {
            constraint.resetAdaptiveConstant()
        }
        
        for subview in view.subviews {
            self.resetConstraintsRecursively(in: subview)
        }
    }
    
    /// 获取所有已适配的约束
    func allAdaptedConstraints() -> [NSLayoutConstraint] {
        var adaptedConstraints: [NSLayoutConstraint] = []
        self.collectAdaptedConstraintsRecursively(in: self, result: &adaptedConstraints)
        return adaptedConstraints
    }
    
    /// 收集已适配的约束
    private func collectAdaptedConstraintsRecursively(in view: UIView, result: inout [NSLayoutConstraint]) {
        for constraint in view.constraints {
            if constraint.hasAdaptiveConstantApplied {
                result.append(constraint)
            }
        }
        
        for subview in view.subviews {
            self.collectAdaptedConstraintsRecursively(in: subview, result: &result)
        }
    }
}
