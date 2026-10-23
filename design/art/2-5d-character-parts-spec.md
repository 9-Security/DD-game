# 2.5D 人物部件規格與提示詞範本

狀態：規格已由使用者確認（2026-10-23）。提示詞範本為草案，供外部 AI 生成工具使用。

## 一、目標

以分層 2D 部件呈現人物，搭配景深與輕微動態，取代目前單張靜態立繪。部件需能獨立疊放、獨立移動，並可在網頁版順暢執行。

## 二、畫布與格式

| 項目 | 規定 |
|---|---|
| 畫布尺寸 | 640 × 960 像素，與現有立繪相同 |
| 格式 | PNG，RGBA，透明背景 |
| 位置 | 所有部件使用同一畫布，不做位置偏移；位置由畫面中的疊放順序決定 |
| 色彩 | sRGB，不含額外的色彩描述檔 |
| 檔案大小 | 每個部件建議小於 1 MB |

## 三、部件清單（四位主角）

每位角色的部件命名為 `[角色代號]_[部件].png`，例如 `freya_head.png`。

| 部件代號 | 內容 | 必要 |
|---|---|---|
| `head` | 臉部與頸部 | 是 |
| `hair_back` | 人物後方的頭髮 | 是 |
| `hair_front` | 遮住額頭或臉側的頭髮 | 是 |
| `body` | 軀幹與衣服 | 是 |
| `cloak_back` | 後方的披風或布料 | 否（有則需要） |
| `arm_front` | 前臂與手 | 是 |
| `prop` | 手持物件（芙蕾雅的巨劍、艾洛恩的權杖、茵芮的召喚書、里克特的匕首） | 否（依角色） |

**軸心點**：每個部件需在檔案名稱之外另附一份 JSON 記錄軸心座標（例如 `freya_head.json`，內容為 `{"pivot": [x, y]}`），軸心點統一在頸部或肩部。

## 四、風格一致性

- **參考圖**：使用現有的 `assets/art/portraits/` 立繪作為風格參考，每次生成都附上同一人物的參考圖。
- **同一人物**：所有部件使用相同的參數、參考圖與生成工具版本。
- **光源**：統一為左上方光源，陰影方向一致。
- **色調**：沿用對應人物的既有配色，不另外創造新色。

## 五、提示詞範本（草案）

以下範本以英文撰寫，因多數生成工具對英文提示的理解較穩定；人物名稱與設定以英文描述，文字不寫入圖中。

**通用前綴**（每次生成都加上）：

> dark fantasy character illustration, single character, transparent background, consistent style with the reference image, soft top-left lighting, no text, no watermark

**部件範本**：

- 頭部：`[角色外貌描述], head and neck only, facing [朝向], neutral expression, isolated on transparent background`
- 後髮：`[角色髮型描述], back hair only, behind the head, no face, isolated on transparent background`
- 前髮：`[角色髮型描述], front hair only, covering forehead and temples, isolated on transparent background`
- 身體：`[角色服裝描述], torso and clothing only, no head, no arms, isolated on transparent background`
- 披風：`[披風描述], back cloak only, behind the body, isolated on transparent background`
- 前臂：`[手臂與袖口描述], forearm and hand only, [持物或空手], isolated on transparent background`
- 持物：`[物件描述], single object only, isolated on transparent background`

**負面提示詞**（若工具支援）：

> multiple characters, cropped at wrong place, extra limbs, text, watermark, background scene, blur, frame border

**角色描述草案**（需要你確認或修改）：

- 艾洛恩・維斯塔：牧靈使，綠色斗篷與白色內衣，手持木質權杖。
- 芙蕾雅・雷恩：近衛隊長，鎧甲與披風，左腕有血色咒痕（生成時可省略，之後以程式疊加）。
- 里克特・安布羅斯：學者型，外套與符文金屬片，腰側有匕首。
- 茵芮・朵維亞：召喚師，長袍，手持召喚書。

## 六、驗收清單

每個部件在進入專案前需通過以下檢查：

- [ ] 尺寸為 640 × 960，透明背景。
- [ ] 只包含指定的部件，沒有其他人物或背景。
- [ ] 與參考圖的人物特徵一致（臉型、髮色、服裝配色）。
- [ ] 邊緣乾淨，沒有殘留的背景色或光暈。
- [ ] 光源方向與其他部件一致。
- [ ] 軸心 JSON 已附上。
- [ ] 授權紀錄已填寫（見第七節）。

## 七、生成紀錄與授權

每次生成都需記錄在 `design/art/generation-log.md`（若檔案不存在則新建），格式如下：

| 日期 | 角色 | 部件 | 工具與版本 | 提示詞 | 參考圖 | 授權條款確認 | 採用與否 |
|---|---|---|---|---|---|---|---|

- 提交前請確認所用工具的條款允許商業用途。
- 若工具要求標示 AI 生成，需依其規定處理。

## 八、後續流程

1. 你依第五節的範本生成部件，並填寫生成紀錄。
2. 上傳素材，我會依第六節檢查尺寸、透明度與命名，並整理進專案（`assets/art/characters/parts/`）。
3. 撰寫一個小工具自動驗證尺寸與命名。
4. 以芙蕾雅一人做分層原型，在第三章的名冊廊廳場景中測試效果。
