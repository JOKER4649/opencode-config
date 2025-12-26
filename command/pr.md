---
agent: agent
# description: "建立PR 重點變更"
---

<目標>
按照 GitHub Flow 建立 Pull Request, 你有責任確保 PR 的品質和正確性, 你必須主動嘗試修復所有問題直到完成。
</目標>

<變更重點>
```
$ARGUMENTS
```
</變更重點>

<流程>
1. 前置檢查
  - 執行 lint 和 test
  - 確認測試通過後再繼續

2. 分支管理
  - 若在 `main` 分支：切換至 `feat/{簡短功能描述}`、`fix/{簡短修復描述}`
  - 若已在分支：繼續使用

3. 提交變更
  - 合理的分組並 `git commit`
  - Commit message 格式：`<type>: <description>`
    - type: feat/fix/refactor/docs/test 等

4. 推送與建立 PR
```bash
git push -u origin <branch-name>
gh pr create --fill
```

5. CI/Review 循環
重複直到通過：
  1. 使用 #github 檢查 CI 狀態和 AI review 意見
  2. 評估 review 建議並進行修改
    - 僅修復錯誤或重要改進
    - 完成後 `resolve conversation`
  3. 如果可能，在本地驗證修復
  4. Commit 並 push 變更

**第一次循環等待3分鐘讓 AI review 完成，之後每次等待1分鐘**

6. 完成
  - 確認所有檢查通過
  - 回報 PR 連結和狀態
</流程>

<注意事項>
- 每次 commit 前確保程式碼可運行
- PR description 需清楚說明變更內容和目的
- 若 CI 失敗，優先修復測試問題
- `gh` (github cli) 絕大多數都是互動命令, 你無法用其來查看 PR 狀態，請使用 #github MCP server
</注意事項>
