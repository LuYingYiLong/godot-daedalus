# FMODExample — 项目协作指南

## 项目概览

Godot 4.7 项目，Forward Plus 渲染 + Direct3D 12 + Jolt Physics 3D。  
名称暗示 FMOD 音频集成方向，当前已配置自定义音频总线布局和多种效果器。  
集成了 godot_daedalus（AI 助手）、godot_gif（GIF 播放）、godot_jieba（中文分词）、markdown_label（Markdown 渲染）四个插件。

当前代码资产单一：一个猜数字小游戏（Control 界面，1-100 范围，7 次机会）。

## 目录结构

```
addons/                     # 第三方插件（禁止 AI 修改）
  godot_daedalus/           # AI 助手插件
  godot_gif/                # GIF 播放 GDExtension
  godot_jieba/              # 中文分词 GDExtension
  markdown_label/           # Markdown 标签 GDExtension
scenes/
  guess_number.tscn         # 猜数字游戏场景（Control 根节点）
scripts/
  guess_number.gd           # 猜数字游戏逻辑
default_bus_layout.tres     # 音频总线布局（含 FMOD 效果链）
project.godot               # 引擎配置
```

## 编码规范

- **语言**：优先 GDScript；有 .NET 配置但当前未使用。
- **类型**：变量、参数、返回值显式强类型；禁止 `:=`。
- **引用**：`%UniqueName` 或 `@onready` 缓存优先；不写死资源路径。
- **场景**：固定信号在 `.tscn` 中连接，动态信号在代码中连接。
- **注释**：简洁中文，只解释非显而易见的设计。
- **插件代码**：`addons/` 目录视为外部代码，不修改。

## 场景与资源修改规则

- 修改场景前先通过 `inspect_scene_tree` 理解节点树、owner、信号连接。
- `.tscn` 修改优先使用语义工具（add_node / attach_script / connect_signal）。
- 不手动编辑 `.godot/` 目录下的任何文件。
- 不修改 `addons/` 目录内的文件。

## 验证命令

```bash
# GDScript 语法检查
"D:/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64.exe" --headless --path "D:/GodotProjects/example" --check-only --quit

# Git 状态检查（可用时）
git status --short
git diff --stat
```

## 工具使用规则

- 写操作（create / overwrite / replace / delete / scene edit）需用户审批。
- 读操作（read / list / inspect / search）直接执行。
- MCP 工具出错时如实报告，不假设操作成功。

## 禁止修改的目录/文件

- `.godot/` — 引擎缓存和导入数据
- `addons/` — 第三方插件代码
- `icon.png.import` — 自动生成的导入配置
