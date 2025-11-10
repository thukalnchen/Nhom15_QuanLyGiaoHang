/// Validation utilities for authentication forms
/// Cung cấp các hàm validation chuyên nghiệp để tăng tính bảo mật và thực tế
/// Tương tự như các ứng dụng logistics như J&T Express

/// Password strength enum
enum PasswordStrength {
  weak, // Yếu
  medium, // Trung bình
  strong, // Mạnh
  veryStrong, // Rất mạnh
}

class ValidationUtils {
  // Regex patterns
  /// Email validation regex - kiểm tra định dạng email hợp lệ
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Vietnamese phone number regex - hỗ trợ định dạng số điện thoại Việt Nam
  /// Hỗ trợ: 0xxxxxxxxx (10 số) hoặc +84xxxxxxxxx
  /// Mobile: 03x, 05x, 07x, 08x, 09x
  /// Landline: 02x (Hà Nội, Hồ Chí Minh) hoặc mã vùng khác
  static final RegExp _phoneRegex = RegExp(
    r'^(?:\+84|0)(3[2-9]|5[6|8|9]|7[0|6-9]|8[1-6|8|9]|9[0-4|6-9]|2[0-9])[0-9]{7,8}$',
  );

  /// Password strength regex patterns
  static final RegExp _hasUpperCase = RegExp(r'[A-Z]');
  static final RegExp _hasLowerCase = RegExp(r'[a-z]');
  static final RegExp _hasDigits = RegExp(r'[0-9]');
  static final RegExp _hasSpecialChar = RegExp(r'[!@#$%^&*(),.?":{}|<>]');

  /// Common weak passwords - danh sách mật khẩu yếu phổ biến
  static const List<String> _commonPasswords = [
    'password',
    '123456',
    '12345678',
    '123456789',
    '1234567890',
    'qwerty',
    'abc123',
    'password1',
    '123123',
    'admin',
    'letmein',
    'welcome',
    'monkey',
    '1234567',
    'password123',
  ];

