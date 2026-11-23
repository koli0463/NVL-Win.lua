# 🚨 CONSTITUTION — Quy Tắc Bắt Buộc Trước Khi Hành Động

## TL;DR
**DỪNG LẠI. ĐỌC. HIỂU. RỒI MỚI LÀM.**
Không bao giờ được hành động dựa trên compaction summary hoặc giả định cũ mà không kiểm chứng trạng thái thực tế của workspace.

---

## 1. KHÔNG TẠO FILE MỚI KHI CHƯA ĐƯỢC YÊU CẦU RÕ RÀNG

- **TUYỆT ĐỐI KHÔNG** tạo file `.lua` mới trừ khi user nói rõ ràng "tạo file mới" hoặc "create new file".
- Nếu user đã xóa một file, **KHÔNG BAO GIỜ** tạo lại file đó dù compaction summary hay context cũ có đề cập.
- Kiểm tra `git status` hoặc `ls` trước khi tạo bất kỳ file nào để xác nhận nó chưa tồn tại hoặc đã bị xóa.

### Ví dụ sai lầm thực tế:
> User đã xóa `NVL-Silentmode.lua` và chuyển sang dùng `Silentmode.cfg` (config approach).
> Agent đọc compaction summary cũ → Copy `NVL.lua` thành `NVL-Silentmode.lua` → **35 phút + hàng nghìn token lãng phí vô nghĩa**.

---

## 2. PHÂN BIỆT CONFIG vs FILE MỚI

| Approach | Khi nào dùng |
|----------|-------------|
| **Config file (.cfg)** | Khi user muốn thay đổi behavior mà KHÔNG duplicate code |
| **File mới (.lua)** | CHỈ khi user yêu cầu rõ ràng tạo script hoàn toàn mới |
| **Sửa file gốc** | Khi cần thay đổi logic trong file đã tồn tại |

- Dự án này sử dụng **config-based approach** cho Silent Mode: file `Silentmode.cfg` được load bởi `NVL.lua`, KHÔNG phải bằng một file `.lua` riêng biệt.

---

## 3. TRƯỚC KHI VIẾT CODE — CHECKLIST BẮT BUỘC

Trước mỗi hành động, tự hỏi:

- [ ] **User có yêu cầu CHÍNH XÁC điều này không?** (Không suy đoán, không assume)
- [ ] **File này có đang tồn tại không?** (`ls` hoặc `git status` để kiểm tra)
- [ ] **File này có từng bị user xóa không?** (Nếu có → KHÔNG tạo lại)
- [ ] **Mình đang giải quyết đúng vấn đề user đang gặp không?**
- [ ] **Approach này có phải là approach mà user đã chọn không?** (Config? Sửa file gốc? Hay tạo file mới?)
- [ ] **Ước tính thời gian: Việc này mất bao lâu? Có xứng đáng không?**

---

## 4. COMPACTION SUMMARY KHÔNG PHẢI GROUND TRUTH

- Compaction summary là snapshot CŨ. Nó có thể đã lỗi thời.
- **LUÔN** kiểm tra trạng thái thực tế của workspace trước khi dựa vào summary.
- Nếu summary nói "tạo file X" nhưng file X đã bị xóa → summary SAI → KHÔNG làm theo.

---

## 5. NGUYÊN TẮC TOKEN EFFICIENCY

- Mỗi tool call tốn token. Mỗi phút chạy tốn tiền.
- **Không spam console read** lặp đi lặp lại khi output giống nhau.
- **Không capture screenshot** nhiều lần khi không cần thiết.
- **Không tạo scratch script** cho những thứ có thể làm inline.
- Nếu task chỉ cần 2 phút → KHÔNG được mất 35 phút.

---

## 6. KHI NGHI NGỜ → HỎI USER

Nếu không chắc chắn 100% user muốn gì:
- **HỎI** thay vì giả định.
- 1 câu hỏi ngắn tốn ít token hơn 35 phút làm sai.

---

## 7. PROJECT-SPECIFIC RULES

### Silent Mode
- Silent Mode được implement qua **config file** (`Silentmode.cfg`), KHÔNG phải file `.lua` riêng.
- `NVL.lua` đã có logic đọc config và apply silent flags.
- **KHÔNG BAO GIỜ** tạo lại `NVL-Silentmode.lua`.

### File Structure  
- `uisimbl/NVL.lua` — Script chính duy nhất
- `uisimbl/library.lua` — UI library
- `uisimbl/Silentmode.cfg` — Config cho silent mode
- `uisimbl/*.cfg` — Các config files khác

