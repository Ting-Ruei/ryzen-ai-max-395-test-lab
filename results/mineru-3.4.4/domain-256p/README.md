# MinerU 3.4.4 domain corpus：256 頁 soak

日期：2026-08-08（Asia/Taipei）

證據等級：`self-attested`。原始 corpus 不可散布，因此外部讀者無法用本
repository 獨立重建這組數字；它只作 domain regression，不作公開準確率排名。

## Corpus

- 私有、不可散布；30 份 PDF、256 頁、18,318,783 bytes。
- 涵蓋主要題本、答案與更正等不同版面角色。
- 公開版本不包含來源檔名、PDF、完整 OCR 文字或私人路徑。
- 上傳至 AI 節點前後逐檔 SHA-256 驗證，30/30 相同。

## vLLM 0.21 結果

| 指標 | 值 |
|---|---:|
| 文件 | 30/30 |
| 頁數 | 256/256 |
| Wall time | 1,049.80 秒 |
| 秒／頁 | 4.101 |
| 頁／秒 | 0.244 |
| Client max RSS | 2,078,592 KiB |
| Swap | 0 |
| Blocks | 5,372 |
| Images | 216 |
| Markdown image references | 164 |
| Missing image references | 0 |
| Exit status | 0 |

時間不含 vLLM worker 約 50 秒啟動與模型載入。Server 與 client 資源分開，
表中的 RSS 只代表 MinerU HTTP client。

## 對參考輸出的結構比較

| 指標 | Apple Silicon reference | AI395 vLLM |
|---|---:|---:|
| 頁數 | 256 | 256 |
| Blocks | 5,373 | 5,372 |
| Images | 217 | 216 |
| 相同每頁 block 數的文件 | 24/30 | 24/30 |
| 相同 block type 統計的文件 | 17/30 | 17/30 |
| 相同圖片內容的文件 | 24/30 | 24/30 |

按文件字元數加權的內容文字相似度為 0.957474；圖片 hash 正規化後的
Markdown 相似度為 0.944776。此比較沒有 ground truth，只能用來找版本／
backend 漂移，不能當作 OCR 準確率。

## 判定

Soak 與輸出完整性通過；通用準確率尚未判定。vLLM 保持選用 backend，待
OmniDocBench 完整 1,651 頁雙軌結果完成後再決定是否提升為預設。
