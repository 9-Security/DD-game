# 第六章事件實作紀錄（墜星之心）

> 依據：`design/narrative/novel/chapter06_heart_of_the_fallen_star.md`（小說）與 `design/characters/source/CHAPTER6_SETTINGS_v1.0.md`（設定集）；第六日原稿為 `design/narrative/STORY_MANUSCRIPT.md`。
> 事件：`assets/data/events/chapter6.json`；序列與規則：`assets/data/rules/balance.json`。

## 已實作

| 步驟 | 行動 | 條件 | 結果 |
|---|---|---|---|
| 抵達 | `go:墜星之心` | 第六日，石階已揭露 | 虛空、墜星之心、七葉神喻草 |
| 浮空斷階 | `cross:test` → `cross:go` | 依序 | 試探浮石後依序跨過；跳步退回原處，花 1 個時段 |
| 群靈 | `inry:stop_force` → `inry:listen` | 斷階已跨過 | 停止強制封閉，逐一聆聽名字；強制封閉（`inry:seal_force`）使混亂加劇，花 1 個時段 |
| 王室真相 | `read:oath_truth` | 群靈已平息 | 王室誓約、代價轉嫁、碎魂熱的揭露（`royal_oath_truth_confirmed`） |
| 採集 | `harvest:assess` → `harvest:whole` | 真相已揭露 | 檢查根鬚後整株取出，七葉完整；摘下一片葉子（`harvest:pluck`）使星核裂開，花 1 個時段 |
| 返程 | `depart:return` | 神喻草已取得 | 「我們只剩第七日了。」（`returned_from_star_heart`） |

## 限制（依設定集與原稿）

- **不新增 Boss**：群靈與星核不是戰鬥目標，本章沒有戰鬥行動。
- **神喻草只能完整取得**：摘葉會裂開星核，因此只有 `harvest:whole` 能完成採集。
- **不解除誓約、不治癒公主、不選定結局**：A、B、C 的選擇留給第七日。
- **瑟維恩的殘影**：小說中的殘影只呈現這段記憶，本章沒有實作殘影的互動，也不確認其生死。

## 尚未實作

- 第七日的回宮與公主的選擇（原稿第七日）。
- 荒潮與護界的具體表現（設定集未定）。
- 瑟維恩殘影的演出與畫面。

## 待確認

- **拼法衝突**：第六章設定集第 4.2 節寫「Servien Lord，沿用第二章設定集正式拼法」，但第二章設定集的正式拼法是 **Servien Lorde**（見 `CHARACTER_BIBLE.md`）。目前遊戲與文件統一用 **Servien Lorde**，待確認後再調整。
