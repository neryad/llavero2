import '../../core/security/pin_validator.dart';
import '../../l10n/generated/app_l10n.dart';

/// Mensaje claro y localizado para cada problema de PIN.
String pinIssueMessage(PinIssue issue, L10n l10n) {
  switch (issue) {
    case PinIssue.tooShort:
      return l10n.pinTooShort;
    case PinIssue.tooLong:
      return l10n.pinTooLong;
    case PinIssue.notDigits:
      return l10n.pinNotDigits;
    case PinIssue.repeated:
      return l10n.pinRepeated;
    case PinIssue.sequential:
      return l10n.pinSequential;
    case PinIssue.tooCommon:
      return l10n.pinTooCommon;
    case PinIssue.ok:
      return '';
  }
}
