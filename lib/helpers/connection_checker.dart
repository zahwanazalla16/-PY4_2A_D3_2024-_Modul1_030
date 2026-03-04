import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logbook_app_001/helpers/log_helper.dart';

class ConnectionChecker {
  static final ConnectionChecker _instance = ConnectionChecker._internal();
  final Connectivity _connectivity = Connectivity();

  factory ConnectionChecker() => _instance;
  ConnectionChecker._internal();

  /// Check apakah device terhubung ke internet
  Future<bool> hasConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      
      // Handle hasil checkConnectivity
      if (result is List) {
        // Untuk versi terbaru - result adalah List<ConnectivityResult>
        return (result as List).any((item) =>
            item == ConnectivityResult.mobile ||
            item == ConnectivityResult.wifi ||
            item == ConnectivityResult.ethernet);
      } else {
        // Untuk versi lama - result adalah ConnectivityResult tunggal
        return result != ConnectivityResult.none;
      }
    } catch (e) {
      await LogHelper.writeLog(
        "WARNING: Gagal cek koneksi - $e",
        source: "connection_checker.dart",
        level: 3,
      );
      return false;
    }
  }

  /// Stream untuk listen perubahan status koneksi
  Stream<bool> get connectionStatusStream {
    return _connectivity.onConnectivityChanged.map((result) {
      if (result is List) {
        return (result as List).any((item) =>
            item == ConnectivityResult.mobile ||
            item == ConnectivityResult.wifi ||
            item == ConnectivityResult.ethernet);
      } else {
        return result != ConnectivityResult.none;
      }
    });
  }

  /// Get user-friendly message berdasarkan status koneksi
  static String getOfflineMessage() {
    return 'Sedang Offline. Data ditampilkan dari penyimpanan lokal.';
  }

  static String getConnectionErrorMessage() {
    return 'Tidak dapat terhubung ke MongoDB Atlas. Cek koneksi internet Anda.';
  }
}
