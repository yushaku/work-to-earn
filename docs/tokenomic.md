# Tokenomics

- name: DeFree
- symbol: DFR
- total supply: 100,000,000
- decimals: 18
- initial distribution:

  - 50% to platform (locked)
  - 25% to community (air drop)
    - 10% for KYC => after create account and KYC - will release funds
    - 5% for reviewing - after client + freelancer review - will release funds
  - 10% to team => locked 2 years
  - 10% to reserve
  - 5% to add liquidity

## money flow

Với các dự án tương tự như nền tảng freelance phi tập trung sử dụng blockchain mà bạn đang thiết kế (dựa trên mô hình mốc tiến độ - Milestone-Based), doanh thu của họ thường đến từ một số nguồn chính. Dựa trên nghiên cứu về các nền tảng blockchain hiện có như LaborX, CryptoTask, Blocklancer, và các mô hình truyền thống như Upwork, dưới đây là các nguồn doanh thu phổ biến và cách chúng có thể áp dụng cho hệ thống của bạn:

1. Phí giao dịch (Transaction Fees)

ví dụ: hơp đồng 100$ thì client phải nạp 101$

- sau khi freelancer hoàn thành thì freelancer sẽ nhận đc 97% (100$ - 3%)
- Protocol sẽ nhận đc 4% (3% từ user + 1% từ client)

- freelancer fee (3%) từ số tiền USDT
- client fee (1%) từ số tiền USDT

2. Phí dịch vụ cao cấp (Premium Services)
   Áp dụng cho bạn: Bạn có thể cung cấp tính năng như xem trước danh tiếng freelancer chi tiết, hoặc ưu tiên giải quyết tranh chấp cho người dùng trả phí.

3. Phí khởi tạo hợp đồng (Contract Creation Fees)
   Áp dụng cho bạn: Thay vì để người dùng chịu toàn bộ phí gas, bạn có thể thu một khoản phí cố định (ví dụ: 1-2 USDT) khi khởi tạo hợp đồng Escrow, giúp đơn giản hóa trải nghiệm người dùng.

4. Doanh thu từ token riêng (Platform Token)
   Cách hoạt động: Phát hành token riêng của nền tảng, yêu cầu sử dụng token này để thanh toán phí hoặc truy cập dịch vụ, tạo doanh thu từ việc bán token hoặc staking.
   Ví dụ thực tế:

   - Blocklancer sử dụng token LNC để thanh toán phí và bỏ phiếu trong "Token Holder Tribunal" cho tranh chấp.
   - Bondex yêu cầu khóa token TIME để nhận ưu đãi.
   - Áp dụng cho bạn: Bạn có thể tạo một token riêng (ví dụ: "FREELANCE_TOKEN"), yêu cầu client và freelancer sử dụng token này để thanh toán phí mốc tiến độ, đồng thời bán token qua ICO hoặc sàn giao dịch.

5. Phí quảng cáo hoặc ưu tiên hiển thị (Featured Listings)
   Cách hoạt động: Cho phép client trả phí để ưu tiên hiển thị công việc của họ, hoặc freelancer trả phí để hồ sơ được nổi bật hơn trên giao diện ngoài chuỗi.
   Ví dụ thực tế:
   Upwork cho phép client trả thêm để "featured" công việc, tăng khả năng thu hút freelancer chất lượng (Upwork Customer Service).
   Freelancer.com cũng có tính năng tương tự với chi phí bổ sung (Freelancer.com).
   Áp dụng cho bạn: Bạn có thể tích hợp tính năng này vào phần ngoài chuỗi, thu phí bằng USDT hoặc token riêng để client hoặc freelancer được ưu tiên.

6. Phí giải quyết tranh chấp (Dispute Resolution Fees)
   Cách hoạt động: Thu phí từ một hoặc cả hai bên khi xảy ra tranh chấp, đặc biệt nếu cần trọng tài hoặc bỏ phiếu cộng đồng (DAO).
   Ví dụ thực tế: Blocklancer sử dụng cơ chế "Token Holder Tribunal" và có thể thu phí để tham gia quá trình này.
   Áp dụng cho bạn: Với mỗi tranh chấp trong mốc tiến độ, bạn có thể thu phí nhỏ (ví dụ: 5-10 USDT) từ bên khởi kiện để bù chi phí vận hành trọng tài.
   So sánh với Upwork

### Upwork kiếm doanh thu chủ yếu từ:

- Phí giao dịch: 20% cho dự án dưới $500, 10% từ $500-$10,000, 5% trên $10,000 từ freelancer, cộng thêm 2.75% phí xử lý thanh toán từ client (CoinCentral - Upwork Revenue).
- Phí subscription: Freelancer Plus ($14.99/tháng) để tăng cơ hội đấu thầu.
- Tổng ước tính: Upwork kiếm khoảng $68-70 triệu mỗi năm từ các nguồn này (CoinCentral).
- Các nền tảng blockchain thường có phí thấp hơn (2-10%) nhờ loại bỏ trung gian, nhưng bù lại họ tận dụng token riêng hoặc phí dịch vụ để duy trì hoạt động.

Đề xuất cho hệ thống của bạn
Với mô hình mốc tiến độ trên blockchain:

- Nguồn doanh thu chính: Thu phí giao dịch 3-5% từ mỗi mốc tiến độ giải ngân, áp dụng cho cả client và freelancer để cân bằng chi phí.
- Nguồn bổ sung:
  - Phí khởi tạo hợp đồng Escrow (1-2 USDT) để bù chi phí gas.
  - Tính năng cao cấp (subscription 5-10 USDT/tháng) cho ưu tiên hiển thị hoặc phân tích công việc.
  - Phát hành token riêng để thanh toán phí và khuyến khích người dùng staking.
  - Ưu điểm: Phí thấp hơn Upwork, tận dụng blockchain để giảm chi phí vận hành, linh hoạt cho dự án lớn.

Kết luận
Doanh thu của các dự án tương tự đến từ phí giao dịch, dịch vụ cao cấp, token riêng, và đôi khi phí quảng cáo hoặc tranh chấp. Với hệ thống của bạn, tập trung vào mô hình mốc tiến độ, bạn có thể kết hợp phí giao dịch thấp (3-5%) với các nguồn bổ sung như token hoặc phí khởi tạo để tạo dòng doanh thu bền vững, đồng thời giữ lợi thế cạnh tranh so với các nền tảng truyền thống như Upwork.
