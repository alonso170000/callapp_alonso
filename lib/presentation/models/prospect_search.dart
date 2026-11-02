import 'dart:math' as math;

import 'package:callerapp_frontend/presentation/models/prospect_models.dart';

/// Motivo por el que un prospecto aparece como sugerencia en el buscador.
enum ProspectSuggestionReason { upcomingContact, recentlyAssigned, other }

/// Prospecto sugerido junto con la razón de la sugerencia.
class ProspectSuggestion {
  const ProspectSuggestion(this.prospect, this.reason);

  final ProspectRecord prospect;
  final ProspectSuggestionReason reason;
}

/// Reglas puras de búsqueda y sugerencias sobre prospectos.
///
/// La pantalla y los repositorios solo orquestan; toda la coincidencia,
/// normalización y prioridad vive aquí para que sea fácil de probar y de
/// reutilizar entre la lista de prospectos y el buscador global.
class ProspectSearch {
  static const int defaultLimit = 50;
  static const int defaultSuggestionLimit = 6;
  static const int _suggestionGroupLimit = 3;
  static const Duration _recentAssignmentWindow = Duration(days: 7);

  static const _accentMap = {
    'á': 'a',
    'à': 'a',
    'ä': 'a',
    'â': 'a',
    'ã': 'a',
    'é': 'e',
    'è': 'e',
    'ë': 'e',
    'ê': 'e',
    'í': 'i',
    'ì': 'i',
    'ï': 'i',
    'î': 'i',
    'ó': 'o',
    'ò': 'o',
    'ö': 'o',
    'ô': 'o',
    'õ': 'o',
    'ú': 'u',
    'ù': 'u',
    'ü': 'u',
    'û': 'u',
    'ñ': 'n',
    'ç': 'c',
  };

  static final _whitespace = RegExp(r'\s+');
  static final _nonDigits = RegExp(r'\D');
  static final _phoneCharacters = RegExp(r'^[\d\s+().-]+$');

  /// Minúsculas, sin acentos y con espacios colapsados.
  static String normalize(String value) {
    final buffer = StringBuffer();
    for (final rune in value.toLowerCase().runes) {
      final character = String.fromCharCode(rune);
      buffer.write(_accentMap[character] ?? character);
    }
    return buffer.toString().replaceAll(_whitespace, ' ').trim();
  }

  /// Solo los dígitos del teléfono, para ignorar espacios, guiones y paréntesis.
  static String normalizePhone(String value) =>
      value.replaceAll(_nonDigits, '');

  /// Filtra y ordena prospectos por relevancia.
  ///
  /// Una consulta vacía devuelve todos los prospectos ordenados por nombre.
  static List<ProspectRecord> filter(
    Iterable<ProspectRecord> records,
    String query, {
    int limit = defaultLimit,
  }) {
    if (limit <= 0) return const [];
    final normalizedQuery = normalize(query);
    if (normalizedQuery.isEmpty) {
      final all = records.where((prospect) => prospect.id != null).toList()
        ..sort(_byName);
      return all.take(limit).toList();
    }

    final tokens = normalizedQuery
        .split(' ')
        .where((token) => token.isNotEmpty)
        .toList();
    final matches = <_RankedProspect>[];
    for (final prospect in records) {
      if (prospect.id == null) continue;
      if (!_matches(prospect, tokens)) continue;
      matches.add(
        _RankedProspect(prospect, _score(prospect, normalizedQuery, tokens)),
      );
    }

    matches.sort((first, second) {
      final byScore = first.score.compareTo(second.score);
      return byScore != 0 ? byScore : _byName(first.prospect, second.prospect);
    });
    return matches
        .take(limit)
        .map((match) => match.prospect)
        .toList(growable: false);
  }

