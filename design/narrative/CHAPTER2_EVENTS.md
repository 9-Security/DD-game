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

- 鏡像反擊：芙蕾雅攻擊鏡面時的反擊與血咒激化（設定集 3.4、5.1）。
- 鏡影精靈的身影與退場演出。
- 門後通道（第三日入口）。

## 三、設定衝突（待確認）

1. **鏡影精靈的定位（C5）**：第二章設定集明確寫「不是茵芮的召喚獸，通關後也不成為茵芮可取得的永久召喚獸」。這與 `CHARACTER_BIBLE.md` 第 7 節的 C5 決定「並存」衝突。本實作不以召喚獸方式呈現鏡影精靈。
2. **第二日剩餘天數**：小說寫「還剩六天」，設定集寫「約五日」。依設定集的優先序（小說高於設定集），採用小說的說法。
