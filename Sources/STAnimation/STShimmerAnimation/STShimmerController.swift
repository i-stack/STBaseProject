//
//  STShimmerController.swift
//  Bajoseek
//
//  Created by 寒江孤影 on 2026/2/3.
//

import UIKit

public class STShimmerController {

    public enum State {
        case idle
        case streaming
        case finished
    }

    private weak var renderer: STShimmerTextView?
    private weak var cursor: STShimmerCursorView?
    public private(set) var state: State = .idle

    public init() {}

    public func bind(renderer: STShimmerTextView, cursor: STShimmerCursorView) {
        self.renderer = renderer
        self.cursor = cursor
    }

    public func onTextUpdated() {
        if self.state == .idle {
            self.state = .streaming
            self.cursor?.startBlink()
        }
    }

    public func finish() {
        guard self.state == .streaming else { return }
        self.state = .finished
        self.renderer?.finishAnimations()
        self.cursor?.fadeOut()
    }

    public func reset() {
        self.state = .idle
        self.cursor?.stopBlink()
        self.cursor?.isHidden = true
        self.cursor?.alpha = 1
    }
}
