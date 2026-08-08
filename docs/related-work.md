# 相關工作與本專案差異

## AIwork4me/MinerU-ROCm

[AIwork4me/MinerU-ROCm](https://github.com/AIwork4me/MinerU-ROCm)（本次檢視
commit `1585e1ec08e5d37bbad068f392cbf9864f016118`）是最接近的
evaluation-backed 社群工作。其公開資料涵蓋：

- Linux Radeon PRO W7900／`gfx1100`／ROCm 7.2；
- MinerU pipeline 與 vLLM-on-ROCm；
- OmniDocBench v1.6 完整 1,651 頁與可重現結果；
- Windows-HIP 的 Ryzen AI MAX+ 395／Strix Halo 實驗。

本專案不複製其 adapter 或宣稱取代它，而是補上 Linux Strix Halo 的新交叉
組合：Ubuntu 26.04、ROCm 7.14、`gfx1151`、統一記憶體、MinerU 3.4.4、
Python 3.13 vLLM worker，以及長時間 soak／資源觀測。正式 benchmark 盡量
沿用相同 OmniDocBench schema，讓結果能互相比較。

## buptanswer/mineru

[buptanswer/mineru](https://github.com/buptanswer/mineru)（本次檢視 commit
`c6e9606883e3aee6b1a8c697a8720137a1661e44`）記錄 RX 系列 RDNA
顯卡的 ROCm、vLLM 編譯與 MinerU 適配。它的重要價值是工程踩坑與可操作
步驟；本專案則避免在已可使用官方 gfx1151 wheel 時套用不必要的
`HSA_OVERRIDE_GFX_VERSION` 或系統 source patch，並把成功與失敗組合納入
正式矩陣。

## 上游與官方

- [opendatalab/MinerU](https://github.com/opendatalab/MinerU)
- [vLLM documentation](https://docs.vllm.ai/)
- [AMD ROCm documentation](https://rocm.docs.amd.com/)
- [OmniDocBench](https://github.com/opendatalab/OmniDocBench)
- [olmOCR](https://github.com/allenai/olmocr)

引用其他專案時應保留其名稱、連結、commit 與授權；若移植程式碼，另記錄
來源檔案與 license，而非只在 README 中口頭致謝。