### Execution Flow
- User execute `NVL.lua` → NVL.lua kiểm tra config → Apply flags tương ứng
- Config approach = flexibility WITHOUT code duplication

### Library Loading Protocol
- Mặc định tải `library` thông qua link GitHub (`https://raw.githubusercontent.com/koli0463/liuuuzuuu/refs/heads/main/librarry.lua`) hoặc theo cấu hình user chỉ định.
- **Lưu ý đồng bộ**: Khi chỉnh sửa `library.lua` cục bộ trên máy, phải lưu ý rằng nếu script load qua GitHub link thì các thay đổi local sẽ không có hiệu lực cho đến khi được push lên GitHub hoặc user tự đổi source load.
- Không tự ý ép buộc script đọc đè file local nếu user đang duy trì workflow load từ GitHub.

### Zero FPS Impact
- Không bao giờ thêm tính toán nặng, vòng lặp đồng bộ hoặc disk I/O (`readfile`, `writefile`, `getasset`) bên trong `RenderStepped`, `Heartbeat`, `Stepped` hoặc vòng lặp animation.
- Tất cả các thao tác lưu/đọc file cấu hình hoặc emote phải theo dạng event-driven (chỉ kích hoạt khi bấm nút hoặc khởi tạo 1 lần).
- Giải phóng instance và ngắt connection cũ để chống leak bộ nhớ và giật FPS từ garbage collection.

---

## 8. TƯ DUY TỐI ƯU — LUÔN ĐỀ XUẤT CÁCH LÀM THÔNG MINH NHẤT

Trước khi implement, **luôn tự hỏi**: "Có cách nào đơn giản hơn không?"

| ❌ Cách ngu (3.8 đã làm) | ✅ Cách thông minh |
|---|---|
| Copy toàn bộ 13,209 dòng NVL.lua → NVL-Silentmode.lua, chỉ thêm 1 dòng flag | Tạo 1 file .cfg 5 dòng, NVL.lua tự đọc config |
| Maintain 2 file giống hệt nhau 439KB mỗi file | 1 file .cfg < 1KB, zero maintenance |
| Mỗi lần sửa NVL.lua phải sửa cả Silentmode.lua | Sửa NVL.lua 1 lần, config tự apply |

### Nguyên tắc:
1. **Config > File mới**: Nếu sự khác biệt chỉ là vài flag/setting → dùng config file
2. **Sửa file gốc > Copy file**: Nếu cần thay đổi logic → sửa file gốc, không duplicate
3. **5 dòng > 13,000 dòng**: Luôn chọn solution có ít code nhất mà vẫn đạt mục đích
4. **Đề xuất trước khi làm**: Nếu user yêu cầu cách A nhưng cách B tốt hơn → đề xuất B, giải thích tại sao, rồi để user quyết định

---

## 9. TIME & TOKEN EFFICIENCY — DEEP THINKING, NOT ENDLESS THINKING

### Core Principle
- High reasoning effort is for difficult problems, not an excuse for unlimited investigation.
- Optimize for the fastest reliable solution, not the largest amount of analysis.
- Spend effort according to task complexity, risk, uncertainty, and expected benefit.

### Investigation Budget
- Simple, clearly scoped tasks: inspect only relevant files and implement directly.
- Medium tasks: inspect dependencies and run the checks needed to validate the change.
- Complex or regression-prone tasks: investigate competing hypotheses and verify the root cause before making risky changes.
- Establish a reasonable investigation budget before broad exploration. Treat it as a checkpoint, not an absolute deadline.
- As a default heuristic, reassess after approximately 5 minutes on a simple task or 15 minutes on a complex task if meaningful progress has not been made. These are review points, not mandatory stopping times.

### Anti-Loop Rules
- Never repeat the same file read, console command, screenshot, search, or test unless new evidence justifies it.
- Do not keep exploring low-probability hypotheses after stronger evidence identifies a likely cause.
- After two unsuccessful attempts using essentially the same approach, change the approach or explain the blocker.
- Do not refactor unrelated code or pursue optional improvements after the requested outcome is achieved.
- Do not create scratch files or helper scripts when a simpler supported method is sufficient.

### Checkpoint and Escalation
When investigation exceeds its expected budget:
1. Summarize what is already known.
2. Identify the remaining uncertainty.
3. Explain the next test most likely to resolve it.
4. Decide whether the expected benefit justifies continuing.
5. Continue when the risk or importance warrants it; otherwise ask the user or report the blocker.

