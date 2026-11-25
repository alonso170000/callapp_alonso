import 'package:callerapp_frontend/data/mappers/prospect_cache_mapper.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ProspectRecord conserva quién realizó la asignación en caché', () {
    const prospect = ProspectRecord(
      id: 17,
      name: 'Ana Pérez',
      phone: '9991234567',
      email: 'ana@example.com',
      status: 'Nuevo',
      temperature: 'Caliente',
      avatarColor: Colors.teal,
      statusColor: Colors.orange,
      assignedBy: 'María Asesora',
    );

    final row = ProspectCacheMapper.toRow(
      prospect,
      userId: 4,
      developmentId: 8,
    );
    final restored = ProspectCacheMapper.fromRow(row);

    expect(row['assigned_by'], 'María Asesora');
    expect(restored.assignedBy, 'María Asesora');
    expect(prospect.copyWith().assignedBy, 'María Asesora');
  });
}
