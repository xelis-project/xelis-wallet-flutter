/// Progress emitted by a long-running native XELIS operation.
///
/// This model is authored Dart API and is independent from generated Flutter
/// Rust Bridge types.
final class ProgressReport {
  const ProgressReport({
    required this.progress,
    required this.step,
    this.message,
  });

  final double progress;
  final String step;
  final String? message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProgressReport &&
          progress == other.progress &&
          step == other.step &&
          message == other.message;

  @override
  int get hashCode => Object.hash(progress, step, message);
}
