import 'package:flutter_dotenv/flutter_dotenv.dart';

class AccessControlService {
  // Mengambil roles dari .env di root
  static List<String> get availableRoles =>
      dotenv.env['APP_ROLES']?.split(',') ?? ['Anggota'];

  static const String actionCreate = 'create';
  static const String actionRead = 'read';
  static const String actionUpdate = 'update';
  static const String actionDelete = 'delete';

  // Matrix perizinan yang tetap fleksibel
  static final Map<String, List<String>> _rolePermissions = {
    'Ketua': [actionCreate, actionRead],
    'Anggota': [actionCreate, actionRead],
    'Asisten': [actionRead],
  };

  static bool canPerform(String role, String action, {bool isOwner = false}) {
    // RULE: Hanya owner yang bisa edit/delete, regardless of role
    if (action == actionUpdate || action == actionDelete) {
      return isOwner;
    }

    // Untuk action lain (create, read), gunakan role-based permission
    final permissions = _rolePermissions[role] ?? [];
    return permissions.contains(action);
  }

  /// Check if can view (read) a note
  static bool canView(String role, bool isPublic, {bool isOwner = false}) {
    // Owner selalu bisa lihat catatan mereka
    if (isOwner) {
      return true;
    }
    // Jika public, siapa saja dalam tim bisa lihat
    if (isPublic) {
      return true;
    }
    // Private dan bukan owner = tidak bisa lihat
    return false;
  }
}
