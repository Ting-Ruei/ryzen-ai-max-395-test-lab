# 實驗紀錄範本

每個新配置複製本文件，檔名使用 `workload/YYYY-MM-DD-short-name.md`。

## 結論

- 狀態：`validated`／`experimental`／`rejected`／`blocked`
- 一句話結果：
- 適用情境：
- 不適用情境：

## 固定環境

| 項目 | 值 |
|---|---|
| APU／GPU | |
| architecture | |
| UMA／VRAM 設定 | |
| OS／kernel | |
| ROCm／HIP | |
| Python | |
| framework | |
| workload package | |
| model repository／revision | |
| source commit | |

## 安裝與執行

只放可公開、可重現且不含私人路徑的命令。若有 source patch，附上最小 diff、
上游連結與授權；不要只描述修改後結果。

## 測試資料

- 公開／私有：
- 文件或 prompt 數：
- 規模：
- dataset revision／checksum：
- 選樣 seed 與規則：

## 效能

分列 cold start、warm median、p95、吞吐、client/server RSS、GPU memory、
swap 與功耗；每個數字註明重跑次數。

## 品質與完整性

使用 workload 的官方 evaluator。另列空輸出、缺頁、缺圖、timeout、錯誤與
人工抽查，不用單一字串相似度取代標準分數。

## 已知限制與失敗

保留失敗命令、錯誤摘要和採納判定。若比較不同硬體、backend 或 scorer，
明確標示未控制變因。

## Provenance

- manifest：
- result bundle SHA-256：
- 執行日期／時區：
- 相關上游 Issue／PR：
