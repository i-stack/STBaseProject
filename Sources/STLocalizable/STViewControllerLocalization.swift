//
//  STViewControllerLocalization.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2017/10/4.
//

import UIKit

// 关联对象键：存储 VC 标题的本地化原始 key，防止语言切换后 key 被覆盖为已本地化字符串
private var st_vcTitleKeyAssociation: UInt8   = 0
private var st_navPromptKeyAssociation: UInt8 = 0

public extension STBaseViewController {

    /// 刷新当前页面所有本地化文本。
    /// STBaseViewController 在 viewDidLoad 时自动订阅 stLanguageDidChange 通知并调用此方法，
    /// 子类无需手动注册通知；若需在初始加载时立即本地化 title 等由代码赋值的 key，
    /// 在 viewDidLoad 末尾手动调用一次即可。
    @objc func st_updateLocalizedTexts() {
        self.st_applyTitleLocalization()
        self.updateLocalizedTextsInView(self.view)
    }

    private func st_applyTitleLocalization() {
        if st_vcTitleKey == nil, let raw = self.title, !raw.isEmpty {
            st_vcTitleKey = raw
        }
        if let key = st_vcTitleKey {
            self.titleLabel.text = Bundle.st_localizedString(key: key)
        }

        if st_navPromptKey == nil, let raw = navigationItem.prompt, !raw.isEmpty {
            st_navPromptKey = raw
        }
        if let key = st_navPromptKey {
            navigationItem.prompt = Bundle.st_localizedString(key: key)
        }
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

    // MARK: - 关联对象
    private var st_vcTitleKey: String? {
        get { objc_getAssociatedObject(self, &st_vcTitleKeyAssociation) as? String }
        set { objc_setAssociatedObject(self, &st_vcTitleKeyAssociation, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC) }
    }

    private var st_navPromptKey: String? {
        get { objc_getAssociatedObject(self, &st_navPromptKeyAssociation) as? String }
        set { objc_setAssociatedObject(self, &st_navPromptKeyAssociation, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC) }
    }
}

