import 'package:flutter/material.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';

const _pickerShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.all(Radius.circular(24)),
);
const _pickerText = TextStyle(
  fontFamily: 'SulphurPoint',
  color: AppColors.agendaProspectBackground,
  fontSize: 15,
);

final _pickerAction = TextButton.styleFrom(
  foregroundColor: AppColors.primaryColor,
  textStyle: const TextStyle(fontFamily: 'BebasNeue', fontSize: 16),
  minimumSize: const Size(80, 44),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
);

final appDatePickerTheme = DatePickerThemeData(
  backgroundColor: AppColors.homeBackground,
  surfaceTintColor: Colors.transparent,
  shape: _pickerShape,
  headerBackgroundColor: AppColors.primaryColor,
  headerForegroundColor: AppColors.profileSincronizacion,
  headerHeadlineStyle: const TextStyle(fontFamily: 'BebasNeue', fontSize: 36),
  headerHelpStyle: const TextStyle(fontFamily: 'BebasNeue', fontSize: 16),
  weekdayStyle: _pickerText.copyWith(fontWeight: FontWeight.w700),
  dayStyle: _pickerText,
  yearStyle: _pickerText,
  dayForegroundColor: WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.disabled)) return AppColors.primaryColor;
    if (states.contains(WidgetState.selected)) return AppColors.profileSincronizacion;
    return AppColors.agendaProspectBackground;
  }),
  dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
    return states.contains(WidgetState.selected)
        ? AppColors.primaryColor
        : null;
  }),
  todayForegroundColor: const WidgetStatePropertyAll(AppColors.primaryColor),
  todayBackgroundColor: const WidgetStatePropertyAll(AppColors.profileSincronizacion),
  todayBorder: const BorderSide(color: AppColors.profileSincronizacion),
  yearForegroundColor: const WidgetStatePropertyAll(AppColors.primaryColor),
  yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
    return states.contains(WidgetState.selected)
        ? AppColors.profileSincronizacion
        : null;
  }),
  dividerColor: AppColors.primaryColor,
  cancelButtonStyle: _pickerAction,
  confirmButtonStyle: _pickerAction,
);

final appTimePickerTheme = TimePickerThemeData(
  backgroundColor: AppColors.homeBackground,
  shape: _pickerShape,
  helpTextStyle: _pickerText.copyWith(fontWeight: FontWeight.w700),
  hourMinuteShape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  ),
  hourMinuteColor: WidgetStateColor.resolveWith((states) {
    return states.contains(WidgetState.selected)
        ? AppColors.primaryColor
        : Colors.white;
  }),
  hourMinuteTextColor: WidgetStateColor.resolveWith((states) {
    return states.contains(WidgetState.selected)
        ? AppColors.profileSincronizacion
        : AppColors.primaryColor;
  }),
  hourMinuteTextStyle: const TextStyle(fontFamily: 'BebasNeue', fontSize: 52),
  dayPeriodColor: WidgetStateColor.resolveWith((states) {
    return states.contains(WidgetState.selected)
        ? AppColors.profileSincronizacion
        : Colors.white;
  }),
  dayPeriodTextColor: AppColors.primaryColor,
  dayPeriodTextStyle: _pickerText.copyWith(fontWeight: FontWeight.w700),
  dayPeriodBorderSide: const BorderSide(color: AppColors.primaryColor),
  dayPeriodShape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  dialBackgroundColor: Colors.white,
  dialHandColor: AppColors.primaryColor,
  dialTextColor: WidgetStateColor.resolveWith((states) {
    return states.contains(WidgetState.selected)
        ? AppColors.profileSincronizacion
        : AppColors.primaryColor;
  }),
  dialTextStyle: _pickerText,
  entryModeIconColor: AppColors.primaryColor,
  cancelButtonStyle: _pickerAction,
  confirmButtonStyle: _pickerAction,
);
