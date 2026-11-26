/// Política de bloqueo por intentos fallidos.
///
/// Después de [attemptsBeforeLockout] PIN incorrectos, la app se bloquea un
/// rato. Cada intento fallido siguiente aumenta el castigo:
///
/// | Intento fallido | Bloqueo |
/// |---|---|
/// | 5 | 30 s |
/// | 6 | 1 min |
/// | 7 | 5 min |
/// | 8 | 15 min |
/// | 9 o más | 1 h |
///
/// El estado (intentos fallidos y hasta cuándo está bloqueada) se guarda
/// en el dispositivo, así que reiniciar la app no "reinicia" la castigo.
abstract final class LockoutPolicy {
  /// Número de intentos fallidos antes del primer bloqueo.
  static const int attemptsBeforeLockout = 5;

  /// Castigos escalonados, del más corto al más largo.
  static const List<Duration> escalatingDurations = <Duration>[
    Duration(seconds: 30),
    Duration(minutes: 1),
    Duration(minutes: 5),
    Duration(minutes: 15),
    Duration(hours: 1),
  ];

  /// Duración del bloqueo tras [failedAttempts] fallos.
  ///
  /// Devuelve `null` si todavía no toca bloquear.
  static Duration? lockoutFor(int failedAttempts) {
    if (failedAttempts < attemptsBeforeLockout) return null;
    final index = failedAttempts - attemptsBeforeLockout;
    if (index >= escalatingDurations.length) {
      return escalatingDurations.last;
    }
    return escalatingDurations[index];
  }
}

/// Estado del bloqueo: cuántos intentos han fallado y hasta cuándo.
///
/// Es una clase suelta de datos (sin Flutter) para poder guardarla y
/// recuperarla fácilmente, y testearla sin montar nada.
class LockoutState {
  const LockoutState({this.failedAttempts = 0, this.lockedUntil});

  /// Número de PIN incorrectos seguidos.
  final int failedAttempts;

  /// Momento (UTC) hasta el que la app está bloqueada, si lo está.
  final DateTime? lockedUntil;

  /// `true` si la app está bloqueada en este momento.
  bool isLockedOut([DateTime? now]) {
    final until = lockedUntil;
    if (until == null) return false;
    final reference = now ?? DateTime.now();
    return reference.isBefore(until);
  }

  /// Tiempo que queda de bloqueo (cero si no está bloqueada).
  Duration remaining([DateTime? now]) {
    final until = lockedUntil;
    if (until == null) return Duration.zero;
    final reference = now ?? DateTime.now();
    final left = until.difference(reference);
    return left.isNegative ? Duration.zero : left;
  }

  /// Registra un PIN incorrecto y devuelve el nuevo estado.
  LockoutState registerFailure(DateTime now) {
    final attempts = failedAttempts + 1;
    final duration = LockoutPolicy.lockoutFor(attempts);
    if (duration == null) {
      return LockoutState(failedAttempts: attempts);
    }
    return LockoutState(
      failedAttempts: attempts,
      lockedUntil: now.add(duration).toUtc(),
    );
  }

  /// Registra un acierto: se borran los intentos anteriores.
  LockoutState registerSuccess() => const LockoutState();

  /// Estado inicial (sin intentos fallidos).
  static const LockoutState initial = LockoutState();

  /// Convierte el estado a JSON para guardarlo.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'failedAttempts': failedAttempts,
      'lockedUntil': lockedUntil?.toUtc().toIso8601String(),
    };
  }

  /// Lee el estado desde JSON.
  factory LockoutState.fromJson(Map<String, Object?> json) {
    final rawDate = json['lockedUntil'] as String?;
    return LockoutState(
      failedAttempts: (json['failedAttempts'] as int?) ?? 0,
      lockedUntil: rawDate == null ? null : DateTime.parse(rawDate),
    );
  }
}
