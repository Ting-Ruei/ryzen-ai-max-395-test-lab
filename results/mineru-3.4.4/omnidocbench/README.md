# MinerU 3.4.4：OmniDocBench 完整評測

日期：2026-08-08～09（Asia/Taipei）  
證據分類：`verification`（官方 scorer）＋`operational evidence`（執行資源）

這是 AMD Ryzen AI MAX+ 395／Radeon 8060S（`gfx1151`）在 Ubuntu 26.04、
ROCm 7.14 上的單機社群實測。它不是 AMD、MinerU、vLLM 或 OpenDataLab 的
官方支援或排名聲明。

## 固定環境

| 項目 | 值 |
|---|---|
| APU／GPU | AMD Ryzen AI MAX+ 395／Radeon 8060S Graphics |
| GPU architecture | `gfx1151` |
| OS／kernel | Ubuntu 26.04／Linux 7.0.0-29-generic |
| ROCm／HIP | 7.14／7.14.60850 |
| MinerU | 3.4.4 |
| VLM model | `opendatalab/MinerU2.5-Pro-2605-1.2B`, revision `bff20d4ae2bf202df9f45284b4d43681555a97ed` |
| serving backend | vLLM 0.21.0, source commit `ad7125a431e176d4161099480a66f0169609a690` |
| served model | `mineru-vlm-1.2b`, `bfloat16`, max model length 8,192 |
| server policy | localhost only; GPU memory utilization `0.70`; one image per prompt |

## 完成結果

### Prediction

- Dataset：[OpenDataLab/OmniDocBench](https://huggingface.co/datasets/opendatalab/OmniDocBench)
  full，1,651 頁。
- Attempted／succeeded／failed：`1,651 / 1,651 / 0`。
- Inference wall time：`15,843.4895` 秒（約 4 小時 24 分）。
- 一份 prediction 先後交給 v1.6 compatibility 與 v1.7 current scorer；兩軌
  的程式 revision 與 provenance 仍分開保存。

### Official scorer metrics

| track | scorer commit | text edit distance ↓ | formula CDM ↑ | table TEDS ↑ | reading-order edit distance ↓ | Overall ↑ |
|---|---|---:|---:|---:|---:|---:|
| v1.6 compatibility | `2b161d010d2e3aff77a0edef359ea3a6411d23cd` | 0.0348329083 | 96.7656% | 93.5003% | 0.1231489910 | 95.5942 |
| v1.7 current | `193627ae9e97d89188468ed1ee3b7a856ff76044` | 0.0348329083 | 96.7656% | 93.5003% | 0.1231489910 | 95.5942 |

Raw values retained in the run record are:

```text
text_edit_distance             0.03483290832570235
formula_cdm                    0.9676559778973065
table_teds                     0.9350027538388601
reading_order_edit_distance    0.12314899083785329
overall                        95.59419411368214
```

「兩軌相同」只表示這次固定 dataset、prediction 與輸出 aggregate 的 metric
parity 通過；不能據此推論不同模型、不同 backend 或其他資料集會有相同結果。

## Reproducibility provenance

| 項目 | checksum／revision |
|---|---|
| Hugging Face dataset revision | `aa1ee96d106dbe53d0ae59474d75c6e6d9b53fec` |
| ground-truth SHA-256 | `a45cd84b04ad8b793e775089640e6b681209abea33ead54c1828ddca35fae496` |
| scorer image | `ghcr.io/zeng-weijun/omnidocbench-eval@sha256:6116ad72172e763b5c43e963d5efebf2093f2362b975f58156ce4f6c9142e617` |
| prediction manifest SHA-256 | `f729c68c70195667e805703c988e62af50c3480d4248ad6ef7878046571f2102` |

Prediction markdown、原始 PDF 與執行節點路徑沒有提交到 GitHub。repository
公開的是可核對的 aggregate、固定 revision 與 manifest checksum；若要做
獨立重現，請依 [雙軌評測說明](../../../docs/omnidocbench-dual-track.md)、
`scripts/omnidocbench/` 與 [可重現性 lock](../../../reproducibility.lock.yaml)
在自己的輸出目錄執行。

## 單 worker 資源觀察

這次是「一個 vLLM server＋一個 prediction writer」，不是多個模型副本的
並發壓力測試。vLLM log 的可核對觀察：

- 模型載入約 2.16 GiB；啟動參數為 `--gpu-memory-utilization 0.70`。
- server 估計可用 KV cache 約 73.84 GiB（6,452,320 tokens，以 8,192
  token request 計算的上限）；單頁跑批期間觀察到的 KV 使用率約 0.0～0.1%。
- graph capture 約 0.24 GiB；主機是 unified-memory APU，因此 GPU 預留會
  同時反映在系統記憶體／GTT 觀察值。
- 256 頁私有 domain soak 的 client max RSS 是 2,078,592 KiB，swap 0；
  這不是 vLLM server RSS，也不代表模型權重大小。

因此單 worker 的高 GPU／記憶體數字主要是 cache reservation、graph 與 vision
encoder workspace 的容量規劃；「已分配」不等於「目前請求有效使用」。實際
數字會隨 vLLM、prompt 長度、`max_num_batched_tokens` 與顯示工具改變。

## 多並發後續方案（尚未宣稱完成）

目前 benchmark 保持單 writer 及恢復 marker。下一步只考慮一個共享 vLLM
server、bounded queue、每 shard 的 atomic checkpoint、backpressure 與
per-request memory budget；不直接啟動多個 vLLM replicas。Transformers
concurrency=3 曾出現 Qwen2-VL position tensor shape mismatch，所以
Transformers 多 worker 仍標示 `rejected`，待另行修正與重跑。
