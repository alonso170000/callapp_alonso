import 'dart:convert';
import 'dart:math';

import 'package:callerapp_frontend/data/local/app_database.dart';
import 'package:callerapp_frontend/data/local/local_scope.dart';
import 'package:callerapp_frontend/services/business_clock.dart';

enum PendingOperationState { pending, syncing, conflict }

class PendingOperation {
  const PendingOperation({
    required this.id,
    required this.scope,
    required this.operationKey,
    required this.kind,
    required this.payload,
    required this.createdAt,
    required this.attemptCount,
    required this.state,
    this.entityId,
    this.lastError,
  });

  final int id;
  final LocalScope scope;
  final String operationKey;
  final String kind;
  final int? entityId;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int attemptCount;
  final String? lastError;
  final PendingOperationState state;
}

class PendingOperationsStore {
  PendingOperationsStore({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;
  static final Random _random = Random.secure();

  bool get isAvailable => _database.isAvailable;

  static String newOperationKey() =>
      '${businessNow().microsecondsSinceEpoch.toRadixString(36)}-${_random.nextInt(0x7fffffff).toRadixString(36)}';

  Future<int?> enqueue(
    LocalScope scope, {
    required String kind,
    required Map<String, dynamic> payload,
    int? entityId,
    String? operationKey,
  }) async {
    final database = await _database.databaseOrNull;
    if (database == null) return null;
    return database.insert('pending_operations', {
      'user_id': scope.userId,
      'development_id': scope.developmentId,
      'operation_key': operationKey ?? newOperationKey(),
      'kind': kind,
      'entity_id': entityId,
      'payload_json': jsonEncode(payload),
      'created_at_ms': businessNow().millisecondsSinceEpoch,
      'state': PendingOperationState.pending.name,
    });
  }

  Future<List<PendingOperation>> read(
    LocalScope scope, {
    bool includeConflicts = true,
  }) async {
    final database = await _database.databaseOrNull;
    if (database == null) return const [];
    final rows = await database.query(
      'pending_operations',
      where:
          'user_id = ? AND development_id = ?${includeConflicts ? '' : " AND state <> 'conflict'"}',
      whereArgs: [scope.userId, scope.developmentId],
      orderBy: 'created_at_ms ASC, id ASC',
    );
    return rows.map(_fromRow).toList();
  }

  Future<void> recoverInterrupted(LocalScope scope) async {
    final database = await _database.databaseOrNull;
    if (database == null) return;
    await database.update(
      'pending_operations',
      {'state': PendingOperationState.pending.name},
      where: 'user_id = ? AND development_id = ? AND state = ?',
      whereArgs: [
        scope.userId,
        scope.developmentId,
        PendingOperationState.syncing.name,
      ],
    );
  }

  Future<void> markSyncing(PendingOperation operation) => _setState(
    operation,
    PendingOperationState.syncing,
    incrementAttempt: true,
  );

  Future<void> markPending(PendingOperation operation, [String? error]) =>
      _setState(operation, PendingOperationState.pending, error: error);

  Future<void> markConflict(PendingOperation operation, String error) =>
      _setState(operation, PendingOperationState.conflict, error: error);

  Future<void> retryConflict(PendingOperation operation) =>
      _setState(operation, PendingOperationState.pending, error: null);

  Future<void> _setState(
    PendingOperation operation,
    PendingOperationState state, {
    String? error,
    bool incrementAttempt = false,
  }) async {
    final database = await _database.databaseOrNull;
    if (database == null) return;
    await database.rawUpdate(
      'UPDATE pending_operations SET state = ?, last_error = ?, attempt_count = attempt_count + ? WHERE id = ? AND user_id = ? AND development_id = ?',
      [
        state.name,
        error,
        incrementAttempt ? 1 : 0,
        operation.id,
        operation.scope.userId,
        operation.scope.developmentId,
      ],
    );
  }

  Future<void> remove(PendingOperation operation) async {
    final database = await _database.databaseOrNull;
    if (database == null) return;
    await database.delete(
      'pending_operations',
      where: 'id = ? AND user_id = ? AND development_id = ?',
      whereArgs: [
        operation.id,
        operation.scope.userId,
        operation.scope.developmentId,
      ],
    );
  }

  Future<void> remapActivityId(
    PendingOperation creation, {
    required int temporaryId,
    required int serverId,
  }) async {
    final database = await _database.databaseOrNull;
    if (database == null) return;
    await database.transaction((transaction) async {
      final args = [
        creation.scope.userId,
        creation.scope.developmentId,
        temporaryId,
      ];
      await transaction.rawUpdate(
        'UPDATE cached_activities SET activity_id = ? WHERE user_id = ? AND development_id = ? AND activity_id = ?',
        [serverId, ...args],
      );
      await transaction.rawUpdate(
        'UPDATE activity_notifications SET activity_id = ? WHERE user_id = ? AND development_id = ? AND activity_id = ?',
        [serverId, ...args],
      );
      final following = await transaction.query(
        'pending_operations',
        where: 'user_id = ? AND development_id = ? AND id > ?',
        whereArgs: [
          creation.scope.userId,
          creation.scope.developmentId,
          creation.id,
        ],
      );
      for (final row in following) {
        final payload = _replaceId(
          jsonDecode(row['payload_json']! as String),
          temporaryId,
          serverId,
        );
        await transaction.update(
          'pending_operations',
          {
            'entity_id': row['entity_id'] == temporaryId
                ? serverId
                : row['entity_id'],
            'payload_json': jsonEncode(payload),
          },
          where: 'id = ?',
          whereArgs: [row['id']],
        );
      }
      await transaction.delete(
        'pending_operations',
        where: 'id = ?',
        whereArgs: [creation.id],
      );
    });
  }

  static dynamic _replaceId(dynamic value, int from, int to) {
    if (value == from) return to;
    if (value is List) {
      return value.map((item) => _replaceId(item, from, to)).toList();
    }
    if (value is Map) {
      return value.map(
        (key, item) => MapEntry(key, _replaceId(item, from, to)),
      );
    }
    return value;
  }

  static PendingOperation _fromRow(Map<String, Object?> row) =>
      PendingOperation(
        id: row['id']! as int,
        scope: LocalScope(
          userId: row['user_id']! as int,
          developmentId: row['development_id']! as int,
        ),
        operationKey: row['operation_key']! as String,
        kind: row['kind']! as String,
        entityId: row['entity_id'] as int?,
        payload: Map<String, dynamic>.from(
          jsonDecode(row['payload_json']! as String) as Map,
        ),
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          row['created_at_ms']! as int,
        ),
        attemptCount: row['attempt_count']! as int,
        lastError: row['last_error'] as String?,
        state: PendingOperationState.values.byName(row['state']! as String),
      );
}
