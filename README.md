# Voice Out

一个可以朗读选中文本的Electron应用程序。

## 功能特点

- 在任何应用程序中选择文本，按下 `Option + V` 即可朗读
- 使用系统的文本转语音能力通过 `say` 包实现
- 直接获取选中的文本，无需手动复制

## 使用方法

1. 启动应用程序
2. 在任何应用程序中选择文本
3. 按下 `Option + V` (Mac) 或 `Alt + V` (Windows/Linux)
4. 应用程序会自动朗读选中的文本

## 技术实现

- 在macOS上使用AppleScript获取选中的文本
- 使用系统的`say`命令进行文本转语音
- 全局键盘监听快捷键

## 开发设置

### 安装

```bash
$ pnpm install
```

### 开发

```bash
$ pnpm dev
```

### 构建

```bash
# For windows
$ pnpm build:win

# For macOS
$ pnpm build:mac

# For Linux
$ pnpm build:linux
```

## Recommended IDE Setup

- [VSCode](https://code.visualstudio.com/) + [ESLint](https://marketplace.visualstudio.com/items?itemName=dbaeumer.vscode-eslint) + [Prettier](https://marketplace.visualstudio.com/items?itemName=esbenp.prettier-vscode)
