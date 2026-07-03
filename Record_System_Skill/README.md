# Record System Skill｜Agent 協作紀錄與規劃專案系統

> 一句話:讓 AI 開發可以**接力、不跑偏、省 token** 的治理系統。
> 核心信念 —— **人類掌舵,AI 執行;文件是記憶,檢查是保證。**

---

## 這是什麼?

一套放進專案就能用的「開發治理規格」。它讓 AI 輔助開發從**一次性、健忘、靠運氣**,變成**可連續、可追溯、可驗證**。
重點不是「寫得更快」,而是「**下次/別人/別的 AI 都能無痛接手**」。

| 你一定遇過的痛 | 這套系統怎麼救 |
|---|---|
| AI 換個 session 就忘了專案在幹嘛 | `docs/` 當外接記憶,讀文件就懂 |
| 每次都重掃整個專案,**很燒 token** | `CODE_INDEX` 碼庫地圖,只讀需要的 1～3 個檔 |
| 做著做著變成**我沒要的東西** | 規格驅動 + 初衷紀錄(`PROJECT_VISION`/`INTENT_TRACE`) |
| 改一個功能**弄壞三個別的** | 機械化檢查、禁改清單、結構測試 |
| AI 說「做完了」其實沒測 | 沒有證據(測試/檢查通過)不准算完成 |
| 換工具(Cursor→Claude Code→Codex)接不上 | 交接靠文件,跟聊天記錄無關 |

---

## 三層,服務一個目標

- **🎯 目標 —— 文件即交接、省 token**:每個階段都寫回 `docs/`,新 agent 只靠 `docs/` 就能接手。
- **① Spec Kit(骨架)**:先講清楚「要做什麼」再做(constitution → spec → clarify → plan → tasks → analyze → implement)。
- **② Superpowers(專業視角)**:每個階段都能調出對應專家(設計、TDD、除錯、審查、驗證)。
- **③ Harness(保證)**:規則不是用「講」的,是用「會報錯的機械檢查」擋住。

### 語言約定(預設)

- 程式碼 **識別符英文、註解繁體中文**(例:`// 處理登入授權`)。
- `docs/CODE_INDEX.md` 為 **雙語**(`Responsibility (EN)` + `職責（繁中）`),讓中、英文思維的 AI 都能用最少 token 理解專案全貌。
- **全資料夾零簡體字** —— 由 `check-consistency.ps1` 機械化把關。
- 專案若需改成其他語言,在 `docs/DECISION_LOG.md` 明示即可。

### Hook 強制同步(免再叮嚀新 agent)

每次新接手的 AI 都得提醒「記得更新 docs」很累。這套系統把它變成自動機制 —— hook 檔產生器已產出,但要跑一次 `install-hooks.ps1` 才會啟用:

- **編輯時提醒**(自動) —— Claude Code `.claude/settings.json` PostToolUse hook + Cursor glob 規則,動了 `src/` 立刻提醒同步 `CODE_INDEX`。
- **Commit 時硬擋**(必殺) —— `scripts/git-hooks/pre-commit` 偵測「動了 `src/` 卻沒一起 stage `docs/CODE_INDEX.md`」就**直接擋下 commit** 並附上修復步驟。連刪檔(`git rm`)和搬檔(`git mv`)都涵蓋。`--no-verify` 緊急繞過需明確意圖 + 同 commit 記到 `ENTROPY_LOG`(§37.5)。
- **使用者對話自動上鏈**(關鍵新功能) —— Claude Code UserPromptSubmit hook 把每則使用者訊息**自動加註時間戳記**寫入 `docs/CONVERSATION_LOG.md`;agent 在每回合結尾更新 Active Summary。**換 agent 接手不必再被問「我們剛剛在討論什麼」**——讀 CONVERSATION_LOG 就知道。
- **背景偵測** —— `check-consistency` 持續掃索引與程式碼新舊差異。

一次性安裝(走腳本,免手動):
```powershell
cd 示範開發環境
powershell -ExecutionPolicy Bypass -File scripts/install-hooks.ps1
# macOS/Linux/WSL 再跑一次: chmod +x scripts/git-hooks/pre-commit
```

從此換哪個 agent 都不必再叮嚀:改 `src/` 沒同步索引 commit 會卡住,而且新 agent 一進來讀 `CONVERSATION_LOG.md` 的 Active Summary,就知道你想往哪走。

### 規劃→確認→執行(免被擅自做超出範圍)

