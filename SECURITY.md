# Security and disclosure policy

本專案只公開可重現的技術資訊，不公開下列內容：

- token、密碼、cookie、SSH key、私有 registry 或服務憑證；
- 使用者姓名、帳號、學習紀錄、正式資料庫內容；
- 私有 PDF、完整 OCR 文字、具識別性的檔名或本機絕對路徑；
- 未取得再散布權利的模型權重、資料集或衍生素材。

公開結果只能包含匿名 document ID、聚合指標、環境版本、公開模型 revision、
程式 commit 與不可反推出內容的 checksum。任何腳本預設不得綁定公開介面；
本機推論服務範例必須使用 `127.0.0.1`。

發現安全問題時，請勿在公開 Issue 張貼祕密或私人資料；應使用 repository 的
private vulnerability reporting（啟用後）聯絡維護者。
