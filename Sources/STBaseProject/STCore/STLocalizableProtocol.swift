//
//  STLocalizableProtocol.swift
//  STBaseProject
//
//  Created by stack on 2018/10/10.
//

import UIKit

// MARK: - Bundle 本地化扩展
// st_localizedString 函数已在 STLocalizationManager.swift 中定义

// MARK: - 本地化协议
public protocol STLocalizable {
    func st_updateLocalizedText()
}

// MARK: - UILabel 本地化扩展
public extension UILabel {
    func st_updateLocalizedText() {
        // 默认实现：如果文本不为空，则进行本地化
        if let text = self.text, !text.isEmpty {
            self.text = Bundle.st_localizedString(key: text)
        }
    }
}

// MARK: - UIButton 本地化扩展
public extension UIButton {
    func st_updateLocalizedText() {
        // 默认实现：如果标题不为空，则进行本地化
        if let title = self.title(for: .normal), !title.isEmpty {
            self.setTitle(Bundle.st_localizedString(key: title), for: .normal)
        }
    }
}

// MARK: - UITextField 本地化扩展
public extension UITextField {
    func st_updateLocalizedText() {
        // 默认实现：如果占位符不为空，则进行本地化
        if let placeholder = self.placeholder, !placeholder.isEmpty {
            self.placeholder = Bundle.st_localizedString(key: placeholder)
        }
    }
}
