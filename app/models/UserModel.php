<?php
class UserModel
{
    private $conn;
    private $table = 'users';
    
    private static $apiKey = 're_Y6Dk3sdy_FsSdW6Vsv334mhCNm1MkG1fG';
    private static $apiUrl = 'https://api.resend.com/emails';
    
    // Định nghĩa các vai trò
    const ROLE_ADMIN = 'admin';
    const ROLE_STAFF = 'staff';
    const ROLE_CUSTOMER = 'customer';

    public function __construct($db)
    {
        $this->conn = $db;
    }    public function register($username, $email, $password, $avatar = null, $age = null, $role = self::ROLE_CUSTOMER, $status = 'approved')
    {
        // Validate input
        $errors = [];
        if (empty($username)) {
            $errors[] = "Tên đăng nhập không được để trống";
        }
        if (empty($email)) {
            $errors[] = "Email không được để trống";
        } elseif (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            $errors[] = "Email không hợp lệ";
        }
        if (empty($password)) {
            $errors[] = "Mật khẩu không được để trống";
        } elseif (strlen($password) < 6) {
            $errors[] = "Mật khẩu phải có ít nhất 6 ký tự";
        }

        if (!empty($errors)) {
            return $errors;
        }

        // Check if username already exists
        $stmt = $this->conn->prepare("SELECT id FROM {$this->table} WHERE username = ? LIMIT 1");
        $stmt->execute([$username]);
        if ($stmt->rowCount() > 0) {
            return ["Tên đăng nhập đã tồn tại"];
        }

        // Check if email already exists
        $stmt = $this->conn->prepare("SELECT id FROM {$this->table} WHERE email = ? LIMIT 1");
        $stmt->execute([$email]);
        if ($stmt->rowCount() > 0) {
            return ["Email đã tồn tại"];
        }        // Hash password
        $hashed_password = password_hash($password, PASSWORD_DEFAULT);        
        // Insert user
        $query = "INSERT INTO {$this->table} (username, email, password, avatar, age, role, status) VALUES (?, ?, ?, ?, ?, ?, ?)";
        $stmt = $this->conn->prepare($query);
        
        if ($stmt->execute([$username, $email, $hashed_password, $avatar, $age, $role, $status])) {
            $userId = $this->conn->lastInsertId();
            // Gửi email xác thực
            if($this->sendVerificationEmail($userId, $email, $username)) {
                return $userId;
            }
            return true;
        }
        
        return ["Đã xảy ra lỗi khi đăng ký"];
    }    public function login($username, $password)
    {
        if (empty($username) || empty($password)) {
            return ["Tên đăng nhập và mật khẩu không được để trống"];
        }

        $stmt = $this->conn->prepare("SELECT * FROM {$this->table} WHERE username = ? LIMIT 1");
        $stmt->execute([$username]);
          if ($stmt->rowCount() > 0) {
            $user = $stmt->fetch(PDO::FETCH_ASSOC);
            if ($user['status'] === 'pending') {
                return ["Tài khoản của bạn đang chờ được phê duyệt"];
            }
            if ($user['status'] === 'rejected') {
                return ["Tài khoản của bạn đã bị từ chối"];
            }
            if ($user['status'] === 'suspended') {
                return ["Tài khoản của bạn đã bị tạm khóa. Vui lòng liên hệ admin để được hỗ trợ."];
            }
            if (password_verify($password, $user['password'])) {
                // Remove password from array
                unset($user['password']);
                return $user;
            }
        }
        
        return ["Tên đăng nhập hoặc mật khẩu không đúng"];
    }    public function getUserById($id)
    {
        $stmt = $this->conn->prepare("SELECT id, username, email, avatar, age, role, status, created_at FROM {$this->table} WHERE id = ? LIMIT 1");
        $stmt->execute([$id]);
        
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }

    public function updateProfile($id, $email, $avatar = null, $age = null)
    {
        $query = "UPDATE {$this->table} SET email = ?, avatar = ?, age = ? WHERE id = ?";
        $stmt = $this->conn->prepare($query);
        
        return $stmt->execute([$email, $avatar, $age, $id]);
    }

    public function changePassword($id, $current_password, $new_password)
    {
        // Validate input
        if (empty($current_password) || empty($new_password)) {
            return ["Mật khẩu hiện tại và mật khẩu mới không được để trống"];
        }

        if (strlen($new_password) < 6) {
            return ["Mật khẩu mới phải có ít nhất 6 ký tự"];
        }

        // Get current user
        $stmt = $this->conn->prepare("SELECT password FROM {$this->table} WHERE id = ? LIMIT 1");
        $stmt->execute([$id]);
        $user = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!password_verify($current_password, $user['password'])) {
            return ["Mật khẩu hiện tại không đúng"];
        }

        // Hash new password
        $hashed_password = password_hash($new_password, PASSWORD_DEFAULT);

