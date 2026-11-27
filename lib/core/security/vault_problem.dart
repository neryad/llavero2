import 'crypto/crypto_errors.dart';

/// Estado concreto de por qué no se pudo abrir la bóveda.
enum VaultProblem {
  newerFormat,
  corrupted,
  unreadable,
  missing,
}

/// Clasifica un error sin filtrar mensajes internos, rutas ni stack traces.
VaultProblem problemFor(Object error) {
  // UnsupportedVaultVersionException extiende TamperedDataException:
  // hay que comprobarla primero.
  if (error is UnsupportedVaultVersionException) return VaultProblem.newerFormat;
  if (error is MissingVaultException) return VaultProblem.missing;
  if (error is TamperedDataException || error is FormatException) {
    return VaultProblem.corrupted;
  }
  return VaultProblem.unreadable;
}
