import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Store values immediately, but never ask widgets to rebuild during a locked
/// build/dispose phase. Multiple writes in a frame publish the latest value once.
class FrameSafeValueNotifier<T> extends ValueNotifier<T> {
  bool _scheduled = false;
  bool _disposed = false;
  FrameSafeValueNotifier(super.value);

  @override
  void notifyListeners() {
    if (_disposed) return;
    SchedulerBinding? binding;
    try {
      binding = SchedulerBinding.instance;
    } catch (_) {
      // Model-only callers may run before a Flutter binding exists.
      super.notifyListeners();
      return;
    }
    final phase = binding.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      _scheduled = false;
      super.notifyListeners();
      return;
    }
    if (_scheduled) return;
    _scheduled = true;
    binding.addPostFrameCallback((_) {
      if (!_scheduled || _disposed) return;
      _scheduled = false;
      super.notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _scheduled = false;
    super.dispose();
  }
}
