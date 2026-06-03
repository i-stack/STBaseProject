//
//  STMarkdownTableGridLayout.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import UIKit

/// 表格 UICollectionView 的自定义 grid 布局。
/// section = 行, item = 列。
/// 借鉴 FluidMarkdown AMMarkdownTableLayout 的思想：
/// 逐列取最大宽度，逐行取最大高度，窄表按比例填充。
public final class STMarkdownTableGridLayout: UICollectionViewLayout {

    public var fillWidth: Bool = true
    public var minimumRowHeight: CGFloat = 35
    public var maximumColumnWidth: CGFloat = 360
    public var interItemSpacing: CGFloat = 0.5
    public var lineSpacing: CGFloat = 0.5
    public var minimumColumnWidth: CGFloat = 56

    /// 流式表格逐行追加时为 true：让本次 batch update 中新出现（appearing）的 cell
    /// 从 alpha 0 在最终位置原地淡入。仅在 `STMarkdownTableView` 的行追加动画期间置位，
    /// 动画结束即复位，故 reloadData 等非动画路径不受影响。
    var animatesAppearingItemsFade: Bool = false

    var sizeForItem: ((_ indexPath: IndexPath) -> CGSize)?

    private var allAttributes: [[UICollectionViewLayoutAttributes]] = []
    private var cachedContentSize: CGSize = .zero
    private var columnWidths: [CGFloat] = []
    private var rowHeights: [CGFloat] = []

    public override func prepare() {
        super.prepare()
        guard let collectionView else { return }

        let sections = collectionView.numberOfSections
        guard sections > 0 else {
            self.allAttributes = []
            self.cachedContentSize = .zero
            return
        }

        let columns = collectionView.numberOfItems(inSection: 0)
        guard columns > 0 else {
            self.allAttributes = []
            self.cachedContentSize = .zero
            return
        }

        var sizeCache: [[CGSize]] = []
        for section in 0..<sections {
            var rowSizes: [CGSize] = []
            let itemCount = collectionView.numberOfItems(inSection: section)
            for item in 0..<itemCount {
                let indexPath = IndexPath(item: item, section: section)
                let size = self.sizeForItem?(indexPath) ?? CGSize(width: self.minimumColumnWidth, height: self.minimumRowHeight)
                rowSizes.append(size)
            }
            while rowSizes.count < columns {
                rowSizes.append(CGSize(width: self.minimumColumnWidth, height: self.minimumRowHeight))
            }
            sizeCache.append(rowSizes)
        }

        var colWidths = Array(repeating: self.minimumColumnWidth, count: columns)
        for section in 0..<sections {
            for col in 0..<columns {
                colWidths[col] = max(colWidths[col], sizeCache[section][col].width)
            }
        }

        var rHeights = Array(repeating: self.minimumRowHeight, count: sections)
        for section in 0..<sections {
            for col in 0..<columns {
                rHeights[section] = max(rHeights[section], sizeCache[section][col].height)
            }
        }

        let totalSpacing = self.interItemSpacing * CGFloat(max(columns - 1, 0))
        let naturalWidth = colWidths.reduce(0, +)
        let containerWidth = collectionView.bounds.width
        if self.fillWidth, naturalWidth + totalSpacing < containerWidth, naturalWidth > 0 {
            let availableWidth = containerWidth - totalSpacing
            for col in 0..<columns {
                colWidths[col] = colWidths[col] / naturalWidth * availableWidth
            }
        } else {
            for col in 0..<columns {
                colWidths[col] = min(colWidths[col], self.maximumColumnWidth)
            }
        }

        var attrs: [[UICollectionViewLayoutAttributes]] = []
        var y: CGFloat = 0
        for section in 0..<sections {
            var rowAttrs: [UICollectionViewLayoutAttributes] = []
            let height = rHeights[section]
            var x: CGFloat = 0
            let itemCount = collectionView.numberOfItems(inSection: section)
            for item in 0..<min(itemCount, columns) {
                let indexPath = IndexPath(item: item, section: section)
                let attribute = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                let width = colWidths[item]
                attribute.frame = CGRect(x: x, y: y, width: width, height: height)
                rowAttrs.append(attribute)
                x += width + self.interItemSpacing
            }
            attrs.append(rowAttrs)
            y += height + self.lineSpacing
        }

        self.allAttributes = attrs
        self.columnWidths = colWidths
        self.rowHeights = rHeights
        let totalWidth = colWidths.reduce(0, +) + totalSpacing
        let totalHeight = y > 0 ? y - self.lineSpacing : 0
        self.cachedContentSize = CGSize(width: totalWidth, height: totalHeight)
    }