        // Update password
        $query = "UPDATE {$this->table} SET password = ? WHERE id = ?";
        $stmt = $this->conn->prepare($query);
        
        if ($stmt->execute([$hashed_password, $id])) {
            return true;
        }
        
        return ["Đã xảy ra lỗi khi đổi mật khẩu"];
    }

    // Thêm phương thức kiểm tra vai trò của người dùng
    public function getUserRole($userId)
    {
        $stmt = $this->conn->prepare("SELECT role FROM {$this->table} WHERE id = ? LIMIT 1");
        $stmt->execute([$userId]);
        $result = $stmt->fetch(PDO::FETCH_ASSOC);
        
        return $result ? $result['role'] : null;
    }
    
    // Thêm phương thức thay đổi vai trò cho người dùng
    public function changeUserRole($userId, $newRole)
    {
        if (!in_array($newRole, [self::ROLE_ADMIN, self::ROLE_STAFF, self::ROLE_CUSTOMER])) {
            return false;
        }
        
        $query = "UPDATE {$this->table} SET role = ? WHERE id = ?";
        $stmt = $this->conn->prepare($query);
        
        return $stmt->execute([$newRole, $userId]);
    }
      // Thêm phương thức lấy danh sách người dùng (dành cho Admin)
    public function getAllUsers()
    {
        $stmt = $this->conn->prepare("SELECT id, username, email, role, status, avatar, age, created_at FROM {$this->table} ORDER BY id DESC");
        $stmt->execute();
        
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
    
    // Phương thức đếm số lượng người dùng đang chờ duyệt
    public function getPendingUsersCount()
    {
        $stmt = $this->conn->prepare("SELECT COUNT(*) as count FROM {$this->table} WHERE status = 'pending'");
        $stmt->execute();
        $result = $stmt->fetch(PDO::FETCH_ASSOC);
        
        return $result ? (int)$result['count'] : 0;
    }
      // Phương thức lấy danh sách người dùng đang chờ duyệt
    public function getPendingUsers()
    {
        $stmt = $this->conn->prepare("SELECT id, username, email, role, status, avatar, age, created_at FROM {$this->table} WHERE status = 'pending' ORDER BY created_at ASC");
        $stmt->execute();
        
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
    
    // Phương thức phê duyệt người dùng
    public function approveUser($userId)
    {
        $query = "UPDATE {$this->table} SET status = 'approved' WHERE id = ?";
        $stmt = $this->conn->prepare($query);
        
        return $stmt->execute([$userId]);
    }    
    public function rejectUser($userId)
    {
        $query = "UPDATE {$this->table} SET status = 'rejected' WHERE id = ?";
        $stmt = $this->conn->prepare($query);
        
        return $stmt->execute([$userId]);
    }

    // Phương thức tạm khóa tài khoản
    public function suspendUser($userId)
    {
        $query = "UPDATE {$this->table} SET status = 'suspended' WHERE id = ?";
        $stmt = $this->conn->prepare($query);
        
        return $stmt->execute([$userId]);
    }

    // Phương thức mở khóa tài khoản
    public function unsuspendUser($userId)
    {
        $query = "UPDATE {$this->table} SET status = 'approved' WHERE id = ?";
        $stmt = $this->conn->prepare($query);
        
        return $stmt->execute([$userId]);
    }

    // Phương thức xóa tài khoản
    public function deleteUser($userId)
    {
        // Kiểm tra xem có phải admin không
        $stmt = $this->conn->prepare("SELECT role FROM {$this->table} WHERE id = ?");
        $stmt->execute([$userId]);
        $user = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($user && $user['role'] === self::ROLE_ADMIN) {
            return false; // Không cho phép xóa tài khoản admin
        }

        $query = "DELETE FROM {$this->table} WHERE id = ? AND role != ?";
        $stmt = $this->conn->prepare($query);
        
        return $stmt->execute([$userId, self::ROLE_ADMIN]);
    }

    // Phương thức gửi email xác thực
    public function sendVerificationEmail($userId, $email, $username)
    {
        try {
            // Tạo mã xác thực
            $verificationCode = bin2hex(random_bytes(16));
            
            // Lưu mã xác thực vào database
            $query = "UPDATE {$this->table} SET verification_code = ?, email_verified = 0 WHERE id = ?";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$verificationCode, $userId]);

            // URL xác thực
            $verificationUrl = "http://" . $_SERVER['HTTP_HOST'] . "/verify-email?code=" . $verificationCode;

            // Nội dung email
            $emailContent = "
                <h2>Xin chào {$username}!</h2>
                <p>Cảm ơn bạn đã đăng ký tài khoản. Vui lòng click vào link bên dưới để xác thực email của bạn:</p>
                <p><a href='{$verificationUrl}'>Xác thực email</a></p>
                <p>Nếu bạn không thực hiện yêu cầu này, vui lòng bỏ qua email này.</p>
            ";

            // Chuẩn bị dữ liệu gửi đi
            $data = [
                'from' => 'Webbanhang <onboarding@resend.dev>',
                'to' => [$email],
                'subject' => 'Xác thực email của bạn',
                'html' => $emailContent
            ];

            // Khởi tạo CURL
            $ch = curl_init(self::$apiUrl);
            
            // Cấu hình CURL
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($ch, CURLOPT_POST, true);
            curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
            curl_setopt($ch, CURLOPT_HTTPHEADER, [
                'Authorization: Bearer ' . self::$apiKey,
                'Content-Type: application/json'
            ]);
            
            // Thực hiện gửi request
            $response = curl_exec($ch);
            $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            $error = curl_error($ch);
            
            // Đóng kết nối CURL
            curl_close($ch);

            // Log kết quả để debug
            error_log("Email sending attempt to: " . $email);
            error_log("HTTP Code: " . $httpCode);
            error_log("Response: " . $response);
            if ($error) {
                error_log("Curl Error: " . $error);
            }

            // Kiểm tra kết quả
            $result = json_decode($response, true);
            return isset($result['id']);
            
        } catch (Exception $e) {
            error_log("Email sending error: " . $e->getMessage());
            return false;
        }
    }

    // Phương thức xác thực email
    public function verifyEmail($verificationCode)
    {
        // Kiểm tra mã xác thực
        $stmt = $this->conn->prepare("SELECT id FROM {$this->table} WHERE verification_code = ? LIMIT 1");
        $stmt->execute([$verificationCode]);
        
        if ($stmt->rowCount() > 0) {
            $user = $stmt->fetch(PDO::FETCH_ASSOC);
            
            // Cập nhật trạng thái xác thực
            $query = "UPDATE {$this->table} SET email_verified = 1, verification_code = NULL WHERE id = ?";
            $stmt = $this->conn->prepare($query);
            
            return $stmt->execute([$user['id']]);
        }
        
        return false;
    }    public function createPasswordResetToken($email)
    {
        error_log("Creating password reset token for email: " . $email);
        
        // Kiểm tra email tồn tại
        $query = "SELECT id FROM {$this->table} WHERE email = ?";
        $stmt = $this->conn->prepare($query);
        $stmt->execute([$email]);
        
        if (!$stmt->fetch()) {
            error_log("Email not found in users table: " . $email);
            return false;
        }        // Tạo mã xác nhận 6 số
        $token = str_pad(random_int(0, 999999), 6, '0', STR_PAD_LEFT);
        $expires = date('Y-m-d H:i:s', strtotime('+30 minutes'));
        
        error_log("Generated verification code: " . $token);
        error_log("Code expires at: " . $expires);
        
        // Xóa token cũ nếu có
        $query = "DELETE FROM password_resets WHERE email = ?";
        $stmt = $this->conn->prepare($query);
        $stmt->execute([$email]);
          // Lưu token vào database
        $query = "INSERT INTO password_resets (email, token, expires_at) VALUES (?, ?, ?)";
        $stmt = $this->conn->prepare($query);
        
        if ($stmt->execute([$email, $token, $expires])) {
            return $token;
        }
        return false;
    }    public function verifyPasswordResetToken($token)
    {
        if (empty($token)) {
            error_log("Token is empty");
            return false;
        }

        error_log("Verifying token: " . $token);
        error_log("Token length: " . strlen($token));
        
        // First check if token exists
        $query = "SELECT * FROM password_resets WHERE token = ? AND used = 0 AND expires_at > NOW()";
        $stmt = $this->conn->prepare($query);
        $stmt->execute([$token]);
        $tokenInfo = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$tokenInfo) {
            error_log("Token not found in database");
            return false;
        }
        
        error_log("Found token info: " . json_encode($tokenInfo));
        
        // Check if token is expired
        if (strtotime($tokenInfo['expires_at']) < time()) {
            error_log("Token has expired. Expires at: " . $tokenInfo['expires_at'] . ", Current time: " . date('Y-m-d H:i:s'));
            return false;
        }
        
        // Check if token is already used
        if ($tokenInfo['used'] == 1) {
            error_log("Token has already been used");
            return false;
        }
        
        $query = "SELECT email FROM password_resets 
                 WHERE token = ? AND expires_at > NOW() AND used = 0";
        $stmt = $this->conn->prepare($query);
        $stmt->execute([$token]);
        
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }

    public function resetPassword($email, $newPassword)
    {
        $hashedPassword = password_hash($newPassword, PASSWORD_DEFAULT);
        
        // Cập nhật mật khẩu mới
        $query = "UPDATE {$this->table} SET password = ? WHERE email = ?";
        $stmt = $this->conn->prepare($query);
        
        if ($stmt->execute([$hashedPassword, $email])) {
            // Đánh dấu token đã sử dụng
            $query = "UPDATE password_resets SET used = 1 WHERE email = ?";
            $stmt = $this->conn->prepare($query);
            $stmt->execute([$email]);
            return true;
        }
        return false;
    }
}
?>