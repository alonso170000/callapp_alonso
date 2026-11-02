import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/presentation/models/prospect_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalización', () {
    test('ignora mayúsculas, acentos y espacios extra', () {
      expect(ProspectSearch.normalize('  José   PÉREZ  '), 'jose perez');
      expect(ProspectSearch.normalize('Núñez'), 'nunez');
      expect(ProspectSearch.normalize('María José'), 'maria jose');
    });

    test('reduce el teléfono a sus dígitos', () {
      expect(
        ProspectSearch.normalizePhone('+52 (998) 123-4567'),
        '529981234567',
      );
    });
  });

  group('búsqueda', () {
    test('encuentra por nombre sin distinguir acentos ni mayúsculas', () {
      final results = ProspectSearch.filter([
        _prospect(id: 1, name: 'José Pérez'),
        _prospect(id: 2, name: 'Ana López'),
      ], 'JOSE');

      expect(results.map((prospect) => prospect.id), [1]);
    });

    test('encuentra por teléfono ignorando el formato', () {
      final results = ProspectSearch.filter([
        _prospect(id: 1, name: 'José Pérez', phone: '+52 998 123 4567'),
      ], '998-123-4567');

      expect(results.map((prospect) => prospect.id), [1]);
      expect(
        ProspectSearch.filter(
          results,
          '1234567',
        ).map((prospect) => prospect.id),
        [1],
      );
    });

    test('encuentra por correo, desarrollo, lote y empresa', () {
      final records = [
        _prospect(id: 1, name: 'José', email: 'jose@correo.com'),
        _prospect(id: 2, name: 'Ana', development: 'Residencial Villa'),
        _prospect(id: 3, name: 'Beto', lot: 'Lote 12'),
        _prospect(id: 4, name: 'Carla', company: 'Inmobiliaria Sol'),
      ];

      expect(ProspectSearch.filter(records, 'correo').single.id, 1);
      expect(ProspectSearch.filter(records, 'villa').single.id, 2);
      expect(ProspectSearch.filter(records, 'lote 12').single.id, 3);
      expect(ProspectSearch.filter(records, 'inmobiliaria').single.id, 4);
    });

    test('exige que todas las palabras coincidan', () {
      final records = [
        _prospect(id: 1, name: 'José Pérez'),
        _prospect(id: 2, name: 'José Gómez'),
      ];

      expect(ProspectSearch.filter(records, 'jose perez').single.id, 1);
      expect(ProspectSearch.filter(records, 'jose gomez').single.id, 2);
      expect(ProspectSearch.filter(records, 'jose ramirez'), isEmpty);
    });

    test('ordena por relevancia: exacto, prefijo y contenido', () {
      final results = ProspectSearch.filter([
        _prospect(id: 1, name: 'Mariana'),
        _prospect(id: 2, name: 'Ana'),
        _prospect(id: 3, name: 'Ana María'),
      ], 'ana');

      expect(results.map((prospect) => prospect.id), [2, 3, 1]);
    });

    test(
      'un teléfono exacto queda por delante de una coincidencia parcial',
      () {
        final results = ProspectSearch.filter([
          _prospect(id: 1, name: 'Zoe', phone: '5551112222'),
          _prospect(id: 2, name: 'Ana', phone: '9981234567'),
        ], '9981234567');

        expect(results.map((prospect) => prospect.id), [2]);
      },
    );

    test('una consulta vacía devuelve todos ordenados por nombre', () {
      final results = ProspectSearch.filter([
        _prospect(id: 1, name: 'Zoe'),
        _prospect(id: 2, name: 'Ana'),
      ], '   ');

      expect(results.map((prospect) => prospect.id), [2, 1]);
    });

    test('respeta el límite y descarta prospectos sin id', () {
      final records = [
        _prospect(id: 1, name: 'Ana'),
        _prospect(id: 2, name: 'Ana María'),
        _prospect(name: 'Ana sin guardar'),
      ];

      expect(ProspectSearch.filter(records, 'ana', limit: 1).length, 1);
      expect(ProspectSearch.filter(records, 'ana', limit: 0), isEmpty);
      expect(
        ProspectSearch.filter(records, 'ana').map((prospect) => prospect.id),
        [1, 2],
      );
    });
  });

  group('sugerencias', () {
    final now = DateTime(2026, 11, 2, 9);

    test('prioriza contactos pendientes y asignaciones recientes', () {
      final suggestions = ProspectSearch.suggestions([
        _prospect(
          id: 1,
          name: 'Zoe',
          nextContact: now.subtract(const Duration(days: 2)),
          assignedAt: now.subtract(const Duration(days: 1)),
        ),
        _prospect(
          id: 2,
          name: 'Ana',
          nextContact: now.add(const Duration(hours: 2)),
        ),
        _prospect(
          id: 3,
          name: 'Beto',
          nextContact: now.subtract(const Duration(days: 1)),
        ),
        _prospect(
          id: 4,
          name: 'Carla',
          assignedAt: now.subtract(const Duration(days: 2)),
        ),
        _prospect(
          id: 5,
          name: 'Dora',
          assignedAt: now.subtract(const Duration(days: 1)),
        ),
        _prospect(
          id: 6,
          name: 'Elena',
          assignedAt: now.subtract(const Duration(days: 20)),
        ),
        _prospect(id: 7, name: 'Fabiola'),
        _prospect(name: 'Sin id', nextContact: now),
      ], now: now);

      expect(suggestions.map((suggestion) => suggestion.prospect.name), [
        'Zoe',
        'Beto',
        'Ana',
        'Dora',
        'Carla',
        'Elena',
      ]);
      expect(suggestions.map((suggestion) => suggestion.reason), [
        ProspectSuggestionReason.upcomingContact,
        ProspectSuggestionReason.upcomingContact,
        ProspectSuggestionReason.upcomingContact,
        ProspectSuggestionReason.recentlyAssigned,
        ProspectSuggestionReason.recentlyAssigned,
        ProspectSuggestionReason.other,
      ]);
    });

    test('respeta el límite y no repite prospectos', () {
      final suggestions = ProspectSearch.suggestions(
        [
          _prospect(id: 1, name: 'Zoe', nextContact: now, assignedAt: now),
          _prospect(id: 2, name: 'Ana', nextContact: now),
          _prospect(id: 3, name: 'Beto', nextContact: now),
        ],
        now: now,
        limit: 2,
      );

      expect(suggestions.map((suggestion) => suggestion.prospect.id), [2, 3]);
      expect(ProspectSearch.suggestions(const [], now: now), isEmpty);
      expect(
        ProspectSearch.suggestions(
          [_prospect(id: 1, name: 'Ana')],
          now: now,
          limit: 0,
        ),
        isEmpty,
      );
    });
  });
}

ProspectRecord _prospect({
  int? id,
  required String name,
  String phone = '5550000000',
  String email = '',
  String development = 'Sin desarrollo seleccionado',
  String lot = 'Sin lote seleccionado',
  String company = 'Sin registro de Empresa',
  DateTime? nextContact,
  DateTime? assignedAt,
}) => ProspectRecord(
  id: id,
  name: name,
  phone: phone,
  email: email,
  status: 'Nuevo',
  temperature: 'Caliente',
  avatarColor: Colors.teal,
  statusColor: Colors.orange,
  interestDevelopment: development,
  interestLot: lot,
  company: company,
  nextContact: nextContact,
  assignedAt: assignedAt,
);
