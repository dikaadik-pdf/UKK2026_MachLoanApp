import 'package:shared_preferences/shared_preferences.dart';
import '../models/users_models.dart';

class SessionService {
  Future<void> saveSession(UserModel user) async {
    final pref = await SharedPreferences.getInstance();
    await pref.setString('id', user.id);
    await pref.setString('username', user.username);
    await pref.setString('role', user.role);
  }

  Future<bool> isLoggedIn() async {
    final pref = await SharedPreferences.getInstance();
    return pref.containsKey('id');
  }

  Future<UserModel?> getSession() async {
    final pref = await SharedPreferences.getInstance();
    if (!pref.containsKey('id')) return null;

    return UserModel(
      id: pref.getString('id')!,
      username: pref.getString('username')!,
      role: pref.getString('role')!,
    );
  }

  Future<void> clear() async {
    final pref = await SharedPreferences.getInstance();
    await pref.clear();
  }
}
