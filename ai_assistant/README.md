# AIAssistant

一个面向商用落地改造的 SwiftUI iOS AI 助手项目，当前以端侧能力为核心，包含：

- 图像识别：`Vision + Core ML`，已内置 Apple 官方 `MobileNetV2.mlmodel`，支持中文优先的识别结果展示。
- 语音处理：包含麦克风录音与系统语音转写，预留 `SoundClassifier.mlmodel` 声音分类接入点。
- 图像生成：预留 `ImageGenerator.mlmodel` 推理入口，当前为本地占位预览，便于先验证 UI、权限和产品流程。
- 商用说明：首页提供隐私、模型授权、生成能力上线前检查等信息入口。

## 打开项目

用 Xcode 打开：

```bash
open AIAssistant.xcodeproj
```

或者命令行构建：

```bash
xcodebuild -project AIAssistant.xcodeproj -scheme AIAssistant -destination 'generic/platform=iOS' build
```

## 添加模型

把 `.mlmodel` 拖入 Xcode，并确认勾选 `AIAssistant` target membership。建议命名：

- `ImageClassifier.mlmodel`
- `SoundClassifier.mlmodel`
- `ImageGenerator.mlmodel`

当前项目已经包含 `AIAssistant/Models/MobileNetV2.mlmodel`。Xcode 会在构建时把 `.mlmodel` 编译成 `.mlmodelc`，运行时服务层会从 Bundle 中查找。

## 商用化改造内容

- 工程、target、scheme、App display name 已统一为 `AIAssistant`。
- Bundle identifier 已改为 `com.lanht.AIAssistant`，发布前可按团队域名继续调整。
- 首页从实验型 demo 改为产品控制台，增加功能状态标签、隐私/离线/模型可替换信任点。
- 权限文案已改为面向用户的用途说明。
- 图像识别已接入真实模型；图像生成入口保留为待接入状态，避免把未完成能力包装成可用功能。
- README 和界面均标明模型来源与上线前授权检查点。

## UI 设计方向

界面基于 `ui-ux-pro-max` 的移动端规则搭建：

- 所有主要操作触控高度至少 44pt。
- 使用系统动态字体、系统颜色和语义色 token，适配浅色与深色模式。
- 首页以功能入口卡片为主，避免说明型落地页，直接进入可用功能。
- 异步状态均提供加载、成功、缺失模型或权限提示。
- 商用风险信息不隐藏在文档里，用户可在 App 内查看说明。
