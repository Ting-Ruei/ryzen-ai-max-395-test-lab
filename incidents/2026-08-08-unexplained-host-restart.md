# 2026-08-08 未定因主機重新開機事件

狀態：獨立系統事件；原因未確認

## 範圍

AI 395 在一段本機 AI 工作負載執行期間重新開機。時間上與測試重疊不代表
因果關係；在取得可重現步驟或硬體／kernel 證據前，本事件不定義為 MinerU、
Transformers、ROCm、vLLM 或硬體衝突，也不納入任一 workload 的相容性判定。

## 已知事實

- 上一個 boot 的 journal 最後紀錄：2026-08-08 10:46:22（Asia/Taipei）。
- 下一個 boot 開始：2026-08-08 10:49:10（Asia/Taipei）。
- 上一個 boot 沒有留下正常 shutdown、OOM、thermal 或 amdgpu error。
- `/sys/fs/pstore` 沒有 crash record。
- 重新開機後，PyTorch 2.12.0+rocm7.14.0 可辨識 Radeon 8060S，
  512×512 FP16 matrix probe 通過。

## 尚未知

- 重新開機的觸發來源與 root cause。
- 是否可由任何單一軟體、driver、電源、韌體或硬體條件重現。

除非後續有獨立重現與診斷證據，其他 benchmark 只記錄「曾被獨立系統事件
中斷」，不得把這個事件轉寫成 MinerU／ROCm failure。
