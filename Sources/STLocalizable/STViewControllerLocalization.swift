//
//  STBaseViewControllerLocalization.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2017/10/4.
//

import UIKit

// MARK: - STBaseViewController 本地化扩展
public extension STBaseViewController {
    
    func st_updateLocalizedTexts() {
        if let title = self.title, !title.isEmpty {
            self.titleLabel.text = Bundle.st_localizedString(key: title)
        }
        
        if let title = navigationItem.title, !title.isEmpty {
            navigationItem.title = Bundle.st_localizedString(key: title)
        }
        if let prompt = navigationItem.prompt, !prompt.isEmpty {
            navigationItem.prompt = Bundle.st_localizedString(key: prompt)
        }
        updateLocalizedTextsInView(self.view)
    }
    
    private func updateLocalizedTextsInView(_ view: UIView?) {
        guard let view = view else { return }
        if let localizable = view as? STLocalizable {
            localizable.st_updateLocalizedText()
        }
        
        for subview in view.subviews {
            updateLocalizedTextsInView(subview)
        }
    }
}
