import 'package:intl/intl.dart';

class DateFormatter {
  /// Format DateTime relatif dalam Bahasa Indonesia
  /// Contoh: "2 menit yang lalu", "1 jam yang lalu", "1 hari yang lalu"
  static String formatRelative(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'baru saja';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes menit yang lalu';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours jam yang lalu';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days hari yang lalu';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks minggu yang lalu';
    } else {
      // Gunakan format penuh untuk tanggal yang lebih lama
      return formatFull(dateTime);
    }
  }

  /// Format DateTime penuh dengan locale Indonesia
  /// Contoh: "4 Mar 2026, 14:30"
  static String formatFull(DateTime dateTime) {
    try {
      final formatter = DateFormat('d MMM yyyy, HH:mm', 'id_ID');
      return formatter.format(dateTime);
    } catch (e) {
      // Fallback jika locale tidak tersedia
      return DateFormat('d MMM yyyy, HH:mm').format(dateTime);
    }
  }

  /// Format DateTime ringkas
  /// Contoh: "04/03/2026"
  static String formatShort(DateTime dateTime) {
    try {
      final formatter = DateFormat('dd/MM/yyyy', 'id_ID');
      return formatter.format(dateTime);
    } catch (e) {
      return DateFormat('dd/MM/yyyy').format(dateTime);
    }
  }

  /// Format DateTime dengan waktu lengkap
  /// Contoh: "Senin, 4 Maret 2026 14:30:20"
  static String formatLong(DateTime dateTime) {
    try {
      final formatter = DateFormat('EEEE, d MMMM yyyy HH:mm:ss', 'id_ID');
      return formatter.format(dateTime);
    } catch (e) {
      return DateFormat('EEEE, d MMMM yyyy HH:mm:ss').format(dateTime);
    }
  }
}
