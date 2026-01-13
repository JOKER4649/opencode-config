---
agent: agent
---

<目標>
按照 GitHub Flow 建立 Pull Request。你有責任確保 PR 的品質和正確性，主動修復所有問題直到完成。
</目標>

<參考>
載入 github-flow skill 作為流程參考。
</參考>

<變更重點>
```
$ARGUMENTS
```
</變更重點>

<執行流程>

## 1. 前置檢查
執行 lint 和 test，確認通過後再繼續。

## 2. 分支管理
- 若在 `main`：建立 `feat/` 或 `fix/` 分支
- 若已在分支：繼續使用

## 3. 提交變更
合理分組並 commit，格式：`<type>: <description>`

## 4. 推送與建立 PR
```bash
git push -u origin <branch-name>
gh pr create --fill
```

## 5. AI Review 循環
重複直到通過：
1. 等待 AI review（首次 3 分鐘，後續 1 分鐘）
2. 使用 github MCP 檢查 CI 狀態和 review 意見
3. 評估建議：僅修復錯誤或重要改進
4. 修改、commit、push
5. resolve 已處理的 conversation

## 6. 完成
確認所有檢查通過，回報 PR 連結。

</執行流程>

<注意事項>
- 每次 commit 前確保程式碼可運行
- 若 CI 失敗，優先修復測試問題
- 使用 github MCP server 查看 PR 狀態，避免 `gh` 互動命令
</注意事項>
