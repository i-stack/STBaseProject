//
//  STWalletLayout.swift
//  STBaseProject_Example
//
//  Created by stack on 2019/7/29.
//  Copyright © 2019 STBaseProject. All rights reserved.
//

import UIKit

class STWalletLayout: UICollectionViewFlowLayout {
    
    /// 内容区域
    var contentInset: UIEdgeInsets = UIEdgeInsets.zero
    /// 每个cell的间距
    var interitemSpacing: CGFloat = 10
    
    /// 上一次选中的indexPath
    private var lastSelectIndexPath: IndexPath = IndexPath.init(row: 0, section: 0)
    /// 当前选中的indexPath
    private var currentSelectIndexPath: IndexPath = IndexPath.init(row: 0, section: 0)
    
    /// 删除的indexPath集合
    private var deleteIndexPathArr = [IndexPath]()
    /// 插入的indexPath集合
    private var insertIndexPathArr = [IndexPath]()
    
    /// cell布局信息
    private var layoutInfoDic = [IndexPath : UICollectionViewLayoutAttributes]()
    
    /// 更新动画类型
    private var animationType : UICollectionViewUpdateItem.Action = .none
    
    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepare() {
        super.prepare()
        
        //重置数组
        self.layoutInfoDic = [IndexPath : UICollectionViewLayoutAttributes]()
        
        //布局只取第0组的信息
        if let numOfItems = self.collectionView?.numberOfItems(inSection: 0) {
            for i in 0 ..< numOfItems {
                let indexPath = IndexPath.init(row: i, section: 0)
                if let attributes = self.layoutAttributesForItem(at: indexPath) {
                    self.layoutInfoDic[indexPath] = attributes
                }
            }
        }
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        attributes.frame = CGRect.init(x: 0, y: 0, width: self.itemSize.width, height: self.itemSize.height)
//        attributes.frame = self.currentFrameWithIndexPath(indexPath: indexPath)
        return attributes
    }
    
    override func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {
        super.prepare(forCollectionViewUpdates: updateItems)
        //数组重置
        self.deleteIndexPathArr = [IndexPath]()
        self.insertIndexPathArr = [IndexPath]()
        
        //保存更新的indexPath
        for item in updateItems {
            switch item.updateAction {
            case .insert:
                let indexPath = item.indexPathAfterUpdate ?? IndexPath()
                self.insertIndexPathArr.append(indexPath)
                self.animationType = .insert
                break
            case .delete:
                let indexPath = item.indexPathBeforeUpdate ?? IndexPath()
                self.deleteIndexPathArr.append(indexPath)
                self.animationType = .delete
                break
            case .reload:
                self.animationType = .reload
                break
            case .move:
                self.animationType = .move
                break
            case .none:
                self.animationType = .none
                break
            @unknown default:
                break
            }
        }
    }
    
//    override func initialLayoutAttributesForAppearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
//        
//        let attributes = self.layoutAttributesForItem(at: itemIndexPath)
//        let transformScale: CGAffineTransform = CGAffineTransform.init(scaleX: 2, y: 0.2)
//        attributes?.transform = transformScale
//        if self.animationType == .insert {
//            //attributes?.center = CGPoint.init(x: (self.collectionView?.bounds.midX)!, y: (self.collectionView?.bounds.minY)! + self.itemSize.height)
//        } else if self.animationType == .delete {
//            //attributes?.center = CGPoint.init(x: (self.collectionView?.bounds.midX)!, y: (self.collectionView?.bounds.maxY)!)
//        }
//        return attributes
//    }

    // MARK: - private method
    func currentFrameWithIndexPath(indexPath: IndexPath) -> CGRect {
        return self.frameWithIndexPath(indexPath: indexPath, selectIndexPath: self.currentSelectIndexPath)
    }
    
    func lastFrameWithIndexPath(indexPath: IndexPath) -> CGRect {
        return self.frameWithIndexPath(indexPath: indexPath, selectIndexPath: self.lastSelectIndexPath)
    }
    
    func frameWithIndexPath(indexPath: IndexPath, selectIndexPath: IndexPath) -> CGRect {
        var left: CGFloat
        var width: CGFloat
        if indexPath.row < selectIndexPath.row {
            left = CGFloat(indexPath.row)*(self.itemSize.width+self.interitemSpacing)
            width = self.itemSize.width
        }
        else if indexPath.row == selectIndexPath.row {
            left = CGFloat(indexPath.row)*(self.itemSize.width+self.interitemSpacing)+self.interitemSpacing
            width = self.itemSize.width
        }
        else {
            left = CGFloat(indexPath.row+1)*(self.itemSize.width+self.interitemSpacing)+self.interitemSpacing
            width = self.itemSize.width
        }
        left = CGFloat(indexPath.row-1)*(self.itemSize.width+self.interitemSpacing)+self.interitemSpacing

//        let frame = CGRect.init(x: left + self.contentInset.left, y: CGFloat(indexPath.section) * self.itemSize.height + self.contentInset.top, width: width, height: itemSize.height)
        let frame = CGRect.init(x: 0, y: left + self.contentInset.left, width: width, height: itemSize.height)

        return frame
    }
    
    func printAttributes(attributes: UICollectionViewLayoutAttributes) {
        print("attributes:")
        print("frame:\(attributes.frame)")
        print("indexPath:\(attributes.indexPath)")
        print("transform:\(attributes.transform)")
        print("alpha:\(attributes.alpha)")
    }
}
