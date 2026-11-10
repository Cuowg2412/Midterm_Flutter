import 'package:flutter/material.dart';

class PasswordStrengthBar extends StatelessWidget {
  final String password;

  const PasswordStrengthBar({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    final score = _calculateScore(password);
    final (label, color, progress) = switch (score) {
      <= 1 => ('Yếu', Colors.red, 0.25),
      2 => ('Trung bình', Colors.orange, 0.5),
      3 => ('Khá', Colors.blue, 0.75),
      _ => ('Mạnh', Colors.green, 1.0),
    };

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 2,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Text(
                'Độ mạnh mật khẩu: $label',
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Nên ≥ 6 ký tự, có chữ hoa & số',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _calculateScore(String pwd) {
    int score = 0;
    if (pwd.length >= 6) score++;
    if (pwd.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(pwd) && RegExp(r'[a-z]').hasMatch(pwd)) {
      score++;
    }
    if (RegExp(r'[0-9]').hasMatch(pwd) ||
        RegExp(r'[!@#\$%^&*(),.?":{}|<>_]').hasMatch(pwd)) {
      score++;
    }
    return score;
  }
}