任何非小修小改的工作,流程都是:**多角度拆解 → 產出規劃書(spec + plan + tasks)→ `/analyze` 跨文件一致性 → 給使用者確認 → 寫入 `APPROVED-NNN` 後才動手寫程式碼**。
這個門檻寫在 SKILL §3.14 / §13.2,並由 §27 的完成定義要求每個任務都對得上一筆批准紀錄。中途改範圍會回到迷你批准循環,不會被悄悄擴張。

---

## 適合誰 / 什麼時候用

**很適合**:長期維護的專案、規格導向的後端/API/產品、多 agent 或多工具協作、接手的既有大型專案、需要可追溯/交接的情境。
**很適合的人**:用嘴開發的創業者(防 AI 跑偏)、長期個人專案的獨立開發者、小團隊接力、想設護欄的 Tech Lead。

### 跨工具設計 —— 唯一入口就是 `AGENTS.md`

**只有一個入口檔:`AGENTS.md`。** 所有 agent 工具(Claude Code、Cursor、OpenAI Codex CLI、Gemini CLI、Aider、GitHub Copilot、本地 LLM、純人類)都讀同一份 `AGENTS.md` + `docs/`。**不再有 `CLAUDE.md` / `GEMINI.md` 之類的逐家轉址檔** —— 那些只是「請讀 AGENTS.md」的重複,容易腐爛、又把真相來源拆散。

| 工具 | 怎麼找到 `AGENTS.md` | 規則來源 |
|---|---|---|
| OpenAI Codex CLI / Cursor | 原生讀 `AGENTS.md`(Cursor 經 `.cursor/rules/`),免額外設定 | `AGENTS.md` |
| Aider | `.aider.conf.yml` 的 `read:` 清單預載(功能設定,非規則副本) | `AGENTS.md` |
| Claude Code | 保留 `.claude/settings.json`(只放 hook)。開場第一句叫它讀 `AGENTS.md`(§29 範本已內建)。想要開機自動載入,自己加一行 `CLAUDE.md` 寫「Read AGENTS.md」即可 —— 預設不附 | `AGENTS.md` |
| Gemini CLI / GitHub Copilot / 本地 LLM / 純 shell | 第一句指令就是「讀 `AGENTS.md`」;CI + pre-commit 不管哪個工具都照擋 | `AGENTS.md` |

**關鍵設計**:核心強制(git pre-commit hook + `check-consistency` + CI)**完全跟工具無關** —— 任何 agent commit 都會被擋下,不依賴任何一家的 hook。`AGENTS.md` 是唯一真相來源,其餘設定檔(`.claude/settings.json`、`.cursor/rules/`、`.aider.conf.yml`)只是「讓某工具自動載入 AGENTS.md / 自動跑檢查」的功能設定,**不放任何規則**。詳見 SKILL §3.16。

> 💡 提示:專案**越長期、越多人/多 agent、出錯代價越高**,效益越大。
> 極短期或拋棄式的小東西要不要用,你自己衡量即可 —— 它有「文件 + 流程」的成本。

---

## 怎麼開始(3 步)

```powershell
# 1) 一鍵產生完整開發環境前置(docs 交接 + 機械檢查 + 範例 feature)
powershell -ExecutionPolicy Bypass -File .\建立開發環境.ps1
#    換專案名/路徑:.\建立開發環境.ps1 -Path .\my-app -ProjectName "My App"

# 2) 驗證機械檢查(乾淨環境應 PASS;故意刪個 docs 檔會大聲報錯並附修法)
powershell -File .\示範開發環境\scripts\check-consistency.ps1
```

**3) 給新 agent 的第一句話(直接複製):**

> 請先讀 `UNIVERSAL_MULTI_AGENT_DEV_SKILL.md` 與 `AGENTS.md`,以及 `docs/` 下的
> PROJECT_VISION、00_AI_CONTEXT_INDEX、HANDOFF、TASKS、CODE_INDEX、GOLDEN_RULES。
> 跑一次 `check-consistency`。先摘要現況,再接續 `HANDOFF` 裡的下一個安全任務。
> **不要掃描整個程式碼庫。**

---

## 資料夾內容

| 檔案 / 資料夾 | 用途 |
|---|---|
| `UNIVERSAL_MULTI_AGENT_DEV_SKILL.md` | 系統本體(完整規格,英文正文 + 繁中註解) |
| `建立開發環境.ps1` | 一鍵產生器:把規格變成可用的 `docs/` + 檢查腳本 + 範例 feature |
| `示範開發環境/` | 產生出來的活範例(Notes API),可直接觀摩或當起點 |
| `README.md` | 本說明 |

---

> **一句總結**:這套系統最大的價值,是讓整個專案在多次、多人、多 agent 的接力下
> **不失憶、不跑偏、不假完成,而且接手成本極低**。