  /// Sugerencias para la pantalla inicial del buscador.
  ///
  /// Prioriza los contactos pendientes para hoy o atrasados, después las
  /// asignaciones de los últimos siete días y completa con el resto en orden
  /// alfabético.
  static List<ProspectSuggestion> suggestions(
    Iterable<ProspectRecord> records, {
    required DateTime now,
    int limit = defaultSuggestionLimit,
  }) {
    if (limit <= 0) return const [];

    final unique = <int, ProspectRecord>{};
    for (final prospect in records) {
      final id = prospect.id;
      if (id != null) unique[id] = prospect;
    }

    final selected = <int>{};
    final result = <ProspectSuggestion>[];
    final endOfDay = DateTime(now.year, now.month, now.day + 1);

    final upcoming =
        unique.values
            .where(
              (prospect) =>
                  prospect.nextContact != null &&
                  prospect.nextContact!.isBefore(endOfDay),
            )
            .toList()
          ..sort((first, second) {
            final byDate = first.nextContact!.compareTo(second.nextContact!);
            return byDate != 0 ? byDate : _byName(first, second);
          });

    for (final prospect in upcoming.take(_suggestionGroupLimit)) {
      if (result.length >= limit) break;
      if (!selected.add(prospect.id!)) continue;
      result.add(
        ProspectSuggestion(prospect, ProspectSuggestionReason.upcomingContact),
      );
    }

    final cutoff = now.subtract(_recentAssignmentWindow);
    final recentlyAssigned =
        unique.values
            .where(
              (prospect) =>
                  !selected.contains(prospect.id) &&
                  prospect.assignedAt != null &&
                  !prospect.assignedAt!.isBefore(cutoff) &&
                  !prospect.assignedAt!.isAfter(now),
            )
            .toList()
          ..sort((first, second) {
            final byDate = second.assignedAt!.compareTo(first.assignedAt!);
            return byDate != 0 ? byDate : _byName(first, second);
          });

    for (final prospect in recentlyAssigned.take(_suggestionGroupLimit)) {
      if (result.length >= limit) break;
      if (!selected.add(prospect.id!)) continue;
      result.add(
        ProspectSuggestion(prospect, ProspectSuggestionReason.recentlyAssigned),
      );
    }

    if (result.length < limit) {
      final remaining =
          unique.values
              .where((prospect) => !selected.contains(prospect.id))
              .toList()
            ..sort(_byName);
      for (final prospect in remaining) {
        if (result.length >= limit) break;
        result.add(
          ProspectSuggestion(prospect, ProspectSuggestionReason.other),
        );
      }
    }

    return List.unmodifiable(result);
  }

  static bool _matches(ProspectRecord prospect, List<String> tokens) {
    for (final token in tokens) {
      if (_isPhoneToken(token)) {
        if (!normalizePhone(prospect.phone).contains(normalizePhone(token))) {
          return false;
        }
        continue;
      }
      if (!_textHaystack(prospect).contains(token)) return false;
    }
    return true;
  }

  static int _score(
    ProspectRecord prospect,
    String query,
    List<String> tokens,
  ) {
    final name = normalize(prospect.name);
    final email = normalize(prospect.email);
    final phone = normalizePhone(prospect.phone);

    if (_isPhoneQuery(query)) {
      final digits = normalizePhone(query);
      if (phone == digits) return 0;
      if (phone.endsWith(digits)) return 1;
      if (phone.contains(digits)) return 2;
    }

    if (name == query) return 3;
    if (name.startsWith(query)) return 4;

    final words = name.split(' ').where((word) => word.isNotEmpty).toList();
    if (words.any((word) => word.startsWith(query))) return 5;
    if (name.contains(query)) return 6;
    if (email.startsWith(query)) return 7;
    if (email.contains(query)) return 8;
    if (_textHaystack(prospect).contains(query)) return 9;

    var best = 9;
    for (final token in tokens) {
      if (_isPhoneToken(token)) {
        final digits = normalizePhone(token);
        if (digits.length < 3) continue;
        if (phone == digits) {
          best = math.min(best, 0);
        } else if (phone.endsWith(digits)) {
          best = math.min(best, 1);
        } else if (phone.contains(digits)) {
          best = math.min(best, 2);
        }
        continue;
      }

      if (name.startsWith(token)) {
        best = math.min(best, 4);
      } else if (words.any((word) => word.startsWith(token))) {
        best = math.min(best, 5);
      } else if (name.contains(token)) {
        best = math.min(best, 6);
      } else if (email.contains(token)) {
        best = math.min(best, 7);
      }
    }
    return best;
  }

  static String _textHaystack(ProspectRecord prospect) => normalize(
    [
      prospect.name,
      prospect.email,
      prospect.interestDevelopment,
      prospect.interestLot,
      prospect.company,
    ].where((value) => value.trim().isNotEmpty).join(' '),
  );

  static bool _isPhoneToken(String token) =>
      token.isNotEmpty &&
      _phoneCharacters.hasMatch(token) &&
      normalizePhone(token).length >= 3;

  static bool _isPhoneQuery(String query) => _isPhoneToken(query);

  static int _byName(ProspectRecord first, ProspectRecord second) {
    final byName = normalize(first.name).compareTo(normalize(second.name));
    if (byName != 0) return byName;
    return (first.id ?? 0).compareTo(second.id ?? 0);
  }
}

class _RankedProspect {
  const _RankedProspect(this.prospect, this.score);

  final ProspectRecord prospect;
  final int score;
}
