import 'package:flutter/material.dart';

class NotificationHelper {
  /// Tampilkan notification di atas dengan border merah melengkung
  static void showTopNotification({
    required BuildContext context,
    required String message,
    bool isError = false,
    Duration duration = const Duration(seconds: 4),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: isError ? Colors.red : Colors.orange,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    isError ? Icons.error_outline : Icons.wifi_off,
                    color: isError ? Colors.red : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => overlayEntry.remove(),
                    child: Icon(
                      Icons.close,
                      size: 18,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Auto remove setelah duration
    Future.delayed(duration, () {
      try {
        overlayEntry.remove();
      } catch (e) {
        // Already removed
      }
    });
  }

  /// Notification offline
  static void showOfflineNotification(BuildContext context) {
    showTopNotification(
      context: context,
      message: 'Mode Offline - Data ditampilkan dari penyimpanan lokal',
      isError: false,
    );
  }

  /// Notification connection error
  static void showConnectionErrorNotification(BuildContext context) {
    showTopNotification(
      context: context,
      message: 'Tidak dapat terhubung ke MongoDB Atlas. Cek koneksi internet.',
      isError: true,
      duration: const Duration(seconds: 5),
    );
  }
}
