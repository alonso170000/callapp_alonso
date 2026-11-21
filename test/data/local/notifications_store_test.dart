import 'package:callerapp_frontend/data/local/app_database.dart';
import 'package:callerapp_frontend/data/local/notifications_store.dart';
import 'package:callerapp_frontend/presentation/models/agenda_models.dart';
import 'package:callerapp_frontend/presentation/models/notification_models.dart';
import 'package:callerapp_frontend/services/business_clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  test('persists read state, dismissals and isolates each seller', () async {
    final database = AppDatabase(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    addTearDown(database.close);
    final store = NotificationsStore(database: database);
    const seller = NotificationScope(userId: 1, developmentId: 10);
    const otherSeller = NotificationScope(userId: 2, developmentId: 10);

    final now = businessNow();
    await store.upsert(seller, [_notification(7, now)]);
    await store.upsert(otherSeller, [_notification(8, now)]);
    await store.markRead(seller, 7);

    expect((await store.read(seller)).single.isRead, isTrue);
    expect((await store.read(otherSeller)).single.activityId, 8);

    await store.dismiss(seller, 7);
    expect(await store.read(seller), isEmpty);
    await store.upsert(seller, [_notification(7, now)]);
    expect(await store.read(seller), isEmpty);

    final rescheduledAt = now.add(const Duration(hours: 1));
    await store.upsert(seller, [_notification(7, rescheduledAt)]);
    final rescheduled = (await store.read(seller)).single;
    expect(rescheduled.isRead, isFalse);
    expect(
      rescheduled.reminderAt.millisecondsSinceEpoch,
      rescheduledAt.millisecondsSinceEpoch,
    );
  });

  test('purges notifications older than the retention cutoff regardless of read state', () async {
    final database = AppDatabase(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    addTearDown(database.close);
    final store = NotificationsStore(database: database);
    const scope = NotificationScope(userId: 1, developmentId: 10);
    final now = businessNow();
    await store.upsert(scope, [
      _notification(1, now.subtract(const Duration(days: 10))),
      _notification(2, now.subtract(const Duration(days: 2))),
      _notification(3, now.subtract(const Duration(days: 8))),
    ]);
    await store.markRead(scope, 1);
    await store.markRead(scope, 2);

    final deleted = await store.purgeOlderThan(
      scope,
      now.subtract(const Duration(days: 5)),
    );

    expect(deleted, 2);
    expect((await store.read(scope)).map((item) => item.activityId), [2]);
  });
}

ActivityNotification _notification(int id, DateTime reminderAt) =>
    ActivityNotification(
      reminderAt: reminderAt,
      isRead: false,
      activity: AgendaActivity(
        id: id,
        prospectId: id + 100,
        type: 'seguimiento',
        medium: 'llamada',
        title: 'SEGUIMIENTO',
        prospect: 'Prospecto $id',
        description: 'Descripción $id',
        date: reminderAt.add(const Duration(minutes: 15)),
        status: AgendaStatus.pending,
        tags: const ['NUEVO'],
        reminderMinutes: 15,
      ),
    );
