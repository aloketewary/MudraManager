import 'package:mudra_manager/core/l10n/app_localizations.dart';

enum BudgetType {
  categoryWise,
  tagWise,
  dayWise,
  festival,
  travel,
}

extension BudgetTypeExtension on BudgetType {
  String localizedName(AppLocalizations ctxt) => switch (this) {
    BudgetType.categoryWise => ctxt.budget_typeCategoryWise,
    BudgetType.tagWise => ctxt.budget_typeTagWise,
    BudgetType.dayWise => ctxt.budget_typeDayWise,
    BudgetType.festival => ctxt.budget_typeFestival,
    BudgetType.travel => ctxt.budget_typeTravel,
  };

  String localizedDesc(AppLocalizations ctxt) => switch (this) {
    BudgetType.categoryWise => ctxt.budget_typeDescCategoryWise,
    BudgetType.tagWise => ctxt.budget_typeDescTagWise,
    BudgetType.dayWise => ctxt.budget_typeDescDayWise,
    BudgetType.festival => ctxt.budget_typeDescFestival,
    BudgetType.travel => ctxt.budget_typeDescTravel,
  };

  /// Fallback for non-UI contexts (backup, serialization)
  String get displayName => switch (this) {
    BudgetType.categoryWise => 'Category-wise',
    BudgetType.tagWise => 'Tag-wise',
    BudgetType.dayWise => 'Daily',
    BudgetType.festival => 'Festival',
    BudgetType.travel => 'Travel',
  };
}
