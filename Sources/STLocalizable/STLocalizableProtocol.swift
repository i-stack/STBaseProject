//
//  STLocalizableProtocol.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/10/10.
//

import UIKit

// MARK: - 本地化协议
public protocol STLocalizable {
    func st_updateLocalizedText()
}

// MARK: - UILabel 本地化扩展
public extension UILabel {
    func st_updateLocalizedText() {
        if let text = self.text, !text.isEmpty {
            self.text = Bundle.st_localizedString(key: text)
        }
    }
}

// MARK: - UIButton 本地化扩展
public extension UIButton {
    func st_updateLocalizedText() {
        if let title = self.title(for: .normal), !title.isEmpty {
            self.setTitle(Bundle.st_localizedString(key: title), for: .normal)
        }
    }
}

// MARK: - UITextField 本地化扩展
public extension UITextField {
    func st_updateLocalizedText() {
        if let placeholder = self.placeholder, !placeholder.isEmpty {
            self.placeholder = Bundle.st_localizedString(key: placeholder)
        }
    }
}
