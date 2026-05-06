//
//  STGlassEffectFactory.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2026/4/29.
//

import UIKit

enum STGlassEffectFactory {
    enum Style {
        case regular
        case clear
    }

    static func makeVisualEffect(style: Style = .clear, isInteractive: Bool = true) -> UIVisualEffect {
        if #available(iOS 26.0, *) {
            return Self.makeSystemGlassEffect(style: style, isInteractive: isInteractive)
        }
        return UIBlurEffect(style: .systemUltraThinMaterial)
    }

    @available(iOS 26.0, *)
    private static func makeSystemGlassEffect(style: Style, isInteractive: Bool) -> UIVisualEffect {
        let systemStyle: UIGlassEffect.Style
        switch style {
        case .regular: systemStyle = .regular
        case .clear: systemStyle = .clear
        }
        let glass = UIGlassEffect(style: systemStyle)
        glass.isInteractive = isInteractive
        return glass
    }
}
