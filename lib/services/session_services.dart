import 'package:shared_preferences/shared_preferences.dart';
import '../models/users_models.dart';

class SessionService {
  // Save user session including avatar
  Future<void> saveSession(UserModel user) async {
    final pref = await SharedPreferences.getInstance();
    await pref.setString('id', user.id);
    await pref.setString('username', user.username);
    await pref.setString('role', user.role);
    
    // Save avatar URL if available
    if (user.avatarUrl != null) {
      await pref.setString('avatar_url', user.avatarUrl!);
    } else {
      // Remove avatar_url if null
      await pref.remove('avatar_url');
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final pref = await SharedPreferences.getInstance();
    return pref.containsKey('id');
  }

  // Get user session including avatar
  Future<UserModel?> getSession() async {
    final pref = await SharedPreferences.getInstance();
    if (!pref.containsKey('id')) return null;

    return UserModel(
      id: pref.getString('id')!,
      username: pref.getString('username')!,
      role: pref.getString('role')!,
      avatarUrl: pref.getString('avatar_url'), // Load avatar from session
    );
  }

  // Update only avatar URL without re-saving entire session
  Future<void> updateAvatar(String avatarUrl) async {
    final pref = await SharedPreferences.getInstance();
    await pref.setString('avatar_url', avatarUrl);
  }

  // Remove avatar from session
  Future<void> removeAvatar() async {
    final pref = await SharedPreferences.getInstance();
    await pref.remove('avatar_url');
  }

  // Clear all session data
  Future<void> clear() async {
    final pref = await SharedPreferences.getInstance();
    await pref.clear();
  }

  // Get user ID from session (helper method)
  Future<String?> getUserId() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getString('id');
  }

  // Get username from session (helper method)
  Future<String?> getUsername() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getString('username');
  }

  // Get role from session (helper method)
  Future<String?> getRole() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getString('role');
  }

  // Get avatar URL from session (helper method)
  Future<String?> getAvatarUrl() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getString('avatar_url');
  }
}