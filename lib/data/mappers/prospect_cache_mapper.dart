import 'dart:convert';

import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';
import 'package:callerapp_frontend/resources/colors/prospect_tag_colors.dart';

class ProspectCacheMapper {
  static Map<String, Object?> toRow(
    ProspectRecord prospect, {
    required int userId,
    required int developmentId,
  }) => {
    'user_id': userId,
    'development_id': developmentId,
    'prospect_id': prospect.id,
    'avatar_url': prospect.avatarUrl,
    'name': prospect.name,
    'phone': prospect.phone,
    'email': prospect.email,
    'status': prospect.status,
    'temperature': prospect.temperature,
    'appointment_at_ms': _dateToInt(prospect.appointment),
    'comments': prospect.comments,
    'product': prospect.product,
    'lot_description': prospect.lotDescription,
    'dimension': prospect.dimension,
    'full_price': prospect.fullPrice,
    'decision': _boolToInt(prospect.decision),
    'willingness': _boolToInt(prospect.willingness),
    'money': _boolToInt(prospect.money),
    'passed_to_to': _boolToInt(prospect.passedToTO),
    'discovery_complete': _boolToInt(prospect.discoveryComplete),
    'days_since_contact': prospect.daysSinceContact,
    'assigned_at_ms': _dateToInt(prospect.assignedAt),
    'next_contact_at_ms': _dateToInt(prospect.nextContact),
    'last_contact_result': prospect.lastContactResult,
    'last_call_duration_ms': prospect.lastCallDuration?.inMilliseconds,
    'last_call_at_ms': _dateToInt(prospect.lastCallAt),
    'last_call_status': prospect.lastCallStatus,
    'city': prospect.city,
    'company': prospect.company,
    'occupation': prospect.occupation,
    'origin': prospect.origin,
    'channel_id': prospect.channelId,
    'status_id': prospect.statusId,
    'campaign_id': prospect.campaignId,
    'interest_development_id': prospect.interestDevelopmentId,
    'interest_development': prospect.interestDevelopment,
    'interest_lot_id': prospect.interestLotId,
    'interest_lot': prospect.interestLot,
    'qualification_json': jsonEncode(prospect.qualification),
  };

  static ProspectRecord fromRow(Map<String, Object?> row) {
    final status = row['status']! as String;
    return ProspectRecord(
      id: row['prospect_id']! as int,
      avatarUrl: row['avatar_url'] as String?,
      name: row['name']! as String,
      phone: row['phone']! as String,
      email: row['email']! as String,
      status: status,
      temperature: row['temperature']! as String,
      avatarColor: AppColors.homeDeepTeal,
      statusColor: ProspectTagColors.status(status),
      appointment: _intToDate(row['appointment_at_ms']),
      comments: row['comments'] as String?,
      product: row['product']! as String,
      lotDescription: row['lot_description']! as String,
      dimension: (row['dimension']! as num).toDouble(),
      fullPrice: (row['full_price']! as num).toDouble(),
      decision: _intToBool(row['decision']),
      willingness: _intToBool(row['willingness']),
      money: _intToBool(row['money']),
      passedToTO: _intToBool(row['passed_to_to']),
      discoveryComplete: _intToBool(row['discovery_complete']),
      daysSinceContact: row['days_since_contact']! as int,
      assignedAt: _intToDate(row['assigned_at_ms']),
      nextContact: _intToDate(row['next_contact_at_ms']),
      lastContactResult: row['last_contact_result']! as String,
      lastCallDuration: switch (row['last_call_duration_ms']) {
        final int milliseconds => Duration(milliseconds: milliseconds),
        _ => null,
      },
      lastCallAt: _intToDate(row['last_call_at_ms']),
      lastCallStatus: row['last_call_status'] as String?,
      city: row['city']! as String,
      company: row['company']! as String,
      occupation: row['occupation']! as String,
      origin: row['origin']! as String,
      channelId: row['channel_id'] as int?,
      statusId: row['status_id'] as int?,
      campaignId: row['campaign_id'] as int?,
      interestDevelopmentId: row['interest_development_id'] as int?,
      interestDevelopment: row['interest_development']! as String,
      interestLotId: row['interest_lot_id'] as int?,
      interestLot: row['interest_lot']! as String,
      qualification: (jsonDecode(row['qualification_json']! as String) as List)
          .cast<String>(),
    );
  }

  static int? _dateToInt(DateTime? value) => value?.millisecondsSinceEpoch;

  static DateTime? _intToDate(Object? value) => switch (value) {
    final int milliseconds => DateTime.fromMillisecondsSinceEpoch(milliseconds),
    _ => null,
  };

  static int _boolToInt(bool value) => value ? 1 : 0;
  static bool _intToBool(Object? value) => value == 1;
}
