import 'package:callerapp_frontend/data/local/onboarding_store.dart';
import 'package:callerapp_frontend/services/platform_support.dart';
import 'package:flutter/foundation.dart';

class OnboardingController extends ChangeNotifier {
  OnboardingController({OnboardingStore? store, bool? isAndroid})
    : _store = store ?? OnboardingStore(),
      _isAndroid = isAndroid ?? PlatformSupport.isAndroid;

  static final instance = OnboardingController();

  final OnboardingStore _store;
  final bool _isAndroid;
  bool _completed = true;

  bool get completed => _completed;

  Future<void> load() async {
    if (!_isAndroid) {
      _completed = true;
      notifyListeners();
      return;
    }
    try {
      _completed = await _store.isCompleted();
    } catch (_) {
      _completed = true;
    }
    notifyListeners();
  }

  Future<void> complete() async {
    _completed = true;
    notifyListeners();
    try {
      await _store.markCompleted();
    } catch (_) {
      // El onboarding nunca bloquea la aplicación por un fallo local.
    }
  }
}
