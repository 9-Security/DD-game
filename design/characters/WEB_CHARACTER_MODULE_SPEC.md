# 網頁角色模組規格（Web Character Module Spec）

> 版本：v1.0　日期：2026-10-23
> 對應：`design/GAME_DESIGN_MASTER.md` 第 9.3 節，以及 `design/characters/CHARACTER_BIBLE.md`。
> 引擎：Godot 4.7.2（GDScript），Compatibility 渲染器，網頁匯出。
> 標記：【已實作】已有程式與測試；【規格】已定義但尚未實作；【建議】待確認。

---

## 1. 目的

把每個角色定義成獨立的資料單元，讓數值、技能與視覺資源可以分開維護，並能在網頁版中載入。角色資料不寫死在程式碼中（見 `src/CLAUDE.md`：遊戲數值必須資料驅動）。

## 2. 檔案位置與命名

| 類型 | 路徑 | 命名規則 |
|---|---|---|
| 角色定義 | `assets/data/characters/<id>.json` | `id` 使用小寫英文，與檔名相同，例如 `freya.json` |
| 技能定義 | `assets/data/skills/<skill_id>.json`【規格】 | 技能 ID 使用 snake_case，例如 `blood_rage` |
| 立繪 | `assets/art/portraits/<id>.png`【規格】 | 寫實風格，尺寸見第 6 節 |
| 精靈圖 | `assets/art/sprites/<id>_sheet.png`【規格】 | 見第 6 節 |

## 3. 角色定義格式【已實作】

每個角色檔案是一個 JSON 物件，必要欄位如下：

```json
{
  "id": "freya",
  "identity": {
    "name": "芙蕾雅・雷恩",
    "role": "frontline",
    "background_ref": "design/narrative/STORY_MANUSCRIPT.md"
  },
  "stats": { "hp": 130, "mp": 20, "atk": 16, "def": 10, "spd": 6 },
  "skills": ["greatsword_slash", "blood_rage", "iron_guard", "ancestral_shield"],
  "fixed_equipment": ["greatsword_father_bone"]
}
```

### 3.1 欄位說明

| 欄位 | 型別 | 必填 | 說明 |
|---|---|---|---|
| `id` | string | 是 | 唯一識別碼，與檔名相同 |
| `identity.name` | string | 是 | 顯示名稱 |
| `identity.role` | string | 否 | 定位：`support` / `frontline` / `trap_explorer` / `summoner` |
| `identity.background_ref` | string | 否 | 背景文件路徑，不由程式讀取 |
| `stats.hp` | number | 是 | 必須大於 0 |
| `stats.mp` / `atk` / `def` / `spd` | number | 否 | 基礎數值 |
| `skills` | array of string | 是 | 至少一個技能 ID |
| `fixed_equipment` | array of string | 否 | 不可更換的裝備，例如芙蕾雅的「亡父之骨」 |

### 3.2 驗證規則【已實作】

`src/characters/character_data.gd` 的 `CharacterData.validate()` 負責驗證：

- 必要欄位存在：`id`、`identity`、`stats`、`skills`。
- `stats.hp` 必須是大於 0 的數字。
- `skills` 必須是非空陣列。

驗證是純函式，不讀取檔案，可以直接單元測試（見 `tests/unit/characters/character_data_validation_test.gd`）。

> **決定**：設計文件 9.3 原本提到 JSON Schema。目前採用 GDScript 驗證，理由是 Godot 內建執行環境就能執行，不需要額外的 JSON Schema 工具鏈。若之後需要外部工具驗證，再補上 Schema 檔案。

## 4. 載入流程

1. 讀取 `assets/data/characters/` 中的檔案。
2. 以 `JSON.parse_string()` 解析。注意：Godot 會把所有 JSON 數字解析為 `float`，比較時需要轉型（見 `tests/integration/characters/character_data_files_test.gd`）。
3. 以 `CharacterData.validate()` 驗證，錯誤會記錄到 `push_error`，並略過該角色。【已實作】
4. 通過驗證的角色進入隊伍。

### 4.1 整合測試【已實作】

`tests/integration/characters/character_data_files_test.gd` 檢查：
- 四名角色檔案都存在、可解析、通過驗證。
- 數值與設計文件 3.1 的表格一致。

## 5. 動畫狀態【規格】

每個角色必須定義以下狀態，即使第一版只有靜態圖也要保留名稱：

| 狀態 | 用途 |
|---|---|
| `idle` | 待機 |
| `attack` | 普通攻擊 |
| `skill` | 施放技能 |
| `hurt` | 受到傷害 |
| `defeat` | 戰敗 |

狀態由角色資料的 `animation_states` 欄位宣告，目前尚未加入 JSON（第一版不實作動畫）。

## 6. 美術資源規格【建議】

以下尺寸是建議值，尚未經過實機測試：

| 資源 | 建議尺寸 | 格式 | 備註 |
|---|---|---|---|
| 立繪（對話用） | 1024 × 1536 px | PNG（透明背景） | 寫實風格，用於對話框 |
| 戰鬥精靈圖 | 每幀 256 × 256 px | PNG 精靈表 | 每個狀態一行 |
| 頭像（UI） | 128 × 128 px | PNG | 隊伍列表使用 |

檔案大小目標：單一角色所有圖片合計 4 MB 以內，以控制網頁載入時間（見設計文件風險表）。

## 7. 固定外觀一致性【建議】

寫實風格立繪需要能穩定重現。建議流程：

1. 為每個角色建立一份「提示詞模板」，放在 `design/characters/prompts/<id>.md`。
2. 模板包含：年齡、髮色、服裝、武器、表情、畫風，以及固定的負面提示詞。
3. 每次產圖都使用同一組種子值與參考圖。
4. 產出的圖片放入 `assets/art/portraits/`，並記錄使用的提示詞版本。

> 注意：AI 生成的圖片需要人工檢查。角色外觀細節（見 CHARACTER_BIBLE.md 第 5 節）目前尚未定稿，產圖前必須先確定。

## 8. 版本與相容性

- 角色檔案必須包含 `schema_version` 欄位，初始值為 `1`【規格】。
- 結構變更時必須升版，並提供舊版資料的遷移說明。
- 數值調整不需升版，但需在 `design/GAME_DESIGN_MASTER.md` 版本紀錄中註明。

## 9. 待確認事項

| 編號 | 問題 | 影響 |
|---|---|---|
| 1 | 是否要把 `background_ref` 改為由程式讀取的正式欄位 | 角色文件與程式的連結方式 |
| 2 | 技能資料是否獨立成 `assets/data/skills/` | 技能數量增加後的維護方式 |
| 3 | 立繪尺寸是否採用第 6 節的建議值 | 美術製作與網頁載入時間 |

---

## 10. 版本紀錄

| 版本 | 日期 | 說明 |
|---|---|---|
| v1.0 | 2026-10-23 | 定義角色模組格式、驗證規則與載入流程；標示已實作與待實作項目 |
