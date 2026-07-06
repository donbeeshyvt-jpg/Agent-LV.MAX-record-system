# Agent-LV.MAX（record-system）

繁體中文 | [English](README.en.md)

> **Agent 協作紀錄系統：多角色 × 規劃協作 × 循環工程**
> 三個可拆可合的技能，讓 AI 做事有紀律：先想清楚、跑過才說做完、留下紀錄好交接。本地或較小的模型套上去，也能逼近商用 agent 的水準。
>
> - **多角色** → [`Agent_OS_Skill`](Agent_OS_Skill/)：12 角色多代理作業系統（管「怎麼想」）
> - **規劃協作** → [`Record_System_Skill`](Record_System_Skill/)：開發治理與交接紀錄（管「怎麼不失憶」）
> - **循環工程** → [`Loop_Engineering_Skill`](Loop_Engineering_Skill/)：迴圈工程規劃（管「怎麼持續做」）
>
> 全部是純 Markdown 的程序 SKILL：貼上 system prompt 就能用，不綁任何特定工具或執行框架，缺工具就誠實降級、絕不假裝。

---

## 三個技能

| 技能 | 一句話 | 入口檔 |
| --- | --- | --- |
| [Agent_OS_Skill](Agent_OS_Skill/) | **12 角色多代理作業系統**：意圖解碼→拆解→多透鏡研究→提案→最小變更實作→除錯→紅隊→證據驗收→綜合→沉澱，一棒接一棒、有證據、可追溯；內建橫切「判斷力層」（動工前三問、Proof Contract、合理化藉口對照表） | `Agent_OS_Skill/SKILL.md` |
| [Loop_Engineering_Skill](Loop_Engineering_Skill/) | **多重迴圈工程規劃**：把「會重複發生的工作」設計成會自己跑的迴圈艦隊，含 12 個迴圈模式、STATE 持久記憶、maker/checker 驗證、人類閘門、預算斷路器、L1→L2→L3 自治階梯 | `Loop_Engineering_Skill/SKILL.md` |
| [Record_System_Skill](Record_System_Skill/) | **開發治理與交接系統**：`AGENTS.md` 唯一入口＋`docs/` 外接記憶（對話紀錄、交接、任務、批准制），讓 AI 開發可連續、可追溯、換 agent 不失憶、省 token | `Record_System_Skill/README.md` |

## 分開怎麼用（各自獨立可用）

**只用 Agent_OS_Skill**，想讓模型「像 agent 一樣做一次性任務」：
1. 複製 `Agent_OS_Skill/SKILL.md` 裡的「★ 主控 System Prompt」整段貼上當 system prompt，直接丟任務。
2. 本地小模型：先無條件貼 `reference/01_執行紀律塊.md`（最高槓桿）；context 很小就只跑 4 角色精簡路徑。
3. 也可只取單一角色：`roles/01`–`12` 每檔的「★ 反向 System Prompt」都可獨立貼上（已內嵌判斷力補充）。

**只用 Loop_Engineering_Skill**，想把重複性工作自動化成受控迴圈：
1. 複製 `Loop_Engineering_Skill/SKILL.md` 的「★ 主控 System Prompt」貼上，描述你的工程，它會產出「迴圈工程規劃書」（主控 prompt 已內嵌 12 角色簡述，不裝 Agent_OS 也能跑）。
2. 規劃出的 `LOOP-NNN.md`／`STATE-NNN.md`／`LOOP_PORTFOLIO.md` 放進專案（無 docs/ 結構就放根目錄 `loops/`）。
3. 沒有排程器也能用：降級成「手動重啟清單」，每次喚醒 agent 讀 STATE 接著跑。鐵律：每支迴圈一律 L1 report-only 出生，升級須人類批准。

**只用 Record_System_Skill**，想讓專案可交接、AI 換了不失憶：
1. 跑 `建立開發環境.ps1` 一鍵產生 `docs/` 治理骨架（或參考 `示範開發環境/`）。
2. 給新 agent 的第一句話：「請先讀 `AGENTS.md` 與 `docs/`（HANDOFF、CONVERSATION_LOG、TASKS、CODE_INDEX），不要掃描整個程式碼庫。」
3. 詳見該資料夾的 `README.md`。

## 一起用（軟性互相偵測，缺件自動降級）

```
使用者任務
   │
   ▼
Agent_OS（引擎）─ ⓠ 情境攝取：偵測到「紀錄系統」結構 → 讀 docs/ 對話紀錄延續思考（不依賴 hook）
   │
   ├─ 一次性任務 → 12 角色接力 → 交付
   │
   └─ 掛 NEEDS_LOOP（會重複發生的工作）→ 載入 Loop_Engineering_Skill
            │
            ▼
      迴圈工程規劃書 → 治理三件套住進紀錄系統的 docs/loops/ → 人類批准（APPROVED）→ 上線
```

- 三包之間**只有軟性偵測**（prompt 指示 AI 主動去找、去讀），沒有硬相依：任一包單獨存在都完整可用，偵測不到夥伴就照各自的降級規則走。
- 連動細節：`Agent_OS_Skill/reference/04_專案紀錄延續.md`（讀紀錄系統）、`Agent_OS_Skill/reference/02_Router真值表.md` 的 `NEEDS_LOOP` 列（觸發迴圈工程）。

## 設計原則（三包共通）

- **軟性 prompt 驅動**：不安裝、不依賴任何 hook／排程器；能力缺席就誠實標「此處需人工補做」。
- **證據本位**：沒跑過不准說 done；預設 NEEDS WORK；數字勝過形容詞。
- **人類在迴圈**：高風險必過人類閘門；自動化一律從「只報告」出生，升級要批准。
- **文件是記憶**：狀態住檔案不住對話，換模型、換工具、換 session 都接得上。

## License

MIT — 見 [LICENSE](LICENSE)。
