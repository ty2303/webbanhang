<?php
/**
 * ========================================
 * WEBBANHANG SETUP INSTALLER
 * ========================================
 * File setup tự động cho hệ thống TITI Shop
 * Chạy file này để cài đặt hoàn chỉnh database và cấu hình
 * 
 * Cách sử dụng:
 * 1. Copy toàn bộ thư mục webbanhang vào htdocs/www
 * 2. Truy cập: http://localhost/webbanhang/setup_installer.php
 * 3. Nhập thông tin database
 * 4. Click "Cài đặt"
 * ========================================
 */

session_start();

// Cấu hình
$setup_file = __DIR__ . '/database/master_setup.sql';
$config_file = __DIR__ . '/app/config/database.php';
$required_dirs = [
    __DIR__ . '/public/uploads',
    __DIR__ . '/app/config',
];

// Kiểm tra setup đã hoàn thành chưa
if (file_exists(__DIR__ . '/.setup_complete') && !isset($_GET['force'])) {
    die('Setup đã hoàn thành. Nếu bạn muốn cài đặt lại, hãy xóa file .setup_complete hoặc thêm ?force=1 vào URL.');
}

$errors = [];
$success = false;
$step = isset($_GET['step']) ? (int)$_GET['step'] : 1;

// Kiểm tra yêu cầu hệ thống
function checkSystemRequirements() {
    $requirements = [
        'PHP Version >= 7.4' => version_compare(PHP_VERSION, '7.4.0', '>='),
        'PDO Extension' => extension_loaded('pdo'),
        'PDO MySQL Extension' => extension_loaded('pdo_mysql'),
        'JSON Extension' => extension_loaded('json'),
        'GD Extension' => extension_loaded('gd'),
        'FileInfo Extension' => extension_loaded('fileinfo'),
    ];
    
    $failed = array_filter($requirements, function($met) {
        return !$met;
    });
    
    return ['met' => empty($failed), 'requirements' => $requirements];
}

// Kiểm tra và tạo thư mục
function createRequiredDirectories($dirs) {
    foreach ($dirs as $dir) {
        if (!file_exists($dir)) {
            if (!@mkdir($dir, 0755, true)) {
                return false;
            }
        } elseif (!is_writable($dir)) {
            return false;
        }
    }
    return true;
}

// Xử lý form
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $db_host = $_POST['db_host'] ?? 'localhost';
    $db_name = $_POST['db_name'] ?? 'webbanhang';
    $db_user = $_POST['db_user'] ?? 'root';
    $db_pass = $_POST['db_pass'] ?? '';
    
    // Validate input
    if (empty($db_host)) $errors[] = "Vui lòng nhập hostname database";
    if (empty($db_name)) $errors[] = "Vui lòng nhập tên database";
    if (empty($db_user)) $errors[] = "Vui lòng nhập username database";
    
    if (empty($errors)) {
        try {
            // Kiểm tra thư mục
            if (!createRequiredDirectories($required_dirs)) {
                throw new Exception("Không thể tạo thư mục cần thiết. Vui lòng kiểm tra quyền ghi.");
            }
            
            // Test kết nối database
            $pdo = new PDO("mysql:host=$db_host", $db_user, $db_pass);
            $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
            
            // Đọc và thực thi file SQL
            if (file_exists($setup_file)) {
                $sql = file_get_contents($setup_file);
                
                // Thực thi từng câu lệnh
                $statements = array_filter(
                    array_map('trim', 
                        explode(';', $sql)
                    ),
                    function($stmt) {
                        return !empty($stmt) && strpos($stmt, '--') !== 0;
                    }
                );
                
                foreach ($statements as $statement) {
                    try {
                        $pdo->exec($statement);
                    } catch (PDOException $e) {
                        // Log lỗi nhưng tiếp tục nếu không phải lỗi nghiêm trọng
                        error_log("SQL Error: " . $e->getMessage());
                    }
                }
                
                // Tạo file config database
                $config_content = "<?php
class Database {
    private \$host = '$db_host';
    private \$db_name = '$db_name';
    private \$username = '$db_user';
    private \$password = '$db_pass';
    public \$conn;

    public function getConnection() {
        \$this->conn = null;
        try {
            \$this->conn = new PDO(
                \"mysql:host=\" . \$this->host . 
                \";dbname=\" . \$this->db_name . 
                \";charset=utf8mb4\", 
                \$this->username, 
                \$this->password
            );
            \$this->conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
            \$this->conn->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
            \$this->conn->setAttribute(PDO::ATTR_EMULATE_PREPARES, false);
        } catch(PDOException \$exception) {
            echo \"Connection error: \" . \$exception->getMessage();
        }
        return \$this->conn;
    }
}";
                
                file_put_contents($config_file, $config_content);
                
                // Đánh dấu setup hoàn thành
                file_put_contents(__DIR__ . '/.setup_complete', json_encode([
                    'timestamp' => date('Y-m-d H:i:s'),
                    'version' => '1.0.0',
                    'database' => $db_name,
                    'php_version' => PHP_VERSION
                ]));
                
                $success = true;
                
            } else {
                throw new Exception("Không tìm thấy file setup SQL");
            }
            
        } catch (Exception $e) {
            $errors[] = "Lỗi: " . $e->getMessage();
        }
    }
}

