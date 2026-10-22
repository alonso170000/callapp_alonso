class SyncConflictViewData {
  const SyncConflictViewData({
    required this.id,
    required this.title,
    required this.message,
    required this.attemptCount,
  });

  final int id;
  final String title;
  final String message;
  final int attemptCount;
}

class SyncPendingViewData {
  const SyncPendingViewData({
    required this.id,
    required this.title,
    required this.message,
    required this.attemptCount,
  });

  final int id;
  final String title;
  final String message;
  final int attemptCount;
}
