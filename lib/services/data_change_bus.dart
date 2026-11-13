import 'dart:async';

import 'package:flutter/foundation.dart';

class DataChangeBus extends ChangeNotifier {
  DataChangeBus({this.debounce = const Duration(milliseconds: 120)});

  static final instance = DataChangeBus();

  final Duration debounce;
  Timer? _timer;
  int _revision = 0;

  int get revision => _revision;

  void notify({bool prospects = false, bool agenda = false}) {
    if (!prospects && !agenda) return;
    _timer?.cancel();
    _timer = Timer(debounce, () {
      _revision++;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
