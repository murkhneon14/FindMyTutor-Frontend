import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
import '../config/navigator_key.dart';

class NotificationService {
  static void showMessageNotification({
    required BuildContext context,
    required String senderName,
    required String message,
    required VoidCallback onTap,
  }) {
    print('🔔 ========== NotificationService.showMessageNotification called ==========');
    print('🔔 Sender: $senderName');
    print('🔔 Message: $message');
    print('🔔 Context: $context');
    print('🔔 Context mounted: ${context.mounted}');
    
    try {
      // Use the global navigator context for overlay notifications
      final overlayContext = navigatorKey.currentContext ?? context;
      if (!overlayContext.mounted) {
        print('❌ Context is not mounted for overlay notification');
        return;
      }
      
      // showOverlayNotification doesn't need a context parameter - it uses the global overlay
      showOverlayNotification(
        (overlayContext) {
          print('🔔 Building overlay notification widget');
          return GestureDetector(
            onTap: () {
              OverlaySupportEntry.of(overlayContext)?.dismiss();
              onTap();
            },
          child: SafeArea(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    child: Text(
                      senderName.isNotEmpty ? senderName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    senderName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ),
        );
        },
        duration: const Duration(seconds: 4),
        position: NotificationPosition.top,
      );
      print('🔔 ✅ Overlay notification shown successfully');
    } catch (e, stackTrace) {
      print('❌ Error showing overlay notification: $e');
      print('❌ Stack trace: $stackTrace');
    }
    print('🔔 ============================================================');
  }

  static void showSimpleToast({
    required String message,
    Color? backgroundColor,
  }) {
    toast(
      message,
      duration: const Duration(seconds: 3),
    );
  }
}
