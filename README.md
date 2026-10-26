# 室內配線丙級線上測驗系統

這是一個獨立的新專案，和既有的 LINE AI 客服、足球戀愛遊戲分開。第一版包含：

- 使用者名稱／密碼註冊與登入（不要求使用者提供真實電子郵件）
- 共同科目、室內配線專業科目
- 一般練習、錯題重測、未練習題目
- 作答解析、個人答題紀錄與跨裝置同步
- 整體正確率、錯題清單、章節熟練度
- GitHub 保存程式碼、Render 部署網站、Supabase 登入與雲端資料庫

目前不會自動產生假題目；題庫需要管理者從自己持有的教材匯入，並核對正確答案。

## 專案檔案

- `index.html`：網站前端與測驗功能
- `config.js`：Supabase 前端連線設定
- `supabase-schema.sql`：題庫及個人學習紀錄資料表、權限政策
- `questions-template.csv`：題目匯入欄位範本

## 第一步：建立 Supabase 專案與資料表

1. 登入 Supabase，建立一個新 Project。
2. 打開左側 **SQL Editor**，建立 New query。
3. 在 GitHub 打開本專案的 `supabase-schema.sql`，複製整份內容貼到 SQL Editor。
4. 按 **Run** 執行。成功後會建立 `questions` 和 `user_progress` 兩張資料表。

資料表用途：
- `questions` 儲存題目、選項、正確答案、解析與來源。
- `user_progress` 儲存每位登入使用者自己的作答紀錄。

## 第二步：填入網站連線設定

1. 在 Supabase 專案設定中找到 **Project URL** 與 **anon/public key**（不同新版介面可能顯示為 publishable key）。
2. 在 GitHub 開啟 `config.js`，按鉛筆圖示編輯。
3. 把 `YOUR_SUPABASE_PROJECT_URL` 換成自己的 Project URL。
4. 把 `YOUR_SUPABASE_ANON_PUBLIC_KEY` 換成自己的 anon/public 或 publishable key。
5. 儲存並 Commit changes。

**安全提醒：** 前端只使用公開 anon/publishable key。絕對不要把 `service_role` key、資料庫密碼或其他私密金鑰放進 `config.js`、`index.html` 或公開 GitHub。

## 第三步：設定不需電子郵件的帳號名稱登入

目前前端讓使用者自行建立帳號名稱與密碼。為了仍使用 Supabase 的安全密碼驗證，網站會在瀏覽器內把正規化後的帳號名稱轉成不可收信的內部登入識別碼，再交給 Supabase Auth；這不會要求使用者提供真的電子郵件。

1. 在 Supabase 專案左側進入 **Authentication → Sign In / Providers → Email**（新版介面名稱可能略有差異）。
2. 確認 Email 登入 provider 已啟用。
3. 將 **Confirm email** 關閉，否則 Supabase 會要求驗證內部識別碼，而使用者無法收到該驗證信。
4. 儲存設定後，再回到 Render 網站測試建立帳號及登入。

**重要限制：**
- 使用者必須自行記住帳號名稱與密碼；目前沒有忘記密碼的電子郵件找回功能。
- 帳號名稱會被轉成小寫後比對，因此大小寫不同視為同一個帳號。
- 帳號名稱只能用中文、英文字母、數字、底線或連字號，長度 2–24 個字，不可有空格。
- 這是一個使用 Supabase email/password 驗證的相容做法，Supabase Auth 內部會存一個不可收信的識別碼；若未來要做密碼找回、帳號名稱修改或真正的 username-first 後端，需再擴充伺服器端功能。

## 第四步：部署到 Render

1. 登入 Render，選 **New + → Static Site**。
2. 連接 GitHub，選擇 `yiting9095-max/online-quiz-system`。
3. Branch 選 `main`。
4. Build Command 留空；Publish Directory 填 `.`。
5. 建立 Static Site，等待部署完成，打開 Render 給你的網站網址。
6. 確認 Supabase Email provider 的 Confirm email 已關閉，然後測試建立帳號、登出再登入。

每次把修改 Commit 到 GitHub 的 `main` 分支後，Render 通常會自動重新部署。

## 第五步：匯入自己的題庫

先使用 `questions-template.csv` 作為欄位範本。請以你持有的 PDF／Word 題庫為依據，逐題核對題目、選項、答案與解析；不要把示範文字或未確認答案當作正式考題。

欄位說明：

| 欄位 | 填寫方式 |
| --- | --- |
| `category` | 共同科目填 `common`；室內配線專業科目填 `professional` |
| `category_label` | 填 `共同科目` 或 `室內配線專業科目` |
| `chapter` | 章節名稱，例如接地、配線設計 |
| `question_text` | 完整題目 |
| `options` | JSON 陣列，例如 `["選項 A","選項 B","選項 C","選項 D"]` |
| `correct_index` | 從 0 開始：A 填 0、B 填 1、C 填 2、D 填 3 |
| `explanation` | 已核對的答案解析；沒有就先留空 |
| `source_name` | 題目來源檔名 |
| `source_page` | 題目所在頁碼 |
| `is_active` | 正式題目填 `true`；未核對題目填 `false` |

匯入時請確保 CSV 欄位和資料表欄位相符。因為 `options` 是 JSON 陣列欄位，若 CSV 匯入工具無法正確解析，建議先在 Supabase 的 Table Editor 用 **Insert row** 測試一題，確認選項以 JSON 陣列格式儲存後，再批次匯入。

## 熟練度計算

目前前端的章節熟練度規則為：至少作答 5 次、累計正確率達 80%，且最近 3 次作答都答對。此規則是本系統的學習指標，並非官方考試評分標準。

## 常見問題

- **網站顯示沒有題目：** 確認題目已匯入 `questions`，`is_active` 設為 `true`，且 `category` 值為 `common` 或 `professional`。
- **帳號註冊後沒有登入：** 確認 Supabase Authentication 的 Email provider 已關閉 Confirm email，並確認 `config.js` 的 URL/key 正確。
- **登入成功但讀不到題目：** 確認已執行 SQL、RLS 政策存在、`config.js` 的 URL/key 正確。
- **答題紀錄無法儲存：** 確認已執行最新的 `supabase-schema.sql`，且登入狀態有效。
- **不要直接公開敏感資料：** 不要把任何使用者密碼、服務金鑰或資料庫密碼貼到聊天或 GitHub。



## 第六步：匯入題庫到 Supabase

已整理好官方學科題庫 CSV，放在 GitHub 的 [imports 資料夾](./imports/README.md)。總共 1,018 題：室內配線專業科目 618 題，以及四類共同科目各 100 題。

1. 逐一打開 [imports 資料夾](./imports) 中的 CSV 檔案，按 **Raw**，將檔案下載到電腦。
2. 進入 Supabase → **Table Editor → questions → Import data from CSV**。
3. 一次匯入一個 CSV，5 個檔案都完成才算匯入完整。
4. **請勿重複匯入同一個 CSV**，以免題目重複。

目前 66 題含圖題先設為 `is_active=false`，因網站尚未支援題圖顯示；其餘 952 題可先練習。詳情與題庫版次請看 [imports/README.md](./imports/README.md)。

來源註記：題庫來自勞動部勞動力發展署技能檢定中心公開資料。官方網站資料開放宣告要求利用時註明來源，使用時也不應暗示測驗網站由政府機關認可或營運。
