typedef RuntimeInitializer = Future<void> Function();
typedef ConfiguredRuntimeInitializer<Configuration> =
    Future<void> Function(Configuration configuration);

/// Guards a process-level initializer.
///
/// Concurrent callers share one attempt. Successful initialization is
/// idempotent, while a failed attempt can be retried.
final class RuntimeLifecycle {
  RuntimeLifecycle({required RuntimeInitializer initializeRuntime})
    : _initializeRuntime = initializeRuntime;

  final RuntimeInitializer _initializeRuntime;

  Future<void>? _initialization;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() {
    if (_isInitialized) {
      return Future<void>.value();
    }

    final initialization = _initialization;
    if (initialization != null) {
      return initialization;
    }

    final trackedInitialization = Future<void>.sync(_initializeRuntime)
        .then<void>((_) {
          _isInitialized = true;
        })
        .whenComplete(() {
          _initialization = null;
        });
    _initialization = trackedInitialization;
    return trackedInitialization;
  }
}

/// Guards a process-level initializer whose successful configuration is fixed.
///
/// Concurrent calls using the same configuration share one attempt. A failed
/// attempt can be retried, while a conflicting configuration is rejected.
final class ConfiguredRuntimeLifecycle<Configuration> {
  ConfiguredRuntimeLifecycle({
    required ConfiguredRuntimeInitializer<Configuration> initializeRuntime,
  }) : _initializeRuntime = initializeRuntime;

  final ConfiguredRuntimeInitializer<Configuration> _initializeRuntime;

  Future<void>? _initialization;
  Configuration? _pendingConfiguration;
  Configuration? _configuration;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initialize(Configuration configuration) {
    if (_isInitialized) {
      if (_configuration == configuration) {
        return Future<void>.value();
      }
      return Future<void>.error(
        StateError('The runtime service is already configured.'),
      );
    }

    final initialization = _initialization;
    if (initialization != null) {
      if (_pendingConfiguration == configuration) {
        return initialization;
      }
      return Future<void>.error(
        StateError('The runtime service is being configured differently.'),
      );
    }

    _pendingConfiguration = configuration;
    late final Future<void> trackedInitialization;
    trackedInitialization =
        Future<void>.sync(() => _initializeRuntime(configuration))
            .then<void>((_) {
              _configuration = configuration;
              _isInitialized = true;
            })
            .whenComplete(() {
              if (identical(_initialization, trackedInitialization)) {
                _initialization = null;
                _pendingConfiguration = null;
              }
            });
    _initialization = trackedInitialization;
    return trackedInitialization;
  }
}
