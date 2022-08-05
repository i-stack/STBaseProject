# STBaseProject

[![CI Status](https://img.shields.io/travis/songMW/STBaseProject.svg?style=flat)](https://travis-ci.org/songMW/STBaseProject)
[![Version](https://img.shields.io/cocoapods/v/STBaseProject.svg?style=flat)](https://cocoapods.org/pods/STBaseProject)
[![License](https://img.shields.io/cocoapods/l/STBaseProject.svg?style=flat)](https://cocoapods.org/pods/STBaseProject)
[![Platform](https://img.shields.io/cocoapods/p/STBaseProject.svg?style=flat)](https://cocoapods.org/pods/STBaseProject)

## Installation

```ruby
pod 'STBaseProject'
```

## 基础配置

在 AppDelegate 中配置：

***自定义导航栏高度***

```swift
private func customNavBar() {
    var model = STConstantBarHeightModel.init()
    model.navNormalHeight = 76
    model.navIsSafeHeight = 100
    STConstants.shared.st_customNavHeight(model: model)
}
```
***设计图基准尺寸配置***

```swift

private func configBenchmarkDesign() {
    STConstants.shared.st_configBenchmarkDesign(size: CGSize.init(width: 375, height: 812))
}
```

## How to use

#### 一、STBaseViewController

主要功能：

> 1、实现自定义导航栏，继承此类的 `ViewController` 可以进行二次封装进行 ***字体、颜色、位置*** 的修改；
> 
> 2、所有 `ViewController` 都可以继承此类；

#### 二、STBaseView

主要功能：

> 可选使用 `UIScrollView` 作为父类进行界面布局；

#### 三、STBaseModel 

主要功能：

> 针对 `forUndefinedKey` 异常的处理；

#### 四、STBtn

主要功能：

> 按钮标题文字与图片位置设置；
