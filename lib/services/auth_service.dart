import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../models/user.dart';

// Provides the current auth state (User or null)
final authProvider = NotifierProvider<AuthNotifier, User?>(() {
  return AuthNotifier();
});

class AuthNotifier extends Notifier<User?> {
  @override
  User? build() {
    return null;
  }

  supa.SupabaseClient get _supabase => supa.Supabase.instance.client;

  // Real Supabase Login functionality
  Future<void> login(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email, 
        password: password
      );

      if (response.user != null) {
        // Fetch custom role details from our public.users table
        final userData = await _supabase
            .from('users')
            .select()
            .eq('id', response.user!.id)
            .maybeSingle();

        if (userData != null) {
          final List<dynamic> rolesDynamic = userData['roles'] ?? [];
          final List<Role> parsedRoles = [];
          
          for (var r in rolesDynamic) {
            if (r == 'student') parsedRoles.add(Role.student);
            if (r == 'faculty') parsedRoles.add(Role.faculty);
            if (r == 'incharge') parsedRoles.add(Role.classIncharge);
            if (r == 'admin') parsedRoles.add(Role.admin);
          }

          final mustChange = userData['must_change_password'] == true;

          state = User(
            id: userData['id'],
            name: userData['name'] ?? 'Unknown User',
            username: userData['email'],
            roles: parsedRoles.isNotEmpty ? parsedRoles : [Role.student],
            mustChangePassword: mustChange,
          );
        } else {
          // User authenticated but no role mapped in `users` table
          state = User(
            id: response.user!.id,
            name: 'New User (No Role)',
            username: email,
            roles: [Role.student], // Default fallback
          );
        }
      }
    } on supa.AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('An unknown error occurred');
    }
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
    state = null;
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      // 1. Update the password in Supabase Auth
      await _supabase.auth.updateUser(
        supa.UserAttributes(password: newPassword),
      );

      // 2. Update the must_change_password flag in public.users
      final user = state;
      if (user != null) {
        final response = await _supabase.from('users').update({
          'must_change_password': false,
        }).eq('id', user.id).select();
        
        if (response.isEmpty) {
          throw Exception('Failed to update password flag in database. Please check permissions.');
        }

        // Update local state
        state = User(
          id: user.id,
          name: user.name,
          username: user.username,
          roles: user.roles,
          mustChangePassword: false,
        );
      }
    } on supa.AuthException catch (e) {
      throw Exception('Auth Error: ${e.message}');
    } catch (e) {
      throw Exception('Database Error: $e');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _supabase.auth.resetPasswordForEmail(
      email,
      redirectTo: 'io.supabase.flutterattendance://login-callback/',
    );
  }
}
