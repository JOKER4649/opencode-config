<UserPreference>
- 使用繁體中文進行對話
</UserPreference>

<!-- 
  文檔哲學 (Documentation Philosophy)
  ===================================
  
  本配置遵循以下原則，所有 agent 應理解並遵守：
-->

<DocumentationPhilosophy>
## 1. 程式碼即文檔 (Code as Documentation)

**原則**：程式碼應透過註解和連結自解釋，而非依賴外部文檔。

### 實踐方式：

```typescript
// ✅ GOOD: 自解釋的程式碼
/**
 * 驗證使用者 JWT token
 * @see https://jwt.io/introduction - JWT 標準說明
 * @see https://github.com/auth0/node-jsonwebtoken#readme - 使用的函式庫
 */
async function validateJWT(token: string): Promise<User> {
  // RFC 7519: JWT 必須包含三個部分
  // https://datatracker.ietf.org/doc/html/rfc7519#section-3
  const [header, payload, signature] = token.split('.');
  
  // 使用 RS256 演算法驗證
  // 原因：比 HS256 更安全，適合分散式系統
  // https://auth0.com/blog/rs256-vs-hs256-whats-the-difference/
  return jwt.verify(token, publicKey, { algorithms: ['RS256'] });
}

// ❌ BAD: 需要查閱外部文檔才能理解
async function validateJWT(token: string): Promise<User> {
  return jwt.verify(token, publicKey, { algorithms: ['RS256'] });
}
```

### 註解應包含：
- **意圖** (WHY) - 為什麼這樣做
- **外部連結** - 標準、RFC、官方文檔
- **決策理由** - 為什麼選擇這個方案而非其他
- **已知限制** - 不支援什麼、邊界條件

### 何時寫註解：
- 非顯而易見的業務邏輯
- 效能考量或優化
- 安全性相關決策
- 與第三方服務整合
- 繞過已知 bug 的 workaround

### 何時不寫註解：
- 淺而易懂的程式碼
- 程式碼已自解釋（良好的命名）
- 重複程式碼內容（如 `// 設定 username` for `username = value`）

---

## 2. 測試即規範 (Tests as Specification)

**原則**：用測試展示預期行為，而非撰寫獨立規範文檔。

### 實踐方式：

```typescript
// ✅ GOOD: 測試即規範
describe('JWT驗證', () => {
  // 規範：有效 token 應成功驗證
  it('應成功驗證有效的 JWT token', async () => {
    const token = generateValidToken({ userId: '123' });
    const user = await validateJWT(token);
    expect(user.id).toBe('123');
  });

  // 規範：過期 token 應拋出特定錯誤
  it('應拋出 TokenExpiredError 當 token 過期', async () => {
    const expiredToken = generateExpiredToken();
    await expect(validateJWT(expiredToken))
      .rejects.toThrow(TokenExpiredError);
  });

  // 規範：簽名無效應拋出錯誤
  // 參考：https://datatracker.ietf.org/doc/html/rfc7519#section-7.2
  it('應拒絕簽名無效的 token', async () => {
    const tamperedToken = generateTamperedToken();
    await expect(validateJWT(tamperedToken))
      .rejects.toThrow('invalid signature');
  });
});
```

### 測試應展示：
- **正常情況** - 預期的成功路徑
- **邊界條件** - 空值、極值、特殊輸入
- **錯誤處理** - 各種失敗情況
- **業務規則** - 領域邏輯的具體案例

### 參考連結優先：
```typescript
// ✅ GOOD: 連結到外部標準
it('應遵循 RFC 7519 的 JWT 格式要求', () => {
  // https://datatracker.ietf.org/doc/html/rfc7519#section-3
  const token = generateToken();
  expect(token.split('.')).toHaveLength(3);
});

// ❌ BAD: 在測試中重複實作說明
it('JWT 應包含三個部分：header, payload, signature', () => {
  // JWT 格式：
  // 1. header: base64url({"alg":"RS256","typ":"JWT"})
  // 2. payload: base64url({...claims})
  // 3. signature: RSASHA256(header.payload, privateKey)
  const token = generateToken();
  expect(token.split('.')).toHaveLength(3);
});
```

---

## 3. 最小化獨立文檔 (Minimize Standalone Docs)

**原則**：僅在以下情況建立獨立文檔。

