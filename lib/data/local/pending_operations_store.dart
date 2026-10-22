import 'dart:convert';
import 'dart:math';

import 'package:sqflite/sqflite.dart';

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
    await remapEntityId(
      creation,
      temporaryId: temporaryId,
      serverId: serverId,
      entity: 'activity',
    );
  }

  Future<void> remapProspectId(
    PendingOperation creation, {
    required int temporaryId,
    required int serverId,
  }) => remapEntityId(
    creation,
    temporaryId: temporaryId,
    serverId: serverId,
    entity: 'prospect',
  );

  Future<void> remapEntityId(
    PendingOperation creation, {
    required int temporaryId,
    required int serverId,
    required String entity,
  }) async {
    final database = await _database.databaseOrNull;
    if (database == null) return;
    await database.transaction((transaction) async {
      final args = [
        creation.scope.userId,
        creation.scope.developmentId,
        temporaryId,
      ];
      if (entity == 'activity') {
        await transaction.rawUpdate(
          'UPDATE cached_activities SET activity_id = ? WHERE user_id = ? AND development_id = ? AND activity_id = ?',
          [serverId, ...args],
        );
        await transaction.rawUpdate(
          'UPDATE activity_notifications SET activity_id = ? WHERE user_id = ? AND development_id = ? AND activity_id = ?',
          [serverId, ...args],
        );
      } else if (entity == 'prospect') {
        await transaction.rawUpdate(
          'UPDATE cached_prospects SET prospect_id = ? WHERE user_id = ? AND development_id = ? AND prospect_id = ?',
          [serverId, ...args],
        );
        await transaction.rawUpdate(
          'UPDATE cached_activities SET prospect_id = ? WHERE user_id = ? AND development_id = ? AND prospect_id = ?',
          [serverId, ...args],
        );
        await transaction.rawUpdate(
          'UPDATE activity_notifications SET prospect_id = ? WHERE user_id = ? AND development_id = ? AND prospect_id = ?',
          [serverId, ...args],
        );
      } else {
        throw ArgumentError.value(
          entity,
          'entity',
          'Entidad local desconocida',
        );
      }
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
      if (entity == 'prospect') {
        await _saveAlias(transaction, creation.scope, serverId);
      }
    });
  }

  static const _aliasesPrefix = 'local_prospect_aliases';
  static const _maxAliases = 100;

  static String _aliasesKey(LocalScope scope) =>
      '$_aliasesPrefix:${scope.userId}:${scope.developmentId}';

  /// Recuerda un id del servidor que nació de una creación local. Evita que el
  /// siguiente refresco lo anuncie como un prospecto recién asignado.
  Future<void> recordLocallyCreated(LocalScope scope, int serverId) async {
    final database = await _database.databaseOrNull;
    if (database == null) return;
    await _saveAlias(database, scope, serverId);
  }

  static Future<void> _saveAlias(
    DatabaseExecutor database,
    LocalScope scope,
    int serverId,
  ) async {
    final key = _aliasesKey(scope);
    final stored = await _readAliases(database, key);
    if (!stored.add(serverId)) return;
    final values = stored.toList()..sort();
    final kept = values.length <= _maxAliases
        ? values
        : values.sublist(values.length - _maxAliases);
    await _writeAliases(database, key, kept);
  }

  /// Consume los alias que ya aparecieron en el snapshot remoto y devuelve
  /// cuáles deben excluirse de los avisos de asignación.
  Future<Set<int>> consumeLocallyCreated(
    LocalScope scope,
    Set<int> visible,
  ) async {
    final database = await _database.databaseOrNull;
    if (database == null || visible.isEmpty) return const {};
    final key = _aliasesKey(scope);
    final stored = await _readAliases(database, key);
    final matched = stored.intersection(visible);
    if (matched.isEmpty) return const {};
    stored.removeAll(matched);
    if (stored.isEmpty) {
      await database.delete('app_metadata', where: 'key = ?', whereArgs: [key]);
    } else {
      await _writeAliases(database, key, stored.toList()..sort());
    }
    return matched;
  }

  static Future<Set<int>> _readAliases(
    DatabaseExecutor database,
    String key,
  ) async {
    final rows = await database.query(
      'app_metadata',
      columns: const ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return <int>{};
    try {
      final decoded = jsonDecode('${rows.single['value']}');
      if (decoded is! List) return <int>{};
      return {
        for (final value in decoded)
          if (value is int) value,
      };
    } on FormatException {
      return <int>{};
    }
  }

  static Future<void> _writeAliases(
    DatabaseExecutor database,
    String key,
    List<int> values,
  ) async {
    await database.insert('app_metadata', {
      'key': key,
      'value': jsonEncode(values),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
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
