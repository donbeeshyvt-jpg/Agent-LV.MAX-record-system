---
name: record-system-skill
description: >-
  「Agent 協作紀錄與規劃專案系統」程序 SKILL——三件套裡的「記憶之家」。讓 AI 輔助開發從一次性、健忘、
  靠運氣，變成可連續、可追溯、可驗證、換 agent 不失憶、省 token。核心：唯一入口 AGENTS.md ＋ docs/
  外接記憶（對話紀錄 CONVERSATION_LOG、交接 HANDOFF、任務 TASKS、碼庫地圖 CODE_INDEX、批准制
  REQUEST_LOG 的 APPROVED-NNN），新 agent 只靠 docs/ 就能接手、不必掃描整個程式碼庫。
  觸發時機：要建立開發治理骨架、長期維護的專案、多 agent／多工具（Cursor／Codex／Gemini／本地模型…）
  接力、規格導向（Spec Kit）開發、接手既有大型專案、需要可交接可追溯的情境；或使用者說「幫我把這專案
  變成可交接／不失憶／有紀錄／有規劃流程」。也用於：偵測到專案根目錄有 AGENTS.md 且 docs/ 下有
  00_AI_CONTEXT_INDEX.md 與 CONVERSATION_LOG.md／HANDOFF.md 時，先讀 docs/ 接手、不掃全庫。
  內含一鍵產生器（建立開發環境.ps1）與可觀摩的示範開發環境。跨工具：所有 agent 都讀同一份 AGENTS.md，
  核心強制（git pre-commit hook ＋ 一致性檢查 ＋ CI）與工具無關，不依賴任何單一家的 hook。
license: MIT
metadata:
  version: "1.0"
  origin: >-
    融合 Spec Kit（規格驅動骨架，WHAT）、Superpowers（各階段專家視角，HOW）、Harness Engineering
    （機械化檢查與 docs-as-memory 保證，ENFORCE）三套方法論；人類掌舵、agent 執行。
    完整規格（約 2800 行）見 UNIVERSAL_MULTI_AGENT_DEV_SKILL.md。
  companions:
    - agent-os-multirole（引擎：12 角色接力；會偵測本系統的 docs/ 延續思考）
    - loop-engineering-multiplan（迴圈工程；治理三件套住進本系統的 docs/loops/）
---

# Record System Skill｜Agent 協作紀錄與規劃專案系統

> 一句話：讓 AI 開發可以**接力、不跑偏、省 token** 的治理系統。
> 核心信念——**人類掌舵，AI 執行；文件是記憶，檢查是保證。**

這是一套**放進專案就能用**的開發治理規格。它讓 AI 輔助開發從「一次性、健忘、靠運氣」變成「可連續、可追溯、可驗證」——重點不是「寫得更快」，而是「**下次／別人／別的 AI 都能無痛接手**」。

## 這個 SKILL 內含的檔案（bundled files）

載入本 skill 後，你可以直接讀取／執行同目錄下的這些檔案：

| 檔案 | 用途 | 你怎麼用 |
| --- | --- | --- |
| [`UNIVERSAL_MULTI_AGENT_DEV_SKILL.md`](UNIVERSAL_MULTI_AGENT_DEV_SKILL.md) | **系統本體（完整規格，約 2800 行，英文正文＋繁中註解）**：Spec Kit 流程、Superpowers 專家視角、Harness 機械化檢查、docs/ 每個檔的職責、APPROVED-NNN 批准制、語言與一致性規則 | 需要細節時精讀對應章節；不必整份載入 |
| [`建立開發環境.ps1`](建立開發環境.ps1) | **一鍵產生器**：把規格變成可用的 `docs/` 骨架＋機械檢查腳本＋範例 feature | 新專案跑 `powershell -ExecutionPolicy Bypass -File .\建立開發環境.ps1`（換名：`-Path .\my-app -ProjectName "My App"`） |
| [`示範開發環境/`](示範開發環境/) | **產生出來的活範例（Notes API）**：`AGENTS.md`＋完整 `docs/`＋`scripts/`＋`.github/` | 直接觀摩結構，或當新專案的起點複製 |
| [`示範開發環境/docs/`](示範開發環境/docs/) | **docs/ 模板全集**：00_AI_CONTEXT_INDEX、PROJECT_VISION、INTENT_TRACE、CONVERSATION_LOG、HANDOFF、TASKS、CODE_INDEX、GOLDEN_RULES、REQUEST_LOG、DECISION_LOG、ENTROPY_LOG、ARCHITECTURE、REQUIREMENTS、SELF_CHECK、TEST_REPORT、features/NNN-*/{spec,plan,tasks} | 每個檔開頭都有用途說明，照填即可 |
| [`示範開發環境/scripts/`](示範開發環境/scripts/) | 機械化檢查與 hook：`check-consistency.{ps1,sh}`、`git-hooks/pre-commit`、`install-hooks.{ps1,sh}`、`log-user-prompt.{ps1,sh}` | 選用；跑 `install-hooks` 才啟用自動同步／擋 commit |
| [`README.md`](README.md) | 人類讀的總覽（痛點對照表、三步開始、跨工具設計） | 給人看，不是給 agent 載入 |

