//
//  STTabBarItemModel.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2024/01/01.
//

import UIKit

/// TabBar Item 显示模式
public enum STTabBarItemDisplayMode: Equatable {
    case imageOnly
    case textOnly
    case imageAndText
    case custom
    case irregular
}

/// 文案与字体
public struct STTabBarItemTypography: Equatable {
    public var fontSize: CGFloat
    public var fontName: String
    public var isLocalized: Bool

    public init(fontSize: CGFloat = 12.0, fontName: String = "PingFangSC-Regular", isLocalized: Bool = false) {
        self.fontSize = fontSize
        self.fontName = fontName
        self.isLocalized = isLocalized
    }

    public static let standard = STTabBarItemTypography(fontSize: 12.0, fontName: "PingFangSC-Regular", isLocalized: false)
}

/// 文本与背景色（选中 / 未选中）
public struct STTabBarItemColors: Equatable {
    public var normalText: UIColor
    public var selectedText: UIColor
    public var normalBackground: UIColor
    public var selectedBackground: UIColor

    public init(
        normalText: UIColor = .systemGray,
        selectedText: UIColor = .systemBlue,
        normalBackground: UIColor = .clear,
        selectedBackground: UIColor = .clear
    ) {
        self.normalText = normalText
        self.selectedText = selectedText
        self.normalBackground = normalBackground
        self.selectedBackground = selectedBackground
    }

    public static let standard = STTabBarItemColors()
}

/// 图标区域布局（图文、不规则等共用）
public struct STTabBarItemLayout: Equatable {
    public var imageSize: CGSize?
    public var imageTopInset: CGFloat

    public init(imageSize: CGSize? = nil, imageTopInset: CGFloat = 6.0) {
        self.imageSize = imageSize
        self.imageTopInset = imageTopInset
    }

    public static let standard = STTabBarItemLayout(imageSize: nil, imageTopInset: 6.0)
}

/// 徽标
public struct STTabBarItemBadge: Equatable {
    public var count: Int
    public var backgroundColor: UIColor
    public var textColor: UIColor

    public init(count: Int = 0, backgroundColor: UIColor = .systemRed, textColor: UIColor = .white) {
        self.count = count
        self.backgroundColor = backgroundColor
        self.textColor = textColor
    }

    public static let standard = STTabBarItemBadge()
}

/// 凸起（不规则）按钮专属外观；仅在 `displayMode == .irregular` 时参与布局与绘制
public struct STTabBarIrregularStyle: Equatable {
    public var protrusionHeight: CGFloat
    public var cornerRadius: CGFloat
    public var backgroundColor: UIColor
    public var shadowColor: UIColor
    public var shadowOffset: CGSize
    public var shadowRadius: CGFloat

    public init(
        protrusionHeight: CGFloat = 20.0,
        cornerRadius: CGFloat = 25.0,
        backgroundColor: UIColor = .systemBlue,
        shadowColor: UIColor = .black,
        shadowOffset: CGSize = CGSize(width: 0, height: 2),
        shadowRadius: CGFloat = 4.0
    ) {
        self.protrusionHeight = protrusionHeight
        self.cornerRadius = cornerRadius
        self.backgroundColor = backgroundColor
        self.shadowColor = shadowColor
        self.shadowOffset = shadowOffset
        self.shadowRadius = shadowRadius
    }

    public static let standard = STTabBarIrregularStyle()
}

/// 单个 Tab 项数据：内容 + 分组样式；`isIrregular` 由 `displayMode == .irregular` 推导，避免与枚举重复维护
public struct STTabBarItemModel {
    public var title: String
    public var normalImage: UIImage?
    public var selectedImage: UIImage?
    public var customView: UIView?
    public var displayMode: STTabBarItemDisplayMode
    public var colors: STTabBarItemColors
    public var typography: STTabBarItemTypography
    public var layout: STTabBarItemLayout
    public var badge: STTabBarItemBadge
    public var irregular: STTabBarIrregularStyle?
    public var isEnabled: Bool
    public var isIrregular: Bool { displayMode == .irregular }

