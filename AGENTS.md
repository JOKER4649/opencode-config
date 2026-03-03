# 專案概述

此倉庫用於備份與同步個人常用工具的設定檔。每個工具的設定以獨立子目錄管理。

## 專案結構

```
myconfig/
├── link.py      # Symlink 管理腳本
├── mise/        # mise 開發工具版本管理器設定
├── opencode/    # OpenCode（AI 編碼助手）完整設定
├── starship/    # Starship 跨 shell 提示字元設定
└── zsh/         # Zsh shell 設定
```

## 慣例

- **目錄組織**：每個工具一個子目錄，目錄名即工具名稱

## 注意事項

- `opencode/` 內的 `node_modules/`、`package.json`、`bun.lock` 已被 `.gitignore` 排除，不應追蹤
- 新增工具設定時，必須完成以下三步：
  1. 建立以工具名稱命名的子目錄，將設定檔放入
  2. 在 `link.py` 的 `LINKS` 清單新增 `LinkEntry`，映射倉庫路徑到系統路徑
  3. 在 `README.md` 的結構表格新增對應項目
