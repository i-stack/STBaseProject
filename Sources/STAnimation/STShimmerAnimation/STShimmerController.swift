//
//  STShimmerController.swift
//  Bajoseek
//
//  Created by 寒江孤影 on 2026/2/3.
//

import UIKit

public class STShimmerController {

    enum State {
        case idle
        case streaming
        case finished
    }

    private weak var renderer: STShimmerTextView?
    private weak var cursor: STShimmerCursorView?
    private(set) var state: State = .idle

    func bind(renderer: STShimmerTextView, cursor: STShimmerCursorView) {
        self.renderer = renderer
        self.cursor = cursor
    }

    func onTextUpdated() {
        if self.state == .idle {
            self.state = .streaming
            self.cursor?.startBlink()
        }
    }

    func finish() {
        guard self.state == .streaming else { return }
        self.state = .finished
        self.renderer?.finishAnimations()
        self.cursor?.fadeOut()
    }

    func reset() {
        self.state = .idle
        self.cursor?.stopBlink()
        self.cursor?.isHidden = true
        self.cursor?.alpha = 1
    }
}