// Kiểm tra yêu cầu hệ thống
$system_check = checkSystemRequirements();

?>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>TITI Shop - Cài đặt hệ thống</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body { background: #f8f9fa; }
        .setup-container {
            max-width: 800px;
            margin: 50px auto;
            padding: 30px;
            background: white;
            border-radius: 10px;
            box-shadow: 0 0 20px rgba(0,0,0,0.1);
        }
        .requirement-item {
            padding: 10px;
            border-bottom: 1px solid #eee;
        }
        .requirement-item:last-child {
            border-bottom: none;
        }
    </style>
</head>
<body>
    <div class="setup-container">
        <h1 class="text-center mb-4">TITI Shop - Cài đặt hệ thống</h1>
        
        <?php if (!empty($errors)): ?>
            <div class="alert alert-danger">
                <ul class="mb-0">
                    <?php foreach ($errors as $error): ?>
                        <li><?php echo htmlspecialchars($error); ?></li>
                    <?php endforeach; ?>
                </ul>
            </div>
        <?php endif; ?>

        <?php if ($success): ?>
            <div class="alert alert-success">
                <h4 class="alert-heading">Cài đặt thành công!</h4>
                <p>Hệ thống đã được cài đặt thành công. Bạn có thể:</p>
                <hr>
                <p class="mb-0">
                    <a href="/webbanhang/" class="btn btn-primary">Truy cập trang chủ</a>
                    <a href="/webbanhang/tkadmin.php" class="btn btn-secondary">Đăng nhập Admin</a>
                </p>
                <hr>
                <h5>Thông tin đăng nhập mặc định:</h5>
                <ul>
                    <li>Admin: admin / admin123</li>
                    <li>Staff: Staff1 / Staff@123</li>
                    <li>Customer: Customer1 / Customer@123</li>
                </ul>
            </div>
        <?php else: ?>
            <?php if ($step === 1): ?>
                <div class="card mb-4">
                    <div class="card-header">
                        <h5 class="mb-0">Kiểm tra yêu cầu hệ thống</h5>
                    </div>
                    <div class="card-body">
                        <?php foreach ($system_check['requirements'] as $requirement => $met): ?>
                            <div class="requirement-item">
                                <i class="fas fa-<?php echo $met ? 'check text-success' : 'times text-danger'; ?>"></i>
                                <?php echo htmlspecialchars($requirement); ?>
                                <?php if ($met): ?>
                                    <span class="badge bg-success float-end">OK</span>
                                <?php else: ?>
                                    <span class="badge bg-danger float-end">Failed</span>
                                <?php endif; ?>
                            </div>
                        <?php endforeach; ?>
                        
                        <?php if ($system_check['met']): ?>
                            <div class="mt-3">
                                <a href="?step=2" class="btn btn-primary">Tiếp tục cài đặt</a>
                            </div>
                        <?php else: ?>
                            <div class="alert alert-warning mt-3">
                                Vui lòng đảm bảo tất cả yêu cầu hệ thống được đáp ứng trước khi tiếp tục.
                            </div>
                        <?php endif; ?>
                    </div>
                </div>
            <?php elseif ($step === 2): ?>
                <form method="post" action="">
                    <div class="mb-3">
                        <label for="db_host" class="form-label">Database Host:</label>
                        <input type="text" class="form-control" id="db_host" name="db_host" value="localhost" required>
                    </div>
                    
                    <div class="mb-3">
                        <label for="db_name" class="form-label">Database Name:</label>
                        <input type="text" class="form-control" id="db_name" name="db_name" value="webbanhang" required>
                    </div>
                    
                    <div class="mb-3">
                        <label for="db_user" class="form-label">Database Username:</label>
                        <input type="text" class="form-control" id="db_user" name="db_user" value="root" required>
                    </div>
                    
                    <div class="mb-3">
                        <label for="db_pass" class="form-label">Database Password:</label>
                        <input type="password" class="form-control" id="db_pass" name="db_pass">
                    </div>
                    
                    <div class="mb-3">
                        <a href="?step=1" class="btn btn-secondary">Quay lại</a>
                        <button type="submit" class="btn btn-primary">Cài đặt</button>
                    </div>
                </form>
            <?php endif; ?>
        <?php endif; ?>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script src="https://kit.fontawesome.com/a076d05399.js"></script>
</body>
</html>
