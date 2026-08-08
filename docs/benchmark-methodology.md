# Benchmark 方法

## 三層證據

1. Smoke：確認 GPU、模型載入、單頁輸出與錯誤處理。
2. Domain regression：私有 30 份／256 頁 corpus，驗證真實工作負載的完整性、
   效能與版本回歸；不作通用準確率聲明。
3. Public benchmark：OmniDocBench 與 olmOCR-Bench，以官方資料與 evaluator
   衡量跨文件類型的文字、公式、表格、版面與閱讀順序。

## 公平 A/B 規則

- 固定輸入 bytes、MinerU 版本、模型 revision、頁面範圍與輸出轉換。
- cold start 與 warm worker 分開；warm 測試至少三次，報 median 與 p95。
- 報告 wall time、pages/s、client/server RSS、GPU memory、swap、timeout、
  空輸出、缺頁與缺圖。
- 比較品質時，各 backend 先轉為相同 prediction schema。
- pipeline 與 VLM 是不同品質路徑，不應只按速度排成同一名次。
- 跨平台結果必須標示為 cross-platform reference，不當成引擎加速比。

## OmniDocBench

主測試採官方完整 1,651 頁。先用固定 seed 建立 50 頁分層 pilot，涵蓋
10 種 document type、語言、layout、表格、公式、模糊掃描與彩色背景；
adapter 與 scoring 通過後才跑完整資料。

報告分成兩條固定版本線：v1.6 compatibility track 對齊
AIwork4me/MinerU-ROCm 的 dataset、scorer revision、prediction schema 與 CDM；
最新 v1.7 作 current track。不同 scorer 的 Overall 不直接互相比較。

報告至少包含 Text Edit Distance、Formula CDM、Table TEDS、layout、reading
order，以及空輸出頁數。資料、scorer、轉換腳本與 commit 都必須固定。

## olmOCR-Bench

先跑固定 100 份 PDF smoke，再跑完整 1,403 份／7,010 個 unit tests。
此結果用於交叉驗證不同 Markdown 表達下的關鍵內容與結構，不取代
OmniDocBench 的 MinerU 生態比較。

## 目前 256 頁 domain 結果的解讀

vLLM 0.21 完成 30/30 份、256/256 頁、5,372 個 blocks、216 張圖片、
164 個 Markdown 圖片引用且零遺失，wall time 1,049.80 秒。另一個
Apple Silicon backend 的相同 corpus 為 2,858.32 秒，但這是跨硬體、跨
backend 參考，不能宣稱 2.72 倍是純 vLLM 引擎加速。

同一 AI 395、相同 4 頁資料的 Transformers 160.36 秒對 vLLM 39.90 秒，
才是目前可報告的同機加速比：4.02 倍；啟動約 50 秒未計入 warm worker
時間。
