//
//  STShimmerRendererView.swift
//  Bajoseek
//
//  Created by 寒江孤影 on 2026/2/3.
//

import UIKit

protocol STShimmerRendererViewDelegate: AnyObject {
    func streamingTextViewDidChangeHeight(_ view: STShimmerRendererView)
}

public class STShimmerRendererView: UIView {

    private var lastHeight: CGFloat = 0
    private let cursor = STShimmerCursorView()
    private let renderer: STShimmerTextView = {
        if #available(iOS 16.0, *) {
            return STShimmerTextView(usingTextLayoutManager: false)
        }
        return STShimmerTextView()
    }()
    private let controller = STShimmerController()
    weak var delegate: STShimmerRendererViewDelegate?
    
    var animatesHeightChanges: Bool = true

    var font: UIFont = .systemFont(ofSize: 16) {
        didSet {
            self.renderer.font = self.font
        }
    }

    var textColor: UIColor = .label {
        didSet {
            self.renderer.textColor = self.textColor
        }
    }

    var tokenFadeDuration: TimeInterval = 0.3 {
        didSet {
            self.renderer.tokenFadeDuration = self.tokenFadeDuration
        }
    }
    
    var text: String {
        return self.renderer.text ?? ""
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        self.updateCursor()
    }

    public override var intrinsicContentSize: CGSize {
        let size = self.renderer.sizeThatFits(
            CGSize(width: self.bounds.width, height: .greatestFiniteMagnitude)
        )
        return CGSize(width: UIView.noIntrinsicMetric, height: size.height)
    }

    private func setup() {
        self.clipsToBounds = false
        self.addSubview(self.renderer)
        self.addSubview(self.cursor)
        self.renderer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.renderer.topAnchor.constraint(equalTo: self.topAnchor),
            self.renderer.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.renderer.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            self.renderer.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
        self.controller.bind(renderer: self.renderer, cursor: self.cursor)
    }

    func append(_ text: String) {
        self.renderer.append(text)
        self.controller.onTextUpdated()
        self.renderer.layoutIfNeeded()
        self.setNeedsLayout()
        self.layoutIfNeeded()
        self.updateCursor()
        self.updateHeightIfNeeded()
    }

    func finish() {
        self.controller.finish()
    }

    func reset() {
        self.renderer.reset()
        self.controller.reset()
        self.cursor.isHidden = true
        self.lastHeight = 0
        self.invalidateIntrinsicContentSize()
    }

    private func updateCursor() {
        guard self.controller.state == .streaming else { return }
        guard let rect = self.renderer.caretRect() else {
            self.cursor.isHidden = true
            return
        }
        self.cursor.isHidden = false
        self.cursor.updateFrame(rect)
    }

    private func updateHeightIfNeeded() {
        let fittingSize = self.renderer.sizeThatFits(
            CGSize(width: self.renderer.bounds.width, height: .greatestFiniteMagnitude)
        )
        let newHeight = ceil(fittingSize.height)
        guard abs(newHeight - self.lastHeight) > 0.5 else { return }
        let oldHeight = self.lastHeight
        self.lastHeight = newHeight
        self.invalidateIntrinsicContentSize()
        if self.animatesHeightChanges && oldHeight > 0 {
            UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseOut, .beginFromCurrentState, .allowUserInteraction]) {
                self.delegate?.streamingTextViewDidChangeHeight(self)
                self.superview?.layoutIfNeeded()
            }
        } else {
            self.delegate?.streamingTextViewDidChangeHeight(self)
        }
    }
}
