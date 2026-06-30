# FMODExample — AI 协作指南

## 项目概览

基于 **Godot 4.7**（Forward Plus）、集成 **FMOD** 音频中间件的技术验证项目，同时作为 **Godot Daedalus 本地 AI Runtime** 的开发测试平台。项目通过 WebSocket 连接 DeepSeek AI 后端实现 AI 辅助对话和工具调用。

## 目录结构与主要文件

```
├── AGENTS.md              ← 本文件（AI 协作规范）
├── project.godot          ← Godot 4.7 项目配置（D3D12、Jolt Physics、MSAA 2x）
├── main.tscn / main.gd    ← 主场景：时间线面板 + FMOD 播放器 + 性能监控
├── test.tscn / test.gd    ← AI Runtime 控制面板（WebSocket 客户端）
├── control.tscn / control2.tscn / node_3d.tscn ← 独立 UI/3D 场景
├── scripts/
│   └── player.gd          ← 玩家脚本
├── assets/
│   ├── scenes/            ← 子场景（note_example、player、audio_callback_test）
│   ├── scripts/           ← 资产相关脚本
│   └── theme.tres         ← 主题资源
├── tests/                 ← 烟雾测试与集成测试
│   ├── fmod_*             ← FMOD 各项功能验证（频谱、混响、延时、录音等）
│   ├── rst_viewer_*       ← RST 文档查看器测试
│   └── dsp_parameter_info_test.gd
├── addons/                ← 8 个插件（不直接修改）
│   ├── audio_visualizer / dwm / fmod_player
│   ├── godot_gif / godot_jieba / markdown_label
│   ├── rst_viewer / timeline_panel
└── default_bus_layout.tres
```

## 编码规范

- **GDScript 风格**：显式声明所有变量类型（禁止 `:=`）；优先使用 `@onready` 缓存常用节点；场景固定信号在 `.tscn` 中连接；使用 `uid://` 路径引用资源。
- **节点访问**：`%UniqueName` 用于单次访问，`@onready` 变量用于复用访问，`@export` 用于可配置依赖。
- **属性配置**：固定属性配置在 `.tscn` 场景文件中，运行时依赖的属性才在代码中设置。
- **测试命名**：`tests/` 目录下的测试场景与脚本成对出现，命名约定为 `fmod_<功能>_smoke_test` 或 `fmod_<功能>_test`。

## 场景与资源修改规则

- **主场景** `main.tscn` 和 **控制面板** `test.tscn` 改动需谨慎，涉及 AI Runtime 核心交互。
- **tests/** 目录中的场景和脚本是正式的回归测试，不得随意删除或跳过断言。
- **addons/** 目录默认不修改；如需修改插件代码，需用户明确授权。
- **.godot/** 目录由 Godot 引擎管理，禁止手动修改或写入。

## 测试与验证命令

```bash
# 语法检查
"D:/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64.exe" --headless --path "D:/GodotProjects/example" --check-only --quit

# 无头运行（执行 _init 中的测试逻辑后退出）
"D:/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64.exe" --headless --path "D:/GodotProjects/example" --quit

# 资源导入（新增 .tscn/.tres 等资源时执行）
"D:/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64.exe" --headless --path "D:/GodotProjects/example" --import --quit
```

修改代码后必须按此顺序验证：语法检查 → 导入（如需）→ 测试执行。

## AI 工具使用与审批规则

- 文件创建、覆盖和删除操作需要用户在 Godot 客户端的 **Approvals（审批）** 区域批准后才能实际写入。
- `propose_*` 工具仅生成预览，不实际写入磁盘。
- `create_text_file` 会触发审批流程，需用户在 Godot 客户端确认后生效。
- 修改已有文件使用 `propose_overwrite_text_file`（整文件覆盖）或 `propose_replace_text_in_file`（文本替换），均需审批。
- 新增回归测试必须保留，临时探针代码在验证后清理。

## 不允许修改的目录

- `.godot/` — 引擎生成文件，任何情况下都不允许写入。
- `addons/` — 默认不允许修改；插件开发需用户明确授权当前工作的插件目录路径。