### 必要時機：
| 情境 | 建立文檔 | 原因 |
|------|---------|------|
| 架構決策記錄 (ADR) | ✅ | 記錄重大技術決策的背景和權衡 |
| 部署流程 | ✅ | 涉及多系統、需人工介入 |
| 新人上手指南 | ✅ | 環境設定、初次貢獻流程 |
| API 對外文檔 | ✅ | 供外部使用者整合 |
| 業務領域知識 | ✅ | 程式碼外的領域概念 |
| 如何使用函式庫 | ❌ | 應連結官方文檔 |
| 程式碼風格指南 | ❌ | 應使用 linter + prettier 配置 |
| 功能詳細說明 | ❌ | 應在程式碼註解 + 測試展示 |

### 文檔格式建議：
```markdown
<!-- ✅ GOOD: 架構決策記錄 -->
# ADR-001: 選擇 PostgreSQL 作為主資料庫

**日期**: 2026-01-02  
**狀態**: 已採用  
**決策者**: Backend Team

## 背景
需要選擇關聯式資料庫支援交易和複雜查詢。

## 考慮方案
1. PostgreSQL - [官方文檔](https://www.postgresql.org/docs/)
2. MySQL - [官方文檔](https://dev.mysql.com/doc/)

## 決策
選擇 PostgreSQL

## 理由
- 更好的 JSON 支援 ([文檔](https://www.postgresql.org/docs/current/datatype-json.html))
- 更強的資料完整性約束
- 團隊已有使用經驗

## 後果
- 需學習 PostgreSQL 特有功能
- 部署需支援 PostgreSQL 12+

## 參考資料
- [PostgreSQL vs MySQL](https://www.postgresql.org/about/)
- [JSON in PostgreSQL](https://www.postgresql.org/docs/current/datatype-json.html)
```

---

## 4. 外部連結優先 (External Links First)

**原則**：實作細節應連結官方文檔，而非重複撰寫。

### 連結優先級：
1. **官方文檔** - 函式庫、框架、標準組織
2. **權威來源** - RFC、W3C、IETF
3. **成熟部落格** - Martin Fowler、Google Engineering Blog
4. **程式碼範例** - GitHub 官方 repo 的 examples/

### 實踐方式：

```typescript
// ✅ GOOD: 連結官方實作指南
/**
 * 實作 OAuth 2.0 授權碼流程
 * 
 * 完整流程請參考：
 * @see https://oauth.net/2/grant-types/authorization-code/ - OAuth 2.0 規範
 * @see https://github.com/panva/node-openid-client#readme - 使用的函式庫範例
 * 
 * 本實作特殊處理：
 * - PKCE 強制啟用（安全考量）
 * - state 參數綁定 session（防 CSRF）
 */
async function handleOAuthCallback(code: string, state: string) {
  // implementation
}

// ❌ BAD: 在註解中重寫實作步驟
/**
 * OAuth 2.0 授權碼流程：
 * 1. 使用者點擊登入按鈕
 * 2. 重導向到授權伺服器
 * 3. 使用者同意授權
 * 4. 回傳授權碼
 * 5. 用授權碼換取 access token
 * 6. 用 access token 取得使用者資訊
 * ...（重複官方文檔內容）
 */
```

### README.md 應包含：
```markdown
<!-- ✅ GOOD: 最小化 README -->
# Project Name

簡短說明（一句話）

## 快速開始
```bash
npm install
npm run dev
```

## 核心文檔連結
- [框架官方文檔](https://example.com/docs)
- [API 設計規範](https://example.com/api-design)
- [部署指南](./docs/deployment.md) ← 僅有必要才建立

## 專案特定說明
- 環境變數設定：見 `.env.example`
- 架構決策：見 `docs/adr/`
- 貢獻指南：見 `CONTRIBUTING.md`
```

---

## 實施指引 (For AI Agents)

當你被要求建立文檔時：

1. **先詢問**：「這個資訊能否透過程式碼註解、測試或外部連結提供？」
2. **建議替代方案**：
   - 「我建議在程式碼加入註解並連結到 [官方文檔]」
   - 「我建議寫測試展示此行為，參考 [範例]」
3. **確認必要性**：「確定需要獨立文檔嗎？這似乎可以...」
4. **如果確實需要**：
   - 保持簡短
   - 大量使用外部連結
   - 避免重複實作說明
   - 專注於「為什麼」而非「如何做」

當你需要了解如何實作某功能時：

1. **先搜尋官方文檔連結**：使用 librarian agent 查找
2. **在程式碼中引用連結**：而非在聊天中解釋
3. **如需範例**：連結到官方 repo 的 examples/

</DocumentationPhilosophy>