### Definition of Done
A task is complete when:
- The requested outcome has been implemented.
- Relevant checks have passed, or verification limitations are explicitly stated.
- No known critical regression remains unaddressed.
- Further investigation is unlikely to materially improve correctness or safety.

Do not continue merely to achieve absolute certainty when the available evidence is sufficient for the task's risk level.

### No Fake Speed
- Never skip essential verification merely to meet a time target.
- Never claim success without evidence.
- Safety, data integrity, and preservation of user changes take priority over speed.
- If a difficult task genuinely needs more time, continue with a clear reason rather than stopping mechanically.

---

## 10. CONTEXT-AWARE REASONING & INTENT UNDERSTANDING

### A. Hiểu bản chất yêu cầu (Intent over literal text)
- Xem mỗi tin nhắn của user là một phần của chuỗi hội thoại liên tục, không cô lập từng câu.
- Phân biệt rõ ràng: lệnh thực thi, bối cảnh, quan sát, giả thuyết, sự thật đã chứng minh, và cảm xúc/phàn nàn.
- Một chi tiết kỹ thuật user nhắc tới **không đồng nghĩa** với việc user yêu cầu sửa nó.
- Tự động nhận diện việc user tự sửa lời (self-correction): lấy ý định đã làm rõ cuối cùng, không cộng dồn các bản nháp mâu thuẫn.
- Nhận biết sắc thái cảm xúc (bực bội, gấp rút, châm biếm) để nắm trọng tâm điều user quan tâm; tuy nhiên **tuyệt đối không** vì gấp gáp mà bỏ qua bước kiểm chứng.
- Không hỏi lại những thông tin đã có sẵn trong hội thoại hoặc tài liệu dự án.

### B. Giữ sự thận trọng và tính không chắc chắn (Preserve uncertainty)
- Không bao giờ biến một giả thuyết thành nguyên nhân gốc rễ đã xác nhận nếu chưa có bằng chứng thực nghiệm.
- Khi có nhiều nguyên nhân khả dĩ, giữ chúng tách biệt cho đến khi có dữ liệu phân biệt rõ ràng.
- Nêu rõ: điều gì đã biết chắc chắn, điều gì suy luận, điều gì đã kiểm chứng và điều gì vẫn là ẩn số.
- Luôn kiểm tra source code, git diff, log runtime và test case trước khi kết luận.

### C. Chỉ đặt câu hỏi thực sự cần thiết (Useful questions only)
- Tự tra cứu bằng chứng có sẵn trong workspace trước khi hỏi user.
- Chỉ hỏi 1 câu ngắn gọn khi có điểm mơ hồ nghiêm trọng ảnh hưởng trực tiếp đến hướng triển khai hoặc rủi ro cao.
- Nếu giải pháp rõ ràng, an toàn, tối thiểu và có thể rollback: chủ động thực hiện ngay, không hỏi rườm rà.
- Không bao giờ âm thầm chọn bừa giữa hai hướng giải pháp khác biệt lớn khi chưa rõ mục tiêu.

### D. Duy trì tính kế thừa dự án (Project continuity)
- Luôn kiểm tra workspace thực tế thay vì tin vào summary cũ hoặc trí nhớ.
- Tái sử dụng các quyết định và phát hiện đã kiểm chứng trước đó.
- Ghi lại các phát hiện kỹ thuật quan trọng vào tài liệu phù hợp trong dự án.

---

## 11. MCP DISCOVERY & VERIFICATION PROTOCOL

1. **Xác minh công cụ thực tế**:
   - `list_clients`: Kiểm tra các PID client Roblox đang kết nối. Luôn gọi trước khi dispatch script.
   - `execute_script`: Nạp chuỗi Luau vào PID được chọn (hoặc tất cả). Trả về cursor để đọc log.
   - `read_console`: Đọc output thực tế từ game client qua `after_cursor` và `wait_ms`.
2. **Không ảo tưởng khả năng của MCP**:
   - Dùng đúng mục đích: xác thực cú pháp (`loadfile` / `loadstring`), test hàm, đọc log runtime.
3. **Quy trình kiểm chứng sau khi sửa mã nguồn (BẮT BUỘC FULL EXECUTION)**:
   - Bước 2: Dùng `list_clients` xác định PID Roblox đang hoạt động.
   - Bước 3: **BẮT BUỘC EXECUTE TOÀN BỘ SOURCE**: Dùng `execute_script` chạy thực tế toàn bộ file qua `pcall(function() loadstring(readfile("uisimbl/NVL.lua"))() end)` để kiểm tra toàn diện lỗi runtime (không chỉ dừng lại ở cú pháp `loadstring` mà phải chạy thực sự qua các hàm khởi tạo UI, hook, listener).
   - Bước 4: Dùng `read_console` với `after_cursor` để đọc log xác nhận `true nil` và không có bất kỳ error traceback nào.
   - Bước 5: Báo cáo trung thực kết quả thực tế kèm log console, chỉ nghiệm thu khi toàn bộ source execute thành công 100%.

