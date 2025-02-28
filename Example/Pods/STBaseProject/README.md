# STBaseProject

[![CI Status](https://img.shields.io/travis/songMW/STBaseProject.svg?style=flat)](https://travis-ci.org/songMW/STBaseProject)
[![Version](https://img.shields.io/cocoapods/v/STBaseProject.svg?style=flat)](https://cocoapods.org/pods/STBaseProject)
[![License](https://img.shields.io/cocoapods/l/STBaseProject.svg?style=flat)](https://cocoapods.org/pods/STBaseProject)
[![Platform](https://img.shields.io/cocoapods/p/STBaseProject.svg?style=flat)](https://cocoapods.org/pods/STBaseProject)

## Installation

```ruby
pod 'STBaseProject'
```

## Basic Configuration

Configure in AppDelegate:

**Custom navigation bar height**

```swift
private func customNavBar() {
    var model = STConstantBarHeightModel.init()
    model.navNormalHeight = 76
    model.navIsSafeHeight = 100
    STConstants.shared.st_customNavHeight(model: model)
}
```
**Design drawing baseline dimension configuration**

```swift

private func configBenchmarkDesign() {
    STConstants.shared.st_configBenchmarkDesign(size: CGSize.init(width: 375, height: 812))
}
```

## How to use

#### 一、STBaseViewController

> 1. Implement a customizable navigation bar, `ViewController` inheriting from this class can be repackaged for modifications of `font, color, position`;
> 
> 2. All `ViewController` can inherit from this class;

#### 二、STBaseView

> Optionally use `UIScrollView` as the parent class for layout；

#### 三、STBaseModel 

> Handling of `forUndefinedKey` exceptions;

#### 四、STBtn

> Button title text and image position settings;

#### 五、STDeviceInfo
