-- ========================================
-- WEBBANHANG MASTER DATABASE SETUP
-- ========================================
-- File này chứa toàn bộ cấu trúc database cho hệ thống TITI Shop
-- Bao gồm: tables, roles, sample data, vouchers, order management
-- Chạy file này để tạo database hoàn chỉnh trên máy mới
-- Version: 2.0 (Updated with vouchers & enhanced order management)
-- ========================================

-- Tạo database nếu chưa tồn tại
DROP DATABASE IF EXISTS webbanhang;
CREATE DATABASE webbanhang CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE webbanhang;

-- ========================================
-- BẢNG USERS (Người dùng)
-- ========================================
CREATE TABLE users ( 
    id INT AUTO_INCREMENT PRIMARY KEY, 
    username VARCHAR(255) NOT NULL UNIQUE, 
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL, 
    avatar VARCHAR(255) DEFAULT NULL,
    age INT DEFAULT NULL,    role ENUM('admin', 'staff', 'customer') NOT NULL DEFAULT 'customer',
    status ENUM('pending', 'approved', 'rejected', 'suspended') NOT NULL DEFAULT 'approved',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP 
);

-- ========================================
-- BẢNG CATEGORIES (Danh mục sản phẩm)
-- ========================================
CREATE TABLE categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ========================================
-- BẢNG PRODUCTS (Sản phẩm)
-- ========================================
CREATE TABLE products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    image VARCHAR(255),
    category_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL
);

-- ========================================
-- BẢNG VOUCHERS (Mã giảm giá)
-- ========================================
CREATE TABLE vouchers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    discount_type ENUM('percentage', 'fixed') NOT NULL DEFAULT 'percentage',
    discount_value DECIMAL(10, 2) NOT NULL,
    min_order_amount DECIMAL(10, 2) DEFAULT 0,
    max_discount_amount DECIMAL(10, 2) NULL,
    applies_to ENUM('all_products', 'specific_products', 'specific_categories') NOT NULL DEFAULT 'all_products',
    product_ids JSON NULL,
    category_ids JSON NULL,
    usage_limit INT NULL,
    used_count INT DEFAULT 0,
    start_date DATETIME NOT NULL,
    end_date DATETIME NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ========================================
-- BẢNG ORDERS (Đơn hàng) - Enhanced with voucher & status management
-- ========================================
CREATE TABLE orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    address TEXT NOT NULL,
    subtotal DECIMAL(10, 2) NOT NULL DEFAULT 0,
    discount_amount DECIMAL(10, 2) DEFAULT 0,
    total_amount DECIMAL(10, 2) NOT NULL,
    voucher_id INT NULL,
    voucher_code VARCHAR(50) NULL,
    status ENUM(
        'pending',      -- Chờ xử lý
        'confirmed',    -- Đã xác nhận
        'processing',   -- Đang xử lý
        'packed',       -- Đã đóng gói
        'shipped',      -- Đã gửi hàng
        'delivered',    -- Đã giao hàng
        'cancelled',    -- Đã hủy
        'returned'      -- Đã trả hàng
    ) DEFAULT 'pending',
    admin_notes TEXT,
    estimated_delivery DATE,
    tracking_number VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (voucher_id) REFERENCES vouchers(id) ON DELETE SET NULL
);

-- ========================================
-- BẢNG ORDER_ITEMS (Chi tiết đơn hàng)
-- ========================================
CREATE TABLE order_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT,
    product_name VARCHAR(255) NOT NULL,
    quantity INT NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE SET NULL
);

-- ========================================
-- BẢNG ORDER_STATUS_HISTORY (Lịch sử trạng thái đơn hàng)
-- ========================================
CREATE TABLE order_status_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    status VARCHAR(50) NOT NULL,
    notes TEXT,
    changed_by INT,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (changed_by) REFERENCES users(id) ON DELETE SET NULL
);

