# 第五章事件實作紀錄（血誓熔窟）

> 依據：`design/narrative/STORY_MANUSCRIPT.md` 第五日（原稿，優先）、`design/narrative/novel/chapter05_blood_oath_cavern.md`（小說）、`design/characters/source/CHAPTER5_SETTINGS_v1.0.md`（設定集）。
> 事件資料：`assets/data/events/chapter5.json`；規則：`assets/data/rules/balance.json` 的 `sequences`、`location_actions`。

## 已實作

| 步驟 | 行動 | 條件 | 結果 |
|---|---|---|---|
| 抵達 | `go:血誓熔窟` | 第五日，失聲之庭已解縛 | 熔窟與徽章；營地密令（`decree_found`） |
| 石室紀錄 | `read:father_record` | 已找到密令 | 父親拒令、被處決、亡父之骨是刑具；守衛開始聚合（`father_record_read`） |
| 斷誓（依序） | `oath:lower` → `oath:cover` → `oath:barrier` → `oath:chain` → `oath:pierce` | 守衛已甦醒 | 放下劍、里克特牽制、艾洛恩結界、茵芮星光鎖鏈、芙蕾雅刺入刻印（`oath_seal_broken`）；守衛瓦解，取得骨片 |
| 斷誓的錯誤 | 跳步，或 `oath:strike`（揮劍） | 同上 | 序列重設、花費 1 個時段、芙蕾雅的血之詛咒加 1 層 |
| 斷誓的成功效果 | 最後一步成功 | — | 血之詛咒減弱 2 層（`curse_weaken`，不是歸零） |
| 石階 | `descend:stairs` | 斷誓完成 | 第五日：公主的聲音與「第五日，尚未結束」；第六日起：只有聲音（`princess_voice_heard`） |

## 與原稿的順序

- 原稿把密令與父親的紀錄都放在抵達時；小說把密令放在營地，父親的處決紀錄放在石室。目前依小說拆開：抵達與密令在第一步，石室紀錄在第二步。
- 「亡父之骨不是遺物，而是刑具。」這一句移到石室紀錄，與小說一致。

## 尚未實作

- 守衛的戰鬥數值（HP、傷害）。設定集沒有定值，目前用序列表示「依序的牽制」，不是戰鬥。
- 芙蕾雅的血咒在斷誓後的生理影響（設定集未定）。目前只有層數減少。
- 芙蕾雅回到第六日前的狀態（設定集列為後續）。

## 連續性檢查

- 芙蕾雅的血之詛咒沒有被治癒：`curse_weaken` 只減少層數，不會歸零（有測試）。
- 亡父之骨只裂開，沒有恢復，也沒有新的神力（設定集 6.1）。
- 守衛瓦解後不會復活；不會掉落父親的靈魂或新神劍。
- 公主的聲音只寫「請不要救我」，來源未確認（設定集 9.10）。
- 第五日的石階是第六日（墜星之心）的入口，沒有新增第五層以上的必經封印。
