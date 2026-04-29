# screen_rotation

一个基于 UIKit 的 iOS 示例工程，演示如何在真实项目中统一管理屏幕旋转策略。  
核心思路是把旋转控制集中到 `ScreenOrientationManager`，页面只声明自己的旋转偏好（竖屏、横屏、自由旋转或自定义）。

## 项目目标

- 统一管理全局方向策略，避免页面各自处理导致冲突
- 支持导航栈 `push/pop`、模态 `present/dismiss` 的方向切换
- 兼容 iOS 13+，并针对 iOS 16+ 使用 `requestGeometryUpdate`
- 让页面只关注业务：通过 `orientationPolicy` 声明自身需求

## 运行环境

- Xcode 15+（推荐）
- Swift 5
- iOS Deployment Target: `13.0`
- UIKit + SceneDelegate 架构

## 快速运行

1. 打开 `screen_rotation.xcodeproj`
2. 选择 `screen_rotation` target 与模拟器（iPhone 或 iPad）
3. 运行后在首页切换策略并点击「应用当前策略」
4. 点击「Push 横屏演示页」查看页面级横屏锁定效果

## 核心设计

### 1) 旋转策略模型

文件：`screen_rotation/ScreenOrientationManager.swift`

- `ScreenOrientationPolicy` 定义策略：
  - `.portrait`
  - `.landscape`
  - `.allButUpsideDown`
  - `.custom(mask:preferred:)`
- 每个策略映射为：
  - `mask`（支持方向集合）
  - `preferredOrientation`（首选方向）

### 2) 中央管理器

文件：`screen_rotation/ScreenOrientationManager.swift`

`ScreenOrientationManager` 负责：

- 保存当前策略 `currentPolicy`
- 挂载当前 `UIWindowScene`
- 从顶部页面递归解析实际生效策略（支持导航、标签页、模态）
- 触发系统旋转：
  - iOS 16+：`UIWindowScene.GeometryPreferences.iOS` + `requestGeometryUpdate`
  - iOS 15 及以下：`UIDevice.orientation` + `attemptRotationToDeviceOrientation`

### 3) 页面与容器协议化

文件：`screen_rotation/RotationAwareControllers.swift`

- `ScreenOrientationConfigurable`：页面声明 `orientationPolicy`
- `RotationAwareViewController`：
  - 默认策略竖屏
  - 在 `viewWillAppear/viewDidAppear` 自动刷新方向
  - 重写 `present`，在弹窗前预应用目标策略
- `RotationAwareNavigationController`：
  - 重写 `pushViewController`
  - 在 `didShow` 回调同步策略
- `RotationAwareTabBarController`：
  - 基于当前 `selectedViewController` 提供方向策略

### 4) App 层接入点

- `AppDelegate.application(_:supportedInterfaceOrientationsFor:)`  
  返回 `ScreenOrientationManager.shared.currentMask`
- `SceneDelegate` 在 scene 激活/连接时：
  - `attach(windowScene:)`
  - `refresh(from:)`

## 示例页面说明

文件：`screen_rotation/ViewController.swift`

- 首页可切换三种策略：竖屏 / 横屏 / 自由旋转
- `LandscapeDemoViewController` 固定返回 `.landscape`
- 导航切换时，方向策略会自动收敛到当前顶层页面

## 如何扩展到你的业务页面

1. 让页面继承 `RotationAwareViewController`
2. 重写 `orientationPolicy` 返回所需策略

示例：

```swift
final class VideoPlayerViewController: RotationAwareViewController {
    override var orientationPolicy: ScreenOrientationPolicy {
        .landscape
    }
}
```

如果是自定义容器控制器，请实现 `ScreenOrientationChildProviding` 并返回当前真正展示内容的子控制器。

## 目录结构

```text
screen_rotation/
├── AppDelegate.swift
├── SceneDelegate.swift
├── ScreenOrientationManager.swift
├── RotationAwareControllers.swift
├── ViewController.swift
└── Info.plist
```

## 注意事项

- 若页面未继承 `RotationAwareViewController`，默认会回退到竖屏策略
- iOS 16+ 的方向更新依赖 `windowScene`，需确保在 `SceneDelegate` 已正确 `attach`
- 当前项目关闭了多 Scene（`UIApplicationSupportsMultipleScenes = false`）

## License

仅作学习与工程实践示例使用。
