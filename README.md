# Ryzen AI MAX+ 395 Test Lab

這是一個以實測證據記錄 AMD Ryzen AI MAX+ 395／Radeon 8060S
（`gfx1151`、Strix Halo）AI 工作負載的社群專案。定位介於玩家工作站與
小型企業 AI 節點：不只記錄「能不能安裝」，也記錄版本、效能、品質、資源、
失敗案例與可重現條件。

目前第一個完整案例是 Ubuntu 26.04 + ROCm 7.14 上的 MinerU 3.4.4，包含
ROCm Transformers、實驗性 AOTriton 與自行編譯的 vLLM 0.21。後續可沿用
相同格式加入 PyTorch、llama.cpp、其他 LLM／VLM serving、embedding、
reranking 與批次 AI 工作。

> 本專案是單機社群實測，不代表 AMD、MinerU、vLLM 或 OpenDataLab 的官方
> 支援聲明。尚未完成的公開 benchmark 不應解讀為通用品質排名；已完成的
> 分數仍只代表本頁所列硬體、版本與執行設定。

## 已驗證平台

| 項目 | 實測值 |
|---|---|
| APU | AMD Ryzen AI MAX+ 395 |
| GPU | AMD Radeon 8060S Graphics |
| GPU architecture | `gfx1151` |
| 記憶體 | 統一記憶體；PyTorch 回報 114,688 MiB GPU 可見容量 |
| OS | Ubuntu 26.04 |
| Kernel | Linux 7.0.0-29-generic |
| ROCm／HIP | 7.14／7.14.60850 |

完整、分 workload 的狀態見 [硬體與軟體矩陣](docs/hardware-matrix.md)。

## MinerU 目前結果

固定 MinerU 3.4.4 與 MinerU2.5-Pro 模型 revision 後：

| 路徑 | 資料 | Wall time | 結果 |
|---|---:|---:|---|
| ROCm Transformers | 4 頁 | 160.36 秒 | 4/4 完成；品質回退基準 |
| Transformers + AOTriton | 1 頁 | 21.18 秒 | 對未加速 Transformers 輸出完全一致；仍屬實驗性 |
| vLLM 0.21 | 4 頁 | 39.90 秒 | 同機同資料較 Transformers 快 4.02 倍 |
| vLLM 0.21 | 私有 domain corpus，30 份／256 頁 | 1,049.80 秒 | 30/30、256/256、零 swap、零缺圖引用 |

另以同一 AI 395 的兩份文件／8 頁做單 worker 對照：Transformers 完成兩份
約 258.0 秒，vLLM 的相同兩份 warm wall time 合計 53.19 秒，約 4.85 倍。
這次單 worker 測試後續被一件未定因的主機重新開機事件中斷；該事件獨立
追蹤，不歸入 MinerU／ROCm 相容性或衝突判定。

256 頁結果是穩定性與 domain regression，不是準確率 benchmark。相對另一個
Apple Silicon backend 的參考輸出，頁數完全一致，但區塊為 5,372 對 5,373、
文字相似度 95.75%、Markdown 相似度 94.48%；因此 vLLM 目前仍標示為
「已驗證的選用加速路徑」，不宣稱與 Transformers／MLX 等價。

標準準確率測試將使用 OmniDocBench 與 olmOCR-Bench；方法見
[benchmark 方法](docs/benchmark-methodology.md)。
OmniDocBench 的固定版本、斷線續跑與雙 scorer 設計見
[雙軌評測說明](docs/omnidocbench-dual-track.md)。

### OmniDocBench 完整結果（已完成）

2026-08-08～09（Asia/Taipei）在同一個 AI MAX+ 395 上，以 vLLM 0.21.0
服務 `mineru-vlm-1.2b` 完成完整 1,651 頁 prediction；1,651/1,651 成功、
0 失敗，推論 wall time 為 15,843.4895 秒。v1.6 compatibility scorer 與
v1.7 current scorer 都完成，結果如下：

| track | text edit distance ↓ | formula CDM ↑ | table TEDS ↑ | reading-order edit distance ↓ | Overall ↑ |
|---|---:|---:|---:|---:|---:|
| v1.6 compatibility | 0.0348329083 | 96.7656% | 93.5003% | 0.1231489910 | 95.5942 |
| v1.7 current | 0.0348329083 | 96.7656% | 93.5003% | 0.1231489910 | 95.5942 |

這是官方 scorer 下的本機實測摘要，不是對其他模型或平台的排名；兩軌
使用同一份 1,651 頁 prediction，並以獨立 scorer revision 留存 provenance。
完整指標、資源觀察、固定 revision 與 prediction manifest checksum 見
[OmniDocBench 結果](results/mineru-3.4.4/omnidocbench/README.md) 與
[公開 manifest](results/mineru-3.4.4/omnidocbench/manifest.yaml)。

## 專案原則

- 每個結論都綁定硬體、OS、kernel、ROCm、Python、模型、backend 與 commit。
- cold start、warm throughput、品質與資源分開報告。
- 成功和失敗版本都保留；失敗不能從相容矩陣中消失。
- 私有 corpus 只公開匿名統計與 checksum，不公開原始文件或私人路徑。
- 公開 benchmark 使用官方 evaluator，不以自製字串相似度代替正式分數。
- 預設服務只監聽 localhost；公開網路部署需另做威脅模型與存取控制。
- 不把未留下 kernel 證據的主機重啟直接歸因 ROCm、模型或硬體；保留時間線與
  重現條件，待獨立重跑與硬體監控後再定因。

## 目錄

```text
docs/                         方法、硬體矩陣與相關工作
incidents/                    與 workload 判定分離的系統事件
results/                      不含私人輸入的結果摘要
scripts/omnidocbench/         可斷線續跑的雙軌評測腳本
reproducibility.lock.yaml     已固定的版本與模型 revision
SECURITY.md                   公開前的資料與祕密規則
```

新增工作負載時使用 [實驗紀錄範本](docs/experiment-template.md)，確保每一個
成功或失敗配置都能用相同欄位比較。

## 相關社群工作

- [AIwork4me/MinerU-ROCm](https://github.com/AIwork4me/MinerU-ROCm)：提供
  OmniDocBench 評估與 Linux W7900／gfx1100 ROCm 路徑。依其提交的硬體
  metadata，另有 Windows-HIP Ryzen AI MAX+ 395／Radeon 8060S（Strix Halo）
  bundle；本專案未獨立驗證該 SKU。本專案聚焦其尚未覆蓋的 Linux gfx1151 +
  Ubuntu 26.04 + ROCm 7.14 組合，兩者互補。
- [buptanswer/mineru](https://github.com/buptanswer/mineru)：提供消費級 AMD
  顯卡自行編譯 vLLM 與 MinerU 適配的實作經驗。
- [opendatalab/MinerU](https://github.com/opendatalab/MinerU)：上游專案。

更完整的比較見 [相關工作](docs/related-work.md)。

## 發布狀態

本 repository 採 Apache-2.0 授權。MinerU 3.4.4 的既有結果已完成匿名化與
發布前檢查；OmniDocBench v1.6 compatibility track 與 v1.7 current track
已完成並以新結果摘要公開。prediction 原始檔不放入 repository，只公開
可重建所需的固定 revision、aggregate 分數與 manifest SHA-256；olmOCR-Bench
仍待後續規劃。
