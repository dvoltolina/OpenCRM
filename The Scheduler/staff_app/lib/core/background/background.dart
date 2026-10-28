// Background sync module for Staff App.
//
// Provides platform-aware background sync capabilities:
// - WorkManager integration for Android
// - BGTaskScheduler support for iOS
// - Battery-aware scheduling
// - Data cleanup during idle time

export 'background_sync_service.dart';
export 'battery_aware_scheduler.dart';
