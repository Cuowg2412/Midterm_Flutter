import 'package:flutter_test/flutter_test.dart';
import 'package:giuaki_flutter/main.dart';
import 'package:giuaki_flutter/models/user_model.dart';
import 'package:giuaki_flutter/utils/validators.dart';

void main() {
  testWidgets('Login screen renders properly', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('ĐĂNG NHẬP ADMIN'), findsOneWidget);
    expect(find.text('ĐĂNG NHẬP'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Mật khẩu'), findsOneWidget);
  });

  test('UserModel serializes only required 4 fields', () {
    final user = UserModel(
      id: '123',
      email: 'test@gmail.com',
      matkhau: '123456',
      hoten: 'Nguyen Van Test',
      hinhanh: '/uploads/test.png',
    );

    final json = user.toJson();
    expect(json.keys.toList(), ['email', 'matkhau', 'hoten', 'hinhanh']);
    expect(json['email'], 'test@gmail.com');
    expect(json['matkhau'], '123456');
    expect(json['hoten'], 'Nguyen Van Test');
    expect(json['hinhanh'], '/uploads/test.png');
  });

  test('FormValidators validates email format properly', () {
    expect(FormValidators.validateEmail(''), isNotNull);
    expect(FormValidators.validateEmail('abc@'), isNotNull);
    expect(FormValidators.validateEmail('admin@gmail.com'), isNull);
  });
}
