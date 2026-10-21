import 'package:callerapp_frontend/data/local/activities_cache.dart';
import 'package:callerapp_frontend/data/local/app_database.dart';
import 'package:callerapp_frontend/data/local/local_scope.dart';
import 'package:callerapp_frontend/data/mappers/activity_cache_mapper.dart';
import 'package:callerapp_frontend/presentation/models/agenda_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  test('aísla y reemplaza actividades por usuario y desarrollo', () async {
    final database = AppDatabase(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    addTearDown(database.close);
    final cache = ActivitiesCache(database: database);
    const firstScope = LocalScope(userId: 1, developmentId: 10);
    const secondScope = LocalScope(userId: 1, developmentId: 20);

    await cache.replace(firstScope, [_activity(11, 'Visita')]);
    await cache.replace(secondScope, [_activity(22, 'Llamada')]);

    expect((await cache.read(firstScope)).single.title, 'Visita');
    expect((await cache.read(secondScope)).single.title, 'Llamada');

    await cache.replace(firstScope, [_activity(33, 'Tarea')]);
    expect((await cache.read(firstScope)).map((item) => item.id), [33]);
    expect((await cache.read(secondScope)).map((item) => item.id), [22]);

    await cache.replace(firstScope, []);
    expect(await cache.read(firstScope), isEmpty);
    expect((await cache.read(secondScope)).single.id, 22);
  });

  test('conserva los campos de presentación y recordatorio', () async {
    final database = AppDatabase(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    addTearDown(database.close);
    final cache = ActivitiesCache(database: database);
    const scope = LocalScope(userId: 2, developmentId: 30);
    final reminder = DateTime(2026, 10, 22, 14, 30);
    final activity = AgendaActivity(
      id: 7,
      prospectId: 99,
      prospectAvatarUrl: 'https://example.com/avatar.png',
      type: 'seguimiento',
      medium: 'whatsapp',
      title: 'SEGUIMIENTO',
      prospect: 'José Pérez',
      description: 'Confirmar la cita',
      date: reminder,
      status: AgendaStatus.pending,
      tags: const ['NUEVO', 'CALIENTE'],
      location: 'LOTE',
      reminderMinutes: 15,
      hasReminder: true,
      lastContact: 'Hace 1 día',
      completedAt: DateTime(2026, 10, 20, 9),
      deleteUntil: DateTime(2026, 10, 20, 9, 5),
    );

    await cache.replace(scope, [activity]);
    final restored = (await cache.read(scope)).single;

    expect(restored.id, activity.id);
    expect(restored.prospectId, activity.prospectId);
    expect(restored.prospectAvatarUrl, activity.prospectAvatarUrl);
    expect(restored.type, activity.type);
    expect(restored.medium, activity.medium);
    expect(restored.title, activity.title);
    expect(restored.prospect, activity.prospect);
    expect(restored.description, activity.description);
    expect(restored.date, activity.date);
    expect(restored.tags, activity.tags);
    expect(restored.location, activity.location);
    expect(restored.reminderMinutes, activity.reminderMinutes);
    expect(restored.hasReminder, isTrue);
    expect(restored.lastContact, activity.lastContact);
    expect(restored.completedAt, activity.completedAt);
    expect(restored.deleteUntil, activity.deleteUntil);
  });

  test('recalcula atrasado al leer según el reloj actual', () async {
    final now = DateTime(2026, 10, 21, 12);
    final past = ActivityCacheMapper.fromRow(
      ActivityCacheMapper.toRow(
        _activity(
          1,
          'Atrasada',
        ).copyWithDate(now.subtract(const Duration(hours: 2))),
        userId: 1,
        developmentId: 1,
      ),
      now: now,
    );
    final future = ActivityCacheMapper.fromRow(
      ActivityCacheMapper.toRow(
        _activity(
          2,
          'Pendiente',
        ).copyWithDate(now.add(const Duration(hours: 2))),
        userId: 1,
        developmentId: 1,
      ),
      now: now,
    );
    final completed = ActivityCacheMapper.fromRow(
      ActivityCacheMapper.toRow(
        _activity(3, 'Completada').copyWith(status: AgendaStatus.completed),
        userId: 1,
        developmentId: 1,
      ),
      now: now,
    );

    expect(past.status, AgendaStatus.overdue);
    expect(future.status, AgendaStatus.pending);
    expect(completed.status, AgendaStatus.completed);
  });
}

AgendaActivity _activity(int id, String title) => AgendaActivity(
  id: id,
  title: title,
  prospect: 'Prospecto $id',
  description: 'Descripción $id',
  date: DateTime(2026, 10, 21, 10),
  status: AgendaStatus.pending,
);

extension on AgendaActivity {
  AgendaActivity copyWithDate(DateTime date) => AgendaActivity(
    id: id,
    prospectId: prospectId,
    prospectAvatarUrl: prospectAvatarUrl,
    type: type,
    medium: medium,
    title: title,
    prospect: prospect,
    description: description,
    date: date,
    status: status,
    tags: tags,
    location: location,
    reminderMinutes: reminderMinutes,
    hasReminder: hasReminder,
    lastContact: lastContact,
    completedAt: completedAt,
    deleteUntil: deleteUntil,
  );
}