-- ========================================
-- BẢNG VOUCHER_USAGE (Lịch sử sử dụng voucher)
-- ========================================
CREATE TABLE voucher_usage (
    id INT AUTO_INCREMENT PRIMARY KEY,
    voucher_id INT NOT NULL,
    order_id INT NOT NULL,
    user_id INT NULL,
    discount_amount DECIMAL(10, 2) NOT NULL,
    used_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (voucher_id) REFERENCES vouchers(id) ON DELETE CASCADE,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

-- ========================================
-- BẢNG PERMISSIONS (Quyền hạn - Tùy chọn)
-- ========================================
CREATE TABLE permissions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ========================================
-- BẢNG ROLE_PERMISSIONS (Vai trò - Quyền hạn)
-- ========================================
CREATE TABLE role_permissions (
    role_id VARCHAR(20) NOT NULL,
    permission_id INT NOT NULL,
    PRIMARY KEY (role_id, permission_id),
    FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE
);

-- ========================================
-- DỮ LIỆU MẪU - USERS (Admin, Staff, Customer)
-- ========================================

-- ADMIN ACCOUNTS
-- Username: admin, Password: admin123
INSERT INTO users (username, email, password, role, status) 
VALUES ('admin', 'admin@titishop.com', '$2y$10$VPGGGPOy3yqzKCNQnWxPKu7xIEqxsszKw1XmQea7d4wPPsG5YrRxO', 'admin', 'approved');

-- Username: Admin1, Password: Admin@123
INSERT INTO users (username, email, password, role, status) 
VALUES ('Admin1', 'admin1@titishop.com', '$2y$10$7HdQJgA5XYBQXJLrD0gfbuJkGWc6eLJqBWDBOuYU0Vm0qz0QgWPM.', 'admin', 'approved');

-- Username: Admin2, Password: Admin@123
INSERT INTO users (username, email, password, role, status) 
VALUES ('Admin2', 'admin2@titishop.com', '$2y$10$7HdQJgA5XYBQXJLrD0gfbuJkGWc6eLJqBWDBOuYU0Vm0qz0QgWPM.', 'admin', 'approved');

-- STAFF ACCOUNTS  
-- Username: Staff1, Password: Staff@123
INSERT INTO users (username, email, password, role, status) 
VALUES ('Staff1', 'staff1@titishop.com', '$2y$10$Sx/sD.zUFc3eVvYFyJT/AuWVFRY.nvGUh4HL0JxCwGSN32Sw/PkVq', 'staff', 'approved');

-- Username: Staff2, Password: Staff@123  
INSERT INTO users (username, email, password, role, status) 
VALUES ('Staff2', 'staff2@titishop.com', '$2y$10$Sx/sD.zUFc3eVvYFyJT/AuWVFRY.nvGUh4HL0JxCwGSN32Sw/PkVq', 'staff', 'approved');

-- CUSTOMER ACCOUNTS
-- Username: Customer1, Password: Customer@123
INSERT INTO users (username, email, password, role, status) 
VALUES ('Customer1', 'customer1@titishop.com', '$2y$10$d.FiNBd6RcJgUXVw7YqHQekCVfLAT6BUezxVnVDOW0DnSvQXQCwA.', 'customer', 'approved');

-- Username: Customer2, Password: Customer@123
INSERT INTO users (username, email, password, role, status) 
VALUES ('Customer2', 'customer2@titishop.com', '$2y$10$d.FiNBd6RcJgUXVw7YqHQekCVfLAT6BUezxVnVDOW0DnSvQXQCwA.', 'customer', 'approved');

-- ========================================
-- DỮ LIỆU MẪU - CATEGORIES
-- ========================================
INSERT INTO categories (name, description) VALUES 
('Điện thoại di động', 'Các loại điện thoại di động thông minh từ các nhãn hiệu nổi tiếng'),
('Laptop', 'Máy tính xách tay cho công việc và giải trí'),
('Tablet', 'Máy tính bảng cho học tập và giải trí'),
('Phụ kiện', 'Các phụ kiện công nghệ như tai nghe, sạc, ốp lưng'),
('Đồng hồ thông minh', 'Smartwatch và đồng hồ thể thao');

-- ========================================
-- DỮ LIỆU MẪU - PRODUCTS (ĐIỆN THOẠI)
-- ========================================
INSERT INTO products (name, description, price, category_id, image) VALUES 
('iPhone 15 Pro Max', 'Điện thoại iPhone 15 Pro Max mới nhất với chip A17 Pro, camera 48MP và màn hình Super Retina XDR 6.7 inch. Pin siêu bền, chống nước IP68.', 28990000, 1, 'iphone15promax.jpg'),

('Samsung Galaxy S24 Ultra', 'Flagship Android với bút S Pen, camera 200MP, màn hình Dynamic AMOLED 6.8 inch và chip Snapdragon 8 Gen 3. Hỗ trợ AI và chụp ảnh chuyên nghiệp.', 26990000, 1, 'galaxys24ultra.jpg'),

('Xiaomi 14 Ultra', 'Camera Leica đỉnh cao với cảm biến chính 50MP, màn hình AMOLED 6.73 inch 120Hz, chip Snapdragon 8 Gen 3 và sạc nhanh 90W.', 22990000, 1, 'xiaomi14ultra.jpg'),

('OPPO Find X7 Ultra', 'Thiết kế cao cấp với camera Hasselblad, màn hình cong 6.82 inch, chip Snapdragon 8 Gen 3 và công nghệ sạc siêu tốc 100W.', 24990000, 1, 'oppofindx7ultra.jpg'),

('iPhone 14', 'iPhone 14 với chip A15 Bionic, camera kép 12MP, màn hình Super Retina XDR 6.1 inch. Thiết kế bền bỉ, hiệu năng mạnh mẽ.', 19990000, 1, 'iphone14.jpg'),

('Samsung Galaxy A55', 'Điện thoại tầm trung với camera 50MP, màn hình Super AMOLED 6.6 inch, chip Exynos 1480 và pin 5000mAh. Giá cả phải chăng.', 8990000, 1, 'galaxya55.jpg'),

('Xiaomi Redmi Note 13 Pro', 'Smartphone gaming với màn hình AMOLED 6.67 inch 120Hz, camera 200MP, chip MediaTek Dimensity 7200 và pin khủng 5100mAh.', 6990000, 1, 'redminote13pro.jpg'),

('Realme GT 5 Pro', 'Performance phone với chip Snapdragon 8 Gen 3, màn hình cong 6.78 inch, camera 50MP và sạc nhanh 100W. Thiết kế thể thao.', 12990000, 1, 'realmegt5pro.jpg'),

('Vivo V30 Pro', 'Chuyên gia selfie với camera trước 50MP, màn hình cong 6.78 inch, chip MediaTek Dimensity 8200 và thiết kế mỏng nhẹ sang trọng.', 11990000, 1, 'vivov30pro.jpg'),

('Honor Magic6 Pro', 'Công nghệ AI tiên tiến với camera 50MP, màn hình OLED 6.8 inch, chip Snapdragon 8 Gen 3 và pin 5600mAh siêu bền.', 18990000, 1, 'honormagic6pro.jpg');

-- ========================================
-- DỮ LIỆU MẪU - PRODUCTS (LAPTOP)
-- ========================================
INSERT INTO products (name, description, price, category_id, image) VALUES 
('MacBook Pro 14 inch M3', 'Laptop chuyên nghiệp với chip M3, màn hình Liquid Retina XDR 14 inch, 16GB RAM và SSD 512GB. Hoàn hảo cho developer và designer.', 45990000, 2, 'macbookpro14.jpg'),

('Dell XPS 13', 'Ultrabook cao cấp với màn hình InfinityEdge 13.4 inch, Intel Core i7, 16GB RAM và thiết kế siêu mỏng nhẹ chỉ 1.2kg.', 32990000, 2, 'dellxps13.jpg'),

('ASUS ROG Strix G15', 'Gaming laptop với RTX 4060, AMD Ryzen 7, màn hình 15.6 inch 144Hz và hệ thống tản nhiệt ROG Intelligent Cooling.', 25990000, 2, 'asusrogstrix.jpg'),

('HP Spectre x360', 'Laptop 2-in-1 cao cấp với màn hình cảm ứng 13.5 inch, Intel Core i7, 16GB RAM và thiết kế xoay 360 độ sang trọng.', 28990000, 2, 'hpspectre.jpg'),

('Lenovo ThinkPad X1 Carbon', 'Business laptop với độ bền quân đội, màn hình 14 inch, Intel Core i7, 16GB RAM và pin 15 giờ sử dụng.', 35990000, 2, 'thinkpadx1.jpg');

-- ========================================
-- DỮ LIỆU MẪU - PRODUCTS (TABLET)
-- ========================================
INSERT INTO products (name, description, price, category_id, image) VALUES 
('iPad Pro 12.9 inch M2', 'Tablet chuyên nghiệp với chip M2, màn hình Liquid Retina XDR 12.9 inch, hỗ trợ Apple Pencil và Magic Keyboard.', 29990000, 3, 'ipadpro129.jpg'),

('Samsung Galaxy Tab S9 Ultra', 'Android tablet cao cấp với màn hình AMOLED 14.6 inch, S Pen đi kèm và hiệu năng Snapdragon 8 Gen 2 mạnh mẽ.', 24990000, 3, 'galaxytabs9.jpg'),

('iPad Air', 'Tablet cân bằng giữa hiệu năng và giá cả với chip M1, màn hình 10.9 inch và thiết kế mỏng nhẹ, đa màu sắc.', 14990000, 3, 'ipadair.jpg');

-- ========================================
-- DỮ LIỆU MẪU - PRODUCTS (PHỤ KIỆN)
-- ========================================
INSERT INTO products (name, description, price, category_id, image) VALUES 
('AirPods Pro 2', 'Tai nghe không dây cao cấp với chống ồn chủ động, âm thanh không gian và hộp sạc MagSafe.', 5990000, 4, 'airpodspro2.jpg'),

('Samsung Galaxy Buds2 Pro', 'Tai nghe true wireless với ANC thông minh, âm thanh 360 độ và khả năng chống nước IPX7.', 3990000, 4, 'galaxybuds2pro.jpg'),

('Anker PowerBank 20000mAh', 'Pin dự phòng dung lượng cao với sạc nhanh PD 22.5W, 3 cổng sạc và màn hình LCD hiển thị dung lượng.', 890000, 4, 'ankerpowerbank.jpg'),

('Belkin MagSafe Charger', 'Đế sạc không dây MagSafe 15W cho iPhone, thiết kế tối giản và sạc nhanh an toàn.', 1290000, 4, 'belkinmagsafe.jpg');

-- ========================================
-- DỮ LIỆU MẪU - PRODUCTS (ĐỒNG HỒ)
-- ========================================
INSERT INTO products (name, description, price, category_id, image) VALUES 
('Apple Watch Series 9', 'Smartwatch cao cấp với chip S9, màn hình Always-On Retina, GPS + Cellular và tính năng sức khỏe toàn diện.', 9990000, 5, 'applewatch9.jpg'),

('Samsung Galaxy Watch6', 'Đồng hồ thông minh Android với thiết kế cổ điển, theo dõi sức khỏe 24/7 và pin 40 giờ sử dụng.', 6990000, 5, 'galaxywatch6.jpg'),

('Amazfit GTR 4', 'Smartwatch thể thao với pin 14 ngày, GPS dual-band, 150+ chế độ thể thao và thiết kế cứng cáp.', 3990000, 5, 'amazfitgtr4.jpg');

-- ========================================
-- DỮ LIỆU MẪU - VOUCHERS
-- ========================================
INSERT INTO vouchers (code, name, description, discount_type, discount_value, min_order_amount, max_discount_amount, applies_to, start_date, end_date, is_active) VALUES
('WELCOME10', 'Voucher chào mừng', 'Giảm 10% cho khách hàng mới, áp dụng cho đơn hàng từ 100.000đ', 'percentage', 10.00, 100000, 50000, 'all_products', '2024-01-01 00:00:00', '2024-12-31 23:59:59', TRUE),
('FREESHIP', 'Miễn phí vận chuyển', 'Giảm 30.000đ phí vận chuyển cho đơn hàng từ 200.000đ', 'fixed', 30000.00, 200000, NULL, 'all_products', '2024-01-01 00:00:00', '2024-12-31 23:59:59', TRUE),
('SUMMER20', 'Voucher mùa hè', 'Giảm 20% tối đa 100.000đ cho đơn hàng từ 500.000đ', 'percentage', 20.00, 500000, 100000, 'all_products', '2024-06-01 00:00:00', '2024-08-31 23:59:59', TRUE),
('NEWUSER50', 'Khách hàng mới', 'Giảm 50.000đ cho khách hàng đăng ký lần đầu', 'fixed', 50000.00, 150000, NULL, 'all_products', '2024-01-01 00:00:00', '2024-12-31 23:59:59', TRUE),
('VIP15', 'VIP Member', 'Giảm 15% cho thành viên VIP, không giới hạn số tiền', 'percentage', 15.00, 300000, 200000, 'all_products', '2024-01-01 00:00:00', '2024-12-31 23:59:59', TRUE);

-- ========================================
-- DỮ LIỆU MẪU - PERMISSIONS
-- ========================================
INSERT INTO permissions (name, description) VALUES 
('manage_products', 'Quản lý sản phẩm - thêm, sửa, xóa'),
('manage_categories', 'Quản lý danh mục sản phẩm'),
('manage_orders', 'Quản lý đơn hàng'),
('view_reports', 'Xem báo cáo doanh thu'),
('manage_users', 'Quản lý người dùng - chỉ dành cho Admin'),
('approve_staff', 'Duyệt tài khoản nhân viên - chỉ dành cho Admin'),
('manage_vouchers', 'Quản lý mã giảm giá'),
('view_analytics', 'Xem thống kê chi tiết');

-- ========================================
-- DỮ LIỆU MẪU - ROLE PERMISSIONS
-- ========================================
INSERT INTO role_permissions (role_id, permission_id) VALUES 
-- Admin có tất cả quyền
('admin', 1), ('admin', 2), ('admin', 3), ('admin', 4), ('admin', 5), ('admin', 6), ('admin', 7), ('admin', 8),
-- Staff có quyền quản lý sản phẩm, danh mục, đơn hàng, xem báo cáo và voucher
('staff', 1), ('staff', 2), ('staff', 3), ('staff', 4), ('staff', 7);

-- ========================================
-- DỮ LIỆU MẪU - SAMPLE ORDERS (Để test hệ thống)
-- ========================================
INSERT INTO orders (user_id, name, email, phone, address, subtotal, discount_amount, total_amount, voucher_id, voucher_code, status, admin_notes, created_at) VALUES
(6, 'Nguyễn Văn A', 'customer1@titishop.com', '0901234567', '123 Đường ABC, Quận 1, TP.HCM', 29990000, 0, 29990000, NULL, NULL, 'pending', NULL, '2024-01-15 10:30:00'),
(7, 'Trần Thị B', 'customer2@titishop.com', '0912345678', '456 Đường XYZ, Quận 3, TP.HCM', 6990000, 50000, 6940000, 4, 'NEWUSER50', 'confirmed', 'Đơn hàng đã được xác nhận và sẽ được xử lý trong 1-2 ngày làm việc', '2024-01-16 14:20:00'),
(6, 'Nguyễn Văn A', 'customer1@titishop.com', '0901234567', '123 Đường ABC, Quận 1, TP.HCM', 45990000, 30000, 45960000, 2, 'FREESHIP', 'processing', 'Đang xử lý và đóng gói đơn hàng', '2024-01-17 09:15:00');

-- ========================================
-- DỮ LIỆU MẪU - ORDER ITEMS
-- ========================================
INSERT INTO order_items (order_id, product_id, product_name, quantity, price) VALUES
(1, 16, 'iPad Pro 12.9 inch M2', 1, 29990000),
(2, 7, 'Xiaomi Redmi Note 13 Pro', 1, 6990000),
(3, 11, 'MacBook Pro 14 inch M3', 1, 45990000);

-- ========================================
-- DỮ LIỆU MẪU - ORDER STATUS HISTORY
-- ========================================
INSERT INTO order_status_history (order_id, status, notes, changed_by, changed_at) VALUES
(1, 'pending', 'Đơn hàng được tạo', NULL, '2024-01-15 10:30:00'),
(2, 'pending', 'Đơn hàng được tạo', NULL, '2024-01-16 14:20:00'),
(2, 'confirmed', 'Đơn hàng đã được xác nhận bởi admin', 1, '2024-01-16 15:30:00'),
(3, 'pending', 'Đơn hàng được tạo', NULL, '2024-01-17 09:15:00'),
(3, 'confirmed', 'Đơn hàng đã được xác nhận', 1, '2024-01-17 10:00:00'),
(3, 'processing', 'Bắt đầu xử lý và đóng gói đơn hàng', 1, '2024-01-17 11:30:00');

-- ========================================
-- DỮ LIỆU MẪU - VOUCHER USAGE
-- ========================================
INSERT INTO voucher_usage (voucher_id, order_id, user_id, discount_amount, used_at) VALUES
(4, 2, 7, 50000, '2024-01-16 14:20:00'),
(2, 3, 6, 30000, '2024-01-17 09:15:00');

-- ========================================
-- CẬP NHẬT VOUCHER USAGE COUNT
-- ========================================
UPDATE vouchers SET used_count = 1 WHERE id = 2;
UPDATE vouchers SET used_count = 1 WHERE id = 4;

-- ========================================
-- HOÀN THÀNH SETUP
-- ========================================
-- Database đã được tạo thành công!
-- 
-- DANH SÁCH TÀI KHOẢN MẪU:
-- 
-- ADMIN ACCOUNTS (3):
-- 1. Username: admin     | Password: admin123     | Email: admin@titishop.com
-- 2. Username: Admin1    | Password: Admin@123    | Email: admin1@titishop.com  
-- 3. Username: Admin2    | Password: Admin@123    | Email: admin2@titishop.com
--
-- STAFF ACCOUNTS (2):
-- 1. Username: Staff1    | Password: Staff@123    | Email: staff1@titishop.com
-- 2. Username: Staff2    | Password: Staff@123    | Email: staff2@titishop.com
--
-- CUSTOMER ACCOUNTS (2):  
-- 1. Username: Customer1 | Password: Customer@123 | Email: customer1@titishop.com
-- 2. Username: Customer2 | Password: Customer@123 | Email: customer2@titishop.com
--
-- VOUCHER CODES:
-- 1. WELCOME10   - Giảm 10% (tối đa 50k) cho đơn từ 100k
-- 2. FREESHIP    - Giảm 30k phí ship cho đơn từ 200k  
-- 3. SUMMER20    - Giảm 20% (tối đa 100k) cho đơn từ 500k
-- 4. NEWUSER50   - Giảm 50k cho khách hàng mới, đơn từ 150k
-- 5. VIP15       - Giảm 15% (tối đa 200k) cho thành viên VIP

SELECT 'Database WEBBANHANG đã được tạo thành công!' as message;
SELECT 'Tổng cộng 7 tài khoản: 3 Admin + 2 Staff + 2 Customer' as accounts_info;
SELECT 'Tổng cộng 5 vouchers đã sẵn sàng sử dụng' as vouchers_info;
SELECT 'Tổng cộng 3 đơn hàng mẫu với các trạng thái khác nhau' as orders_info;
SELECT COUNT(*) as total_products FROM products;
SELECT COUNT(*) as total_categories FROM categories;
SELECT COUNT(*) as total_users FROM users;
SELECT COUNT(*) as total_vouchers FROM vouchers;
SELECT COUNT(*) as total_orders FROM orders;
