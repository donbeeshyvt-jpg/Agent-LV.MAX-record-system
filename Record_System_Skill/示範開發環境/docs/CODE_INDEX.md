# Code Index

Last updated: 2026-06-05

> 雙語索引 (English + 繁體中文)。新 agent 先讀這份,即可定位 1–3 個關鍵檔,不必掃整個專案。
> Bilingual map of the codebase. A new agent reads this first to locate the 1–3 files a task needs without opening anything else.

## Module Map (planned — fill as code lands)
| Path | Responsibility (EN) | 職責（繁中） | Public API | Used By | Tests | Risk |
|---|---|---|---|---|---|---|
| src/api/notes.* | HTTP routes for notes | 對外 HTTP 路由：建立／列出／刪除筆記 | POST/GET/DELETE /notes | server | tests/api/notes.* | low |
| src/service/notes.* | note rules (validate, ids) | 商業邏輯：驗證輸入、產生 id、組裝回應 | createNote/listNotes/deleteNote | api | tests/service/* | low |
| src/storage/notes.* | persistence (SQLite) | 持久化層：SQLite 讀寫筆記資料 | save/all/remove | service | tests/storage/* | med |

No source files exist yet; rows above are the planned shape from the spec. 尚無實作檔案;以上為依規格規劃的雛型。

<!-- Optional per-file detail block — add when a single row isn't enough.
     新增程式碼後,可在此區追加每個檔案的詳細條目。範本:
## src/api/notes.ts
Responsibility (EN): HTTP routes for /notes (POST/GET/DELETE)
職責（繁中）: 對外 HTTP 路由,呼叫 service 層處理筆記 CRUD
Public functions/classes: registerRoutes(app)
Depends on: src/service/notes
Used by: src/server.ts
Related tests: tests/api/notes.test.ts
Change risk: low
Notes / 備註: 驗證錯誤統一回 400;失敗回 500。
-->
