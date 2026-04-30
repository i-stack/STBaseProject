//
//  STMarkdownInteraction.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import UIKit

public protocol STMarkdownInteractable: AnyObject {
    var onLinkTap: ((URL) -> Void)? { get set }
    var onSelectionChange: ((String) -> Void)? { get set }
    var isTextSelectionEnabled: Bool { get set }
}
