# 第二章事件（第二日・黑曜石之門）

> 來源：`design/narrative/novel/chapter02_day02.md`，`design/characters/source/CHAPTER2_SETTINGS_v1.0.md`。
> 實作：`assets/data/events/chapter2.json`。

## 一、已實作的事件

| 事件 ID | 觸發 | 效果 | 來源段落 |
|---|---|---|---|
| `ch2_gate_reveal` | 前往黑曜石之門 | 峽谷無回聲的描述 | 一、沒有回聲的峽谷 |
| `ch2_confess_eron` | 承認：艾洛恩的枯林 | 設旗標 `mirror_eron_acknowledged` | 二、第一面鏡 |
| `ch2_confess_freya` | 承認：芙蕾雅的封村 | 設旗標 `mirror_freya_acknowledged` | 四、第二面鏡 |
| `ch2_confess_richter` | 承認：里克特的兄長 | 設旗標 `mirror_richter_acknowledged` | 四、第三面鏡 |
| `ch2_confess_inry` | 承認：茵芮的失控 | 設旗標 `mirror_inry_acknowledged` | 四、第四面鏡 |
| `ch2_gate_open` | 四人皆承認 | 設旗標 `obsidian_gate_open` | 五、第一份代價 |

承認不花時間，且只能在黑曜石之門進行。順序不限。

## 二、尚未實作

- 鏡影精靈的身影與退場演出。

## 二之二、已實作：鏡像反擊

- 行動 `strike:mirror`，只能在黑曜石之門、只有芙蕾雅能攻擊，花 1 個時段，門開後不可用。
- 效果：芙蕾雅受傷（數值在 `balance.json` 的 `mirror_counter`，目前 8），血之詛咒激化（目前 +2 層）。
- 不設擊殺分支，不影響承認流程。
- 門後通道（`go:門後通道`）：門未開啟時無法通行，不花時間也不觸發事件；抵達時觸發 `ch2_passage_arrival`，設定旗標 `passage_entered`。門的需求由 `balance.json` 的 `location_requirements` 指定。
- 注意：原型目前只到第一日，抵達文字不寫日數。第三日的內容（咒牆迷廊起）尚未實作。

## 三、設定衝突（待確認）

1. **鏡影精靈的定位（C5）**：已決，採用封印守衛定位，不是召喚物。見 `design/characters/MIRROR_SPIRIT.md`。
2. **第二日剩餘天數**：小說寫「還剩六天」，設定集寫「約五日」。依設定集的優先序（小說高於設定集），採用小說的說法。
