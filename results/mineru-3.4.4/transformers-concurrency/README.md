# ROCm Transformers 多文件穩定性

日期：2026-08-08（Asia/Taipei）

## 預設併發測試

- 輸入：5 份／14 頁，與 vLLM 代表集相同。
- MinerU temporary API 預設 `MINERU_API_MAX_CONCURRENT_REQUESTS=3`。
- 結果：第一份／4 頁完成；其餘 4 個 task 失敗，CLI exit 1。
- 錯誤：Qwen2-VL `prepare_inputs_for_generation` 的 position tensor shape
  不一致，例如 target `[3, 4, 1]`、source `[0, 1]`。
- Wall time：338.74 秒；不是有效的速度 baseline。

這較像同一 in-process Transformers predictor 的並行共享狀態問題；目前沒有
足夠證據把它歸因單一 ROCm kernel。

## 單 worker 測試

以公開環境參數限制 request concurrency：

```bash
MINERU_API_MAX_CONCURRENT_REQUESTS=1 mineru \
  -p INPUT_DIRECTORY \
  -o OUTPUT_DIRECTORY \
  -m ocr
```

前兩份／8 頁完整通過：345 blocks、零缺頁、零缺圖引用。從 predictor 就緒至
第二份完成約 258.0 秒。同兩份在已預熱 vLLM worker 的逐份 wall time 合計
53.19 秒，約 4.85 倍；Transformers 對 vLLM 的文字相似度 0.999777、
Markdown 相似度 0.998994，但 blocks 為 345 對 339。

後續執行被一件未定因的系統重新開機事件中斷。該事件與本結果分開追蹤，
不歸因於 MinerU、Transformers、ROCm 或硬體，也不納入 workload 相容性判定。
詳見[獨立事件紀錄](../../../incidents/2026-08-08-unexplained-host-restart.md)。

## 判定

- 多文件預設併發：`rejected`。
- 多文件單 worker：`validated-8-pages`；更大範圍尚未完成。
- 小型單文件 Transformers：保留作診斷，不作批次預設。
- vLLM 0.21：目前較穩定的批次路徑，但是否作正式預設仍等待公開準確率
  benchmark。
