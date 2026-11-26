/// Política de bloqueo por intentos fallidos.
abstract final class LockoutPolicy {
  static const int attemptsBeforeLockout = 5;

  static const List<Duration> escalatingDurations = <Duration>[
    Duration(seconds: 30),
    Duration(minutes: 1),
    Duration(minutes: 5),
    Duration(minutes: 15),
    Duration(hours: 1),
  ];

  static Duration? lockoutFor(int failedAttempts) {
    if (failedAttempts < attemptsBeforeLockout) return null;
    final index = failedAttempts - attemptsBeforeLockout;
    if (index >= escalatingDurations.length) {
      return escalatingDurations.last;
    }
    return escalatingDurations[index];
  }
}

/// Estado del bloqueo.
///
/// Guardamos el **tiempo restante** y la última marca de tiempo vista, en vez
/// de una fecha absoluta de fin. Si el reloj del dispositivo se mueve hacia
/// atrás, el tiempo transcurrido se considera cero y el castigo no se acorta.
/// Es una mitigación, no una garantía: sin servidor nadie puede demostrar la
/// hora real, y un atacante con root o que reinstale la app puede borrar el
/// estado.
class LockoutState {
  const LockoutState({
    this.failedAttempts = 0,
    this.remainingMicros = 0,
    this.lastSeenMicros = 0,
  });

  final int failedAttempts;

  /// Microsegundos de castigo que aún quedan.
  final int remainingMicros;

  /// Microsegundos (reloj del dispositivo) de la última actualización.
  final int lastSeenMicros;

  /// Fecha estimada de fin (solo para compatibilidad con la UI anterior).
  DateTime? get lockedUntil => remainingMicros > 0
      ? DateTime.fromMicrosecondsSinceEpoch(
          lastSeenMicros + remainingMicros,
        ).toUtc()
      : null;

  /// Tiempo restante tras aplicar el reloj actual.
  Duration remaining([DateTime? now]) {
    if (remainingMicros <= 0) return Duration.zero;
    final current = (now ?? DateTime.now()).microsecondsSinceEpoch;
    final wallElapsed = current - lastSeenMicros;
    // Reloj hacia atrás => no avanza el castigo.
    final effectiveElapsed = wallElapsed > 0 ? wallElapsed : 0;
    final left = remainingMicros - effectiveElapsed;
    return left > 0 ? Duration(microseconds: left) : Duration.zero;
  }

  bool isLockedOut([DateTime? now]) => remaining(now) > Duration.zero;

  /// Avanza el castigo y devuelve el estado resultante (para persistir).
  LockoutState tick([DateTime? now]) {
    final current = (now ?? DateTime.now()).microsecondsSinceEpoch;
    if (remainingMicros <= 0) return this;
    final wallElapsed = current - lastSeenMicros;
    final effectiveElapsed = wallElapsed > 0 ? wallElapsed : 0;
    final left = remainingMicros - effectiveElapsed;
    if (left <= 0) return LockoutState(failedAttempts: failedAttempts);
    return LockoutState(
      failedAttempts: failedAttempts,
      remainingMicros: left,
      lastSeenMicros: current,
    );
  }

  LockoutState registerFailure(DateTime now) {
    final attempts = failedAttempts + 1;
    final duration = LockoutPolicy.lockoutFor(attempts);
    if (duration == null) {
      return LockoutState(failedAttempts: attempts);
    }
    return LockoutState(
      failedAttempts: attempts,
      remainingMicros: duration.inMicroseconds,
      lastSeenMicros: now.microsecondsSinceEpoch,
    );
  }

  LockoutState registerSuccess() => const LockoutState();

  static const LockoutState initial = LockoutState();

  Map<String, Object?> toJson() => <String, Object?>{
        'failedAttempts': failedAttempts,
        'remainingMicros': remainingMicros,
        'lastSeenMicros': lastSeenMicros,
      };

  factory LockoutState.fromJson(Map<String, Object?> json) {
    // Migración del formato antiguo con fecha absoluta.
    final oldDate = json['lockedUntil'] as String?;
    if (oldDate != null) {
      final until = DateTime.tryParse(oldDate);
      if (until != null) {
        final left = until.difference(DateTime.now()).inMicroseconds;
        return LockoutState(
          failedAttempts: (json['failedAttempts'] as int?) ?? 0,
          remainingMicros: left > 0 ? left : 0,
          lastSeenMicros: DateTime.now().microsecondsSinceEpoch,
        );
      }
    }
    return LockoutState(
      failedAttempts: (json['failedAttempts'] as int?) ?? 0,
      remainingMicros: (json['remainingMicros'] as int?) ?? 0,
      lastSeenMicros: (json['lastSeenMicros'] as int?) ?? 0,
    );
  }
}
