//
//  STGlassEffectFactory.swift
//  STBaseProject
//
//  Created by Codex on 2026/4/29.
//

import UIKit
import Foundation

enum STGlassEffectFactory {
    static func makeVisualEffect() -> UIVisualEffect {
        if #available(iOS 26.0, *),
           let glassEffect = self.makeRuntimeGlassEffect() {
            return glassEffect
        }
        return UIBlurEffect(style: .systemUltraThinMaterial)
    }

    @available(iOS 26.0, *)
    private static func makeRuntimeGlassEffect() -> UIVisualEffect? {
        guard let glassType = NSClassFromString("UIGlassEffect") as? NSObject.Type else {
            return nil
        }

        let effectSelector = NSSelectorFromString("effect")
        if glassType.responds(to: effectSelector),
           let unmanaged = glassType.perform(effectSelector),
           let effect = unmanaged.takeUnretainedValue() as? UIVisualEffect {
            return effect
        }

        return glassType.init() as? UIVisualEffect
    }
}