## 何時用這個 SKILL

- 要**建立開發治理骨架**（讓專案從此可交接、不失憶）。
- **長期維護**的專案、**多 agent／多工具接力**（Cursor→Codex→本地模型都讀同一份 `AGENTS.md`）。
- **規格導向**開發：先講清楚「要做什麼」再做（constitution → spec → clarify → plan → tasks → analyze → implement）。
- **接手既有大型專案**：只讀 `docs/` 就懂，不掃全庫。
- 使用者說「幫我把這專案變成可交接／有紀錄／有規劃流程」。

## 三種用法

### 1. 新專案 — 建立骨架
```powershell
powershell -ExecutionPolicy Bypass -File .\建立開發環境.ps1
# 驗證機械檢查（乾淨環境應 PASS）：
powershell -File .\示範開發環境\scripts\check-consistency.ps1
```
產出 `docs/` 交接骨架＋檢查腳本＋範例 feature。想啟用「改 src/ 沒同步索引就擋 commit」「使用者對話自動上鏈」等自動機制，再跑一次 `scripts/install-hooks.ps1`（**選用**，不裝也能用，只是少了自動強制）。

### 2. 接手既有的紀錄系統專案 — 只靠 docs/ 上手
偵測指紋：根目錄有 `AGENTS.md`，且 `docs/` 下有 `00_AI_CONTEXT_INDEX.md` 與（`CONVERSATION_LOG.md` 或 `HANDOFF.md`）。命中就**照這個順序讀、不要掃全庫**：
> `docs/00_AI_CONTEXT_INDEX.md` → `CONVERSATION_LOG.md`（Active Summary＋近期使用者訊息）→ `HANDOFF.md`（下一個安全任務）→ `GOLDEN_RULES.md` → `REQUEST_LOG.md`（Approvals/Corrections）→ `PROJECT_VISION.md`／`INTENT_TRACE.md` → `TASKS.md`／`CODE_INDEX.md`（只讀需要的 1–3 檔）。
先摘要現況，再接續 `HANDOFF` 的下一個安全任務。任一檔為空或不存在就跳過、不幻覺。

### 3. 當夥伴技能（與另外兩包連動）
- **Agent_OS_Skill**：它的 ⓠ 情境攝取會**自動偵測**本系統結構，讀 `docs/` 對話紀錄來延續思考（軟性、不依賴 hook）。
- **Loop_Engineering_Skill**：它規劃的治理三件套（`LOOP-NNN.md`／`STATE-NNN.md`／`LOOP_PORTFOLIO.md`）住進本系統的 `docs/loops/`，上線走 `APPROVED-NNN` 批准。

## 唯一入口與跨工具設計

**只有一個入口檔：`AGENTS.md`。** 所有 agent 工具（Claude Code、Cursor、Codex、Gemini CLI、Aider、本地 LLM、純人類）都讀同一份 `AGENTS.md` ＋ `docs/`。核心強制（git `pre-commit` hook ＋ `check-consistency` ＋ CI）**與工具無關**——任何 agent commit 都會被擋下，不依賴任何一家的 hook。其餘設定檔（`.cursor/rules/`、`.aider.conf.yml` 等）只是「讓某工具自動載入 `AGENTS.md`」的功能設定，不放任何規則。

## 給新 agent 的第一句話（可直接複製）

> 請先讀 `UNIVERSAL_MULTI_AGENT_DEV_SKILL.md` 與 `AGENTS.md`，以及 `docs/` 下的
> PROJECT_VISION、00_AI_CONTEXT_INDEX、HANDOFF、TASKS、CODE_INDEX、GOLDEN_RULES。
> 跑一次 `check-consistency`。先摘要現況，再接續 `HANDOFF` 裡的下一個安全任務。
> **不要掃描整個程式碼庫。**

---

MIT 授權。完整規格與所有章節見 [`UNIVERSAL_MULTI_AGENT_DEV_SKILL.md`](UNIVERSAL_MULTI_AGENT_DEV_SKILL.md)。
