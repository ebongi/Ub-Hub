import 'package:flutter_test/flutter_test.dart';
import 'package:neo/Screens/Shared/constanst.dart';

void main() {
  group('UserModel Tests', () {
    test('Initial values should be correctly set', () {
      final user = UserModel(
        uid: '123',
        name: 'Test Member',
        email: 'test@example.com',
        matricule: 'FE24A001',
        phonenumber: '123456789',
      );

      expect(user.uid, '123');
      expect(user.name, 'Test Member');
      expect(user.email, 'test@example.com');
      expect(user.matricule, 'FE24A001');
      expect(user.phoneNumber, '123456789');
    });

    test('setName should update the name and notify listeners', () {
      final user = UserModel(name: 'Initial Name');
      var notified = false;
      user.addListener(() {
        notified = true;
      });

      user.setName('New Name');

      expect(user.name, 'New Name');
      expect(notified, isTrue);
    });

    test('update should correctly modify specified fields', () {
      final user = UserModel(
        name: 'Old Name',
        matricule: 'Old Mat',
        phonenumber: '000',
      );

      user.update(name: 'New Name', phoneNumber: '111');

      expect(user.name, 'New Name');
      expect(user.matricule, 'Old Mat');
      expect(user.phoneNumber, '111');
    });
  });
}
