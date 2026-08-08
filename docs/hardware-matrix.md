# 硬體與軟體矩陣

狀態只描述已完成且有證據的實測，不推論其他 AMD architecture 也能使用。

| 平台 | Backend／workload | 軟體路徑 | 狀態 | 證據 |
|---|---|---|---|---|
| Linux `gfx1151`／Radeon 8060S | MinerU 3.4.4 VLM | PyTorch 2.12.0+rocm7.14，Transformers | `single-document-only` | 1 頁與 4 頁通過；多文件預設併發因 tensor shape error 失敗；單 worker 已驗證 8 頁 |
| Linux `gfx1151`／Radeon 8060S | MinerU pipeline | PyTorch ROCm 7.14 | `validated-fast-path` | 4 頁 39.50 秒 |
| Linux `gfx1151`／Radeon 8060S | MinerU VLM + AOTriton | PyTorch ROCm experimental SDPA | `experimental` | 1 頁較基準減少 18.69%，輸出完全一致 |
| Linux `gfx1151`／Radeon 8060S | MinerU VLM | vLLM 0.21 source build、localhost HTTP | `validated-optional` | 30 份／256 頁 soak；標準準確率 benchmark 尚待執行 |
| Linux `gfx1151`／Radeon 8060S | MinerU VLM | AMD vLLM 0.23.1.dev1 wheel | `rejected` | 三種 attention 設定皆輸出 8,192 個重複 `!` |

## 主環境

```text
Ubuntu 26.04
Linux 7.0.0-29-generic
ROCm 7.14 / HIP 7.14.60850
Python 3.12.12
MinerU 3.4.4
PyTorch 2.12.0+rocm7.14.0
GPU gfx1151 / AMD Radeon 8060S Graphics
```

## vLLM worker

```text
Python 3.13.13
vLLM 0.21.0
source commit ad7125a431e176d4161099480a66f0169609a690
PyTorch 2.11.0+rocm7.14.0
Transformers 4.57.6
bind 127.0.0.1:18080
```

MinerU 主環境與 vLLM worker 使用不同 venv，透過 OpenAI-compatible localhost
HTTP 連接。這不是 Python 版本混裝，也不修改系統 `/opt/rocm`。

## Transformers 批次限制

MinerU 3.4.4 temporary API 的預設 request concurrency 為 3。同時送出 5 份
Transformers VLM 任務時，4 份出現 Qwen2-VL position tensor shape error。
設定 `MINERU_API_MAX_CONCURRENT_REQUESTS=1` 後前兩份／8 頁完整通過。其後的
執行被獨立追蹤的系統重新開機事件中斷；該事件不納入 MinerU／ROCm 相容性
判定，也不作為本段批次限制的證據。

因此目前不使用 ROCm Transformers 執行多文件批次；它只保留為小型單文件
診斷路徑。詳細時間線見
[Transformers concurrency 結果](../results/mineru-3.4.4/transformers-concurrency/README.md)。
獨立系統事件見
[2026-08-08 主機重新開機事件](../incidents/2026-08-08-unexplained-host-restart.md)。