    public init(
        title: String = "",
        normalImage: UIImage? = nil,
        selectedImage: UIImage? = nil,
        customView: UIView? = nil,
        displayMode: STTabBarItemDisplayMode = .imageAndText,
        colors: STTabBarItemColors = .standard,
        typography: STTabBarItemTypography = .standard,
        layout: STTabBarItemLayout = .standard,
        badge: STTabBarItemBadge = .standard,
        irregular: STTabBarIrregularStyle? = nil,
        isEnabled: Bool = true
    ) {
        self.title = title
        self.normalImage = normalImage
        self.selectedImage = selectedImage
        self.customView = customView
        self.displayMode = displayMode
        self.colors = colors
        self.typography = typography
        self.layout = layout
        self.badge = badge
        self.irregular = irregular
        self.isEnabled = isEnabled
    }

    public init(title: String, normalImage: UIImage? = nil, selectedImage: UIImage? = nil) {
        self.init(
            title: title,
            normalImage: normalImage,
            selectedImage: selectedImage,
            customView: nil,
            displayMode: .imageAndText,
            colors: .standard,
            typography: .standard,
            layout: .standard,
            badge: .standard,
            irregular: nil,
            isEnabled: true
        )
    }
    
    public static func createWithImageNames(
        title: String,
        normalImageName: String,
        selectedImageName: String,
        titleSize: CGFloat = 12.0,
        titleFontName: String = "PingFangSC-Regular",
        normalTitleColor: UIColor = .systemGray,
        selectedTitleColor: UIColor = .systemBlue,
        backgroundColor: UIColor = .clear,
        imageSize: CGSize? = nil,
        imageTopInset: CGFloat = 6.0,
        badgeValue: String? = nil,
        badgeColor: UIColor = .systemRed,
        isLocalized: Bool = false
    ) -> STTabBarItemModel {
        let finalTitle = isLocalized ? title.localized : title
        let normalImage = loadImage(named: normalImageName, imageSize: imageSize)
        let selectedImage = loadImage(named: selectedImageName, imageSize: imageSize)
        let count = badgeCountFromString(badgeValue)
        return STTabBarItemModel(
            title: finalTitle,
            normalImage: normalImage,
            selectedImage: selectedImage,
            displayMode: .imageAndText,
            colors: STTabBarItemColors(
                normalText: normalTitleColor,
                selectedText: selectedTitleColor,
                normalBackground: backgroundColor,
                selectedBackground: backgroundColor
            ),
            typography: STTabBarItemTypography(fontSize: titleSize, fontName: titleFontName, isLocalized: isLocalized),
            layout: STTabBarItemLayout(imageSize: imageSize, imageTopInset: imageTopInset),
            badge: STTabBarItemBadge(count: count, backgroundColor: badgeColor, textColor: .white)
        )
    }

    public static func createLocalized(
        localizedTitle: String,
        normalImageName: String,
        selectedImageName: String,
        normalColor: UIColor = .systemGray,
        selectedColor: UIColor = .systemBlue
    ) -> STTabBarItemModel {
        createWithImageNames(
            title: localizedTitle,
            normalImageName: normalImageName,
            selectedImageName: selectedImageName,
            normalTitleColor: normalColor,
            selectedTitleColor: selectedColor,
            isLocalized: true
        )
    }

    public static func fromUITabBarItem(_ tabBarItem: UITabBarItem) -> STTabBarItemModel {
        STTabBarItemModel(
            title: tabBarItem.title ?? "",
            normalImage: tabBarItem.image,
            selectedImage: tabBarItem.selectedImage,
            displayMode: .imageAndText,
            colors: .standard,
            typography: .standard,
            badge: STTabBarItemBadge(
                count: badgeCountFromString(tabBarItem.badgeValue),
                backgroundColor: tabBarItem.badgeColor ?? .systemRed,
                textColor: .white
            )
        )
    }

