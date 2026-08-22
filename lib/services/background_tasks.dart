import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import '../database/isar_service.dart';
import 'app_icon_service.dart';

const String dailyIconRefreshTaskName = 'habitquest.dailyIconRefresh';
const String _uniqueTaskName = 'habitquest-daily-icon-refresh';

/// Runs in a separate background isolate — no access to the running app's
/// state — so it opens its own Isar connection before reusing
/// AppIconService's decision logic (HabitQuest_PRD.md §9, "ideally also
/// once daily even if the app isn't opened").
@pragma('vm:entry-point')
void appIconBackgroundDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await IsarService.instance.init();
      await AppIconService.instance.refreshIcon();
    } catch (error, stack) {
      debugPrint('[Workmanager] Daily icon refresh failed: $error\n$stack');
    }
    return true;
  });
}

/// Registers the once-daily icon refresh. Best-effort and non-fatal: on
/// Android this schedules an approximate daily window via WorkManager (no
/// server, no exact-time guarantee — the OS can delay/coalesce runs under
/// battery optimization). The per-launch refresh in main() is what the
/// dynamic-icon feature actually depends on; this just keeps the icon
/// reasonably fresh on days the app never gets opened.
Future<void> registerDailyIconRefresh() async {
  try {
    await Workmanager().initialize(appIconBackgroundDispatcher);
    await Workmanager().registerPeriodicTask(
      _uniqueTaskName,
      dailyIconRefreshTaskName,
      frequency: const Duration(hours: 24),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      constraints: Constraints(networkType: NetworkType.notRequired),
    );
  } catch (error, stack) {
    debugPrint('[Workmanager] registerDailyIconRefresh failed: $error\n$stack');
  }
}