  /// Email validation
  /// Trả về null nếu hợp lệ, hoặc thông báo lỗi nếu không hợp lệ
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập email';
    }

    final email = value.trim().toLowerCase();

    // Kiểm tra định dạng email cơ bản
    if (!email.contains('@')) {
      return 'Email phải chứa ký tự @';
    }

    // Kiểm tra định dạng email bằng regex
    if (!_emailRegex.hasMatch(email)) {
      return 'Email không hợp lệ. Vui lòng kiểm tra lại định dạng';
    }

    // Kiểm tra độ dài email
    if (email.length > 254) {
      return 'Email quá dài (tối đa 254 ký tự)';
    }

    // Kiểm tra domain hợp lệ (có ít nhất một dấu chấm sau @)
    final parts = email.split('@');
    if (parts.length != 2 || parts[1].isEmpty || !parts[1].contains('.')) {
      return 'Email phải có domain hợp lệ';
    }

    // Kiểm tra không có khoảng trắng
    if (email.contains(' ')) {
      return 'Email không được chứa khoảng trắng';
    }

    return null;
  }

  /// Phone number validation (Vietnamese format)
  /// Trả về null nếu hợp lệ, hoặc thông báo lỗi nếu không hợp lệ
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập số điện thoại';
    }

    // Loại bỏ khoảng trắng, dấu gạch ngang, và dấu chấm
    String phone = value.trim().replaceAll(RegExp(r'[\s\-\.]'), '');

    // Chuẩn hóa: nếu bắt đầu bằng +84, chuyển thành 0
    if (phone.startsWith('+84')) {
      phone = '0${phone.substring(3)}';
    }

    // Kiểm tra chỉ chứa số (sau khi chuẩn hóa)
    if (!RegExp(r'^\d+$').hasMatch(phone)) {
      return 'Số điện thoại chỉ được chứa số';
    }

    // Kiểm tra độ dài (10 số cho số điện thoại Việt Nam)
    if (phone.length != 10) {
      return 'Số điện thoại Việt Nam phải có đúng 10 số';
    }

    // Kiểm tra bắt đầu bằng 0
    if (!phone.startsWith('0')) {
      return 'Số điện thoại Việt Nam phải bắt đầu bằng 0';
    }

    // Kiểm tra số thứ hai hợp lệ (2-9)
    // 02x: Hà Nội, Hồ Chí Minh (landline)
    // 03x, 05x, 07x, 08x, 09x: Mobile
    final secondDigit = int.tryParse(phone[1]);
    if (secondDigit == null || secondDigit < 2 || secondDigit > 9) {
      return 'Số điện thoại không hợp lệ. Số thứ hai phải từ 2-9';
    }

    return null;
  }

  /// Full name validation
  /// Trả về null nếu hợp lệ, hoặc thông báo lỗi nếu không hợp lệ
  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập họ và tên';
    }

    final name = value.trim();

    // Kiểm tra độ dài tối thiểu
    if (name.length < 2) {
      return 'Họ và tên phải có ít nhất 2 ký tự';
    }

    // Kiểm tra độ dài tối đa
    if (name.length > 100) {
      return 'Họ và tên quá dài (tối đa 100 ký tự)';
    }

    // Kiểm tra không chứa số
    if (RegExp(r'[0-9]').hasMatch(name)) {
      return 'Họ và tên không được chứa số';
    }

    // Kiểm tra không chứa ký tự đặc biệt (trừ dấu cách, dấu gạch ngang, dấu nháy)
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>\[\]\\/]').hasMatch(name)) {
      return 'Họ và tên không được chứa ký tự đặc biệt';
    }

    // Kiểm tra có ít nhất một khoảng trắng (họ và tên)
    if (!name.contains(' ')) {
      return 'Vui lòng nhập đầy đủ họ và tên (có khoảng trắng)';
    }

    // Kiểm tra không có nhiều khoảng trắng liên tiếp
    if (RegExp(r'\s{2,}').hasMatch(name)) {
      return 'Họ và tên không được chứa nhiều khoảng trắng liên tiếp';
    }

    return null;
  }

  /// Password strength analysis
  /// Phân tích độ mạnh của mật khẩu và trả về thông tin chi tiết
  static Map<String, dynamic> analyzePasswordStrength(String password) {
    int strengthScore = 0;
    final List<String> missingRequirements = [];

    // Kiểm tra độ dài
    if (password.length >= 8) {
      strengthScore += 1;
    } else {
      missingRequirements.add('Ít nhất 8 ký tự');
    }

    if (password.length >= 12) {
      strengthScore += 1;
    }

    // Kiểm tra chữ hoa
    if (_hasUpperCase.hasMatch(password)) {
      strengthScore += 1;
    } else {
      missingRequirements.add('Chữ hoa (A-Z)');
    }

    // Kiểm tra chữ thường
    if (_hasLowerCase.hasMatch(password)) {
      strengthScore += 1;
    } else {
      missingRequirements.add('Chữ thường (a-z)');
    }

    // Kiểm tra số
    if (_hasDigits.hasMatch(password)) {
      strengthScore += 1;
    } else {
      missingRequirements.add('Số (0-9)');
    }

    // Kiểm tra ký tự đặc biệt
    if (_hasSpecialChar.hasMatch(password)) {
      strengthScore += 1;
    } else {
      missingRequirements.add('Ký tự đặc biệt (!@#\$%^&*)');
    }

    // Kiểm tra mật khẩu phổ biến
    final isCommonPassword = _commonPasswords.any(
      (common) => password.toLowerCase().contains(common.toLowerCase()),
    );
    if (isCommonPassword) {
      strengthScore -= 2; // Trừ điểm nếu là mật khẩu phổ biến
      missingRequirements.add('Không sử dụng mật khẩu phổ biến');
    }

    // Xác định độ mạnh
    PasswordStrength strength;
    if (strengthScore <= 2) {
      strength = PasswordStrength.weak;
    } else if (strengthScore <= 4) {
      strength = PasswordStrength.medium;
    } else if (strengthScore <= 5) {
      strength = PasswordStrength.strong;
    } else {
      strength = PasswordStrength.veryStrong;
    }

    return {
      'strength': strength,
      'score': strengthScore,
      'missingRequirements': missingRequirements,
      'isValid': strengthScore >= 4 && !isCommonPassword,
    };
  }

  /// Password validation
  /// Trả về null nếu hợp lệ, hoặc thông báo lỗi nếu không hợp lệ
  static String? validatePassword(String? value, {bool showDetailedError = false}) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }

    // Kiểm tra độ dài tối thiểu
    if (value.length < 8) {
      return 'Mật khẩu phải có ít nhất 8 ký tự';
    }

    // Kiểm tra độ dài tối đa
    if (value.length > 128) {
      return 'Mật khẩu quá dài (tối đa 128 ký tự)';
    }

    // Phân tích độ mạnh mật khẩu
    final analysis = analyzePasswordStrength(value);

    // Kiểm tra mật khẩu phổ biến
    final isCommonPassword = _commonPasswords.any(
      (common) => value.toLowerCase().contains(common.toLowerCase()),
    );
    if (isCommonPassword) {
      return 'Mật khẩu này quá phổ biến và không an toàn. Vui lòng chọn mật khẩu khác';
    }

    // Kiểm tra các yêu cầu bắt buộc
    if (!analysis['isValid'] as bool) {
      if (showDetailedError && (analysis['missingRequirements'] as List).isNotEmpty) {
        final missing = (analysis['missingRequirements'] as List<String>).join(', ');
        return 'Mật khẩu chưa đủ mạnh. Thiếu: $missing';
      }
      return 'Mật khẩu phải chứa chữ hoa, chữ thường, số và ký tự đặc biệt';
    }

    return null;
  }

  /// Confirm password validation
  /// Trả về null nếu hợp lệ, hoặc thông báo lỗi nếu không hợp lệ
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng xác nhận mật khẩu';
    }

    if (value != password) {
      return 'Mật khẩu xác nhận không khớp';
    }

    return null;
  }

  /// Address validation
  /// Trả về null nếu hợp lệ, hoặc thông báo lỗi nếu không hợp lệ
  static String? validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập địa chỉ';
    }

    final address = value.trim();

    // Kiểm tra độ dài tối thiểu (5 ký tự để đảm bảo có thông tin địa chỉ cơ bản)
    if (address.length < 5) {
      return 'Địa chỉ phải có ít nhất 5 ký tự';
    }

    // Kiểm tra độ dài tối đa
    if (address.length > 200) {
      return 'Địa chỉ quá dài (tối đa 200 ký tự)';
    }

    return null;
  }
}

