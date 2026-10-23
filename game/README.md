# 《七日之藥，深淵之願》— 遊戲原始碼

> 狀態：尚未建立 M1 骨架。設計依據見 `design/GAME_DESIGN_MASTER.md`。

## 技術棧

| 項目 | 選擇 |
|---|---|
| 引擎 | Phaser 3 |
| 語言 | TypeScript |
| 建置 | Vite |
| 測試 | Vitest |

## 目錄

```text
src/
  core/          時間系統、回合控制、存檔
  battle/        戰鬥邏輯（與畫面分離）
  exploration/   地圖與互動
  narrative/     對話與日終事件
  characters/    角色資料載入與驗證
  scenes/        Phaser 場景（只負責畫面）
data/            JSON 資料（角色、技能、敵人、關卡）
schemas/         JSON Schema 驗證規則
assets/
tests/
```

## 原則

- 戰鬥與時間邏輯不依賴 Phaser，可獨立測試。
- 數值放在 `data/`，調整數值不需修改程式碼。
- 原始故事稿以 `design/` 內的文件為準。
