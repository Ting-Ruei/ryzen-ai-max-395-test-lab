# OmniDocBench 雙軌評測

AI 395 的 GPU prediction 與 CPU scorer 分開執行：MinerU2.5-Pro 維持原生
ROCm／vLLM 0.21，官方 Docker image 只執行 OmniDocBench scorer 與 CDM。

## 固定版本

| 項目 | Revision |
|---|---|
| AIwork4me/MinerU-ROCm adapter | `1585e1ec08e5d37bbad068f392cbf9864f016118` |
| v1.6 compatibility scorer | `2b161d010d2e3aff77a0edef359ea3a6411d23cd` |
| v1.7 current scorer | `193627ae9e97d89188468ed1ee3b7a856ff76044` |
| Hugging Face dataset | `aa1ee96d106dbe53d0ae59474d75c6e6d9b53fec` |
| GT SHA-256 | `a45cd84b04ad8b793e775089640e6b681209abea33ead54c1828ddca35fae496` |
| 官方 scorer image | `sha256:6116ad72172e763b5c43e963d5efebf2093f2362b975f58156ce4f6c9142e617` |

評測啟動時，v1.6 與 v1.7 scorer revision 的程式與 config 相同，差異只有
README；資料集 GT 亦相同。因此只產生一次 1,651 頁 prediction，再各跑一次
scorer，最後檢查 metric parity。兩軌仍保存獨立 result artifact，不能只複製
一份分數冒充兩次評測。

## 續跑與離線設計

- 每頁 Markdown 以 temporary file、`fsync`、atomic rename 寫入。
- 包含空白頁在內，每頁另有 SHA-256 completion marker；只有 marker 與輸出
  checksum 相符才會跳過。
- 單一 writer lock 防止重複服務同時寫 prediction。
- inference、v1.6 scoring、v1.7 scoring 與 finalize 各有 completion marker。
- vLLM 僅監聽 `127.0.0.1:18080`；scorer container 使用 `--network none`。
- user systemd service 可在 SSH 中斷後繼續；`Linger=yes` 時可在重新開機後
  自動恢復未完成 phase。

`status.sh` 只讀取 marker、manifest 與最後 20 行 log，不會變更評測狀態。
