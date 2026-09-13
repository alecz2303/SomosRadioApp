import 'package:flutter/foundation.dart';

class PushNavigation {
  PushNavigation._();

  static final ValueNotifier<String?> pendingAction = ValueNotifier<String?>(null);

  static void request(String? action) {
    final normalized = action?.trim();
    if (normalized == null || normalized.isEmpty) return;
    pendingAction.value = normalized;
  }

  static void clear(String action) {
    if (pendingAction.value == action) {
      pendingAction.value = null;
    }
  }
}
