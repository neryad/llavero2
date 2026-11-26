import '../../controllers/categories_controller.dart';
import '../../core/theme/category_colors.dart';
import '../../l10n/generated/app_l10n.dart';

/// Nombre visible de una categoría, por defecto o personalizada.
String categoryDisplayName(
  String id,
  L10n l10n,
  CategoriesController categories,
) {
  switch (id) {
    case CategoryIds.wifi:
      return l10n.categoryWifi;
    case CategoryIds.email:
      return l10n.categoryEmail;
    case CategoryIds.streaming:
      return l10n.categoryStreaming;
    case CategoryIds.banking:
      return l10n.categoryBanking;
    case CategoryIds.pinCode:
      return l10n.categoryPin;
    case CategoryIds.social:
      return l10n.categorySocial;
    case CategoryIds.devices:
      return l10n.categoryDevices;
    case CategoryIds.documents:
      return l10n.categoryDocuments;
    case CategoryIds.other:
      return l10n.categoryOther;
    default:
      return categories.byId(id)?.name ?? l10n.categoryOther;
  }
}
