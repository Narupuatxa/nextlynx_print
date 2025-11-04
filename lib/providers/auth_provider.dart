import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';

class AuthProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  User? _user;
  String? _role;
  Map<String, dynamic>? _profile;

  User? get user => _user;
  String? get role => _role;
  Map<String, dynamic>? get profile => _profile;

  // CADASTRO (INSERE EM profiles E roles)
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String address,
    required int age,
    required String role, // 'admin' ou 'employee'
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        final userId = response.user!.id;

        // INSERE NA TABELA profiles
        await _supabase.from('profiles').insert({
          'id': userId,
          'full_name': fullName,
          'phone': phone,
          'address': address,
          'age': age,
          'email': email,
        });

        // INSERE NA TABELA roles
        await _supabase.from('roles').insert({
          'user_id': userId,
          'role': role,
        });

        _user = response.user;
        _role = role;
        _profile = {
          'full_name': fullName,
          'phone': phone,
          'address': address,
          'age': age,
          'email': email,
        };

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erro no cadastro: $e');
      rethrow;
    }
  }

  // LOGIN (CARREGA DE profiles E roles)
  Future<void> signIn(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        final userId = response.user!.id;

        // CARREGA PERFIL
        final profileResponse = await _supabase
            .from('profiles')
            .select()
            .eq('id', userId)
            .single();

        // CARREGA ROLE DA TABELA roles
        final roleResponse = await _supabase
            .from('roles')
            .select('role')
            .eq('user_id', userId)
            .single();

        _user = response.user;
        _role = roleResponse['role'];
        _profile = profileResponse;

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erro no login: $e');
      rethrow;
    }
  }

  // LOGOUT
  Future<void> logout() async {
    await _supabase.auth.signOut();
    _user = null;
    _role = null;
    _profile = null;
    notifyListeners();
  }

  // UPLOAD DE FOTO (WEB + MOBILE) - CORRIGIDO
  Future<String?> uploadAvatarToSupabase(XFile image) async {
    if (_user == null) return null;

    try {
      final fileExt = path.extension(image.name);
      final filePath = '${_user!.id}/avatar$fileExt';

      debugPrint('Uploading to: avatars/$filePath');

      Uint8List bytes;
      if (kIsWeb) {
        bytes = await image.readAsBytes();
      } else {
        final file = File(image.path);
        bytes = await file.readAsBytes();
      }

      // 1. FAZ UPLOAD
      await _supabase.storage
          .from('avatars')
          .uploadBinary(filePath, bytes, fileOptions: const FileOptions(upsert: true));

      final url = _supabase.storage.from('avatars').getPublicUrl(filePath);
      debugPrint('URL: $url');

      // 2. ATUALIZA user_metadata
      await _supabase.auth.updateUser(
        UserAttributes(data: {'avatar_url': url}),
      );

      // 3. FORÇA ATUALIZAÇÃO DO USUÁRIO
      final updatedUser = await _supabase.auth.currentUser;
      if (updatedUser != null) {
        _user = updatedUser;
      }

      // 4. NOTIFICA A UI
      notifyListeners();

      return url;
    } catch (e) {
      debugPrint('Erro no upload: $e');
      return null;
    }
  }

  // CORRIGIDO: 'Interfaces' → 'avatar_url'
  String? get avatarUrl => _user?.userMetadata?['avatar_url'];
}