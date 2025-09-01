//
//  STBaseViewUsageExample.swift
//  STBaseProject
//
//  Created by stack on 2018/3/14.
//

import UIKit

// MARK: - 使用示例

/// 示例1: 自动布局模式 - 根据内容自动决定是否需要滚动
class STAutoLayoutExampleView: STBaseView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        // 使用自动布局模式
        st_setLayoutMode(.auto)
        
        // 添加一些子视图
        let titleLabel = UILabel()
        titleLabel.text = "自动布局示例"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 24)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let descriptionLabel = UILabel()
        descriptionLabel.text = "这是一个很长的描述文本，用来测试自动布局功能。当内容超出视图范围时，系统会自动切换到ScrollView模式。"
        descriptionLabel.numberOfLines = 0
        descriptionLabel.font = UIFont.systemFont(ofSize: 16)
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 添加到内容视图
        st_addSubviewToContent(titleLabel)
        st_addSubviewToContent(descriptionLabel)
        
        // 设置约束
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: st_getContentView().topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: st_getContentView().leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: st_getContentView().trailingAnchor, constant: -20),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            descriptionLabel.leadingAnchor.constraint(equalTo: st_getContentView().leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: st_getContentView().trailingAnchor, constant: -20),
            descriptionLabel.bottomAnchor.constraint(equalTo: st_getContentView().bottomAnchor, constant: -20)
        ])
    }
}

/// 示例2: 强制ScrollView模式 - 适用于需要滚动的复杂界面
class STScrollViewExampleView: STBaseView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        // 强制使用ScrollView模式
        st_setLayoutMode(.scroll)
        st_setScrollDirection(.vertical)
        
        // 创建多个卡片视图
        for i in 0..<10 {
            let cardView = createCardView(index: i)
            st_addSubviewToContent(cardView)
            
            // 设置约束
            NSLayoutConstraint.activate([
                cardView.topAnchor.constraint(equalTo: st_getContentView().topAnchor, constant: CGFloat(i * 120 + 20)),
                cardView.leadingAnchor.constraint(equalTo: st_getContentView().leadingAnchor, constant: 20),
                cardView.trailingAnchor.constraint(equalTo: st_getContentView().trailingAnchor, constant: -20),
                cardView.heightAnchor.constraint(equalToConstant: 100)
            ])
        }
        
        // 设置内容视图底部约束
        if let lastCard = st_getContentView().subviews.last {
            NSLayoutConstraint.activate([
                st_getContentView().bottomAnchor.constraint(equalTo: lastCard.bottomAnchor, constant: 20)
            ])
        }
    }
    
    private func createCardView(index: Int) -> UIView {
        let cardView = UIView()
        cardView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        cardView.layer.cornerRadius = 8
        cardView.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = "卡片 \(index + 1)"
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        cardView.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: cardView.centerYAnchor)
        ])
        
        return cardView
    }
}

/// 示例3: TableView模式 - 适用于列表数据展示
class STTableViewExampleView: STBaseView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        // 使用TableView模式
        st_setLayoutMode(.table)
        
        // 选择TableView样式（可选）
        st_setTableViewStyle(.grouped) // 或者 .plain
        
        // 设置TableView代理和数据源
        st_setupTableView(delegate: self, dataSource: self)
        
        // 注册Cell
        st_registerTableViewCell(UITableViewCell.self)
    }
}

extension STTableViewExampleView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 20
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: UITableViewCell.self), for: indexPath)
        cell.textLabel?.text = "行 \(indexPath.row + 1)"
        return cell
    }
}

/// 示例4: CollectionView模式 - 适用于网格布局
class STCollectionViewExampleView: STBaseView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        // 使用CollectionView模式
        st_setLayoutMode(.collection)
        
        // 设置CollectionView代理和数据源
        st_setupCollectionView(delegate: self, dataSource: self)
        
        // 注册Cell
        st_registerCollectionViewCell(UICollectionViewCell.self)
        
        // 配置布局
        if let flowLayout = st_collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.itemSize = CGSize(width: 80, height: 80)
            flowLayout.minimumLineSpacing = 10
            flowLayout.minimumInteritemSpacing = 10
            flowLayout.sectionInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        }
    }
}

extension STCollectionViewExampleView: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 30
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: UICollectionViewCell.self), for: indexPath)
        cell.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.3)
        cell.layer.cornerRadius = 8
        return cell
    }
}

/// 示例5: 固定布局模式 - 适用于内容固定的界面
class STFixedLayoutExampleView: STBaseView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        // 使用固定布局模式
        st_setLayoutMode(.fixed)
        
        // 添加固定大小的内容
        let centerView = UIView()
        centerView.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.2)
        centerView.layer.cornerRadius = 12
        centerView.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = "固定布局\n内容居中显示"
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 18)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        centerView.addSubview(label)
        st_addSubviewToContent(centerView)
        
        // 设置约束
        NSLayoutConstraint.activate([
            centerView.centerXAnchor.constraint(equalTo: st_getContentView().centerXAnchor),
            centerView.centerYAnchor.constraint(equalTo: st_getContentView().centerYAnchor),
            centerView.widthAnchor.constraint(equalToConstant: 200),
            centerView.heightAnchor.constraint(equalToConstant: 150),
            
            label.centerXAnchor.constraint(equalTo: centerView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerView.centerYAnchor)
        ])
    }
}

// MARK: - 使用演示
class STBaseViewUsageExample {
    
    static func demonstrateAllLayoutModes() {
        print("=== STBaseView 布局模式演示 ===")
        
        // 1. 自动布局模式
        let autoView = STAutoLayoutExampleView(frame: CGRect(x: 0, y: 0, width: 300, height: 200))
        print("自动布局模式: \(autoView.st_getCurrentLayoutMode())")
        
        // 2. ScrollView模式
        let scrollView = STScrollViewExampleView(frame: CGRect(x: 0, y: 0, width: 300, height: 200))
        print("ScrollView模式: \(scrollView.st_getCurrentLayoutMode())")
        
        // 3. TableView模式
        let tableView = STTableViewExampleView(frame: CGRect(x: 0, y: 0, width: 300, height: 200))
        print("TableView模式: \(tableView.st_getCurrentLayoutMode())")
        
        // 4. CollectionView模式
        let collectionView = STCollectionViewExampleView(frame: CGRect(x: 0, y: 0, width: 300, height: 200))
        print("CollectionView模式: \(collectionView.st_getCurrentLayoutMode())")
        
        // 5. 固定布局模式
        let fixedView = STFixedLayoutExampleView(frame: CGRect(x: 0, y: 0, width: 300, height: 200))
        print("固定布局模式: \(fixedView.st_getCurrentLayoutMode())")
        
        print("=== 演示完成 ===\n")
    }
}