    public static func createImageOnly(
        normalImageName: String,
        selectedImageName: String,
        imageSize: CGSize = CGSize(width: 24, height: 24),
        backgroundColor: UIColor = .clear,
        badgeValue: String? = nil
    ) -> STTabBarItemModel {
        let normalImage = loadImage(named: normalImageName, imageSize: imageSize)
        let selectedImage = loadImage(named: selectedImageName, imageSize: imageSize)
        let count = badgeCountFromString(badgeValue)
        return STTabBarItemModel(
            title: "",
            normalImage: normalImage,
            selectedImage: selectedImage,
            displayMode: .imageOnly,
            colors: STTabBarItemColors(
                normalText: .systemGray,
                selectedText: .systemBlue,
                normalBackground: backgroundColor,
                selectedBackground: backgroundColor
            ),
            typography: .standard,
            layout: STTabBarItemLayout(imageSize: imageSize, imageTopInset: 6.0),
            badge: STTabBarItemBadge(count: count)
        )
    }

    public static func createTextOnly(
        title: String,
        titleSize: CGFloat = 14.0,
        titleFontName: String = "PingFangSC-Medium",
        normalTitleColor: UIColor = .systemGray,
        selectedTitleColor: UIColor = .systemBlue,
        backgroundColor: UIColor = .clear,
        isLocalized: Bool = false
    ) -> STTabBarItemModel {
        let finalTitle = isLocalized ? title.localized : title
        return STTabBarItemModel(
            title: finalTitle,
            displayMode: .textOnly,
            colors: STTabBarItemColors(
                normalText: normalTitleColor,
                selectedText: selectedTitleColor,
                normalBackground: backgroundColor,
                selectedBackground: backgroundColor
            ),
            typography: STTabBarItemTypography(fontSize: titleSize, fontName: titleFontName, isLocalized: isLocalized)
        )
    }

    public static func createIrregular(
        title: String,
        normalImageName: String,
        selectedImageName: String,
        irregularHeight: CGFloat = 20.0,
        irregularCornerRadius: CGFloat = 25.0,
        irregularBackgroundColor: UIColor = .systemBlue,
        titleSize: CGFloat = 12.0,
        imageSize: CGSize = CGSize(width: 24, height: 24)
    ) -> STTabBarItemModel {
        let normalImage = loadImage(named: normalImageName, imageSize: imageSize)
        let selectedImage = loadImage(named: selectedImageName, imageSize: imageSize)
        let irr = STTabBarIrregularStyle(
            protrusionHeight: irregularHeight,
            cornerRadius: irregularCornerRadius,
            backgroundColor: irregularBackgroundColor,
            shadowColor: .black,
            shadowOffset: CGSize(width: 0, height: 2),
            shadowRadius: 4.0
        )
        return STTabBarItemModel(
            title: title,
            normalImage: normalImage,
            selectedImage: selectedImage,
            displayMode: .irregular,
            colors: STTabBarItemColors(
                normalText: .white,
                selectedText: .white,
                normalBackground: irregularBackgroundColor,
                selectedBackground: irregularBackgroundColor
            ),
            typography: STTabBarItemTypography(fontSize: titleSize, fontName: "PingFangSC-Regular", isLocalized: false),
            layout: STTabBarItemLayout(imageSize: imageSize, imageTopInset: 6.0),
            irregular: irr
        )
    }

    public static func createCustom(customView: UIView, title: String = "") -> STTabBarItemModel {
        STTabBarItemModel(title: title, customView: customView, displayMode: .custom)
    }

    private static func loadImage(named imageName: String, imageSize: CGSize? = nil) -> UIImage? {
        guard let image = UIImage(named: imageName) else {
            print("⚠️ STTabBarItemModel: 图片加载失败 - \(imageName)")
            return nil
        }
        return image.withRenderingMode(.alwaysOriginal)
    }

    private static func badgeCountFromString(_ badgeValue: String?) -> Int {
        guard let badgeValue = badgeValue else { return 0 }
        if badgeValue == "99+" {
            return 100
        }
        return Int(badgeValue) ?? 0
    }
}
