# 第四章事件實作紀錄（失聲之庭）

> 依據：`design/narrative/novel/chapter04_garden_of_silence.md`（小說，優先）與 `design/characters/source/CHAPTER4_SETTINGS_v1.0.md`（設定集）。
> 事件資料：`assets/data/events/chapter4.json`；規則：`assets/data/rules/balance.json` 的 `sequences`、`location_requirements`、`location_actions`。

## 已實作

- **進入條件**：第四日起，且已走出咒牆迷廊（`chapter3_exit`）。
- **解縛序列**（`release` sequence，依序）：
  1. `commune:tree`：艾洛恩向古樹獻出一段記憶，古樹回應「你可以令我們安靜，也可以令我們自由」。
  2. `release:stabilize`：茵芮召來光靈穩住艾洛恩。
  3. `release:chain_one`、`release:chain_two`：里克特與芙蕾雅斬斷兩道石鏈，巨獸不攻擊。
  4. `release:core`：艾洛恩承受晶核之痛，晶核碎裂，巨獸存活，透明種子交付。
- **跳步的失敗**：序列重設，花費 1 個時段，沒有詛咒代價。文字為「重新來過」。
- **解陣失敗的分歧（最小版本）**：第三章解陣失敗時，流程設定旗標 `seal_failed`。第四日進入失聲之庭時，開場依旗標分為兩個事件：`ch4_garden_arrival`（未失敗）與 `ch4_garden_arrival_after_failure`（失敗後，多一段里克特的反應）。兩者只差開場文字，事件順序與結果相同。
- **不殺巨獸**：庭園中沒有戰鬥行動，巨獸不會被擊殺。

## 尚未實作

- 巨獸的殘破靈魂個別去向（設定集明確未定）。
- 巨獸與古樹的演出與動畫（目前只有文字）。
- 艾洛恩承受痛苦的數值效果（設定集沒有 HP 定值）。
- 第五日（血誓熔窟）與之後的內容。

## 連續性檢查

- 巨獸存活，之後的章節不得追述為被殺死。
- 透明種子由艾洛恩持有，第七日需交至公主掌心。
- 芙蕾雅的血之詛咒仍在（失敗的代價只在第三章的解陣）。
- 「神喻草能編織靈魂，卻不能憑空創造靈魂」的原句已保留。
