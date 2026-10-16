const businessUtcOffset = Duration(hours: -5);

DateTime businessTimeFromInstant(DateTime instant) {
  final shifted = instant.toUtc().add(businessUtcOffset);
  return DateTime(
    shifted.year,
    shifted.month,
    shifted.day,
    shifted.hour,
    shifted.minute,
    shifted.second,
    shifted.millisecond,
    shifted.microsecond,
  );
}

DateTime businessNow() => businessTimeFromInstant(DateTime.now());

String businessTimeToUtcIso8601(DateTime value) => DateTime.utc(
  value.year,
  value.month,
  value.day,
  value.hour,
  value.minute,
  value.second,
  value.millisecond,
  value.microsecond,
).subtract(businessUtcOffset).toIso8601String();
