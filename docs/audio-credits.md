# 音樂與音效授權清單

> 本文件是所有音檔的授權來源紀錄。每加入一個音檔，都要先在這裡登記，再把路徑寫進 `assets/data/audio/bgm.json`。
> 遊戲內的製作人員與授權頁，應從本文件的「已採用」清單產生。

## 一、登記規則

每個音檔必須填寫以下欄位，缺任何一欄都不能合併進主線：

| 欄位 | 說明 |
|---|---|
| 專案內路徑 | `res://assets/audio/...`，與 `bgm.json` 的值完全相同 |
| 代號 | `bgm.json` 中的 key，例如 `explore`、`battle` |
| 曲名 | 原始曲名 |
| 作者 | 作者或帳號名稱，與來源頁面相同 |
| 來源網址 | 下載頁的完整網址 |
| 授權類型 | CC0、CC-BY 4.0、Pixabay License 等 |
| 授權頁網址 | 授權條款的完整網址 |
| 是否需署名 | 是／否 |
| 署名文字 | 需署名時，照來源頁面建議的格式填寫 |
| 查核日期 | 確認授權的日期（YYYY-MM-DD） |
| 查核人 | 負責確認的人 |

**不採用的條件**（任何一項成立即不採用）：

- 授權頁面找不到明確的授權類型。
- 頁面要求用戶通知作者，或附有「All Rights Reserved」以外的限制而沒有書面同意。
- 授權只允許個人使用，或禁止商業用途。
- 來源是以「付費版」與「免費版」並存，而免費版的授權條款沒有明確寫出。

## 二、網頁版的特別注意

網頁版會把音檔放進可下載的 `.pck` 封裝中。以下兩類授權要特別確認：

- **Pixabay License**：官方說明可用於遊戲，但不能再散布或轉售原始音檔。網頁版的 `.pck` 屬於遊戲的一部分，需要確認是否構成散布。若無法確定，請改用 CC0 或 CC-BY 曲目。
- **CC-BY**：需要在遊戲內顯示署名。網頁版與桌面版都要有同一份製作人員頁。

## 三、已採用的音檔

目前沒有採用任何音檔。`assets/data/audio/bgm.json` 的所有代號都是空字串。

| 代號 | 專案內路徑 | 曲名 | 作者 | 授權類型 | 需署名 | 查核日期 |
|---|---|---|---|---|---|---|
| prologue | — | — | — | — | — | — |
| explore | — | — | — | — | — | — |
| night | — | — | — | — | — | — |
| battle | — | — | — | — | — | — |
| heart | — | — | — | — | — | — |
| ending_a | — | — | — | — | — | — |
| ending_b | — | — | — | — | — | — |
| ending_c | — | — | — | — | — | — |

## 四、候選來源（尚未下載、尚未試聽）

以下資訊來自公開頁面的搜尋摘要，**尚未逐一開啟授權頁面確認**。採用前必須逐項核對。

| 來源 | 授權（摘要所述） | 需署名 | 備註 | 網址 |
|---|---|---|---|---|
| Pixabay Music | Pixabay License | 否 | 官方 FAQ 說明可用於遊戲；網頁版散布需再確認 | https://pixabay.com/service/faq/ |
| OpenGameArt「Dark Forest Theme」（cynicmusic） | CC0 | 否 | 頁面請求聯絡作者 | https://opengameart.org/content/dark-forest-theme |
| FarBeyond Studio「Heart of Sin」 | CC-BY 4.0 | 是 | 黑暗史詩感，適合墜星之心或結局 | https://farbeyond-studio.itch.io/heart-of-sin |
| OpenGameArt「Lonely Witch」 | CC-BY 4.0 | 是 | 管弦樂，偏奇幻 | https://opengameart.org/content/lonely-witch-horrorpen-of-far-different-nature |
| OpenGameArt「Modern Castle」 | CC-BY 4.0 | 是 | 氛圍詭異，適合夜間 | https://opengameart.org/content/modern-castle-bogart-vgm-sygil-isaiah658 |
| OpenGameArt「Dark Ambience Loop」 | CC-BY 3.0 或 GPL（需選 CC-BY） | 是 | 同時列有 GPL，採用時只選 CC-BY | https://opengameart.org/content/dark-ambience-loop |

## 五、明確不採用

| 來源 | 原因 | 網址 |
|---|---|---|
| R3sound 黑暗奇幻包 | 要求以電子郵件或私訊通知作者，並標示 All Rights Reserved | https://r3sound-japan.itch.io/instant-game-music-for-dark-fantasy-action |
| alkakrab「6 Dark Fantasy Boss Battle Tracks」 | 寫「商業免費」但未標明標準授權，需先向作者確認 | https://alkakrab.itch.io/6-dark-fantasy-boss-battle-tracks |

## 六、製作人員頁的產生規則

- 只列出「已採用」清單中的音檔，不列候選來源。
- 每筆包含：曲名、作者、授權類型、授權頁網址、署名文字（需署名者）。
- 每次新增或移除音檔，都要同步更新這個頁面與遊戲內的製作人員頁。
- 授權頁的截圖或存檔保存在 `production/qa/evidence/audio/`，以備日後查核。