---

## 12. LUAU & ROBLOX RUNTIME COMPATIBILITY

- **Không áp đặt cực đoan**: Không gượng ép `--!strict` lên các file script monolithic 30,000 dòng legacy nếu gây ra hàng trăm lỗi type giả tạo.
- **Ưu tiên tính ổn định**: Tránh thay đổi cấu trúc dữ liệu đang chia sẻ nếu không kiểm soát hết các listener.
- **Bảo toàn animation track & priorities**:
  - `Idle`: `Enum.AnimationPriority.Idle`
  - `Movement` / `Run`: `Enum.AnimationPriority.Movement`
  - `Tool / Action`: `Enum.AnimationPriority.Action`
  - Tuyệt đối không để animation di chuyển đè lên animation cầm vũ khí hoặc ngược lại.

---

## 13. NGUYÊN TẮC REVERSE-ENGINEERING & INTEGRATION (TUYỆT ĐỐI KHÔNG TỰ CHẾ LẠI)

- Khi reverse-engineer, porting hoặc tích hợp một UI / module / resource có sẵn từ game hoặc từ cộng đồng (Devforum, Creator Store, Roblox Asset):
  - **CẤM TUYỆT ĐỐI việc tự ý chế lại UI, tự vẽ lại icon, đổi font hay thay đổi layout làm xấu và vỡ thiết kế gốc**.
  - **BẮT BUỘC LẤY 100% NGUYÊN BẢN GỐC**: Sử dụng chính xác toàn bộ cấu trúc GUI, icon asset, math handler (Circle, Square, Triangle), thanh trượt (HSV/RGB sliders), palette và các module đi kèm của resource gốc.
  - **TÁCH BIỆT DRAG TƯƠNG TÁC**: Event drag để chọn màu / kéo slider phải được xử lý cô lập (`InputBegan` / `InputChanged` trên canvas con), tuyệt đối không để kéo màu làm trôi cả khung cửa sổ UI chính.

---

## 14. BẢO TỒN ĐỊNH DANH DỰ ÁN VÀ TIÊU CHUẨN UI (NEVERLOSE / MEMORY)

1. **BẢN SẮC DỰ ÁN LÀ BẤT KHẢ XÂM PHẠM**:
   - Tên dự án: **Neverlose / Memory UI** (Title: `Memory`).
   - Logo chính: **Crown Logo** màu tím phát sáng (`sidebar_crown_logo.png`).
   - Watermark: **NEVERLOSE** (`NEVERLOSE | SERVER | FPS | PING | TIME`).
   - Accent: Lavender Purple `#ba91fc`.
   - **Tuyệt đối không lấy tên mockup/ảnh tham khảo (Leywin, Pandora...) để đổi tên dự án hay đè logo.**

2. **TABS & SUB-TABS PHẢI ĐẦY ĐỦ**:
   - Khi tham khảo ảnh, phải implement đầy đủ hệ thống tab và sub-tabs (`Thread`, `Enemy`, `Other`, `Team`) ở TopBar, cho phép lọc card mượt mà.

3. **SPECTATORS LIST CHUYÊN NGHIỆP**:
   - Phải có avatar thumbnail người chơi (`rbxthumb://type=AvatarHeadShot&id=...`), DisplayName, `@Username`, và tag chế độ spectate (`[1st]`, `[3rd]`, `[Watching]`), kèm trạng thái khi không có ai xem.

4. **NÚT CÀI ĐẶT BÁNH RĂNG (⚙) VÀ POPUP CON**:
   - Bấm vào icon ⚙ để bật/tắt (toggle) panel cài đặt con.
   - **CẤM** đặt nút "X" trong panel con.

5. **TÊN PLACE DƯỚI LOGO THAY VÌ "ROBLOX"**:
   - Dưới logo `Memory`, hiển thị tên place/game thực tế từ `MarketplaceService:GetProductInfo(game.PlaceId).Name`.

6. **CHỐNG CHỒNG LẤP ANIMATION ĐỔI TAB**:
   - Không được để 2 canvas tab hiển thị đồng thời khi transition. Phải ẩn (`Visible = false`) canvas cũ trước hoặc đồng bộ khi canvas mới trượt vào.

