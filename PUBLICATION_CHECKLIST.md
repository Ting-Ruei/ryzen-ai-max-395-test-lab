# 公開發布檢查表

## 必須完成

- [x] GitHub owner：`Ting-Ruei`；repository：`ryzen-ai-max-395-test-lab`。
- [x] 本專案採 Apache-2.0；第三方程式碼、模型、資料集分開標示原授權。
- [x] 只提交匿名結果；不提交 private corpus、PDF、原始 OCR 或私人路徑。
- [x] 執行祕密掃描，並人工檢查初始 Git history 與工作樹。
- [x] 檢查所有外部專案名稱、連結與固定 commit。
- [x] 可公開重建者提供腳本與 manifest；私有 corpus 數字標為 self-attested。
- [x] 將 cold start、warm worker、跨平台參考與同機 A/B 明確分開。
- [x] 在公開 README 標示非官方支援與已知失敗版本。

## 首次發布後

- [x] 將 Linux gfx1151 結果分享至對應的 MinerU／ROCm 社群 Issue：
  [AIwork4me/MinerU-ROCm #21](https://github.com/AIwork4me/MinerU-ROCm/issues/21)、
  [buptanswer/mineru #2](https://github.com/buptanswer/mineru/issues/2)。
- [x] OmniDocBench v1.6／v1.7 完整評測完成後，以新 commit 補分數與 prediction manifest。
- [ ] 完整 1,651 頁完成後建立不可變的 results tag。
- [ ] 任何新 ROCm、PyTorch 或 backend 組合新增一列矩陣，不覆寫舊結果。