/// Login security utilities
/// Quản lý bảo mật đăng nhập như rate limiting và theo dõi số lần thử
class LoginSecurityUtils {
  static const String _failedAttemptsKey = 'login_failed_attempts';
  static const String _lastAttemptTimeKey = 'login_last_attempt_time';
  static const String _lockedUntilKey = 'login_locked_until';
  static const int _maxFailedAttempts = 5; // Số lần thử tối đa
  static const int _lockoutDurationMinutes = 15; // Thời gian khóa (phút)
  static const int _resetAttemptsAfterMinutes = 30; // Reset sau X phút

  /// Kiểm tra xem tài khoản có bị khóa không
  static Future<bool> isAccountLocked() async {
    // Implementation sẽ sử dụng SharedPreferences
    // Tạm thời return false - sẽ implement đầy đủ khi có SharedPreferences
    return false;
  }

  /// Lấy thời gian còn lại trước khi có thể thử lại
  static Future<int?> getRemainingLockoutTime() async {
    // Implementation sẽ sử dụng SharedPreferences
    // Tạm thời return null
    return null;
  }

  /// Ghi nhận lần đăng nhập thất bại
  static Future<void> recordFailedAttempt() async {
    // Implementation sẽ sử dụng SharedPreferences
  }

  /// Reset số lần thử thất bại
  static Future<void> resetFailedAttempts() async {
    // Implementation sẽ sử dụng SharedPreferences
  }
}