    public override var collectionViewContentSize: CGSize {
        self.cachedContentSize
    }

    public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        self.allAttributes.flatMap { $0 }.filter { $0.frame.intersects(rect) }
    }

    public override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard indexPath.section < self.allAttributes.count,
              indexPath.item < self.allAttributes[indexPath.section].count else {
            return nil
        }
        return self.allAttributes[indexPath.section][indexPath.item]
    }

    /// 默认自定义 layout 会让 appearing item 直接出现在最终位置（无淡入）。
    /// 行追加动画期间返回「最终帧位置 + alpha 0」的属性，使新插入 section 的 cell 原地淡入；
    /// 追加发生在表尾、已有行不位移，故只有新 section 的 cell 命中 appearing 路径。
    public override func initialLayoutAttributesForAppearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard self.animatesAppearingItemsFade else {
            return super.initialLayoutAttributesForAppearingItem(at: itemIndexPath)
        }
        guard let attributes = self.layoutAttributesForItem(at: itemIndexPath)?.copy() as? UICollectionViewLayoutAttributes else {
            return super.initialLayoutAttributesForAppearingItem(at: itemIndexPath)
        }
        attributes.alpha = 0
        return attributes
    }

    public override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        guard let collectionView else { return false }
        return self.fillWidth && newBounds.width != collectionView.bounds.width
    }

    public struct ComputeSizeMetrics {
        public var fillWidth: Bool
        public var containerWidth: CGFloat
        public var minimumRowHeight: CGFloat
        public var minimumColumnWidth: CGFloat
        public var maximumColumnWidth: CGFloat
        public var interItemSpacing: CGFloat
        public var lineSpacing: CGFloat

        public init(fillWidth: Bool,
                    containerWidth: CGFloat,
                    minimumRowHeight: CGFloat,
                    minimumColumnWidth: CGFloat,
                    maximumColumnWidth: CGFloat,
                    interItemSpacing: CGFloat,
                    lineSpacing: CGFloat) {
            self.fillWidth = fillWidth
            self.containerWidth = containerWidth
            self.minimumRowHeight = minimumRowHeight
            self.minimumColumnWidth = minimumColumnWidth
            self.maximumColumnWidth = maximumColumnWidth
            self.interItemSpacing = interItemSpacing
            self.lineSpacing = lineSpacing
        }
    }

    /// 静态计算表格尺寸（不需要 collectionView 实例）
    public static func computeSize(rows: Int, columns: Int, sizeForItem: (_ indexPath: IndexPath) -> CGSize, metrics: ComputeSizeMetrics) -> CGSize {
        guard rows > 0, columns > 0 else { return .zero }
        var colWidths = Array(repeating: metrics.minimumColumnWidth, count: columns)
        var rowHeights = Array(repeating: metrics.minimumRowHeight, count: rows)
        for section in 0..<rows {
            for col in 0..<columns {
                let size = sizeForItem(IndexPath(item: col, section: section))
                colWidths[col] = max(colWidths[col], size.width)
                rowHeights[section] = max(rowHeights[section], size.height)
            }
        }

        let totalSpacing = metrics.interItemSpacing * CGFloat(max(columns - 1, 0))
        let naturalWidth = colWidths.reduce(0, +)
        if metrics.fillWidth, naturalWidth + totalSpacing < metrics.containerWidth, naturalWidth > 0 {
            let availableWidth = metrics.containerWidth - totalSpacing
            for col in 0..<columns {
                colWidths[col] = colWidths[col] / naturalWidth * availableWidth
            }
        } else {
            for col in 0..<columns {
                colWidths[col] = min(colWidths[col], metrics.maximumColumnWidth)
            }
        }
        let totalWidth = colWidths.reduce(0, +) + totalSpacing
        let lineSpacingTotal = metrics.lineSpacing * CGFloat(max(rows - 1, 0))
        let totalHeight = rowHeights.reduce(0, +) + lineSpacingTotal
        return CGSize(width: totalWidth, height: totalHeight)
    }
}
