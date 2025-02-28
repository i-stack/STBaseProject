//
//  STBaseView.swift
//  STBaseProject
//
//  Created by stack on 2018/3/14.
//

import UIKit

open class STBaseView: UIView {
    
    private var extraContentSizeOffset: CGFloat = 0
        
    deinit {
#if DEBUG
        print("🌈 -> \(self) 🌈 ----> 🌈 dealloc")
#endif
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    // MARK: - UIScrollView
    public func st_baseViewAddScrollView() -> Void {
        self.addSubview(self.baseScrollView )
        self.addConstraints([
            NSLayoutConstraint.init(item: self.baseScrollView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint.init(item: self.baseScrollView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint.init(item: self.baseScrollView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint.init(item: self.baseScrollView, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: 0)
        ])
        self.baseScrollView.addSubview(self.baseContentView)
        self.baseScrollView.addConstraints([
            NSLayoutConstraint.init(item: self.baseContentView, attribute: .width, relatedBy: .equal, toItem: self.baseScrollView, attribute: .width, multiplier: 1, constant: 0),
            NSLayoutConstraint.init(item: self.baseContentView, attribute: .top, relatedBy: .equal, toItem: self.baseScrollView, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint.init(item: self.baseContentView, attribute: .leading, relatedBy: .equal, toItem: self.baseScrollView, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint.init(item: self.baseContentView, attribute: .bottom, relatedBy: .equal, toItem: self.baseScrollView, attribute: .bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint.init(item: self.baseContentView, attribute: .trailing, relatedBy: .equal, toItem: self.baseScrollView, attribute: .trailing, multiplier: 1, constant: 0)
        ])
    }
    
    public func st_updateExtraContentSize(offset: CGFloat) {
        self.extraContentSizeOffset = offset
    }
    
    public lazy var baseScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.isPagingEnabled = true
        scrollView.isScrollEnabled = true
        scrollView.isUserInteractionEnabled = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    public lazy var baseContentView: UIView = {
        let contentView = UIView()
        contentView.backgroundColor = UIColor.clear
        contentView.translatesAutoresizingMaskIntoConstraints = false
        return contentView
    }()
    
    // MARK: - UITableView
    public lazy var baseTableViewG: UITableView = {
        let view = UITableView.init(frame: .zero, style: .grouped)
        view.separatorStyle = .none
        view.tableFooterView = UIView()
        view.backgroundColor = UIColor.clear
        view.rowHeight = UITableView.automaticDimension
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    public lazy var baseTableViewP: UITableView = {
        let view = UITableView.init(frame: .zero, style: .plain)
        view.separatorStyle = .none
        view.tableFooterView = UIView()
        view.backgroundColor = UIColor.clear
        view.rowHeight = UITableView.automaticDimension
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // MARK: - UICollectionView
    public lazy var baseCollectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
}
