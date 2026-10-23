# 第七章與結局實作紀錄

> 依據：`novel/chapter07_deep_abyss_wish.md`、`novel/chapter07_ending_a/b/c_*.md`、`characters/source/CHAPTER7_SETTINGS_v1.0.md`、`narrative/ENDING_TRIGGER_DESIGN_v1.0.md`。對照見 `CHAPTER7_PLAN.md`。

## 已實作（依使用者確認的建議）

- **時段**：第五日的石階推進到第六日開始（`advance_day` 效果），第六日不再需要純移動。
- **返程**：兩條路線，都在墜星之心執行。
  - `return:safe`：花 3 段，準時抵達王宮。
  - `return:shortcut`：花 2 段，有 50% 機率崩落；崩落會再花 6 段，超過時限，成為結局 C。
- **共同主線**（王宮藥室，依序）：攤出死亡名冊 → 出示封村密令與處決紀錄 → 向黎安娜說明代價 → 黎安娜作出決定。
- **結局 A**：需要共同主線完成，且國王明示自願（`final:king_volunteers`），再進行儀式（`final:ritual_a`）。國王的姓名在遊戲中不顯示，只寫「國王的姓名」。
- **結局 B**：需要共同主線完成，且前章成果齊備：`chapter3_sealed`、`oath_seal_broken`、`spirits_listened`、`translucent_seed_received`。
- **結局 C**：由兩種情況觸發，皆不進入共同主線。
  - 捷徑崩落且超過時限（`ch7_return_shortcut_late`）。
  - 時限到期時尚未達成結局 A 或 B（`DayOneFlow.ending_id()` 的後備判定）。依原稿附錄「時限逾期：任務失敗或自動轉入結局 C」。
- **互斥**：A 與 B 互相排除；結局確定後，所有行動都停止，只剩結局面板（可從存檔重來或重新開始）。

## 數值與時限

- 時限為 21 段，第七夜結束時到期。抵達的時段必須小於 21。
- 第六章結束時為第 16 段（含抵達墜星之心），安全路線抵達第 19 段，捷徑準時抵達第 18 段。

## 尚未實作

- 結局 A、B、C 的完整小說文字目前以關鍵段落的事件呈現，完整版本仍可在 `novel/` 查閱。
- 瑟維恩的殘影與荒潮的表現（設定集未確定）。
- 時限提示的 UI：目前只在捷徑的按鈕文字中警告。

## 已決定（依設計原稿為主）

- **英文名字**：芙蕾雅・雷恩 **Freya Raine**、里克特・安布羅斯 **Richter Ambrose**，與原稿一致。設定集中的 Freya Rayne、Lict Ambros 不採用，設定集原文保留不改（見 `characters/CHARACTER_BIBLE.md` 決議 C1、C2）。
- **瑟維恩的拼法**：**Servien Lorde**。原稿未寫出此名（只稱「導師」），第二章設定集為正式拼法；第六章設定集的 Servien Lord 為筆誤。
- **時限逾期**：轉入結局 C，依原稿附錄。
