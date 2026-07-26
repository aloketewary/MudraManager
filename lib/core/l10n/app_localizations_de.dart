// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get onboard_manageYourMoneyDescription =>
      '100% offline. Ihre Daten verlassen niemals Ihr Gerät.';

  @override
  String onboard_welcomeToApp(Object appName) {
    return 'Willkommen bei $appName';
  }

  @override
  String get onboard_TrackYourTransactions =>
      'Automatische Verfolgung durch Bank-SMS';

  @override
  String get onboard_SeeWhereYourMoneyGoes =>
      'Automatischer Import von Bank-SMS und Benachrichtigungen. Funktioniert mit über 50 Banken.';

  @override
  String get onboard_SetBudgetsAndGoals =>
      'Budgets, Ziele & intelligente Warnungen';

  @override
  String get onboard_stayOnTrackAndAchieveYourDream =>
      'Erhalten Sie Warnungen, bevor Sie zu viel ausgeben. Sparen Sie für das, was wichtig ist.';

  @override
  String get onboard_GetStarted => 'Loslegen!';

  @override
  String get onboard_letsSetupYourAccount =>
      'Lassen Sie uns Ihr Konto einrichten.';

  @override
  String get onboard_howShouldWeCallYou => 'Wie sollen wir Sie nennen?';

  @override
  String get onboard_enterYourNameToPersonalizeYourExperience =>
      'Geben Sie Ihren Namen ein, um Ihre Erfahrung zu personalisieren.';

  @override
  String get onboard_enterYourName => 'Geben Sie Ihren Namen ein';

  @override
  String get onboard_setupYourFirstAccount => 'Erstes Konto einrichten';

  @override
  String get onboard_letsCreateYourFirstAccount =>
      'Lassen Sie uns Ihr erstes Konto erstellen (z. B. Bargeld).';

  @override
  String get onboard_accountName => 'Kontoname';

  @override
  String get onboard_initialBalance => 'Anfangssaldo';

  @override
  String get onboard_youCanUpdateOtherDetailsLaterAsWell =>
      'Sie können andere Details auch später noch aktualisieren.';

  @override
  String onboard_pleaseFillThe(Object inputName) {
    return 'Bitte füllen Sie das Feld \"$inputName\" aus';
  }

  @override
  String onboard_pleaseEnterAValidNumberFor(Object hintText) {
    return 'Bitte geben Sie eine gültige Zahl für \"$hintText\" ein';
  }

  @override
  String get onboard_youAreAllSet => 'Alles bereit!';

  @override
  String get onboard_letsStartManagingYourMoneyWisely =>
      'Fangen wir an, Ihr Geld klug zu verwalten.';

  @override
  String get app_settings_appbar_title => 'App-Einstellungen';

  @override
  String get language_settings_appbar_title => 'Sprache wählen';

  @override
  String get app_settings_language_title => 'Sprache';

  @override
  String get app_settings_language_subtitle => 'Wählen Sie Ihre Sprache';

  @override
  String get app_settings_theme_mode_title => 'Design-Modus';

  @override
  String get app_settings_theme_mode_light => 'Hell';

  @override
  String get app_settings_theme_mode_dark => 'Dunkel';

  @override
  String get app_settings_theme_mode_system_default => 'Systemstandard';

  @override
  String get app_settings_theme_mode_amoled => 'AMOLED';

  @override
  String get app_settings_theme_mode_subtitle =>
      'Wählen Sie Ihr bevorzugtes Design';

  @override
  String get app_settings_daily_reminder_title => 'Tägliche Ausgabenerinnerung';

  @override
  String get home_screen_title => 'Start';

  @override
  String get transaction_screen_title => 'Aktivität';

  @override
  String get statistics_screen_title => 'Statistiken';

  @override
  String get profile_screen_title => 'Profil';

  @override
  String get add_edit_transaction_screen_title => 'Transaktion hinzufügen';

  @override
  String get transaction_list_screen_title => 'Transaktionsliste';

  @override
  String get transaction_listViewGroupTodayLabel => 'Heute';

  @override
  String get transaction_listViewGroupYesterdayLabel => 'Gestern';

  @override
  String get greeting_good_morning_text => 'Guten Morgen';

  @override
  String get greeting_good_afternoon_text => 'Guten Tag';

  @override
  String get greeting_good_evening_text => 'Guten Abend';

  @override
  String get greeting_good_night_text => 'Gute Nacht';

  @override
  String get greeting_hello_text => 'Hallo';

  @override
  String get transaction_type_income => 'Einkommen';

  @override
  String get transaction_type_expense => 'Ausgabe';

  @override
  String get dashboard_add_transaction_text => 'Transaktion hinzufügen';

  @override
  String get dashboard_add_transfer_text => 'Überweisung';

  @override
  String get dashboard_cash_flow_text => 'Cashflow';

  @override
  String get cash_flow_filter_type_day => 'Tag';

  @override
  String get cash_flow_filter_type_week => 'Woche';

  @override
  String get cash_flow_filter_type_month => 'Monat';

  @override
  String get cash_flow_filter_type_year => 'Jahr';

  @override
  String get dashboard_mini_budget_text => 'Budget';

  @override
  String get dashboard_mini_budget_not_found_text =>
      'Keine Budgets definiert, fügen Sie eines hinzu!';

  @override
  String get dashboard_mini_budget_add_text => 'Budget hinzufügen';

  @override
  String get transaction_list_cash_flow_screen_title => 'Transaktionen';

  @override
  String get transaction_list_filter_all => 'Alle';

  @override
  String get transaction_list_filter_income => 'Einkommen';

  @override
  String get transaction_list_filter_expense => 'Ausgabe';

  @override
  String get transaction_list_pending_transaction_message_text =>
      '⚡ Neue Transaktionen gefunden! Jetzt prüfen';

  @override
  String get transaction_listPendingTransactionMessageActionLabel => 'Prüfen';

  @override
  String get transaction_noTransactionFoundText =>
      'Keine Transaktionen gefunden.';

  @override
  String get transaction_deleteAlertTitleText => 'Transaktion löschen?';

  @override
  String get transaction_deleteAlertBodyText =>
      'Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get transaction_deleteButtonActionText => 'Löschen';

  @override
  String get transaction_cancelButtonActionText => 'Abbrechen';

  @override
  String get transaction_filterCategoryText => 'Transaktionen filtern';

  @override
  String transaction_noteDescriptionText(Object description) {
    return 'Hinweis: $description';
  }

  @override
  String get calendar_week_monday_initial_text => 'M';

  @override
  String get calendar_week_tuesday_initial_text => 'D';

  @override
  String get calendar_week_wednesday_initial_text => 'M';

  @override
  String get calendar_week_thursday_initial_text => 'D';

  @override
  String get calendar_week_friday_initial_text => 'F';

  @override
  String get calendar_week_saturday_initial_text => 'S';

  @override
  String get calendar_week_sunday_initial_text => 'S';

  @override
  String get dashboard_netWorthTitle => 'Nettovermögen';

  @override
  String get budget_dashboardMiniCardBudgetTitleText => 'Budget';

  @override
  String get budget_dashboardMiniCardSpentTitleText => 'Ausgegeben';

  @override
  String get budget_dashboardPageTitle => 'Budget-Details';

  @override
  String get budget_dashboardNotFoundText =>
      'Keine Budgets definiert, fügen Sie eines hinzu!';

  @override
  String get budget_dashboardAddBudgetText => 'Budget hinzufügen';

  @override
  String get budget_categoriesTitle => 'Kategorien';

  @override
  String budget_dashboardPieChartLabelText(
      Object spentPercent, Object title, Object totalPercent) {
    return '$title ($totalPercent des Gesamtwerts, $spentPercent des ausgegebenen Betrags)';
  }

  @override
  String get budget_buttonDeleteTitleText => 'Budget löschen?';

  @override
  String get budget_buttonDeleteBodyText =>
      'Dies entfernt das Budget und seine Zuweisungen. Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get budget_buttonDeleteActionText => 'Löschen';

  @override
  String get budget_buttonCancelActionText => 'Abbrechen';

  @override
  String get budget_buttonAddText => 'Budget hinzufügen';

  @override
  String get budget_buttonEditText => 'Budget bearbeiten';

  @override
  String get budget_budgetNameControllerText => 'Budgetname';

  @override
  String get budget_budgetAmountControllerText => 'Gesamtbetrag';

  @override
  String get budget_recurrenceControllerText => 'Wiederholung';

  @override
  String get budget_nameRequiredHintText => 'Budgetname ist erforderlich';

  @override
  String get budget_amountRequiredHintText =>
      'Gültiger Betrag ist erforderlich';

  @override
  String get budget_selectStartDateText => 'Startdatum wählen';

  @override
  String budget_selectedStartDateText(Object startDate) {
    return 'Start: $startDate';
  }

  @override
  String get budget_selectEndDateText => 'Enddatum wählen';

  @override
  String budget_selectedEndDateText(Object endDate) {
    return 'Ende: $endDate';
  }

  @override
  String get budget_categoryTitle => 'Kategorien & Zuweisungen wählen';

  @override
  String get budget_allocateAmountText => 'Betrag zuweisen';

  @override
  String get budget_categoryMessageInfoText =>
      'Sie können Kategoriezuweisungen manuell eingeben oder sie leer lassen, um den verbleibenden Betrag automatisch gleichmäßig zu verteilen.';

  @override
  String budget_totalAllocatedBudgetText(Object totalAlloc) {
    return 'Gesamt zugewiesen: $totalAlloc';
  }

  @override
  String get budget_recurrenceText => 'Wiederholung';

  @override
  String get budget_recurrenceNoneText => 'Keine';

  @override
  String get budget_recurrenceDailyText => 'Täglich';

  @override
  String get budget_recurrenceWeeklyText => 'Wöchentlich';

  @override
  String get budget_recurrenceMonthlyText => 'Monatlich';

  @override
  String get budget_recurrenceYearlyText => 'Jährlich';

  @override
  String get budget_saveButtonText => 'Speichern';

  @override
  String get budget_updateButtonText => 'Aktualisieren';

  @override
  String get budget_pickBothDatesErrorText => 'Wählen Sie beide Daten';

  @override
  String get budget_selectAtLeastOneCategoryErrorText =>
      'Wählen Sie mindestens eine Kategorie';

  @override
  String get budget_allocatedAmountExceedsTotalBudgetText =>
      'Der zugewiesene Betrag übersteigt das Gesamtbudget';

  @override
  String get transaction_amountControllerText => 'Betrag';

  @override
  String get transaction_descriptionControllerText => 'Beschreibung (optional)';

  @override
  String get transaction_amountControllerErrorText => 'Betrag eingeben';

  @override
  String get transaction_selectAccountLabel => 'Konto wählen';

  @override
  String get transaction_selectCategoryLabel => 'Kategorie wählen';

  @override
  String get transaction_selectTagLabel => 'Tag wählen';

  @override
  String get transaction_addNewCategoryText => 'Neue \nKategorie';

  @override
  String get transaction_addNewTagText => 'Neuen Tag hinzufügen';

  @override
  String get transaction_tagNameControllerText => 'Tag-Name';

  @override
  String get transaction_saveTagButtonLabel => 'Tag speichern';

  @override
  String get transaction_saveTransactionButtonLabel => 'Transaktion speichern';

  @override
  String transaction_tripCurrencyMismatch(String currency) {
    return 'Trip is in $currency — amount will be converted';
  }

  @override
  String get transaction_customizeSplit => 'Customize Split';

  @override
  String get transaction_changeTrip => 'Change Trip';

  @override
  String transaction_remainingPercent(String percent) {
    return 'Remaining: $percent%';
  }

  @override
  String transaction_remainingAmount(String amount) {
    return 'Remaining: $amount';
  }

  @override
  String get transaction_splitEqual => 'Equal';

  @override
  String get transaction_splitCustom => 'Custom';

  @override
  String get transaction_participants => 'Participants';

  @override
  String get transaction_selectTrip => 'Select Trip';

  @override
  String get transaction_noneTripOption => 'None';

  @override
  String get transaction_tagNameHint => 'e.g., Travel, Food, Shopping';

  @override
  String transaction_suggestedCategory(String category) {
    return 'Suggested: $category';
  }

  @override
  String get transaction_tapToApply => 'Tap to apply';

  @override
  String stats_nTransactions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count txns',
      one: '$count txn',
    );
    return '$_temp0';
  }

  @override
  String get stats_selectRange => 'Select Range';

  @override
  String get stats_selectPeriod => 'Select Period';

  @override
  String get stats_thisWeek => 'This Week';

  @override
  String get stats_thisMonth => 'This Month';

  @override
  String get stats_thisYear => 'This Year';

  @override
  String get stats_customRange => 'Custom Range';

  @override
  String get export_noTemplatesTitle => 'No export templates enabled';

  @override
  String get export_noTemplatesDesc => 'Enable templates in Settings → Plugins';

  @override
  String export_nTemplatesAvailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count templates available',
      one: '1 template available',
    );
    return '$_temp0';
  }

  @override
  String export_completed(String format) {
    return '$format export completed';
  }

  @override
  String get common_refresh => 'Refresh';

  @override
  String get utility_financialAdvisory => 'Financial Advisory (Beta)';

  @override
  String utility_nItemsNeedAttention(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items may need attention',
      one: '1 item may need attention',
    );
    return '$_temp0';
  }

  @override
  String utility_advisoryCollapseSemantic(int count) {
    return 'Financial Advisory, $count items, tap to collapse';
  }

  @override
  String utility_advisoryExpandSemantic(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return 'Financial Advisory, $_temp0 may need attention, tap to expand';
  }

  @override
  String utility_nMoreItems(int count) {
    return '$count more items…';
  }

  @override
  String transaction_tripParticipantsSemantic(String name, int count) {
    return 'Trip: $name, $count participants';
  }

  @override
  String transaction_dateSemantic(String date) {
    return 'Transaction date: $date, tap to change';
  }

  @override
  String transaction_timeSemantic(String time) {
    return 'Transaction time: $time, tap to change';
  }

  @override
  String transaction_nParticipants(int count) {
    return '$count participants';
  }

  @override
  String get transaction_selectOneAccountErrorText =>
      'Wählen Sie mindestens ein Konto';

  @override
  String get transaction_selectOneCategoryErrorText =>
      'Wählen Sie mindestens eine Kategorie';

  @override
  String get transaction_incomeButtonLabel => 'EINKOMMEN';

  @override
  String get transaction_expenseButtonLabel => 'AUSGABE';

  @override
  String get statistics_weTrimDownDecimalInfoText =>
      'Wir runden Dezimalstellen ab, bitte runden Sie bei Bedarf auf.';

  @override
  String get statistics_selectPeriodTodayText => 'Heute';

  @override
  String get statistics_selectPeriodWeekText => 'Woche';

  @override
  String get statistics_selectPeriodMonthText => 'Monat';

  @override
  String get statistics_selectPeriodYearText => 'Jahr';

  @override
  String get statistics_chartLineIncomeText => 'Einkommen';

  @override
  String get statistics_chartLineExpenseText => 'Ausgabe';

  @override
  String statistics_chartLineTodayHourText(Object hour) {
    return '${hour}h';
  }

  @override
  String get statistics_categoryNotPresentText => 'Kategorie nicht vorhanden.';

  @override
  String get statistics_transactionNotPresentText =>
      'Keine Transaktionen vorhanden.';

  @override
  String get statistics_byCategoryTitleText => 'Nach Kategorie';

  @override
  String get statistics_recentTransactionsTitleText => 'Letzte Transaktionen';

  @override
  String get statistics_metricIncomeText => 'Einkommen';

  @override
  String get statistics_metricExpenseText => 'Ausgabe';

  @override
  String get statistics_metricNetText => 'Netto';

  @override
  String get statistics_showAllButtonText => 'Alle anzeigen';

  @override
  String get statistics_exportToPdfButtonText => 'Als PDF exportieren';

  @override
  String get statistics_exportToExcelButtonText => 'Nach Excel exportieren';

  @override
  String get profile_userProfileTitleText => 'Benutzerprofil';

  @override
  String get profile_userProfileSubtitleText =>
      'Profilbild, Name und E-Mail ändern';

  @override
  String get profile_nameControllerText => 'Name';

  @override
  String get profile_nameControllerHintText => 'Geben Sie Ihren Namen ein';

  @override
  String get profile_nameRequiredHintText => 'Name ist erforderlich';

  @override
  String get profile_emailControllerText => 'E-Mail';

  @override
  String get profile_emailControllerHintText => 'Geben Sie Ihre E-Mail ein';

  @override
  String get profile_phoneControllerText => 'Telefon';

  @override
  String get profile_phoneControllerHintText =>
      'Geben Sie Ihre Telefonnummer ein';

  @override
  String get profile_weAreNotStoringInfoText =>
      'Alle Ihre Daten verbleiben auf diesem Gerät. Keine Server, keine Cloud, kein Tracking.';

  @override
  String get profile_saveButtonText => 'Speichern';

  @override
  String get profile_editUserProfileAppTitle => 'Benutzerprofil bearbeiten';

  @override
  String get pendingTranx_reviewPendingTransactionsScreenTitle =>
      'Ausstehende Transaktionen';

  @override
  String get statistics_quickOverviewTitle => 'Schnellübersicht';

  @override
  String get statistics_insightsTitle => 'Einblicke';

  @override
  String get statistics_detailedAnalysisTitle => 'Detaillierte Analyse';

  @override
  String get statistics_categoryBreakdownSubtitle =>
      'Kategorienaufschlüsselung anzeigen';

  @override
  String get statistics_expenseTrendsTitle => 'Ausgabentrends';

  @override
  String get statistics_expenseTrendsSubtitle => 'Trends der letzten 12 Monate';

  @override
  String get statistics_recentTransactionsSubtitle => 'Letzte 5 Transaktionen';

  @override
  String get statistics_categoryBreakdownTitle => 'Kategorienaufschlüsselung';

  @override
  String get statistics_recentTransactionsModalTitle => 'Letzte Transaktionen';

  @override
  String get transfer_screenTitle => 'Geld überweisen';

  @override
  String get transfer_resetTooltip => 'Zurücksetzen';

  @override
  String get transfer_selectAccountsLabel => 'KONTEN WÄHLEN';

  @override
  String get transfer_fromLabel => 'VON';

  @override
  String get transfer_toLabel => 'NACH';

  @override
  String get transfer_detailsLabel => 'ÜBERWEISUNGSDETAILS';

  @override
  String get transfer_amountLabel => 'Betrag';

  @override
  String get transfer_amountValidationError => 'Gültigen Betrag eingeben';

  @override
  String get transfer_dateLabel => 'Datum';

  @override
  String get transfer_noteLabel => 'Notiz (optional)';

  @override
  String get transfer_buttonLabel => 'Überweisen';

  @override
  String get transfer_updateButtonLabel => 'Überweisung aktualisieren';

  @override
  String get transfer_errorLoadingAccounts => 'Fehler beim Laden der Konten';

  @override
  String get app_settings_themeModeModalTitle => 'Design-Modus';

  @override
  String get category_expenseLabel => 'AUSGABE';

  @override
  String get category_incomeLabel => 'EINKOMMEN';

  @override
  String get category_addTitle => 'Kategorie hinzufügen';

  @override
  String get category_editTitle => 'Kategorie bearbeiten';

  @override
  String get category_tapToChangeIcon => 'Zum Ändern des Icons tippen';

  @override
  String get category_nameLabel => 'Kategoriename';

  @override
  String get category_nameRequired => 'Erforderlich';

  @override
  String get category_typeLabel => 'Kategorietyp';

  @override
  String get category_colorLabel => 'Farbe';

  @override
  String get category_tapToChangeColor => 'ZUM ÄNDERN DER FARBE TIPPEN';

  @override
  String get category_saveButton => 'KATEGORIE SPEICHERN';

  @override
  String get category_updateButton => 'KATEGORIE AKTUALISIEREN';

  @override
  String get dashboard_incomeLabel => 'Einkommen';

  @override
  String get dashboard_spentLabel => 'Ausgegeben';

  @override
  String get dashboard_noDataLabel => 'Keine Daten';

  @override
  String get dashboard_editLabel => 'Bearbeiten';

  @override
  String get dashboard_archiveLabel => 'Archivieren';

  @override
  String get currency_crore_short => 'Cr';

  @override
  String get currency_lakh_short => 'L';

  @override
  String get currency_thousand_short => 'k';

  @override
  String common_errorText(Object error) {
    return 'Fehler: $error';
  }

  @override
  String get statistics_expenseShort => 'Ausg.';

  @override
  String get statistics_incomeShort => 'Eink.';

  @override
  String get transaction_categoryFilter => 'Kategoriefilter';

  @override
  String get transaction_dateFilter => 'Datumsfilter';

  @override
  String get transaction_allCategories => 'Alle Kategorien';

  @override
  String get transaction_applyFilters => 'FILTER ANWENDEN';

  @override
  String get sms_selectTransactions => 'Transaktionen wählen';

  @override
  String get common_addLabel => 'Hinzufügen';

  @override
  String get dashboard_removeLabel => 'Entfernen';

  @override
  String get dashboard_viewAllLabel => 'Alle anzeigen';

  @override
  String get common_noAccountsYet => 'Noch keine Konten';

  @override
  String get common_loading => 'Laden...';

  @override
  String get common_editLabel => 'Bearbeiten';

  @override
  String get common_deleteLabel => 'Löschen';

  @override
  String get common_fromLabel => 'Von';

  @override
  String get common_toLabel => 'Nach';

  @override
  String get theme_chooseThemeTitle => 'Design wählen';

  @override
  String get theme_applyThemeLabel => 'Design anwenden';

  @override
  String get theme_themeAppliedMessage => 'Design angewendet!';

  @override
  String get backup_backupRestoreTitle => 'Backup & Wiederherstellung';

  @override
  String get backup_backupDataTitle => 'Daten sichern';

  @override
  String get backup_backupDataSubtitle =>
      'Alle Datenbanken und Einstellungen exportieren';

  @override
  String get backup_restoreBackupTitle => 'Backup wiederherstellen';

  @override
  String get backup_restoreBackupSubtitle =>
      'Datenbank und Einstellungen importieren';

  @override
  String get backup_includeAttachmentsTitle => 'Anhänge einschließen?';

  @override
  String get backup_includeAttachmentsMessage =>
      'Belegbilder im Backup einschließen? Dies erhöht die Dateigröße.';

  @override
  String get backup_yesLabel => 'Ja';

  @override
  String get backup_noLabel => 'Nein';

  @override
  String get backup_completedMessage => 'Backup abgeschlossen';

  @override
  String get backup_restoreSuccessMessage => 'Wiederherstellung erfolgreich';

  @override
  String backup_lastBackupLabel(Object date) {
    return 'Letztes Backup: $date';
  }

  @override
  String get backup_noBackupFoundLabel => 'Kein Backup gefunden';

  @override
  String get categories_manageCategoriesTitle => 'Kategorien verwalten';

  @override
  String get categories_noCategoriesFound => 'Keine Kategorien gefunden.';

  @override
  String categories_transactionCount(Object count, Object plural) {
    return '$count Transaktion$plural';
  }

  @override
  String get categories_addCategoryLabel => 'Kategorie hinzufügen';

  @override
  String get categories_deleteCategoryTitle => 'Kategorie löschen';

  @override
  String get categories_deleteCategoryMessage =>
      'Sind Sie sicher, dass Sie diese Kategorie löschen möchten?\nAlle verknüpften Transaktionen werden ebenfalls entfernt.';

  @override
  String get categories_categoryDeletedMessage =>
      'Kategorie und ihre Transaktionen gelöscht';

  @override
  String get accounts_manageAccountsTitle => 'Konten verwalten';

  @override
  String get accounts_noAccountsAddedYet => 'Noch keine Konten hinzugefügt';

  @override
  String get accounts_addAccountLabel => 'Konto hinzufügen';

  @override
  String get accounts_deleteAccountTitle => 'Konto löschen';

  @override
  String accounts_deleteAccountMessage(Object accountName) {
    return 'Sind Sie sicher, dass Sie \"$accountName\" löschen möchten?';
  }

  @override
  String get accounts_archiveAccountTitle => 'Konto archivieren';

  @override
  String accounts_archiveAccountMessage(Object accountName) {
    return 'Sind Sie sicher, dass Sie \"$accountName\" archivieren möchten?';
  }

  @override
  String get accounts_cancelLabel => 'Abbrechen';

  @override
  String get accounts_archiveLabel => 'Archivieren';

  @override
  String accounts_accountArchivedMessage(Object accountName) {
    return '\"$accountName\" archiviert';
  }

  @override
  String get accounts_atLeastOneAccountRequired =>
      'Mindestens 1 Konto erforderlich, um fortzufahren';

  @override
  String get transaction_tripLabel => 'REISE';

  @override
  String get transaction_tripPartOfMessage =>
      'Diese Transaktion ist Teil der folgenden Reise(n)';

  @override
  String get sms_autoAddTooltip => 'Autom. Hinzufügen';

  @override
  String get sms_clearAllTooltip => 'Alle löschen';

  @override
  String get sms_importedFromSmsDescription => 'Autom. importiert';

  @override
  String get sms_selectAtLeastOneMessage =>
      'Bitte wählen Sie mindestens eine Transaktion aus';

  @override
  String get dashboard_allTimeLabel => 'Gesamtzeit';

  @override
  String get transaction_editTransactionTitle => 'Transaktion bearbeiten';

  @override
  String get transaction_addExpenseTitle => 'Ausgabe hinzufügen';

  @override
  String get transaction_addIncomeTitle => 'Einkommen hinzufügen';

  @override
  String get transaction_accountRequired => 'Konto ist erforderlich';

  @override
  String get transaction_categoryRequired => 'Kategorie ist erforderlich';

  @override
  String get transaction_dateLabel => 'Datum';

  @override
  String get transaction_addNoteHint => 'Notiz hinzufügen';

  @override
  String get transaction_enterValidAmountError =>
      'Bitte geben Sie einen gültigen Betrag ein.';

  @override
  String get sms_noPendingTransactions => 'Keine ausstehenden Transaktionen';

  @override
  String get sms_approveLabel => 'Genehmigen';

  @override
  String get sms_approveTransactionTitle => 'Transaktion genehmigen';

  @override
  String get onboard_SmartSmsTracking => 'Intelligentes SMS-Tracking';

  @override
  String get onboard_SmartSmsTrackingDesc =>
      'Erkennen und importieren Sie Transaktionen automatisch aus Ihren Bank-SMS-Nachrichten.';

  @override
  String get onboard_InsightsAndAnalytics => 'Einblicke & Analysen';

  @override
  String get onboard_InsightsAndAnalyticsDesc =>
      'Verstehen Sie Ihre Ausgabengewohnheiten mit detaillierten Diagrammen, Trends und intelligenten Einblicken.';

  @override
  String get onboard_SecureAndPrivate => 'Sicher & Privat';

  @override
  String get onboard_SecureAndPrivateDesc =>
      'Ihre Daten bleiben auf Ihrem Gerät. Keine Cloud, kein Tracking – nur verschlüsselter lokaler Speicher.';

  @override
  String get onboard_SmartAutoTracking => 'Intelligentes Auto-Tracking';

  @override
  String get onboard_SmartAutoTrackingDesc =>
      'Erkennen und importieren Sie Transaktionen automatisch aus Ihren Bank-Benachrichtigungen.';

  @override
  String get nav_activity => 'Aktivität';

  @override
  String get nav_manage => 'Verwalten';

  @override
  String get nav_insights => 'Einblicke';

  @override
  String get common_save => 'Speichern';

  @override
  String get common_cancel => 'Abbrechen';

  @override
  String get common_next => 'Weiter';

  @override
  String get common_back => 'Zurück';

  @override
  String get common_undo => 'Rückgängig';

  @override
  String get common_delete => 'Löschen';

  @override
  String get common_edit => 'Bearbeiten';

  @override
  String get common_add => 'Hinzufügen';

  @override
  String get common_done => 'Fertig';

  @override
  String get common_close => 'Schließen';

  @override
  String get common_inactive => 'Inactive';

  @override
  String get common_confirm => 'Bestätigen';

  @override
  String get common_archive => 'Archivieren';

  @override
  String get common_remove => 'Entfernen';

  @override
  String get common_search => 'Suche';

  @override
  String get common_filter => 'Filter';

  @override
  String get common_reset => 'Zurücksetzen';

  @override
  String get common_calculator => 'Calculator';

  @override
  String get common_customize => 'Customize';

  @override
  String get common_download => 'Download';

  @override
  String get common_notifications => 'Notifications';

  @override
  String get common_clear => 'Clear';

  @override
  String get common_viewDetails => 'Details anzeigen';

  @override
  String get common_apply => 'Anwenden';

  @override
  String get common_yes => 'Ja';

  @override
  String get common_no => 'Nein';

  @override
  String get common_ok => 'OK';

  @override
  String get common_retry => 'Wiederholen';

  @override
  String get common_noData => 'Keine Daten';

  @override
  String get common_error => 'Etwas ist schiefgelaufen';

  @override
  String get common_required => 'Erforderlich';

  @override
  String get common_maybeLater => 'Maybe later';

  @override
  String get title_budgets => 'Budgets';

  @override
  String get title_goals => 'Ziele';

  @override
  String get title_bills => 'Rechnungen';

  @override
  String get title_groups => 'Gruppen';

  @override
  String get title_trips => 'Reisen';

  @override
  String get title_shared => 'Geteilt';

  @override
  String get title_achievements => 'Erfolge';

  @override
  String get title_notifications => 'Benachrichtigungen';

  @override
  String get title_appearance => 'Erscheinungsbild';

  @override
  String get title_currency => 'Währung';

  @override
  String get title_security => 'Sicherheit';

  @override
  String get title_about => 'Über';

  @override
  String get title_analytics => 'Analysen';

  @override
  String get title_netWorth => 'Nettovermögen';

  @override
  String get title_financialHealth => 'Finanzielle Gesundheit';

  @override
  String get title_spendingPersonality => 'Ausgabenpersönlichkeit';

  @override
  String get title_monthlyRecap => 'Monatlicher Rückblick';

  @override
  String get title_compareMonths => 'Monate vergleichen';

  @override
  String get title_smsImport => 'SMS-Import';

  @override
  String get title_backupShare => 'Backup & Teilen';

  @override
  String get title_exchangeRates => 'Wechselkurse';

  @override
  String get title_recurringTransactions => 'Wiederkehrende Transaktionen';

  @override
  String get title_billControlCenter => 'Rechnungskontrollzentrum';

  @override
  String get title_plugins => 'Plugins';

  @override
  String get title_editCategory => 'Kategorie bearbeiten';

  @override
  String get title_allCategories => 'Alle Kategorien';

  @override
  String get title_exportOptions => 'Exportoptionen';

  @override
  String get title_dashboardLayout => 'Dashboard-Layout';

  @override
  String get section_activeMoney => 'Aktives Geld';

  @override
  String get section_planning => 'Planung';

  @override
  String get section_insights => 'Einblicke';

  @override
  String get section_coreSettings => 'Kerneinstellungen';

  @override
  String get section_appData => 'App & Daten';

  @override
  String get section_appearance => 'Erscheinungsbild';

  @override
  String get section_advanced => 'Erweitert';

  @override
  String get section_supportLegal => 'Support & Rechtliches';

  @override
  String get section_active => 'Aktiv';

  @override
  String get section_ongoing => 'Laufend';

  @override
  String get section_archive => 'Archiv';

  @override
  String get label_income => 'Einkommen';

  @override
  String get label_expense => 'Ausgabe';

  @override
  String get label_balance => 'Saldo';

  @override
  String get label_savings => 'Ersparnisse';

  @override
  String get label_total => 'Gesamt';

  @override
  String get label_amount => 'Betrag';

  @override
  String get label_date => 'Datum';

  @override
  String get label_category => 'Kategorie';

  @override
  String get label_account => 'Konto';

  @override
  String get label_description => 'Beschreibung';

  @override
  String get label_type => 'Typ';

  @override
  String get label_transfer => 'Überweisung';

  @override
  String get label_from => 'Von';

  @override
  String get label_to => 'Nach';

  @override
  String get label_all => 'Alle';

  @override
  String get label_today => 'Heute';

  @override
  String get label_yesterday => 'Gestern';

  @override
  String get label_thisWeek => 'Diese Woche';

  @override
  String get label_thisMonth => 'Diesen Monat';

  @override
  String get label_thisYear => 'Dieses Jahr';

  @override
  String get label_custom => 'Benutzerdefiniert';

  @override
  String get label_daily => 'Täglich';

  @override
  String get label_weekly => 'Wöchentlich';

  @override
  String get label_monthly => 'Monatlich';

  @override
  String get label_yearly => 'Jährlich';

  @override
  String get label_none => 'Keine';

  @override
  String get label_frequency => 'Häufigkeit';

  @override
  String get label_repeatEvery => 'Wiederholen alle';

  @override
  String get label_days => 'Tage';

  @override
  String get label_weeks => 'Wochen';

  @override
  String get label_months => 'Monate';

  @override
  String get label_years => 'Jahre';

  @override
  String get trip_expenses => 'Ausgaben';

  @override
  String get trip_settlements => 'Abrechnungen';

  @override
  String get trip_balances => 'Salden';

  @override
  String get trip_report => 'Bericht';

  @override
  String get trip_createTrip => 'Reise erstellen';

  @override
  String get trip_createGroup => 'Geteilte Gruppe erstellen';

  @override
  String get trip_editTrip => 'Reise bearbeiten';

  @override
  String get trip_archiveTrip => 'Reise archivieren';

  @override
  String get trip_archiveGroup => 'Gruppe archivieren';

  @override
  String get trip_trackTravel => 'Reiseausgaben mit Daten & Budget verfolgen';

  @override
  String get trip_splitBills => 'Rechnungen mit Freunden teilen';

  @override
  String get trip_live => 'Live';

  @override
  String get budget_spendingLimits => 'Ausgabenlimits';

  @override
  String get budget_savingsProgress => 'Sparfortschritt';

  @override
  String get budget_upcomingRecurring => 'Anstehend & wiederkehrend';

  @override
  String get budget_tripsAndSplits => 'Reisen & Teilungen';

  @override
  String import_importing(int count) {
    return '$count Transaktionen werden importiert...';
  }

  @override
  String get import_dontClose => 'Bitte schließen Sie die App nicht';

  @override
  String get import_complete => 'Import abgeschlossen!';

  @override
  String get import_failed => 'Import fehlgeschlagen';

  @override
  String get import_imported => 'Importiert';

  @override
  String get import_duplicatesSkipped => 'Duplikate übersprungen';

  @override
  String get import_errorsSkipped => 'Fehler/übersprungen';

  @override
  String get import_categoriesCreated => 'Kategorien erstellt';

  @override
  String get import_previewImport => 'Vorschau Import';

  @override
  String get recap_yourMonthAtGlance => 'Ihr Monat auf einen Blick';

  @override
  String get recap_trackProgressOverTime =>
      'Fortschritt im Laufe der Zeit verfolgen';

  @override
  String recap_transactions(int count) {
    return '$count Transaktionen';
  }

  @override
  String get recap_downloadPdf => 'PDF herunterladen';

  @override
  String get comparison_current => 'Aktuell';

  @override
  String comparison_byDay(int day) {
    return 'Bis Tag $day';
  }

  @override
  String get comparison_topCategories => 'Top-Kategorien';

  @override
  String get comparison_categoryImpact => 'KATEGORIE-AUSWIRKUNG';

  @override
  String get comparison_dailySpendingPace => 'Tägliches Ausgabentempo';

  @override
  String comparison_projected(String amount) {
    return 'Prognostiziert: $amount diesen Monat';
  }

  @override
  String get utility_customizeUtilities => 'Tools anpassen';

  @override
  String get utility_addUtilities => 'Tools hinzufügen';

  @override
  String get utility_analyticsSubtitle =>
      'Gesundheits-Score, Trends & Prognosen';

  @override
  String get utility_cashFlowSubtitle => 'Einnahmen vs. Ausgaben Prognosen';

  @override
  String get utility_spendingTrendsSubtitle => 'Kategorieweise Ausgabenmuster';

  @override
  String get utility_taxSubtitle => 'Einkommensteuer schätzen';

  @override
  String get profile_accounts => 'Konten';

  @override
  String get profile_manageAccounts => 'Verwalten Sie Ihre Konten';

  @override
  String get profile_categories => 'Kategorien';

  @override
  String get profile_manageCategories => 'Verwalten Sie Ihre Kategorien';

  @override
  String get profile_language => 'Sprache';

  @override
  String get profile_notifications => 'Benachrichtigungen';

  @override
  String get profile_dailyWeeklySummaries =>
      'Tägliche & wöchentliche Zusammenfassungen';

  @override
  String get profile_autoImport => 'Autom. Import';

  @override
  String get profile_autoImportDesc =>
      'Autom. Import aus Bank-Benachrichtigungen';

  @override
  String get profile_importExport => 'Import & Export';

  @override
  String get profile_importExportDesc => 'Excel Import & Export';

  @override
  String get profile_backupRestore => 'Backup & Wiederherstellung';

  @override
  String get profile_manageData => 'Verwalten Sie Ihre Daten';

  @override
  String get profile_themeDisplay => 'Design, Ton & Anzeige';

  @override
  String get profile_customizeWidgets => 'Widgets & Karten anpassen';

  @override
  String get profile_manageExtensions => 'Erweiterungen verwalten';

  @override
  String get profile_helpSupport => 'Hilfe & Support';

  @override
  String get profile_faqs => 'FAQs und Funktionsleitfäden';

  @override
  String get profile_aboutApp => 'Über die App';

  @override
  String get profile_versionInfo => 'Version & Info';

  @override
  String get profile_pinFingerprint => 'PIN oder Fingerabdruck';

  @override
  String get profile_upgradePro => 'Auf Pro upgraden';

  @override
  String get profile_unlimitedFeatures => 'Unbegrenzte Konten, Analysen & mehr';

  @override
  String get profile_freeTier => 'Kostenlose Stufe';

  @override
  String get profile_fullAccess => 'Vollzugriff';

  @override
  String get profile_proActive => 'Pro Aktiv';

  @override
  String get profile_yourAchievements => 'Ihre Erfolge';

  @override
  String get profile_bestStreak => 'Beste Serie';

  @override
  String get trips_active => 'AKTIV';

  @override
  String get trips_live => 'Live';

  @override
  String get trips_allSettled => 'Alles abgerechnet';

  @override
  String get tone_friendly_txnAdded =>
      'Erledigt! Transaktion gespeichert ✨|Hab\'s! Alles protokolliert 👍|Gespeichert! Du hast es voll im Griff ✨|Notiert! Eine weitere verfolgt 📝';

  @override
  String get tone_friendly_txnUpdated =>
      'Aktualisiert! Sieht gut aus 👍|Änderungen gespeichert! ✓|Alles aktualisiert! 👌';

  @override
  String get tone_friendly_txnDeleted =>
      'Weg! Transaktion entfernt 🗑️|Gelöscht! Eine weniger zu verfolgen|Entfernt! Tabula rasa 🗑️';

  @override
  String get tone_friendly_txnFailed =>
      'Hmm, konnte das nicht speichern. Erneut versuchen?';

  @override
  String get tone_friendly_enterAmount =>
      'Wie viel war es? Gib einen Betrag ein';

  @override
  String get tone_friendly_pickAccount =>
      'Welches Konto? Wähle eines aus, um fortzufahren';

  @override
  String get tone_friendly_pickCategory => 'Wofür war es? Wähle eine Kategorie';

  @override
  String get tone_friendly_fillAllFields =>
      'Fast geschafft — fülle alle Felder aus';

  @override
  String get tone_friendly_invalidAmount =>
      'Das sieht nicht richtig aus — gib einen gültigen Betrag ein';

  @override
  String get tone_friendly_budgetCreated =>
      'Budget festgelegt! Bleiben wir auf Kurs 💪|Budget fixiert! Du planst voraus 💪|Schön! Das Budget ist startklar 📊';

  @override
  String get tone_friendly_budgetUpdated => 'Budget aktualisiert!';

  @override
  String get tone_friendly_budgetDeleted => 'Budget entfernt';

  @override
  String get tone_friendly_goalCreated =>
      'Ziel gesetzt! Du schaffst das 🎯|Neues Ziel! Packen wir\'s an 🎯|Ziel fixiert! Den Preis fest im Blick 🎯';

  @override
  String get tone_friendly_goalUpdated => 'Ziel aktualisiert!';

  @override
  String get tone_friendly_goalDeleted => 'Ziel entfernt';

  @override
  String get tone_friendly_accountCreated => 'Konto hinzugefügt! 🏦';

  @override
  String get tone_friendly_billAdded =>
      'Rechnung erfasst! Ich erinnere dich 🔔';

  @override
  String get tone_friendly_billPaid =>
      'Super, Rechnung als bezahlt markiert! ✅|Rechnung erledigt! Eine Sorge weniger ✅|Bezahlt! Das ist eine Erleichterung ✅';

  @override
  String get tone_friendly_backupSuccess =>
      'Backup erledigt! Deine Daten sind sicher 🛡️';

  @override
  String get tone_friendly_restoreSuccess =>
      'Wiederhergestellt! Willkommen zurück 🎉';

  @override
  String get tone_friendly_noTransactions =>
      'Hier gibt es noch nichts\nFüge deine erste Transaktion hinzu, um loszulegen|Momentan leer\nFang an zu tracken — es dauert nur eine Sekunde|Noch keine Transaktionen\nDeine finanzielle Reise beginnt mit einem Eintrag';

  @override
  String get tone_friendly_noBudgets =>
      'Noch keine Budgets\nRichte eines ein, um deine Ausgaben zu verfolgen';

  @override
  String get tone_friendly_noGoals =>
      'Noch keine Ziele\nTräume groß — setze dein erstes Ziel!';

  @override
  String get tone_friendly_genericError =>
      'Etwas ist schiefgelaufen. Erneut versuchen?';

  @override
  String get tone_friendly_smsImportEnabled =>
      'Auto-Import ist an! Ich verfolge deine Transaktionen 📩';

  @override
  String get tone_friendly_dashboardAllCaughtUp =>
      'Du bist auf dem Laufenden! 🎉|Nichts braucht deine Aufmerksamkeit — schön! ✨|Alles bestens hier! Genieße deinen Tag 🎉';

  @override
  String get tone_friendly_dailySummaryEmpty =>
      'Gestern wurde nichts aufgezeichnet — entweder ein Null-Ausgaben-Sieg oder Zeit aufzuholen!|Ruhiger Tag gestern — dein Geldbeutel dankt es dir!|Keine Transaktionen gestern — heute Neuanfang!';

  @override
  String tone_friendly_streakMessage(int days) {
    return '$days Tage Serie! Mach weiter so! 🔥';
  }

  @override
  String tone_friendly_budgetExceededBy(String amount) {
    return 'Du hast dein Budget um $amount überschritten 😬';
  }

  @override
  String get tone_professional_txnAdded =>
      'Transaktion aufgezeichnet.|Eintrag erfolgreich gespeichert.|Transaktion protokolliert.';

  @override
  String get tone_professional_txnUpdated =>
      'Transaktion aktualisiert.|Änderungen übernommen.|Eintrag erfolgreich aktualisiert.';

  @override
  String get tone_professional_txnDeleted =>
      'Transaktion gelöscht.|Eintrag entfernt.|Eintrag erfolgreich gelöscht.';

  @override
  String get tone_professional_txnFailed =>
      'Transaktion konnte nicht gespeichert werden. Bitte versuchen Sie es erneut.';

  @override
  String get tone_professional_enterAmount =>
      'Bitte geben Sie einen gültigen Betrag ein.';

  @override
  String get tone_professional_pickAccount => 'Bitte wählen Sie ein Konto aus.';

  @override
  String get tone_professional_pickCategory =>
      'Bitte wählen Sie eine Kategorie aus.';

  @override
  String get tone_professional_fillAllFields =>
      'Alle Pflichtfelder müssen ausgefüllt werden.';

  @override
  String get tone_professional_invalidAmount => 'Ungültiger Betrag eingegeben.';

  @override
  String get tone_professional_budgetCreated =>
      'Budget erstellt.|Budget erfolgreich konfiguriert.|Neues Budget ist aktiv.';

  @override
  String get tone_professional_budgetUpdated => 'Budget aktualisiert.';

  @override
  String get tone_professional_budgetDeleted => 'Budget gelöscht.';

  @override
  String get tone_professional_goalCreated =>
      'Ziel erstellt.|Sparziel konfiguriert.|Neues Ziel ist aktiv.';

  @override
  String get tone_professional_goalUpdated => 'Ziel aktualisiert.';

  @override
  String get tone_professional_goalDeleted => 'Ziel gelöscht.';

  @override
  String get tone_professional_accountCreated =>
      'Konto erfolgreich hinzugefügt.';

  @override
  String get tone_professional_billAdded =>
      'Rechnung hinzugefügt. Sie erhalten rechtzeitig Erinnerungen.';

  @override
  String get tone_professional_billPaid =>
      'Rechnung als bezahlt markiert.|Zahlung erfasst.|Rechnung beglichen.';

  @override
  String get tone_professional_backupSuccess =>
      'Sicherung erfolgreich abgeschlossen.';

  @override
  String get tone_professional_restoreSuccess =>
      'Daten erfolgreich wiederhergestellt.';

  @override
  String get tone_professional_noTransactions =>
      'Keine Transaktionen erfasst.\nFügen Sie Ihren ersten Eintrag hinzu.|Keine Datensätze gefunden.\nBeginnen Sie mit einer Transaktion.|Transaktionsverlauf ist leer.\nStarten Sie die Aufzeichnung.';

  @override
  String get tone_professional_noBudgets => 'Keine Budgets konfiguriert.';

  @override
  String get tone_professional_noGoals => 'Keine Ziele gesetzt.';

  @override
  String get tone_professional_genericError => 'Ein Fehler ist aufgetreten.';

  @override
  String get tone_professional_smsImportEnabled => 'Auto-Import ist aktiviert.';

  @override
  String get tone_professional_dashboardAllCaughtUp =>
      'Alles auf dem neuesten Stand.|Keine anstehenden Aktionen.|Alles aktuell.';

  @override
  String get tone_professional_dailySummaryEmpty =>
      'Gestern wurden keine Transaktionen erfasst.|Gestern gab es keine Aktivitäten.|Keine Einträge für den vorangegangenen Tag.';

  @override
  String tone_professional_streakMessage(int days) {
    return '$days aufeinanderfolgende Tage der Verfolgung.';
  }

  @override
  String tone_professional_budgetExceededBy(String amount) {
    return 'Budget um $amount überschritten.';
  }

  @override
  String get tone_motivational_txnAdded =>
      'Toller Schritt! Transaktion gespeichert! 💪|Erfasst! Du bist in Fahrt 💪|Noch eine verfolgt! Behalte den Schwung bei! ✨|Gespeichert! Jeder Eintrag ist ein Schritt nach vorn! 🚀';

  @override
  String get tone_motivational_txnUpdated =>
      'Schönes Update! Bleib wachsam! ✨|Aktualisiert! Präzision zählt! ✨|Änderungen gespeichert! Du bist dran! 👍';

  @override
  String get tone_motivational_txnDeleted =>
      'Aufgeräumt! Eine Sorge weniger|Entfernt! Alles sauber halten! 💪|Weg! Konzentriere dich auf das, was zählt';

  @override
  String get tone_motivational_txnFailed =>
      'Hat nicht geklappt — versuch\'s noch mal!';

  @override
  String get tone_motivational_enterAmount =>
      'Jeder Euro zählt — gib den Betrag ein!';

  @override
  String get tone_motivational_pickAccount =>
      'Wähle ein Konto, um organisiert zu bleiben!';

  @override
  String get tone_motivational_pickCategory =>
      'Kategorisiere es — du wirst es dir später danken!';

  @override
  String get tone_motivational_fillAllFields =>
      'Fast geschafft! Fülle alles aus, um fortzufahren';

  @override
  String get tone_motivational_invalidAmount =>
      'Dieser Betrag sieht nicht richtig aus — versuch\'s noch mal!';

  @override
  String get tone_motivational_budgetCreated =>
      'Kluger Schachzug! Budget steht! 💪|Budget fixiert! Du übernimmst die Kontrolle! 💪|Das ist Disziplin! Budget bereit! 📊';

  @override
  String get tone_motivational_budgetUpdated =>
      'Budget angepasst — bleib flexibel!';

  @override
  String get tone_motivational_budgetDeleted => 'Budget entfernt';

  @override
  String get tone_motivational_goalCreated =>
      'Ich liebe diesen Ehrgeiz! Ziel gesetzt! 🎯|Große Träume beginnen hier! Ziel fixiert! 🎯|Das ist der Geist! Neues Ziel bereit! 🚀';

  @override
  String get tone_motivational_goalUpdated => 'Ziel verfeinert — bleib dran!';

  @override
  String get tone_motivational_goalDeleted =>
      'Ziel entfernt — neue Prioritäten, neue Pläne';

  @override
  String get tone_motivational_accountCreated =>
      'Konto hinzugefügt! Du wirst organisiert! 🏦';

  @override
  String get tone_motivational_billAdded =>
      'Rechnung erfasst! Du bleibst vorn! 🔔';

  @override
  String get tone_motivational_billPaid =>
      'Rechnung bezahlt! Eine Sorge weniger! ✅|Geschafft! Rechnung ist erledigt! ✅|Bezahlt und erledigt! Du bist dem Spiel voraus! 💪';

  @override
  String get tone_motivational_backupSuccess =>
      'Gesichert! Dein Fortschritt ist sicher! 🛡️';

  @override
  String get tone_motivational_restoreSuccess =>
      'Wiederhergestellt! Direkt wieder auf Kurs! 🎉';

  @override
  String get tone_motivational_noTransactions =>
      'Neuanfang! 🌟\nFüge deine erste Transaktion hinzu — jede Reise beginnt mit einem Schritt|Unbeschriebenes Blatt! 🌟\nDein erster Eintrag wartet — los geht\'s!|Noch nichts! 💪\nEine Transaktion und du bist auf dem Weg!';

  @override
  String get tone_motivational_noBudgets =>
      'Noch keine Budgets\nErstelle eines — dein zukünftiges Ich wird es dir danken! 💪';

  @override
  String get tone_motivational_noGoals =>
      'Noch keine Ziele\nTräume groß — setze dein erstes Ziel! 🎯';

  @override
  String get tone_motivational_genericError =>
      'Etwas ist schiefgelaufen — versuch\'s noch mal!';

  @override
  String get tone_motivational_smsImportEnabled =>
      'Auto-Import an! Deine Finanzen verfolgen sich jetzt von selbst! 📩';

  @override
  String get tone_motivational_dashboardAllCaughtUp =>
      'Alles erledigt — du bist dem Spiel voraus! 🏆|Nichts ausstehend — du hast es voll im Griff 💪|Alles klar! Behalte diese Energie bei 🏆';

  @override
  String get tone_motivational_dailySummaryEmpty =>
      'Null Ausgaben gestern — dein Geldbeutel dankt es dir! ✨|Gestern nichts ausgegeben — das ist Willenskraft! 💪|Ein Tag ohne Ausgaben! Das ist ein Sieg! 🏆';

  @override
  String tone_motivational_streakMessage(int days) {
    return '$days Tage Serie! Unaufhaltsam! 🔥';
  }

  @override
  String tone_motivational_budgetExceededBy(String amount) {
    return 'Um $amount drüber — du kannst das korrigieren! 💪';
  }

  @override
  String get tone_calm_txnAdded => 'Notiert.|Aufgezeichnet.|Ruhig gespeichert.';

  @override
  String get tone_calm_txnUpdated =>
      'Aktualisiert.|Angepasst.|Änderungen gespeichert.';

  @override
  String get tone_calm_txnDeleted => 'Losgelassen.|Entfernt.|Gehen gelassen.';

  @override
  String get tone_calm_txnFailed =>
      'Das hat nicht geklappt. Versuche es noch einmal sanft.';

  @override
  String get tone_calm_enterAmount => 'Ein Betrag wird benötigt.';

  @override
  String get tone_calm_pickAccount => 'Wähle, wohin dies gehört.';

  @override
  String get tone_calm_pickCategory => 'Gib ihm einen Zweck.';

  @override
  String get tone_calm_fillAllFields => 'Ein paar Dinge sind noch leer.';

  @override
  String get tone_calm_invalidAmount => 'Der Betrag muss angepasst werden.';

  @override
  String get tone_calm_budgetCreated =>
      'Grenze gesetzt.|Budget steht.|Limits definiert.';

  @override
  String get tone_calm_budgetUpdated => 'Angepasst.';

  @override
  String get tone_calm_budgetDeleted => 'Losgelassen.';

  @override
  String get tone_calm_goalCreated =>
      'Absicht gesetzt.|Eine neue Richtung.|Ziel gepflanzt.';

  @override
  String get tone_calm_goalUpdated => 'Verfeinert.';

  @override
  String get tone_calm_goalDeleted => 'Losgelassen.';

  @override
  String get tone_calm_accountCreated => 'Konto eröffnet.';

  @override
  String get tone_calm_billAdded => 'Notiert. Du wirst erinnert werden.';

  @override
  String get tone_calm_billPaid =>
      'Erledigt.|Bezahlt. Eines weniger.|Fertig. Seelenfrieden.';

  @override
  String get tone_calm_backupSuccess => 'Sicher aufbewahrt.';

  @override
  String get tone_calm_restoreSuccess =>
      'Wiederhergestellt. Willkommen zurück.';

  @override
  String get tone_calm_noTransactions =>
      'Ein unbeschriebenes Blatt.\nBeginne, wenn du bereit bist.|Hier ist noch nichts.\nBeginne sanft.|Leer.\nEin Neuanfang wartet.';

  @override
  String get tone_calm_noBudgets =>
      'Noch keine Grenzen.\nSetze eine, wenn es sich richtig anfühlt.';

  @override
  String get tone_calm_noGoals =>
      'Noch keine Absichten.\nSetze eine, wenn du bereit bist.';

  @override
  String get tone_calm_genericError =>
      'Etwas hat sich verschoben. Versuche es erneut.';

  @override
  String get tone_calm_smsImportEnabled =>
      'Beobachtet leise deine Transaktionen.';

  @override
  String get tone_calm_dashboardAllCaughtUp =>
      'Alles ist in Ordnung.|Nichts braucht Aufmerksamkeit.|Alles ist gut.';

  @override
  String get tone_calm_dailySummaryEmpty =>
      'Ein ruhiger Tag. Nichts aufgezeichnet.|Gestern war es still. Keine Einträge.|Nichts ausgegeben. Ein erholsamer Tag.';

  @override
  String tone_calm_streakMessage(int days) {
    return '$days Tage achtsame Verfolgung.';
  }

  @override
  String tone_calm_budgetExceededBy(String amount) {
    return 'Um $amount drüber. Ein Moment zum Nachdenken.';
  }

  @override
  String get tone_friendly_insightBillsDueSoon => 'Achtung — Rechnungen kommen';

  @override
  String get tone_friendly_insightOverBudget => 'Über Budget';

  @override
  String get tone_friendly_insightNearBudget => 'Es wird knapp...';

  @override
  String get tone_friendly_insightOverspending =>
      'Ausgaben übersteigen Einkommen';

  @override
  String get tone_friendly_insightSpendingSpike => 'Ausgabenspitze heute';

  @override
  String get tone_friendly_insightWeekendAlert => 'Wochenend-Ausgaben-Warnung';

  @override
  String get tone_friendly_insightGetStarted => 'Los geht\'s! 🚀';

  @override
  String get tone_friendly_insightGetStartedMessage =>
      'Füge deine erste Transaktion hinzu — es dauert nur eine Sekunde';

  @override
  String tone_friendly_insightBillsDueMessage(int count) {
    return '$count Rechnung(en) bald fällig, nicht vergessen!';
  }

  @override
  String tone_friendly_insightOverBudgetMessage(int count) {
    return '$count Budget(s) diesen Monat überschritten — schau mal nach';
  }

  @override
  String tone_friendly_insightNearBudgetMessage(int count) {
    return '$count Budget(s) über 80% — noch Zeit, einzubremsen';
  }

  @override
  String tone_friendly_insightOverspendingMessage(String amount) {
    return 'Du bist $amount über deinem Einkommen diesen Monat — vielleicht etwas langsamer machen';
  }

  @override
  String tone_friendly_insightSpendingSpikeMessage(String avg, String today) {
    return 'Normalerweise gibst du $avg/Tag aus. Heute sind es schon $today.';
  }

  @override
  String tone_friendly_insightWeekendAlertMessage(String avg, String current) {
    return 'Normalerweise gibst du am Wochenende $avg aus. Dieses Mal sind es schon $current.';
  }

  @override
  String get tone_professional_insightBillsDueSoon => 'Anstehende Rechnungen';

  @override
  String get tone_professional_insightOverBudget => 'Budget überschritten';

  @override
  String get tone_professional_insightNearBudget => 'Budgetlimit nähert sich';

  @override
  String get tone_professional_insightOverspending =>
      'Ausgaben übersteigen Einkommen';

  @override
  String get tone_professional_insightSpendingSpike => 'Erhöhte Ausgaben heute';

  @override
  String get tone_professional_insightWeekendAlert =>
      'Wochenendausgaben erhöht';

  @override
  String get tone_professional_insightGetStarted => 'Loslegen';

  @override
  String get tone_professional_insightGetStartedMessage =>
      'Erfassen Sie Ihre erste Transaktion, um mit der Verfolgung zu beginnen.';

  @override
  String tone_professional_insightBillsDueMessage(int count) {
    return '$count Rechnung(en) in den nächsten Tagen fällig.';
  }

  @override
  String tone_professional_insightOverBudgetMessage(int count) {
    return '$count Budget(s) diesen Monat überschritten.';
  }

  @override
  String tone_professional_insightNearBudgetMessage(int count) {
    return '$count Budget(s) über 80% Auslastung.';
  }

  @override
  String tone_professional_insightOverspendingMessage(String amount) {
    return 'Die Ausgaben übersteigen das Einkommen diesen Monat um $amount.';
  }

  @override
  String tone_professional_insightSpendingSpikeMessage(
      String avg, String today) {
    return 'Täglicher Durchschnitt: $avg. Heute: $today.';
  }

  @override
  String tone_professional_insightWeekendAlertMessage(
      String avg, String current) {
    return 'Wochenend-Durchschnitt: $avg. Aktuell: $current.';
  }

  @override
  String get tone_motivational_insightBillsDueSoon =>
      'Rechnungen stehen an! 📋';

  @override
  String get tone_motivational_insightOverBudget =>
      'Über Budget — Zeit zum Umorientieren';

  @override
  String get tone_motivational_insightNearBudget => 'Fast am Limit';

  @override
  String get tone_motivational_insightOverspending =>
      'Ausgaben übersteigen Einkommen';

  @override
  String get tone_motivational_insightSpendingSpike => 'Ausgabenspitze heute';

  @override
  String get tone_motivational_insightWeekendAlert =>
      'Wochenend-Ausgaben-Warnung';

  @override
  String get tone_motivational_insightGetStarted =>
      'Lass uns etwas Großes aufbauen! 🚀';

  @override
  String get tone_motivational_insightGetStartedMessage =>
      'Füge deine erste Transaktion hinzu — du bist nur einen Schritt entfernt!';

  @override
  String tone_motivational_insightBillsDueMessage(int count) {
    return '$count Rechnung(en) bald fällig — bleib dran!';
  }

  @override
  String tone_motivational_insightOverBudgetMessage(int count) {
    return '$count Budget(s) überschritten — du kannst das korrigieren!';
  }

  @override
  String tone_motivational_insightNearBudgetMessage(int count) {
    return '$count Budget(s) über 80% — du schaffst das, bleib achtsam!';
  }

  @override
  String tone_motivational_insightOverspendingMessage(String amount) {
    return '$amount über Einkommen — kleine Anpassungen machen einen großen Unterschied!';
  }

  @override
  String tone_motivational_insightSpendingSpikeMessage(
      String avg, String today) {
    return 'Normalerweise $avg/Tag. Heute sind es $today — sei bewusst!';
  }

  @override
  String tone_motivational_insightWeekendAlertMessage(
      String avg, String current) {
    return 'Wochenend-Durchschnitt: $avg. Dieses Mal sind es $current — bleib aufmerksam!';
  }

  @override
  String get tone_calm_insightBillsDueSoon => 'Rechnungen nähren sich';

  @override
  String get tone_calm_insightOverBudget => 'Über der Linie';

  @override
  String get tone_calm_insightNearBudget => 'Nahe am Rand';

  @override
  String get tone_calm_insightOverspending => 'Abfluss übersteigt Zufluss';

  @override
  String get tone_calm_insightSpendingSpike => 'Ein schwererer Tag';

  @override
  String get tone_calm_insightWeekendAlert => 'Wochenend-Ausgaben';

  @override
  String get tone_calm_insightGetStarted => 'Ein Neuanfang';

  @override
  String get tone_calm_insightGetStartedMessage =>
      'Beginne mit deiner ersten Transaktion.';

  @override
  String tone_calm_insightBillsDueMessage(int count) {
    return '$count Rechnung(en) treffen bald ein.';
  }

  @override
  String tone_calm_insightOverBudgetMessage(int count) {
    return '$count Budget(s) überschritten. Reflektiere und passe an.';
  }

  @override
  String tone_calm_insightNearBudgetMessage(int count) {
    return '$count Budget(s) über 80%. Achtsames Ausgeben hilft.';
  }

  @override
  String tone_calm_insightOverspendingMessage(String amount) {
    return '$amount mehr ausgegeben als eingenommen. Ein Moment zum Innehalten.';
  }

  @override
  String tone_calm_insightSpendingSpikeMessage(String avg, String today) {
    return 'Normalerweise $avg/Tag. Heute $today.';
  }

  @override
  String tone_calm_insightWeekendAlertMessage(String avg, String current) {
    return 'Normalerweise $avg. Dieses Wochenende $current.';
  }

  @override
  String tone_friendly_insightMoneyLeak(
      String category, int count, String total) {
    return '$category: $count Mal diesen Monat, $total insgesamt — kleine Beträge summieren sich';
  }

  @override
  String tone_friendly_insightBestDay(
      String worst, String wAvg, String best, String bAvg, String saving) {
    return '$wAvg Durchschn. an ${worst}en vs $bAvg an ${best}en — das sind $saving, die du behalten könntest';
  }

  @override
  String tone_professional_insightMoneyLeak(
      String category, int count, String total) {
    return '$category: $count Transaktionen, $total insgesamt diesen Monat.';
  }

  @override
  String tone_professional_insightBestDay(
      String worst, String wAvg, String best, String bAvg, String saving) {
    return '$wAvg Durchschn. an ${worst}en vs $bAvg an ${best}en. Mögliche Ersparnis: $saving.';
  }

  @override
  String tone_motivational_insightMoneyLeak(
      String category, int count, String total) {
    return '$category: $count Mal, $total — kleine Siege summieren sich, wenn du sparst!';
  }

  @override
  String tone_motivational_insightBestDay(
      String worst, String wAvg, String best, String bAvg, String saving) {
    return '$wAvg an ${worst}en vs $bAvg an ${best}en — $saving potenzielle Ersparnis!';
  }

  @override
  String tone_calm_insightMoneyLeak(String category, int count, String total) {
    return '$category: $count Mal, $total. Kleine Ströme bilden große Flüsse.';
  }

  @override
  String tone_calm_insightBestDay(
      String worst, String wAvg, String best, String bAvg, String saving) {
    return '${worst}e: $wAvg. ${best}e: $bAvg. $saving zum Behalten.';
  }

  @override
  String get tone_friendly_txnNotFound => 'Transaktion unauffindbar';

  @override
  String get tone_friendly_futureDate => 'Nimm heute oder ein Datum davor';

  @override
  String get tone_friendly_selectAccountAndCategory =>
      'Wähle erst ein Konto & eine Kategorie';

  @override
  String get tone_friendly_addParticipant =>
      'Füge mindestens eine Person zum Aufteilen hinzu';

  @override
  String get tone_friendly_budgetExceededAdjust =>
      'Budget überschritten. Vielleicht etwas kürzer treten?';

  @override
  String get tone_friendly_budgetGreatDiscipline =>
      'Starke Disziplin! Du bist voll im Budget ✨';

  @override
  String get tone_friendly_comparisonSpentSame =>
      'Du hast etwa so viel ausgegeben wie letzten Monat — stabil!';

  @override
  String get tone_friendly_accountUpdated => 'Konto aktualisiert!';

  @override
  String get tone_friendly_accountDeleted => 'Konto entfernt';

  @override
  String get tone_friendly_accountLocked =>
      'Konto gesperrt — hol dir Pro für vollen Zugriff 🔒';

  @override
  String get tone_friendly_categoryCreated => 'Kategorie ist da!';

  @override
  String get tone_friendly_categoryDeleted => 'Kategorie gelöscht';

  @override
  String get tone_friendly_categoryNameRequired => 'Gib der Sache einen Namen!';

  @override
  String get tone_friendly_billDeleted => 'Rechnung entfernt';

  @override
  String get tone_friendly_backupFailed =>
      'Backup hat nicht geklappt — noch mal versuchen?';

  @override
  String get tone_friendly_restoreFailed =>
      'Wiederherstellung fehlgeschlagen — ist die Datei okay?';

  @override
  String get tone_friendly_invalidBackupFile =>
      'Das sieht nicht nach einer gültigen Backup-Datei aus';

  @override
  String get tone_friendly_corruptBackup =>
      'Dieses Backup scheint beschädigt zu sein 😕';

  @override
  String get tone_friendly_settingsSaved => 'Gespeichert! ✓';

  @override
  String get tone_friendly_reminderUpdated => 'Erinnerung steht ⏰';

  @override
  String get tone_friendly_biometricFailed =>
      'Authentifizierung fehlgeschlagen — probier\'s noch mal';

  @override
  String get tone_friendly_incorrectPin => 'Falsche PIN — versuch\'s noch mal';

  @override
  String get tone_friendly_notificationAccessDenied =>
      'Brauche Zugriff auf Benachrichtigungen für den Auto-Import';

  @override
  String get tone_friendly_noBills =>
      'Noch keine Rechnungen\nFüge wiederkehrende Kosten hinzu, um nichts zu verpassen';

  @override
  String get tone_friendly_noAccounts =>
      'Noch keine Konten\nLeg eins an, um loszulegen';

  @override
  String get tone_friendly_noCategories => 'Noch keine Kategorien';

  @override
  String get tone_friendly_noNotifications =>
      'Alles ruhig hier\nNoch keine Benachrichtigungen';

  @override
  String get tone_friendly_noData =>
      'Noch nicht genug Daten\nTracke weiter für mehr Einblicke';

  @override
  String get tone_friendly_noRecurring =>
      'Keine wiederkehrenden Zahlungen\nFüge Rechnungen für automatisches Tracking hinzu';

  @override
  String get tone_friendly_exportSuccess => 'Bericht exportiert! 📄';

  @override
  String get tone_friendly_purchaseFailed =>
      'Kauf hat nicht geklappt — noch mal versuchen?';

  @override
  String get tone_friendly_playNotAvailable =>
      'Google Play ist auf diesem Gerät nicht verfügbar';

  @override
  String get tone_friendly_deleteTitle => 'Bist du sicher?';

  @override
  String get tone_friendly_deleteCancel => 'Behalten';

  @override
  String get tone_friendly_deleteConfirm => 'Löschen';

  @override
  String get tone_friendly_logoutTitle => 'Schon fertig?';

  @override
  String get tone_friendly_logoutMessage =>
      'Alle deine Daten werden von diesem Gerät gelöscht.';

  @override
  String get tone_friendly_logoutConfirm => 'Abmelden';

  @override
  String get tone_friendly_currencyChanged => 'Währung aktualisiert! 💱';

  @override
  String get tone_friendly_currencyChangeTitle => 'Währung ändern?';

  @override
  String get tone_friendly_currencyChangeCancel => 'Behalten';

  @override
  String get tone_friendly_currencyPickerTitle => 'Wähle deine Währung';

  @override
  String get tone_friendly_dashboardWelcomeBack =>
      'Willkommen zurück! Schauen wir uns den Stand an';

  @override
  String get tone_professional_txnNotFound => 'Transaktion nicht gefunden.';

  @override
  String get tone_professional_futureDate =>
      'Zukunftsdaten sind nicht zulässig.';

  @override
  String get tone_professional_selectAccountAndCategory =>
      'Konto und Kategorie sind erforderlich.';

  @override
  String get tone_professional_addParticipant =>
      'Mindestens ein Teilnehmer ist erforderlich.';

  @override
  String get tone_professional_budgetExceededAdjust =>
      'Budget überschritten. Ausgaben prüfen oder Limit anpassen.';

  @override
  String get tone_professional_budgetGreatDiscipline =>
      'Gut im Budget. Hervorragende Finanzdisziplin.';

  @override
  String get tone_professional_comparisonSpentSame =>
      'Die Ausgaben sind konsistent zum Vormonat.';

  @override
  String get tone_professional_accountUpdated => 'Konto aktualisiert.';

  @override
  String get tone_professional_accountDeleted => 'Konto entfernt.';

  @override
  String get tone_professional_accountLocked =>
      'Konto gesperrt. Pro-Abonnement erforderlich.';

  @override
  String get tone_professional_categoryCreated => 'Kategorie hinzugefügt.';

  @override
  String get tone_professional_categoryDeleted => 'Kategorie entfernt.';

  @override
  String get tone_professional_categoryNameRequired =>
      'Kategoriename ist erforderlich.';

  @override
  String get tone_professional_billDeleted => 'Rechnung entfernt.';

  @override
  String get tone_professional_backupFailed =>
      'Backup fehlgeschlagen. Bitte versuchen Sie es erneut.';

  @override
  String get tone_professional_restoreFailed =>
      'Wiederherstellung fehlgeschlagen. Überprüfen Sie die Backup-Datei.';

  @override
  String get tone_professional_invalidBackupFile =>
      'Ungültiges Backup-Dateiformat.';

  @override
  String get tone_professional_corruptBackup => 'Backup-Datei ist beschädigt.';

  @override
  String get tone_professional_settingsSaved => 'Einstellungen gespeichert.';

  @override
  String get tone_professional_reminderUpdated =>
      'Erinnerungszeit aktualisiert.';

  @override
  String get tone_professional_biometricFailed =>
      'Authentifizierung fehlgeschlagen.';

  @override
  String get tone_professional_incorrectPin => 'Falsche PIN.';

  @override
  String get tone_professional_notificationAccessDenied =>
      'Benachrichtigungszugriff ist für den Auto-Import erforderlich.';

  @override
  String get tone_professional_noBills => 'Keine wiederkehrenden Rechnungen.';

  @override
  String get tone_professional_noAccounts => 'Keine Konten konfiguriert.';

  @override
  String get tone_professional_noCategories => 'Keine Kategorien definiert.';

  @override
  String get tone_professional_noNotifications => 'Keine Benachrichtigungen.';

  @override
  String get tone_professional_noData =>
      'Unzureichende Daten.\nFahren Sie mit der Erfassung von Transaktionen fort.';

  @override
  String get tone_professional_noRecurring =>
      'Keine wiederkehrenden Transaktionen konfiguriert.';

  @override
  String get tone_professional_exportSuccess => 'Bericht exportiert.';

  @override
  String get tone_professional_purchaseFailed =>
      'Kauf fehlgeschlagen. Bitte versuchen Sie es erneut.';

  @override
  String get tone_professional_playNotAvailable =>
      'Google Play Dienste nicht verfügbar.';

  @override
  String get tone_professional_deleteTitle => 'Löschen bestätigen';

  @override
  String get tone_professional_deleteCancel => 'Abbrechen';

  @override
  String get tone_professional_deleteConfirm => 'Löschen';

  @override
  String get tone_professional_logoutTitle => 'Abmeldung bestätigen';

  @override
  String get tone_professional_logoutMessage =>
      'Alle lokalen Daten werden gelöscht.';

  @override
  String get tone_professional_logoutConfirm => 'Abmelden';

  @override
  String get tone_professional_currencyChanged => 'Basiswährung aktualisiert.';

  @override
  String get tone_professional_currencyChangeTitle => 'Basiswährung ändern';

  @override
  String get tone_professional_currencyChangeCancel => 'Abbrechen';

  @override
  String get tone_professional_currencyPickerTitle => 'Währung wählen';

  @override
  String get tone_professional_dashboardWelcomeBack =>
      'Willkommen zurück. Hier ist Ihre Zusammenfassung.';

  @override
  String get tone_motivational_txnNotFound =>
      'Unauffindbar — vielleicht wurde es gelöscht?';

  @override
  String get tone_motivational_futureDate =>
      'Bleib im Jetzt — wähle heute oder früher';

  @override
  String get tone_motivational_selectAccountAndCategory =>
      'Konto & Kategorie zuerst — du hast es fast geschafft!';

  @override
  String get tone_motivational_addParticipant =>
      'Füge jemanden zum Aufteilen hinzu!';

  @override
  String get tone_motivational_budgetExceededAdjust =>
      'Über Budget — aber jeder Tag ist eine neue Chance! 💪';

  @override
  String get tone_motivational_budgetGreatDiscipline =>
      'Wahnsinns-Disziplin! Du bist weit voraus! 🏆';

  @override
  String get tone_motivational_comparisonSpentSame =>
      'Stabil! Konstante Ausgaben zeigen Kontrolle 💪';

  @override
  String get tone_motivational_accountUpdated => 'Konto aktualisiert!';

  @override
  String get tone_motivational_accountDeleted => 'Konto entfernt';

  @override
  String get tone_motivational_accountLocked =>
      'Konto gesperrt — hol dir Pro zum Freischalten! 🔒';

  @override
  String get tone_motivational_categoryCreated => 'Neue Kategorie hinzugefügt!';

  @override
  String get tone_motivational_categoryDeleted => 'Kategorie entfernt';

  @override
  String get tone_motivational_categoryNameRequired =>
      'Gib der Sache einen Namen!';

  @override
  String get tone_motivational_billDeleted => 'Rechnung entfernt';

  @override
  String get tone_motivational_backupFailed =>
      'Backup fehlgeschlagen — versuch\'s noch mal!';

  @override
  String get tone_motivational_restoreFailed =>
      'Wiederherstellung fehlgeschlagen — Datei prüfen und erneut versuchen';

  @override
  String get tone_motivational_invalidBackupFile =>
      'Das sieht nicht nach einem gültigen Backup aus';

  @override
  String get tone_motivational_corruptBackup =>
      'Backup scheint beschädigt zu sein';

  @override
  String get tone_motivational_settingsSaved => 'Gespeichert! ✓';

  @override
  String get tone_motivational_reminderUpdated => 'Erinnerung steht! ⏰';

  @override
  String get tone_motivational_biometricFailed =>
      'Authentifizierung fehlgeschlagen — noch mal probieren!';

  @override
  String get tone_motivational_incorrectPin =>
      'Falsche PIN — du schaffst das, versuch\'s noch mal!';

  @override
  String get tone_motivational_notificationAccessDenied =>
      'Brauche Zugriff auf Benachrichtigungen für automatisches Tracking';

  @override
  String get tone_motivational_noBills =>
      'Keine Rechnungen erfasst\nBleib vorn, indem du deine Fixkosten hinzufügst';

  @override
  String get tone_motivational_noAccounts =>
      'Noch keine Konten\nLeg eins an und starte deine Reise!';

  @override
  String get tone_motivational_noCategories => 'Noch keine Kategorien';

  @override
  String get tone_motivational_noNotifications =>
      'Alles klar!\nKeine Benachrichtigungen — du hast alles im Griff';

  @override
  String get tone_motivational_noData =>
      'Weiter so! 📈\nMehr Daten bedeuten bessere Einblicke';

  @override
  String get tone_motivational_noRecurring =>
      'Keine wiederkehrenden Kosten\nAutomatisiere deine Rechnungen!';

  @override
  String get tone_motivational_exportSuccess => 'Bericht exportiert! 📄';

  @override
  String get tone_motivational_purchaseFailed =>
      'Kauf fehlgeschlagen — noch mal versuchen?';

  @override
  String get tone_motivational_playNotAvailable =>
      'Google Play ist auf diesem Gerät nicht verfügbar';

  @override
  String get tone_motivational_deleteTitle => 'Bist du sicher?';

  @override
  String get tone_motivational_deleteCancel => 'Behalten';

  @override
  String get tone_motivational_deleteConfirm => 'Löschen';

  @override
  String get tone_motivational_logoutTitle => 'Schon am Gehen?';

  @override
  String get tone_motivational_logoutMessage =>
      'Alle Daten auf diesem Gerät werden gelöscht.';

  @override
  String get tone_motivational_logoutConfirm => 'Abmelden';

  @override
  String get tone_motivational_currencyChanged =>
      'Währung gewechselt! Neues Kapitel! 💱';

  @override
  String get tone_motivational_currencyChangeTitle => 'Bereit zum Wechseln?';

  @override
  String get tone_motivational_currencyChangeCancel => 'Noch nicht';

  @override
  String get tone_motivational_currencyPickerTitle => 'Wähle deine Währung! 🌍';

  @override
  String get tone_motivational_dashboardWelcomeBack =>
      'Du bist zurück! Lass uns den Fortschritt fortsetzen! 🚀';

  @override
  String get tone_calm_txnNotFound =>
      'Nicht gefunden. Es könnte weitergezogen sein.';

  @override
  String get tone_calm_futureDate => 'Bleibe in der Gegenwart.';

  @override
  String get tone_calm_selectAccountAndCategory =>
      'Konto und Kategorie, bitte.';

  @override
  String get tone_calm_addParticipant => 'Füge jemanden zum Teilen hinzu.';

  @override
  String get tone_calm_budgetExceededAdjust =>
      'Grenze überschritten. Halte inne und überlege neu.';

  @override
  String get tone_calm_budgetGreatDiscipline =>
      'Gut innerhalb der Grenzen. Friedlich.';

  @override
  String get tone_calm_comparisonSpentSame =>
      'Die Ausgaben fließen im gleichen Tempo.';

  @override
  String get tone_calm_accountUpdated => 'Angepasst.';

  @override
  String get tone_calm_accountDeleted => 'Geschlossen.';

  @override
  String get tone_calm_accountLocked =>
      'Dieses ruht gerade. Pro schaltet es frei.';

  @override
  String get tone_calm_categoryCreated => 'Hinzugefügt.';

  @override
  String get tone_calm_categoryDeleted => 'Entfernt.';

  @override
  String get tone_calm_categoryNameRequired => 'Ein Name, bitte.';

  @override
  String get tone_calm_billDeleted => 'Losgelassen.';

  @override
  String get tone_calm_backupFailed =>
      'Konnte nicht speichern. Versuche es sanft erneut.';

  @override
  String get tone_calm_restoreFailed =>
      'Konnte nicht wiederherstellen. Überprüfe die Datei.';

  @override
  String get tone_calm_invalidBackupFile =>
      'Diese Datei fühlt sich nicht richtig an.';

  @override
  String get tone_calm_corruptBackup => 'Die Datei scheint beschädigt zu sein.';

  @override
  String get tone_calm_settingsSaved => 'Gespeichert.';

  @override
  String get tone_calm_reminderUpdated => 'Erinnerung angepasst.';

  @override
  String get tone_calm_biometricFailed => 'Nicht erkannt. Versuche es erneut.';

  @override
  String get tone_calm_incorrectPin => 'Nicht ganz. Versuche es erneut.';

  @override
  String get tone_calm_notificationAccessDenied =>
      'Berechtigung für leises Tracking erforderlich.';

  @override
  String get tone_calm_noBills => 'Nichts Wiederkehrendes.\nFriedlich.';

  @override
  String get tone_calm_noAccounts => 'Noch keine Konten.\nBeginne einfach.';

  @override
  String get tone_calm_noCategories => 'Noch keine Kategorien.';

  @override
  String get tone_calm_noNotifications =>
      'Stille.\nNichts braucht Aufmerksamkeit.';

  @override
  String get tone_calm_noData =>
      'Noch nicht genug.\nEs wird mit der Zeit kommen.';

  @override
  String get tone_calm_noRecurring =>
      'Nichts Wiederkehrendes.\nFüge hinzu, wenn du bereit bist.';

  @override
  String get tone_calm_exportSuccess => 'Exportiert.';

  @override
  String get tone_calm_purchaseFailed =>
      'Kauf wurde nicht abgeschlossen. Versuche es erneut.';

  @override
  String get tone_calm_playNotAvailable => 'Play Store hier nicht verfügbar.';

  @override
  String get tone_calm_deleteTitle => 'Loslassen?';

  @override
  String get tone_calm_deleteCancel => 'Warten';

  @override
  String get tone_calm_deleteConfirm => 'Freigeben';

  @override
  String get tone_calm_logoutTitle => 'Weiterziehen?';

  @override
  String get tone_calm_logoutMessage => 'Deine Daten hier werden gelöscht.';

  @override
  String get tone_calm_logoutConfirm => 'Verlassen';

  @override
  String get tone_calm_currencyChanged => 'Währung verschoben.';

  @override
  String get tone_calm_currencyChangeTitle => 'Eine neue Währung?';

  @override
  String get tone_calm_currencyChangeCancel => 'Bleiben';

  @override
  String get tone_calm_currencyPickerTitle => 'Wähle deine Währung';

  @override
  String get tone_calm_dashboardWelcomeBack => 'Willkommen zurück.';

  @override
  String get notif_quietDayTitle => '📊 Ruhiger Tag gestern';

  @override
  String get notif_heresYesterdayTitle => '📊 Hier ist der gestrige Tag';

  @override
  String get notif_weekInReviewTitle => '📅 Rückblick auf die Woche';

  @override
  String get notif_yourWeekInReviewTitle => '📅 Dein Rückblick auf die Woche';

  @override
  String get notif_niceOneTitle => '🏆 Gut gemacht!';

  @override
  String notif_streakDaysTitle(int days) {
    return '🔥 $days Tage in Folge!';
  }

  @override
  String notif_levelUpTitle(int level) {
    return '🎉 Level $level!';
  }

  @override
  String notif_budgetsOverLimitTitle(int count) {
    return '🚨 $count Budget(s) über Limit';
  }

  @override
  String notif_budgetsGettingTightTitle(int count) {
    return '⚠️ $count Budget(s) werden knapp';
  }

  @override
  String notif_billDueTitle(String name, String label) {
    return '📅 $name ist am $label fällig';
  }

  @override
  String get notif_fundsGettingLowTitle => '📉 Guthaben wird niedrig';

  @override
  String notif_categoryCreepingUpTitle(String category) {
    return '💡 $category steigt an';
  }

  @override
  String get notif_bigDayTitle => '📈 Whoa, großer Tag';

  @override
  String notif_smsFoundTitle(int count) {
    return '📱 $count SMS-Transaktionen gefunden';
  }

  @override
  String get notif_smallSpendsTitle => '💧 Kleinvieh macht auch Mist';

  @override
  String get notif_missYouTitle => '👋 Wir vermissen dich';

  @override
  String notif_daysUntrackedTitle(int days) {
    return '📊 $days Tage nicht verfolgt';
  }

  @override
  String notif_streakEndedTitle(int days) {
    return '💔 $days-Tage-Serie beendet';
  }

  @override
  String get notif_fewDaysUntrackedTitle => '📊 Ein paar Tage nicht verfolgt';

  @override
  String notif_budgetExceededBody(String name) {
    return '$name ist über Budget — Zeit für eine Überprüfung';
  }

  @override
  String notif_budgetExceededBodyMulti(String names) {
    return '$names sind über Budget';
  }

  @override
  String notif_budgetWarningBody(String name) {
    return '$name nähert sich dem Limit';
  }

  @override
  String notif_budgetWarningBodyMulti(String names) {
    return '$names nähern sich ihren Limits';
  }

  @override
  String notif_budgetWarningPctBody(String name, String pct) {
    return '$name: $pct% verbraucht';
  }

  @override
  String notif_billPaidAutoTitle(String name) {
    return '✅ $name — autom. abgeglichen';
  }

  @override
  String notif_billPaidRecordedTitle(String name) {
    return '✅ $name — erfasst';
  }

  @override
  String get notif_smsLoggedTitle => '✅ Transaktion protokolliert';

  @override
  String get notif_smsNeedsReviewTitle => '👀 Braucht deine Überprüfung';

  @override
  String notif_smsLoggedBody(String amount, String sender) {
    return '$amount von $sender — autom. gespeichert';
  }

  @override
  String notif_smsLoggedBodyNoAmount(String sender) {
    return 'Von $sender — autom. gespeichert';
  }

  @override
  String notif_smsNeedsReviewBody(String sender) {
    return 'Transaktion von $sender — zum Überprüfen tippen';
  }

  @override
  String get notif_smsGotItTitle => '✅ Verstanden!';

  @override
  String get notif_smsAllCaughtUpTitle => '✅ Alles erledigt!';

  @override
  String get notif_smsAlmostThereTitle => '📋 Fast geschafft!';

  @override
  String get notif_smsNeedHelpTitle => '👋 Hey, brauche deine Hilfe!';

  @override
  String notif_streakOnLineTitle(int days) {
    return '🔥 $days-Tage-Serie steht auf dem Spiel!';
  }

  @override
  String get notif_quickActionTitle => '⚡ 5 Sekunden reichen aus';

  @override
  String get notif_dailyReminderTitle => '📊 Dein Tag in Zahlen';

  @override
  String get notif_dailyReminderBody =>
      'So lief es gestern — wirf einen kurzen Blick darauf';

  @override
  String get notif_weeklyReminderTitle => '📅 Deine Woche zusammengefasst';

  @override
  String get notif_weeklyReminderBody =>
      'Lass uns sehen, wie die Woche lief — zum Überprüfen tippen';

  @override
  String get notif_goalStatusTitle => '🎯 Monatlicher Zielstatus';

  @override
  String notif_goalStatusBody(int count, String name, String pct) {
    return 'Du hast $count aktive Ziele. $name ist zu $pct% abgeschlossen!';
  }

  @override
  String notif_streakCountingTitle(int days) {
    return '🔥 $days Tage und es geht weiter!';
  }

  @override
  String notif_achievementBody(String title, int xp) {
    return '$title — das sind +$xp XP für dich';
  }

  @override
  String get notif_levelUpBody =>
      'Du bist gerade ein Level aufgestiegen — mach weiter so!';

  @override
  String get notif_streakMilestoneBody =>
      'Das ist Hingabe — deine Serie brennt';

  @override
  String get notif_weeklyZeroBody =>
      'Null Ausgaben diese Woche — das ist beeindruckend 💪';

  @override
  String get insight_moneyLeakTitle => 'Leises Geldleck 💧';

  @override
  String insight_bestDayTitle(String day) {
    return '${day}s kosten dich am meisten';
  }

  @override
  String get budget_alert_exceededTitle => 'Budget Exceeded!';

  @override
  String budget_alert_warningTitle(Object percent) {
    return 'Budget Alert: $percent%';
  }

  @override
  String get label_percentage_with_colon => 'Percentage:';

  @override
  String get label_budget_with_colon => 'Budget:';

  @override
  String get label_spent_with_colon => 'Spent:';

  @override
  String get bills_howBillsWorkTitle => 'How Bills Work';

  @override
  String get bills_howBillsWorkDesc =>
      'Track recurring bills like rent, subscriptions, and utilities. Get reminders before due dates and mark bills as paid.';

  @override
  String get bills_gotIt => 'Got it';

  @override
  String get bills_addBill => 'Add Bill';

  @override
  String get bills_markAsPaid => 'Mark as Paid';

  @override
  String get bills_deleteBill => 'Delete Bill';

  @override
  String get bills_addNewBill => 'Add New Bill';

  @override
  String get bills_billName => 'Bill Name';

  @override
  String get bills_amount => 'Amount';

  @override
  String get bills_frequency => 'Frequency';

  @override
  String get bills_monthly => 'Monthly';

  @override
  String get bills_quarterly => 'Quarterly';

  @override
  String get bills_yearly => 'Yearly';

  @override
  String get bills_dueDate => 'Due Date';

  @override
  String get goal_deleteGoalTitle => 'Ziel löschen?';

  @override
  String get goal_editGoal => 'Ziel bearbeiten';

  @override
  String get goal_deleteGoal => 'Ziel löschen';

  @override
  String get goal_saved => 'Gespart';

  @override
  String get goal_target => 'Ziel';

  @override
  String get goal_quickDeposit => 'Schnelleinzahlung';

  @override
  String get goal_targetDate => 'Zieldatum';

  @override
  String get goal_milestones => 'Meilensteine';

  @override
  String get goal_recentActivity => 'Letzte Aktivitäten';

  @override
  String get goal_addToGoal => 'Zum Ziel hinzufügen';

  @override
  String get goal_goalReached => 'Ziel erreicht!';

  @override
  String get goal_whatsThisAbout => 'Wofür ist dieses Ziel?';

  @override
  String get goal_icon => 'Icon';

  @override
  String get goal_color => 'Farbe';

  @override
  String get dashboard_enableCards => 'Karten aktivieren';

  @override
  String get recurring_fixedExpenses => 'Fixkosten';

  @override
  String get goal_freePlanLimit =>
      'Kostenlose Version erlaubt bis zu 2 Ziele. Upgrade auf Pro für unbegrenzte Ziele.';

  @override
  String get goal_editGoalTitle => 'Ziel bearbeiten';

  @override
  String get goal_newGoalTitle => 'Neues Ziel';

  @override
  String get goal_yourGoal => 'Dein Ziel';

  @override
  String get goal_appearance => 'Erscheinungsbild';

  @override
  String get goal_goalName => 'Zielname';

  @override
  String get goal_giveGoalName => 'Gib deinem Ziel einen Namen';

  @override
  String get goal_targetAmount => 'Zielbetrag';

  @override
  String get goal_enterValidTarget => 'Gib einen gültigen Zielbetrag ein';

  @override
  String get goal_alreadySaved => 'Bereits gespart';

  @override
  String get goal_targetDateLabel => 'Zieldatum';

  @override
  String get goal_setTargetDate => 'Zieldatum setzen (optional)';

  @override
  String get goal_smartInsight => 'Smarter Einblick';

  @override
  String get goal_onTrack => 'Auf Kurs';

  @override
  String get goal_onTrackDesc => 'Dieses Ziel ist sehr gut erreichbar 👍';

  @override
  String get goal_needsEffort => 'Braucht Anstrengung';

  @override
  String get goal_needsEffortDesc => 'Benötigt etwas mehr Spardisziplin';

  @override
  String get goal_ambitious => 'Ambitioniert';

  @override
  String get goal_ambitiousDesc => 'Überlege, die Frist zu verlängern';

  @override
  String get goal_addNote => 'Notiz hinzufügen (optional)';

  @override
  String get goal_note => 'Notiz';

  @override
  String get goal_updateGoal => 'Ziel aktualisieren';

  @override
  String get goal_createGoal => 'Ziel erstellen';

  @override
  String get profile_developerMode => 'Entwicklermodus aktiviert! 🚀';

  @override
  String get profile_couldNotOpenLink => 'Link konnte nicht geöffnet werden';

  @override
  String get profile_about => 'Über';

  @override
  String get profile_unableToCheckUpdates => 'Update-Prüfung fehlgeschlagen';

  @override
  String get profile_openSourceLicenses => 'Open-Source-Lizenzen';

  @override
  String get account_totalValue => 'Gesamtwert';

  @override
  String get account_gainLoss => 'Gewinn/Verlust';

  @override
  String get account_holdings => 'Bestände';

  @override
  String get account_addHolding => 'Bestand hinzufügen';

  @override
  String get account_addMissingTransaction => 'Fehlende Transaktion hinzufügen';

  @override
  String get account_whatWasThisFor => 'Wofür war diese Transaktion?';

  @override
  String get budget_used => 'Verbraucht';

  @override
  String get budget_selectAtLeastOneTag => 'Bitte wähle mindestens einen Tag';

  @override
  String get budget_over => 'drüber';

  @override
  String get budget_left => 'übrig';

  @override
  String get budget_breakdown => 'AUFSCHLÜSSELUNG';

  @override
  String get budget_basicInfo => 'Basis-Informationen';

  @override
  String get budget_duration => 'Dauer';

  @override
  String get budget_budgetType => 'Budget-Typ';

  @override
  String get budget_selectType => 'Typ wählen';

  @override
  String get budget_categoryAllocation => 'Kategorie-Zuweisung';

  @override
  String get budget_totalBudget => 'Gesamtbudget';

  @override
  String get budget_allocated => 'Zugewiesen';

  @override
  String get budget_remaining => 'Verbleibend';

  @override
  String get budget_overBudget => 'Über Budget';

  @override
  String get budget_safeToSpend => 'Sicher auszugeben';

  @override
  String get budget_startDate => 'Startdatum';

  @override
  String get budget_endDate => 'Enddatum';

  @override
  String get budget_selectTags => 'Tags wählen';

  @override
  String get budget_tagInfo =>
      'Alle Ausgaben mit den gewählten Tags zählen für dieses Budget.';

  @override
  String get budget_noTags =>
      'Noch keine Tags. Füge zuerst Tags zu deinen Transaktionen hinzu.';

  @override
  String get budget_freePlanLimit =>
      'Kostenlose Version erlaubt bis zu 2 Budgets. Upgrade auf Pro für unbegrenzte Budgets.';

  @override
  String budget_daysRemaining(Object count) {
    return '$count Tage';
  }

  @override
  String get budget_delete => 'Löschen';

  @override
  String get budget_emotionUnderControl => 'Ausgaben unter Kontrolle 💪';

  @override
  String get budget_emotionHalfway => 'Hälfte des Monats geschafft ✨';

  @override
  String get budget_emotionAlmostThere => 'Wird knapp, sei vorsichtig ⚠️';

  @override
  String get budget_emotionExceeded =>
      'Budget überschritten, Zeit gegenzusteuern 🔴';

  @override
  String get budget_highlightLabel => 'Braucht Aufmerksamkeit';

  @override
  String get budget_overBudgetSection => 'Über Budget';

  @override
  String get budget_activeBudgets => 'Aktive Budgets';

  @override
  String get budget_onTrackSection => 'Auf Kurs';

  @override
  String get budget_spendingPace => 'Ausgabentempo';

  @override
  String budget_dailyActual(Object amount) {
    return '$amount/Tag tatsächlich';
  }

  @override
  String budget_dailyAllowed(Object amount) {
    return '$amount/Tag erlaubt';
  }

  @override
  String get budget_stepNote0 =>
      'Gib deinem Budget einen Namen und lege fest, wie viel du ausgeben möchtest.';

  @override
  String get budget_stepNote1 =>
      'Wähle, wie oft sich dieses Budget wiederholt und lege die Daten fest.';

  @override
  String get budget_stepNote2 =>
      'Wähle aus, welche Kategorien oder Tags dieses Budget verfolgen soll.';

  @override
  String get budget_autoDistributed => 'auto';

  @override
  String budget_categoriesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Kategorien',
      one: '1 Kategorie',
    );
    return '$_temp0';
  }

  @override
  String budget_tagsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tags',
      one: '1 Tag',
    );
    return '$_temp0';
  }

  @override
  String get budget_typeCategoryWise => 'Kategorieweise';

  @override
  String get budget_typeTagWise => 'Tag-weise';

  @override
  String get budget_typeDayWise => 'Täglich';

  @override
  String get budget_typeFestival => 'Festival/Event';

  @override
  String get budget_typeTravel => 'Reise';

  @override
  String get budget_typeDescCategoryWise =>
      'Budgets für bestimmte Ausgabenkategorien';

  @override
  String get budget_typeDescTagWise => 'Budgets für bestimmte Tags';

  @override
  String get budget_typeDescDayWise => 'Tägliches Ausgabenlimit festlegen';

  @override
  String get budget_typeDescFestival =>
      'Budget für Feste und besondere Anlässe';

  @override
  String get budget_typeDescTravel => 'Budget für Reiseausgaben';

  @override
  String get budget_reviewTitle => 'Prüfen & Speichern';

  @override
  String get budget_selectCategories => 'Kategorien wählen';

  @override
  String get budget_noActiveTrip =>
      'Keine aktive Reise. Starte erst eine Reise, um das Reisebudget zu nutzen.';

  @override
  String get budget_stepNote3 =>
      'Prüfe alles vor dem Speichern. Tippe auf einen Bereich zum Bearbeiten.';

  @override
  String budget_categoryDeleteWarning(Object count) {
    return 'Diese Kategorie wird in $count Budget(s) verwendet. Löschen beeinflusst das Budget-Tracking.';
  }

  @override
  String get budget_invalidCategories =>
      'Einige Kategorien wurden gelöscht. Bearbeite das Budget zum Fixen.';

  @override
  String budget_pastBudgets(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Budgets',
      one: 'Budget',
    );
    return '$count vergangene $_temp0';
  }

  @override
  String get budget_spent => 'Spent';

  @override
  String get budget_currentPace => 'Current pace';

  @override
  String get budget_allowedPace => 'Allowed pace';

  @override
  String get budget_exceedingBy => 'Exceeding by';

  @override
  String get budget_underBy => 'Under by';

  @override
  String budget_forecastBreach(int days) {
    return 'At current pace: limit reached in $days days';
  }

  @override
  String get budget_remainingAllowance => 'remaining allowance';

  @override
  String get budget_insufficientData => 'Insufficient activity data';

  @override
  String get budget_addExpense => 'Add Expense';

  @override
  String get budget_viewTransactions => 'View Transactions';

  @override
  String get budget_reduceBy => 'Reduce by';

  @override
  String get budget_spendAtMost => 'Spend ≤';

  @override
  String get budget_reviewSpending => 'Review Spending';

  @override
  String get budget_viewDetails => 'View Details';

  @override
  String get budget_fixData => 'Fix Data';

  @override
  String get budget_alreadyBreached => 'At current pace: already breached';

  @override
  String get budget_paceBelowLimit => 'Current pace below limit';

  @override
  String get budget_createBudget => 'Create Budget';

  @override
  String get budget_limit => 'Limit';

  @override
  String get budget_basedOnHistory => 'Based on your spending';

  @override
  String get budget_lastMonth => 'Last month';

  @override
  String get budget_threeMonthAvg => '3-month average';

  @override
  String get budget_bufferAbove => 'buffer vs last month';

  @override
  String get budget_bufferBelow => 'below last month';

  @override
  String get budget_templateRecommended => 'Recommended';

  @override
  String get budget_templateConservative => 'Conservative';

  @override
  String get budget_templateFlexible => 'Flexible';

  @override
  String get budget_periodThisWeek => 'This Week';

  @override
  String get budget_periodThisMonth => 'This Month';

  @override
  String get budget_periodThisYear => 'This Year';

  @override
  String get budget_periodCustom => 'Custom';

  @override
  String get budget_perDay => 'day';

  @override
  String get budget_days => 'days';

  @override
  String get budget_advanced => 'Advanced';

  @override
  String get budget_adjustLimit => 'Adjust Limit';

  @override
  String get budget_dangerZone => 'Danger Zone';

  @override
  String get budget_archive => 'Archive';

  @override
  String get budget_archiveConfirm =>
      'Archive this budget? It will move to your past budgets.';

  @override
  String get category_categoryName => 'Kategoriename';

  @override
  String get category_keywords => 'Keywords (Komma-getrennt)';

  @override
  String get category_noneTopLevel => 'Keine (Hauptebene)';

  @override
  String get common_searchCurrency => 'Währung suchen...';

  @override
  String get common_selectCategory => 'Kategorie wählen';

  @override
  String get common_noDescription => 'Keine Beschreibung';

  @override
  String get common_errors => 'Fehler';

  @override
  String get dashboard_enableCardsDesc =>
      'Aktiviere Dashboard-Karten für deinen Finanzüberblick';

  @override
  String get dashboard_customizeDashboard => 'Dashboard anpassen';

  @override
  String get dashboard_newToApp => 'Neu bei Mudra Manager?';

  @override
  String get dashboard_tapToExploreHelp => 'Tippe für die Hilfe-Übersicht';

  @override
  String get dashboard_tapToReviewTxn => 'Tippe zum Prüfen von Transaktionen';

  @override
  String get dashboard_autoImportPaused => 'Auto-Import pausiert';

  @override
  String get dashboard_enable => 'Aktivieren';

  @override
  String get dashboard_enableAutoImport => 'Auto-Import aktivieren';

  @override
  String get dashboard_autoTrackDesc =>
      'Transaktionen automatisch aus Bank-Benachrichtigungen erfassen';

  @override
  String get profile_awesomeUser => 'Super User';

  @override
  String get profile_logout => 'Abmelden';

  @override
  String get profile_proActiveLabel => 'Pro Aktiv';

  @override
  String get profile_freeTierLabel => 'Kostenlose Stufe';

  @override
  String get profile_fullAccessLabel => 'Vollzugriff';

  @override
  String get profile_upgradeToProLabel => 'Auf Pro upgraden';

  @override
  String get profile_fullAccessEnjoy => 'Vollzugriff — genieße alle Features!';

  @override
  String profile_fullAccessDaysRemaining(int days) {
    return 'Vollzugriff — $days Tage verbleibend';
  }

  @override
  String profile_fullAccessEndsIn(int days) {
    return 'Vollzugriff endet in $days Tagen';
  }

  @override
  String get profile_trialEnded =>
      'Testzeitraum beendet — Upgrade für alle Features';

  @override
  String get profile_unlimitedDesc => 'Unbegrenzte Konten, Analysen & mehr';

  @override
  String get profile_expiredRenew => 'Abgelaufen — zum Erneuern tippen';

  @override
  String get profile_expiresToday => 'Läuft heute ab';

  @override
  String get profile_renewsTomorrow => 'Erneuert sich morgen';

  @override
  String profile_renewsInDays(int days) {
    return 'Erneuert sich in $days Tagen';
  }

  @override
  String get profile_activeSubscription => 'Aktives Abo';

  @override
  String get profile_unknown => 'Unbekannt';

  @override
  String get profile_accountsLabel => 'Konten';

  @override
  String get profile_categoriesLabel => 'Kategorien';

  @override
  String get profile_budgetsLabel => 'Budgets';

  @override
  String get profile_bestStreakLabel => 'Beste Serie';

  @override
  String get profile_yourAchievementsLabel => 'Deine Erfolge';

  @override
  String get profile_aboutMudra => 'Über Mudra Manager';

  @override
  String get profile_aboutMudraDesc =>
      'Dein persönlicher Finanzbegleiter. Tracke Ausgaben, verwalte Budgets und verstehe dein Geld.';

  @override
  String get txnList_searchHint => 'Transaktionen suchen...';

  @override
  String get txnList_category => 'Kategorie';

  @override
  String get txnList_dateRange => 'Zeitraum';

  @override
  String get txnList_tag => 'Tag';

  @override
  String get txnList_allTransactions => 'Alle Transaktionen';

  @override
  String get txnList_tapStartEnd => 'Start- und Enddatum wählen';

  @override
  String get txnList_scrollToLoad => 'Scrollen zum Laden';

  @override
  String get txnList_month => 'Monat';

  @override
  String get txnList_previousMonth => 'Vorheriger Monat';

  @override
  String get txnList_resetToCurrentMonth => 'Zum aktuellen Monat';

  @override
  String get txnList_selectMonth => 'Monat wählen';

  @override
  String get txnList_nextMonth => 'Nächster Monat';

  @override
  String get txnList_monthView => 'Monatsansicht';

  @override
  String get txnList_subscriptionTagRemoved => 'Abo-Tag entfernt';

  @override
  String get txnList_filterByTag => 'Nach Tag filtern';

  @override
  String get txnList_noTagsYet =>
      'Noch keine Tags. Füge Tags zu Transaktionen hinzu.';

  @override
  String get txnList_clear => 'Leeren';

  @override
  String get txnList_filterOptions => 'Filteroptionen';

  @override
  String get txnList_transactionType => 'Transaktionstyp';

  @override
  String get txnList_allCategories => 'Alle Kategorien';

  @override
  String get txnList_selectDateRange => 'Zeitraum wählen';

  @override
  String get txnList_clearDateRange => 'Zeitraum leeren';

  @override
  String get txnList_convertToTransfer => 'In Überweisung umwandeln';

  @override
  String get txnList_convertToTransferDesc =>
      'Dies war eigentlich eine Überweisung zwischen Konten';

  @override
  String get txnList_convertedToTransfer => 'In Überweisung umgewandelt';

  @override
  String txnList_selectedCount(int count) {
    return '$count selected';
  }

  @override
  String get txnList_mergeSelectHint => 'Select the matching transaction';

  @override
  String get txnList_mergeReadyHint => 'Tap merge in the app bar';

  @override
  String get txnList_expenseRequired =>
      'Select one expense and one income transaction';

  @override
  String get txnList_matchingAmounts => 'Amounts must match (within 1%)';

  @override
  String get txnList_within24Hours => 'Transactions must be within 24 hours';

  @override
  String get txnList_differentAccounts =>
      'Cannot transfer between the same account';

  @override
  String get txnList_applyFilters => 'Apply Filters';

  @override
  String get txnList_filterAll => 'ALL';

  @override
  String get txnList_filterSpends => 'SPENDS';

  @override
  String get txnList_filterIncome => 'INCOME';

  @override
  String get txnList_filterTransfers => 'TRANSFERS';

  @override
  String txnList_budgetUpdateTitle(String category) {
    return '$category Budget Update';
  }

  @override
  String txnList_budgetExceededSubtitle(String category) {
    return 'You\'ve exceeded your $category budget';
  }

  @override
  String txnList_budgetSpentSubtitle(String amount, String category) {
    return 'You\'ve spent $amount on $category this period';
  }

  @override
  String get stats_today => 'Heute';

  @override
  String get stats_week => 'Woche';

  @override
  String get stats_month => 'Monat';

  @override
  String get stats_year => 'Jahr';

  @override
  String get stats_custom => 'Benutzerdefiniert';

  @override
  String get stats_unableToLoad => 'Statistiken konnten nicht geladen werden';

  @override
  String get stats_overview => 'Übersicht';

  @override
  String get stats_trends => 'Trends';

  @override
  String get stats_spendingByDay => 'Ausgaben pro Tag';

  @override
  String get stats_insights => 'Einblicke';

  @override
  String get stats_nextMonthForecast => 'Prognose nächster Monat';

  @override
  String get stats_topSpending => 'Top Ausgaben';

  @override
  String get stats_12MonthTrend => '12-Monats-Trend';

  @override
  String stats_trendUp(Object category, Object percent) {
    return '$category steigt — $percent% der Gesamtausgaben';
  }

  @override
  String stats_trendDown(Object category) {
    return '$category ist diesen Monat rückläufig 📉';
  }

  @override
  String stats_topCategory(Object category, Object percent) {
    return '$category ist deine Top-Kategorie — $percent% der Ausgaben';
  }

  @override
  String stats_weekendPeak(Object day) {
    return 'Du gibst am Wochenende mehr aus — $day ist dein Spitzentag';
  }

  @override
  String stats_weekdayPeak(Object day) {
    return 'Wochentage kosten mehr — $day ist dein größter Tag';
  }

  @override
  String stats_peakAndQuiet(Object peak, Object quiet) {
    return '$peak ist dein Spitzentag, $quiet der ruhigste';
  }

  @override
  String get stats_expand => 'Expand';

  @override
  String get stats_otherCategory => 'Other';

  @override
  String stats_dayNumber(Object day) {
    return 'Day $day';
  }

  @override
  String get stats_categoryTrends => 'Kategorie-Trends';

  @override
  String get stats_spendingByTag => 'Ausgaben nach Tag';

  @override
  String get stats_netWorth => 'Nettovermögen';

  @override
  String get stats_savings => 'Ersparnisse';

  @override
  String get stats_categoryImpact => 'KATEGORIE-EINFLUSS';

  @override
  String get stats_income => 'Einkommen';

  @override
  String get stats_expense => 'Ausgabe';

  @override
  String get stats_net => 'Netto';

  @override
  String get stats_dailySpendingPace => 'Tägliches Ausgabentempo';

  @override
  String get stats_topCategories => 'Top-Kategorien';

  @override
  String stats_projectedThisMonth(Object amount) {
    return 'Hochrechnung: $amount diesen Monat';
  }

  @override
  String stats_byDay(Object day, Object amount, Object month) {
    return 'Bis Tag $day: $amount im $month';
  }

  @override
  String get stats_steadyHeadline => 'Alles im grünen Bereich';

  @override
  String get stats_steadyDetail =>
      'Deine Ausgaben sind konstant — das zeugt von Disziplin.';

  @override
  String get stats_doingGreatHeadline => 'Du machst das super 🌟';

  @override
  String get stats_spendingUpHeadline => 'Achtung — die Ausgaben steigen';

  @override
  String get stats_downloadPdf => 'PDF herunterladen';

  @override
  String get stats_generating => 'Wird generiert...';

  @override
  String stats_newCategory(Object category) {
    return 'New spending in $category detected.';
  }

  @override
  String stats_categoryStopped(Object category) {
    return 'No spending in $category this period.';
  }

  @override
  String get stats_spendingSteady => 'Spending is steady compared to baseline.';

  @override
  String stats_forecastHigher(Object period) {
    return 'At current pace, you may spend more than $period.';
  }

  @override
  String stats_forecastLower(Object period) {
    return 'On track to finish below $period.';
  }

  @override
  String get stats_howItWorks => 'How Statistics Work';

  @override
  String get stats_howItWorksDesc =>
      'Track income, spending, and trends for the selected period. Tap the date range at the top to switch between day, week, month, year, or a custom range.';

  @override
  String get stats_netFlow => 'Net Flow';

  @override
  String get recap_belowAvg => 'Unter Durchschnitt';

  @override
  String get recap_aboveAvg => 'Über Durchschnitt';

  @override
  String get recap_recurring => 'Wiederkehrend';

  @override
  String get recap_oneTime => 'Einmalig';

  @override
  String get recap_recapTitle => 'Rückblick';

  @override
  String get notifSettings_dailySummary => 'Tages-Zusammenfassung';

  @override
  String get notifSettings_weeklySummary => 'Wochen-Zusammenfassung';

  @override
  String get notifSettings_comeBackNudges => 'Erinnerungs-Stupser';

  @override
  String get notifSettings_streakReminder => 'Serie-Erinnerung';

  @override
  String get notifSettings_smartAlerts => 'Smarte Alarme';

  @override
  String get notifSettings_selectDay => 'Tag wählen';

  @override
  String get notifSettings_summariesDesc =>
      'Zusammenfassungen zeigen Ausgaben, Einkommen, Top-Kategorie & Saldo';

  @override
  String get notifSettings_reminderTime => 'Erinnerungszeit';

  @override
  String get notifSettings_sendTestNotif => 'Test-Benachrichtigung senden';

  @override
  String get notifSettings_testNotifSent => 'Test-Benachrichtigung gesendet';

  @override
  String get notifSettings_dailyNudgeStreak =>
      'Täglicher Stupser, um deine Serie zu halten';

  @override
  String get notifSettings_summaryDay => 'Tag der Zusammenfassung';

  @override
  String get notifSettings_gentleReminders =>
      'Sanfte Erinnerungen, wenn du die App länger nicht geöffnet hast';

  @override
  String get notifSettings_budgetWarningsDesc =>
      'Budget-Warnungen, Ausgabenspitzen, Rechnungs-Erinnerungen';

  @override
  String get notifSettings_localNotifDisclaimer =>
      'Benachrichtigungen werden lokal auf deinem Gerät erstellt. Es werden keine Daten an einen Server gesendet.';

  @override
  String get smsImport_autoImport => 'Auto-Import';

  @override
  String get smsImport_permissions => 'Berechtigungen';

  @override
  String get smsImport_notifAccess => 'Benachrichtigungs-Zugriff';

  @override
  String get smsImport_notifAccessEnabled =>
      'Benachrichtigungs-Zugriff aktiviert';

  @override
  String get smsImport_allowReadingNotif =>
      'Bank-Benachrichtigungen lesen erlauben';

  @override
  String get smsImport_autoDetectTxn =>
      'Transaktionen automatisch aus Benachrichtigungen erkennen';

  @override
  String get smsImport_privacyNote =>
      'Benachrichtigungen werden lokal auf deinem Gerät gelesen, um Transaktionen zu finden. Es wird niemals etwas hochgeladen oder geteilt.';

  @override
  String get smsImport_tools => 'Tools';

  @override
  String get smsImport_txnActivity => 'Transaktions-Aktivität';

  @override
  String get smsImport_viewDetectedTxn =>
      'Alle erkannten Transaktionen anzeigen';

  @override
  String get smsImport_clearHistory => 'Verlauf leeren';

  @override
  String get smsImport_resetDetection => 'Erkennungsverlauf zurücksetzen';

  @override
  String get smsImport_howItWorks => 'So funktioniert\'s';

  @override
  String get smsImport_readsBankNotif =>
      'Liest Bank- & Wallet-Benachrichtigungen';

  @override
  String get smsImport_dataStaysOnDevice =>
      'Alle Daten bleiben auf deinem Gerät';

  @override
  String get smsImport_autoCreatesTxn => 'Erstellt Transaktionen automatisch';

  @override
  String get smsImport_personalIgnored =>
      'Private Nachrichten werden ignoriert';

  @override
  String get smsImport_noDataSent => 'Keine Datenübertragung an Server';

  @override
  String get smsImport_active => 'Aktiv';

  @override
  String get smsImport_inactive => 'Inaktiv';

  @override
  String get smsImport_grantAccess =>
      'Benachrichtigungs-Zugriff gewähren, um loszulegen';

  @override
  String get smsImport_notAvailableIos => 'Nicht verfügbar auf iOS';

  @override
  String get smsImport_enableAccessFirst =>
      'Aktiviere erst den Benachrichtigungs-Zugriff';

  @override
  String get smsImport_notifAccessRequired =>
      'Benachrichtigungs-Zugriff erforderlich';

  @override
  String get smsImport_notifAccessDesc =>
      'Mudra Manager braucht Zugriff auf Benachrichtigungen, um Transaktionen deiner Bank-Apps automatisch zu erkennen.';

  @override
  String get smsImport_onlyBankRead =>
      'Nur Bank-/Wallet-Meldungen werden gelesen';

  @override
  String get smsImport_personalNeverRead =>
      'Private Nachrichten werden niemals gelesen';

  @override
  String get smsImport_openSettings => 'Einstellungen öffnen';

  @override
  String get smsImport_clearHistoryConfirm => 'Verlauf leeren?';

  @override
  String get smsImport_clearHistoryWarning =>
      'Zuvor erkannte Meldungen werden erneut verarbeitet, was Duplikate erzeugen kann.';

  @override
  String get smsImport_tapAgainSettings =>
      'Nochmal tippen, um die Systemeinstellungen zu öffnen';

  @override
  String get upgrade_purchaseFailed =>
      'Kauf fehlgeschlagen. Bitte versuche es erneut.';

  @override
  String get upgrade_purchasePending =>
      'Kauf ausstehend. Pro wird aktiviert, sobald die Zahlung abgeschlossen ist.';

  @override
  String get upgrade_welcomePro => 'Willkommen bei Pro!';

  @override
  String get upgrade_allFeaturesUnlocked =>
      'Alle Funktionen sind jetzt freigeschaltet. Danke für deine Unterstützung!';

  @override
  String get upgrade_startExploring => 'Jetzt erkunden';

  @override
  String get upgrade_yourProFeatures => 'Deine Pro-Features';

  @override
  String get upgrade_manageSubscription =>
      'Um dein Abo zu verwalten, gehe zum Google Play Store > Abonnements.';

  @override
  String get upgrade_everythingInPro => 'Alles in Pro';

  @override
  String get upgrade_chooseYourPlan => 'Wähle dein Paket';

  @override
  String get upgrade_yearly => 'Jährlich';

  @override
  String get upgrade_save43 => '43% sparen';

  @override
  String get upgrade_monthly => 'Monatlich';

  @override
  String get upgrade_continue => 'Weiter';

  @override
  String get upgrade_restorePurchases => 'Käufe wiederherstellen';

  @override
  String get upgrade_renewsToday => 'Erneuert sich heute';

  @override
  String get upgrade_mudraManagerPro => 'Mudra Manager Pro';

  @override
  String get upgrade_unlockFullPower =>
      'Entfessle die volle Power deiner Finanzen';

  @override
  String upgrade_unlockAccountsTitle(int count) {
    return 'Unlock all $count accounts';
  }

  @override
  String upgrade_accountsFreePlanLimit(int max) {
    return 'Free plan includes $max accounts. Upgrade to Pro to use all your accounts.';
  }

  @override
  String get upgrade_seeProPlans => 'See Pro Plans';

  @override
  String get day_monday => 'Montag';

  @override
  String get day_tuesday => 'Dienstag';

  @override
  String get day_wednesday => 'Mittwoch';

  @override
  String get day_thursday => 'Donnerstag';

  @override
  String get day_friday => 'Freitag';

  @override
  String get day_saturday => 'Samstag';

  @override
  String get day_sunday => 'Sonntag';

  @override
  String get recap_income => 'Einkommen';

  @override
  String get recap_expense => 'Ausgabe';

  @override
  String get recap_saved => 'Gespart';

  @override
  String get recap_dailySpending => 'Tägliche Ausgaben';

  @override
  String get recap_spendingPace => 'Ausgabentempo';

  @override
  String get recap_recurringVsOneTime => 'Wiederkehrend vs. Einmalig';

  @override
  String get recap_topCategories => 'Top-Kategorien';

  @override
  String get recap_mostFrequent => 'Am häufigsten';

  @override
  String get recap_incomeSources => 'Einnahmequellen';

  @override
  String get recap_byAccount => 'Nach Konto';

  @override
  String get recap_budgetHealth => 'Budget-Gesundheit';

  @override
  String get recap_biggestExpenses => 'Größte Ausgaben';

  @override
  String get recap_biggestIncome => 'Größte Einnahmen';

  @override
  String get recap_generating => 'Wird erstellt...';

  @override
  String get recap_avgPerDay => 'Schnitt/Tag';

  @override
  String get recap_weekdayAvg => 'Wochentag Schnitt';

  @override
  String get recap_weekendAvg => 'Wochenende Schnitt';

  @override
  String get recap_budgets => 'Budgets';

  @override
  String get recap_badges => 'Abzeichen';

  @override
  String get recap_streak => 'Serie';

  @override
  String get recap_best => 'Bestleistung';

  @override
  String get recap_savings => 'Ersparnisse';

  @override
  String get about_developerMode => 'Entwicklermodus aktiviert!';

  @override
  String get about_couldNotOpenLink => 'Link konnte nicht geöffnet werden';

  @override
  String get about_title => 'Über';

  @override
  String get about_privacyDesc =>
      'Alles bleibt auf deinem Gerät. Keine Konten, keine Cloud, keine Datensammlung. Deine Finanzen gehören dir allein.';

  @override
  String get about_legalTransparency => 'Rechtliches & Transparenz';

  @override
  String get about_privacyPolicy => 'Datenschutzerklärung';

  @override
  String get about_privacyPolicyDesc => 'Wie wir deine Daten schützen';

  @override
  String get about_termsOfService => 'Nutzungsbedingungen';

  @override
  String get about_termsDesc => 'Bedingungen für die App-Nutzung';

  @override
  String get about_openSourceLicenses => 'Open-Source-Lizenzen';

  @override
  String get about_openSourceDesc =>
      'Drittanbieter-Bibliotheken, die wir nutzen';

  @override
  String get about_supportConnect => 'Support & Kontakt';

  @override
  String get about_checkForUpdates => 'Nach Updates suchen';

  @override
  String get about_checkForUpdatesDesc => 'App-Version manuell prüfen';

  @override
  String get about_latestVersion => 'Du nutzt die neueste Version';

  @override
  String get about_unableToCheck => 'Prüfung fehlgeschlagen';

  @override
  String get about_officialWebsite => 'Offizielle Webseite';

  @override
  String get about_visitWebsite => 'Besuche mudramanager.com';

  @override
  String get about_contactSupport => 'Support kontaktieren';

  @override
  String get about_contactSupportDesc => 'Hilfe erhalten oder Fehler melden';

  @override
  String get about_rateApp => 'App bewerten';

  @override
  String get about_rateAppDesc => 'Teile deine Erfahrung im Store';

  @override
  String get about_developerModeSection => 'Entwicklermodus';

  @override
  String get about_mudraManager => 'Mudra Manager';

  @override
  String get about_secureFinancial => 'Deine finanzielle Kommandozentrale';

  @override
  String get about_loadingLicenses => 'Lizenzen werden geladen...';

  @override
  String get appearance_title => 'Erscheinungsbild';

  @override
  String get appearance_themeMode => 'Design-Modus';

  @override
  String get appearance_display => 'Anzeige';

  @override
  String get appearance_toneVoice => 'Ton & Stimme';

  @override
  String get appearance_changesApplyInstantly =>
      'Änderungen werden sofort übernommen.';

  @override
  String get appearance_darkAppearance => 'Dunkles Design';

  @override
  String get appearance_lightAppearance => 'Helles Design';

  @override
  String get appearance_accountStyle => 'Konto-Stil';

  @override
  String get appearance_cards => 'Karten';

  @override
  String get appearance_stack => 'Stapel';

  @override
  String get appearance_bento => 'Bento';

  @override
  String get appearance_highContrast => 'Hoher Kontrast';

  @override
  String get appearance_highContrastDesc =>
      'Bessere Lesbarkeit bei Sehschwäche';

  @override
  String get appearance_guestMode => 'Gastmodus';

  @override
  String get appearance_guestModeOnDesc => 'Echte Beträge sind versteckt';

  @override
  String get appearance_guestModeOffDesc => 'Sensible Finanzdaten verbergen';

  @override
  String get appearance_lightMode => 'Helles Design';

  @override
  String get appearance_darkMode => 'Dunkles Design';

  @override
  String get appearance_systemDefault => 'Systemstandard';

  @override
  String get analytics_financialHealthScore => 'Finanz-Score';

  @override
  String get analytics_savingsRate => 'Sparquote';

  @override
  String get analytics_expenseRatio => 'Ausgabenquote';

  @override
  String get analytics_insights => 'Einblicke';

  @override
  String get analytics_spendingPrediction => 'Ausgaben-Prognose';

  @override
  String get analytics_nextMonth => 'Nächster Monat';

  @override
  String get analytics_basedOnAvg =>
      'Basierend auf dem Schnitt der letzten 3 Monate';

  @override
  String get analytics_categoryTrends => 'Kategorie-Trends';

  @override
  String get analytics_spendingByDay => 'Ausgaben nach Wochentag';

  @override
  String get trip_notFound => 'Reise nicht gefunden';

  @override
  String get trip_notFoundMsg => 'Reise unauffindbar';

  @override
  String get trip_tripLabel => 'Reise';

  @override
  String get trip_groupLabel => 'Gruppe';

  @override
  String get trip_archiveTripTitle => 'Reise archivieren';

  @override
  String get trip_archiveMsg =>
      'Diese Reise wird ins Archiv verschoben. Alle Daten und Abrechnungen bleiben erhalten.';

  @override
  String get trip_archiveConfirm => 'Archivieren';

  @override
  String get trip_totalSpent => 'Gesamt ausgegeben';

  @override
  String get trip_splitExpense => 'Ausgabe aufteilen';

  @override
  String get trip_allPeople => 'Alle Personen';

  @override
  String get trip_allCategories => 'Alle Kategorien';

  @override
  String get trip_uncategorized => 'Nicht kategorisiert';

  @override
  String get trip_removeFromTrip => 'Remove this expense from the trip?';

  @override
  String get trip_removeFromGroup => 'Remove this expense from the group?';

  @override
  String get trip_removeConfirm => 'Remove';

  @override
  String get trip_unknown => 'Unknown';

  @override
  String get trip_youPaid => 'You paid';

  @override
  String get trip_noPendingSettlements =>
      'No pending settlements for this trip';

  @override
  String get trip_everyoneSquare => 'Everyone is square';

  @override
  String get trip_archiveGroupTitle => 'Archive Group';

  @override
  String get trip_archiveGroupMsg =>
      'This group will be moved to archive. All data and settlements will be preserved.';

  @override
  String get trip_errorLoading => 'Error loading trips';

  @override
  String get trip_noTripsYet => 'No trips yet';

  @override
  String get trip_noSplitsYet => 'No split groups yet';

  @override
  String get trip_createTripDesc => 'Create a trip to track travel expenses';

  @override
  String get trip_createSplitDesc => 'Split bills with friends without a trip';

  @override
  String get trip_spent => 'spent';

  @override
  String get trip_yourShare => 'your share';

  @override
  String trip_nPeople(int count) {
    return '$count people';
  }

  @override
  String get common_new => 'New';

  @override
  String get trip_archive => 'Archive';

  @override
  String get trip_ofBudget => 'of budget';

  @override
  String trip_nDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'days',
      one: 'day',
    );
    return '$_temp0';
  }

  @override
  String trip_nExpenses(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'expenses',
      one: 'expense',
    );
    return '$_temp0';
  }

  @override
  String get trip_removeExpense => 'Remove Expense';

  @override
  String get trip_removeExpenseMsg => 'Remove this expense from the trip?';

  @override
  String get trip_remove => 'Remove';

  @override
  String trip_paidBySplitAmong(String name, int count) {
    return 'Paid by $name • Split among $count';
  }

  @override
  String get trip_archiveToSettle => 'Archivieren zum Abrechnen';

  @override
  String get trip_settlementHistory => 'Settlement History';

  @override
  String get trip_allSettled => 'Alles erledigt!';

  @override
  String get trip_removeGroupExpenseMsg =>
      'Remove this expense from the group?';

  @override
  String trip_nPendingSettlements(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'settlements',
      one: 'settlement',
    );
    return '$count pending $_temp0';
  }

  @override
  String get trip_addSplitExpense => 'Add Split Expense';

  @override
  String get trip_amount => 'Amount';

  @override
  String get trip_whatWasThisFor => 'What was this for?';

  @override
  String get trip_paidBy => 'Paid By';

  @override
  String get trip_splitType => 'Split Type';

  @override
  String get trip_equally => 'Equally';

  @override
  String get trip_custom => 'Custom';

  @override
  String get trip_splitWith => 'Split With';

  @override
  String get trip_addToTrip => 'Add to Trip';

  @override
  String get trip_addToGroup => 'Add to Group';

  @override
  String get trip_autoFillRemaining => 'Auto-fill remaining';

  @override
  String get trip_finalizeTrip => 'Finalize Trip';

  @override
  String get trip_closeGroup => 'Close Group';

  @override
  String get trip_finalizeTripMsg =>
      'This will mark the trip as ended. You can\'t add expenses after this.';

  @override
  String get trip_closeGroupMsg =>
      'This will close the group. You can\'t add expenses after this.';

  @override
  String get trip_finalize => 'Finalize';

  @override
  String get trip_close => 'Close';

  @override
  String get trip_tripNotFound => 'Trip not found';

  @override
  String get trip_groupNotFound => 'Group not found';

  @override
  String get trip_editGroup => 'Gruppe bearbeiten';

  @override
  String get trip_editSplitGroup => 'Edit Split Group';

  @override
  String get trip_travelTrip => 'Travel Trip';

  @override
  String get trip_splitGroup => 'Split Group';

  @override
  String get trip_tripName => 'Trip Name';

  @override
  String get trip_groupName => 'Group Name';

  @override
  String get trip_tripNameHint => 'e.g., Goa Trip 2024';

  @override
  String get trip_groupNameHint => 'e.g., Weekend dinner split';

  @override
  String get trip_tripDescHint => 'Beach vacation with friends';

  @override
  String get trip_groupDescHint => 'Split expenses with friends';

  @override
  String get trip_budgetHint => 'e.g., 50000';

  @override
  String get trip_currency => 'Currency';

  @override
  String get common_update => 'Aktualisieren';

  @override
  String get common_create => 'Erstellen';

  @override
  String get editTrip_add => 'Add';

  @override
  String get editTrip_addParticipant => 'Add Participant';

  @override
  String get editTrip_name => 'Name';

  @override
  String get editTrip_enterName => 'Enter participant name';

  @override
  String get editTrip_finalizeTrip => 'Finalize Trip';

  @override
  String get editTrip_closeGroup => 'Close Group';

  @override
  String get editTrip_finalizeMsg =>
      'This will mark the trip as ended. You cannot add expenses after this.';

  @override
  String get editTrip_closeGroupMsg =>
      'This will close the group. You cannot add expenses after this.';

  @override
  String get editTrip_finalize => 'Finalize';

  @override
  String get editTrip_close => 'Close';

  @override
  String get editTrip_groupNotFound => 'Group Not Found';

  @override
  String get editTrip_groupNotFoundMsg => 'Group not found';

  @override
  String get editTrip_editTrip => 'Edit Trip';

  @override
  String get editTrip_editGroup => 'Edit Group';

  @override
  String get editTrip_editSplitGroup => 'Edit Split Group';

  @override
  String get editTrip_createTrip => 'Create Trip';

  @override
  String get editTrip_createSplitGroup => 'Create Split Group';

  @override
  String get editTrip_travelTrip => 'Travel Trip';

  @override
  String get editTrip_splitGroup => 'Split Group';

  @override
  String get editTrip_tripDetails => 'Trip Details';

  @override
  String get editTrip_groupDetails => 'Group Details';

  @override
  String get editTrip_tripName => 'Trip Name';

  @override
  String get editTrip_groupName => 'Group Name';

  @override
  String get editTrip_descriptionOptional => 'Description (Optional)';

  @override
  String get editTrip_tripHint => 'Beach vacation with friends';

  @override
  String get editTrip_groupHint => 'Split expenses with friends';

  @override
  String get editTrip_budgetOptional => 'Budget (Optional)';

  @override
  String get editTrip_currency => 'Currency';

  @override
  String get editTrip_baseCurrencyDefault => 'Base currency (default)';

  @override
  String get editTrip_duration => 'Duration';

  @override
  String get editTrip_warningDateChange => 'Warning: Date Change';

  @override
  String get expense_notFound => 'Not Found';

  @override
  String get expense_notFoundMsg => 'Expense not found';

  @override
  String get expense_details => 'Expense Details';

  @override
  String get expense_paidBy => 'Paid by';

  @override
  String get expense_you => 'You';

  @override
  String get expense_yourShare => 'Your share';

  @override
  String get expense_noteLabel => 'Note';

  @override
  String get expense_editSplit => 'Edit Split';

  @override
  String get expense_splitType => 'Split Type';

  @override
  String get expense_equal => 'Equal';

  @override
  String get expense_custom => 'Custom';

  @override
  String get expense_participants => 'Participants';

  @override
  String get expense_autoFillRemaining => 'Auto-fill remaining';

  @override
  String get expense_deleteExpense => 'Delete Expense';

  @override
  String get expense_deleteExpenseMsg =>
      'This will adjust everyones balance. Continue?';

  @override
  String get expense_splitUpdated => 'Split updated';

  @override
  String get expense_remaining => 'Remaining';

  @override
  String get billCenter_overdue => 'Overdue';

  @override
  String get billCenter_thisWeek => 'This Week';

  @override
  String get billCenter_thisMonth => 'This Month';

  @override
  String get billCenter_later => 'Later';

  @override
  String get billCenter_totalUpcoming => 'Total upcoming';

  @override
  String get billCenter_today => 'Today';

  @override
  String get billCenter_tomorrow => 'Tomorrow';

  @override
  String get billCenter_afterUpcoming => 'After upcoming bills';

  @override
  String get billCenter_dueToday => 'Due today';

  @override
  String get billCenter_paid => 'Paid';

  @override
  String get billCenter_pay => 'Pay';

  @override
  String get billCenter_existingTxnFound => 'Existing Transaction Found';

  @override
  String get billCenter_linkTransaction => 'Link This Transaction';

  @override
  String get billCenter_createNewEntry => 'Create New Entry';

  @override
  String get billCenter_lowBuffer => 'Low buffer';

  @override
  String get billCenter_safe => 'Covered';

  @override
  String billCenter_unfundedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bills may not be covered',
      one: '1 bill may not be covered',
    );
    return '$_temp0';
  }

  @override
  String get billCenter_thisWeekRequired => 'Required this week';

  @override
  String billCenter_activeBills(int count) {
    return '$count active bills';
  }

  @override
  String get billCenter_largestBill => 'Largest';

  @override
  String billCenter_upcomingIn(int days) {
    return 'Upcoming in $days days';
  }

  @override
  String get billCenter_cannotPayFuture => 'Cannot mark future bills as paid';

  @override
  String billCenter_markedPaid(String name) {
    return '$name marked as paid';
  }

  @override
  String billCenter_inDays(int days) {
    return 'In $days days';
  }

  @override
  String billCenter_daysAgo(int days) {
    return '${days}d ago';
  }

  @override
  String billCenter_daysOverdue(int days) {
    return '${days}d overdue';
  }

  @override
  String billCenter_moreCount(int count) {
    return '+$count more';
  }

  @override
  String get billCenter_addBill => 'Add a recurring bill to see it here';

  @override
  String get frequency_daily => 'Daily';

  @override
  String get frequency_weekly => 'Weekly';

  @override
  String get frequency_monthly => 'Monthly';

  @override
  String get frequency_yearly => 'Yearly';

  @override
  String get comparison_steady => 'Steady as she goes';

  @override
  String get comparison_steadyDesc =>
      'Your spending is consistent — that is discipline.';

  @override
  String get comparison_doingGreat => 'You are doing great';

  @override
  String get comparison_headsUp => 'Heads up — spending is up';

  @override
  String get reconcile_title => 'Reconcile';

  @override
  String get reconcile_info =>
      'Enter the current balance shown in your bank app or passbook. We\'ll adjust the difference automatically.';

  @override
  String get reconcile_balanceInApp => 'Balance in App';

  @override
  String get reconcile_actualBalance => 'Actual Bank Balance';

  @override
  String get reconcile_balanced => 'Balanced!';

  @override
  String get reconcile_difference => 'Difference';

  @override
  String reconcile_incomeAdjustment(String amount) {
    return 'An income adjustment of $amount will be added.';
  }

  @override
  String reconcile_expenseAdjustment(String amount) {
    return 'An expense adjustment of $amount will be added.';
  }

  @override
  String get balanceHistory_currentBalance => 'Current Balance';

  @override
  String get balanceHistory_highest => 'Highest';

  @override
  String get balanceHistory_lowest => 'Lowest';

  @override
  String get balanceHistory_average => 'Average';

  @override
  String get common_errorLoading => 'Failed to load data';

  @override
  String get balanceHistory_trend => '30-Day Trend';

  @override
  String get balanceHistory_growing => 'Your balance is growing 📈';

  @override
  String get balanceHistory_declining =>
      'Balance has dipped — let\'s recover 💪';

  @override
  String get balanceHistory_steady => 'Holding steady ⚖️';

  @override
  String get account_editTitle => 'Edit Account';

  @override
  String get account_newTitle => 'New Account';

  @override
  String get account_name => 'Account Name';

  @override
  String get account_typeLabel => 'Account Type';

  @override
  String get account_detailsLabel => 'Details';

  @override
  String get account_colorLabel => 'Color';

  @override
  String get account_currencyLabel => 'Currency';

  @override
  String get account_balance => 'Balance';

  @override
  String get account_outstanding => 'Outstanding';

  @override
  String get account_last4 => 'Last 4 digits';

  @override
  String get account_last4Helper => 'For SMS auto-matching';

  @override
  String get account_initialBalance => 'Initial balance';

  @override
  String get account_cardPaidOff => 'Enter 0 if card is paid off';

  @override
  String get account_min4 => 'At least 4 digits';

  @override
  String get account_max4 => 'Only last 4 digits';

  @override
  String get iconPicker_title => 'Pick an Icon';

  @override
  String get iconPicker_search => 'Search icons...';

  @override
  String get iconPicker_noResults => 'No icons found';

  @override
  String get colorPicker_title => 'Pick a Color';

  @override
  String get color_red => 'Red';

  @override
  String get color_pink => 'Pink';

  @override
  String get color_purple => 'Purple';

  @override
  String get color_indigo => 'Indigo';

  @override
  String get color_blue => 'Blue';

  @override
  String get color_cyan => 'Cyan';

  @override
  String get color_teal => 'Teal';

  @override
  String get color_green => 'Green';

  @override
  String get color_orange => 'Orange';

  @override
  String get color_brown => 'Brown';

  @override
  String get color_grey => 'Grey';

  @override
  String get accounts_totalBalance => 'Total Balance';

  @override
  String get accounts_accountsCount => 'accounts';

  @override
  String get accounts_archived => 'Archived';

  @override
  String get accounts_howItWorks => 'How Accounts Work';

  @override
  String get accounts_howItWorksDesc =>
      'Manage all your bank accounts, wallets, and cash in one place. Track balances and transactions across multiple accounts.';

  @override
  String get accounts_primary => 'Primary';

  @override
  String get categories_label => 'categories';

  @override
  String get categories_transactionsLabel => 'transactions';

  @override
  String categories_deleteWithTransactions(String name, int count) {
    return 'This will permanently delete \"$name\" and $count linked transactions. This action cannot be undone.';
  }

  @override
  String get categories_deleteAll => 'Delete All';

  @override
  String get categories_edit => 'Edit Category';

  @override
  String get categories_delete => 'Delete Category';

  @override
  String get categories_deleteSubtitle => 'Removes all linked transactions';

  @override
  String get category_save => 'Save';

  @override
  String get category_detailsLabel => 'Details';

  @override
  String get category_parentLabel => 'Parent Category';

  @override
  String get category_nameHint => 'Category Name';

  @override
  String get category_keywordsHint => 'Keywords (comma-separated)';

  @override
  String get category_keywordsHelper =>
      'For SMS auto-detection (e.g. swiggy, zomato)';

  @override
  String get category_suggestedKeywords => 'Suggested keywords';

  @override
  String get currency_title => 'Currency';

  @override
  String get currency_baseCurrency => 'Base Currency';

  @override
  String get currency_baseDescription =>
      'All totals, budgets, and analytics use this currency.';

  @override
  String get currency_exchangeRates => 'Exchange Rates';

  @override
  String get currency_exchangeRatesDesc => 'View and edit conversion rates';

  @override
  String get currency_archivedDesc =>
      'View transactions from previous currencies';

  @override
  String exchange_unitInfo(String base) {
    return 'unit of foreign currency = X $base. Tap any rate to edit.';
  }

  @override
  String get exchange_search => 'Search currency...';

  @override
  String exchange_rateUpdated(String code) {
    return '$code rate updated';
  }

  @override
  String exchange_editRate(String code) {
    return 'Edit $code Rate';
  }

  @override
  String get exchange_rateLabel => 'Rate';

  @override
  String get exchange_invalidRate => 'Enter a valid rate';

  @override
  String get archived_transaction => 'Transaction';

  @override
  String get currency_changingCurrency => 'Changing currency...';

  @override
  String get currency_pleaseWait =>
      'Archiving transactions and updating settings';

  @override
  String get security_title => 'Security';

  @override
  String get security_unprotected => 'Unprotected';

  @override
  String get security_basic => 'Basic';

  @override
  String get security_strong => 'Strong';

  @override
  String get security_unprotectedDesc =>
      'Enable PIN or biometrics to protect your data';

  @override
  String security_protectionsActive(int count, int total) {
    return '$count of $total protections active';
  }

  @override
  String get security_authentication => 'Authentication';

  @override
  String get security_pinLock => 'PIN Lock';

  @override
  String get security_pinActive => '4-digit PIN active';

  @override
  String get security_pinSet => 'Set a 4-digit PIN';

  @override
  String get security_biometric => 'Biometric Unlock';

  @override
  String get security_biometricDesc => 'Fingerprint or Face ID';

  @override
  String get security_manage => 'Manage';

  @override
  String get security_changePin => 'Change PIN';

  @override
  String get security_changePinDesc => 'Update your 4-digit PIN';

  @override
  String get security_enablePinFirst => 'Enable PIN first';

  @override
  String get security_biometricEnabled => 'Biometric enabled';

  @override
  String get security_biometricDisabled => 'Biometric disabled';

  @override
  String get security_infoText =>
      'Your PIN is stored securely on this device — it never touches a server. Digits are randomized on entry for extra protection.';

  @override
  String notifSettings_activeCount(int count) {
    return '$count of 5 active';
  }

  @override
  String get notifSettings_summaryDesc =>
      'Summaries show spending, income, top category & balance';

  @override
  String get notifSettings_dailySummaryDesc => 'Yesterday\'s spending overview';

  @override
  String notifSettings_weeklySchedule(String day) {
    return 'Every $day at 9:00 AM';
  }

  @override
  String get smsImport_autoImporting =>
      'Transactions are being imported automatically';

  @override
  String get smsImport_enableToStart => 'Enable auto import to start tracking';

  @override
  String get smsImport_iosRestriction =>
      'Auto import is only available on Android due to iOS platform restrictions.';

  @override
  String get common_change => 'Change';

  @override
  String get goal_whatSavingFor => 'What are you saving for?';

  @override
  String get netWorth_totalLabel => 'Total Net Worth';

  @override
  String get netWorth_notEnoughData => 'Not enough data yet';

  @override
  String get netWorth_assets => 'Assets';

  @override
  String get netWorth_liabilities => 'Liabilities';

  @override
  String get netWorth_composition => 'Wealth Composition';

  @override
  String get goal_milestoneStarted => 'Started';

  @override
  String get goal_milestoneStartedDesc => 'Your journey began';

  @override
  String get goal_milestone25 => '25%';

  @override
  String get goal_milestone25Desc => 'Quarter way there';

  @override
  String get goal_milestone50 => '50%';

  @override
  String get goal_milestone50Desc => 'Halfway done!';

  @override
  String get goal_milestone75 => '75%';

  @override
  String get goal_milestone75Desc => 'Almost there';

  @override
  String get goal_milestone100 => '100%';

  @override
  String get goal_milestone100Desc => 'Goal reached! 🎉';

  @override
  String get goal_flexibleTimeline => 'Flexible timeline';

  @override
  String get goal_amount => 'Amount';

  @override
  String get goal_emotionReached => 'Goal reached! 🎉';

  @override
  String get goal_emotionProgress => 'Great progress ✨';

  @override
  String goal_emotionMoreToGo(Object amount) {
    return 'Just $amount more to go 💪';
  }

  @override
  String get goal_emotionSetTarget => 'Set your target 🎯';

  @override
  String get goal_emotionWhatSaving => 'What are you saving for?';

  @override
  String get goal_exceededTarget => 'You\'ve exceeded your target! 🎉';

  @override
  String get goal_alreadyReached => 'Goal already reached! 🎉';

  @override
  String goal_progressLeft(Object percent, Object amount) {
    return '$percent% there • $amount left';
  }

  @override
  String goal_paceDaily(Object daily, Object monthly) {
    return 'At this pace, you need $daily/day to reach your goal.\nThat\'s $monthly/month.';
  }

  @override
  String goal_daysRemaining(Object count) {
    return '$count days remaining';
  }

  @override
  String goal_daysLeft(Object count) {
    return '$count days left';
  }

  @override
  String goal_startSaving(Object amount) {
    return 'Start saving $amount';
  }

  @override
  String goal_goalsInProgress(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count goals in progress',
      one: '1 goal in progress',
    );
    return '$_temp0';
  }

  @override
  String get goal_completedSection => 'Completed 🎉';

  @override
  String get goal_emotionAlmost => 'Almost there 🚀';

  @override
  String get goal_emotionHalfway => 'Halfway there 💪';

  @override
  String get goal_emotionEvery => 'Every bit counts 🌱';

  @override
  String get goal_emotionHalfwayDone => 'Halfway done ✨';

  @override
  String get goal_emotionKeepPushing => 'Keep pushing 🔥';

  @override
  String get goal_emotionJustStarted => 'Just getting started 🌱';

  @override
  String get goal_closestToCompletion => 'Closest to completion';

  @override
  String goal_acrossGoals(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'across $count goals',
      one: 'across 1 goal',
    );
    return '$_temp0';
  }

  @override
  String get goal_suffixSaved => 'saved';

  @override
  String get goal_suffixLeft => 'left';

  @override
  String get goal_suffixDone => 'done';

  @override
  String get goal_suffixAchieved => 'achieved';

  @override
  String get goal_suffixToGo => 'to go';

  @override
  String get goal_needsAttention => 'Needs attention ⚠️';

  @override
  String goal_needAttention(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count need attention',
      one: '1 needs attention',
    );
    return '$_temp0';
  }

  @override
  String get goal_aheadOfSchedule => 'Ahead of schedule 🎯';

  @override
  String goal_monthsLeft(Object count) {
    return '$count months left';
  }

  @override
  String get goal_emotionDidIt => 'You did it! 🎉';

  @override
  String get goal_emotionSoClose => 'So close, keep going! 💪';

  @override
  String get goal_emotionMomentum => 'Building momentum 🔥';

  @override
  String get goal_emotionCatchUp => 'Let\'s catch up ⚡';

  @override
  String get goal_finishGoal => 'Finish this goal! 🚀';

  @override
  String get goal_onTrackStatus => 'On Track ✅';

  @override
  String get goal_behindPace => 'Behind pace ⚠️';

  @override
  String goal_daysAgo(Object count) {
    return '$count days ago';
  }

  @override
  String goal_onPaceFor(Object date) {
    return 'On pace for $date';
  }

  @override
  String get goal_aheadOfPace => 'Ahead of target pace';

  @override
  String goal_behindByAmount(Object amount) {
    return 'Behind by $amount';
  }

  @override
  String get goal_neededPerMonth => 'Needed / month';

  @override
  String get goal_currentAvgMonth => 'Your avg / month';

  @override
  String get goal_forecastLabel => 'Forecast';

  @override
  String get goal_basedOnRecent => 'based on recent contributions';

  @override
  String get goal_timeLeft => 'Time left';

  @override
  String get goal_paceStatus => 'Pace';

  @override
  String get common_today => 'Today';

  @override
  String get common_yesterday => 'Yesterday';

  @override
  String get common_amount => 'Amount';

  @override
  String get accounts_edit => 'Edit Account';

  @override
  String get accounts_balanceHistory => 'Balance History';

  @override
  String get accounts_matchBank => 'Match with bank statement';

  @override
  String get accounts_viewPortfolio => 'View Portfolio';

  @override
  String get accounts_setAsPrimary => 'Set as Primary';

  @override
  String get accounts_primaryDesc => 'Default account for splits & trips';

  @override
  String get accounts_archive => 'Archive';

  @override
  String get accounts_archiveDesc => 'Hide from active accounts';

  @override
  String get accounts_unarchive => 'Unarchive';

  @override
  String get accounts_unarchiveDesc => 'Restore to active accounts';

  @override
  String get accounts_deleteDesc => 'Permanently remove account';

  @override
  String get smsActivity_title => 'Transaction Activity';

  @override
  String get smsActivity_approved => 'Approved';

  @override
  String get smsActivity_pending => 'Pending';

  @override
  String get smsActivity_rejected => 'Rejected';

  @override
  String get smsActivity_needsReview => 'Needs Review';

  @override
  String get smsActivity_duplicates => 'Duplicates';

  @override
  String get smsActivity_filterByStatus => 'Filter by Status';

  @override
  String smsActivity_transactionCount(Object count) {
    return '$count Transactions';
  }

  @override
  String smsActivity_needsAttention(Object count) {
    return '$count needs attention';
  }

  @override
  String smsActivity_resultCount(Object count) {
    return '$count results';
  }

  @override
  String get smsActivity_noActivities => 'No matching activities';

  @override
  String get smsActivity_status => 'Status';

  @override
  String get smsActivity_confidence => 'Confidence';

  @override
  String get smsActivity_account => 'Account';

  @override
  String get smsActivity_bank => 'Bank';

  @override
  String get smsActivity_type => 'Type';

  @override
  String get smsActivity_merchant => 'Merchant';

  @override
  String get smsActivity_balance => 'Balance';

  @override
  String get smsActivity_reference => 'Reference';

  @override
  String get smsActivity_duplicateLabel => 'DUPLICATE';

  @override
  String get smsActivity_transferLabel => 'TRANSFER';

  @override
  String get smsActivity_reject => 'Reject';

  @override
  String get smsActivity_approve => 'Approve';

  @override
  String get smsActivity_transfer => 'Transfer';

  @override
  String get smsActivity_addAccount => 'Add A/C';

  @override
  String get smsActivity_duplicateWarning =>
      'This may be a duplicate transaction. Review carefully before approving.';

  @override
  String smsActivity_noAccountWarning(Object account) {
    return 'No account found matching \"$account\". Add one to approve.';
  }

  @override
  String get smsActivity_transferWarning =>
      'This looks like a transfer between your accounts. Approving will open the transfer screen.';

  @override
  String get common_all => 'All';

  @override
  String get backup_lastBackup => 'Last backup';

  @override
  String get backup_noBackups => 'No backups yet';

  @override
  String get backup_createFirst =>
      'Create your first backup to protect your data';

  @override
  String get backup_actions => 'Actions';

  @override
  String get backup_history => 'History';

  @override
  String get backup_noHistory => 'No backup history';

  @override
  String get backup_infoText =>
      'Backups are encrypted with your password and saved as .mudra files. Keep your password safe — it cannot be recovered.';

  @override
  String get backup_justNow => 'Just now';

  @override
  String backup_minutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String backup_hoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String backup_daysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String backup_recordCount(int count) {
    return '$count records';
  }

  @override
  String get account_changeCurrency => 'Change Currency?';

  @override
  String account_resetTo(String code) {
    return 'Reset to $code';
  }

  @override
  String get account_baseCurrencyInfo =>
      'Transactions in this account use your base currency.';

  @override
  String account_foreignCurrencyInfo(String code, String base) {
    return 'Transactions will be recorded in $code and converted to $base for totals.';
  }

  @override
  String get account_warningNoConvert =>
      'Existing balances will NOT be converted automatically.';

  @override
  String get account_warningNewCurrency =>
      'New transactions will use the new currency.';

  @override
  String get account_warningManualAdjust =>
      'You may need to manually adjust the balance.';

  @override
  String get category_selectParent => 'Select Parent Category';

  @override
  String get appearance_colorTheme => 'Color Theme';

  @override
  String get appearance_amoledMode => 'AMOLED Mode';

  @override
  String appearance_toneActivated(String name) {
    return '$name tone activated';
  }

  @override
  String dashboard_cardsActive(int visible, int total) {
    return '$visible of $total cards active';
  }

  @override
  String get dashboard_dragToReorder =>
      'Drag to reorder, toggle to show or hide';

  @override
  String get dashboard_smartOrdering => 'Smart ordering';

  @override
  String get dashboard_catEssential => 'Essential';

  @override
  String get dashboard_catFinance => 'Finance';

  @override
  String get dashboard_catAnalytics => 'Analytics';

  @override
  String get dashboard_catActions => 'Actions';

  @override
  String get dashboard_catAI => 'AI Insights';

  @override
  String get dashboard_catContextual => 'Contextual';

  @override
  String get importExport_title => 'Import & Export';

  @override
  String get importExport_export => 'Export';

  @override
  String get importExport_import => 'Import';

  @override
  String get importExport_exportTitle => 'Export Transactions';

  @override
  String get importExport_exportDesc =>
      'Download your transactions as an Excel file.';

  @override
  String get importExport_exporting => 'Exporting...';

  @override
  String get importExport_exportAsExcel => 'Export as Excel';

  @override
  String get importExport_importTitle => 'Import from Excel';

  @override
  String get importExport_importDesc =>
      'Import transactions from an .xlsx file. You\'ll be able to preview and map columns before importing.';

  @override
  String get importExport_excelFormat => 'Excel (.xlsx)';

  @override
  String get importExport_bankStatement => 'Bank Statement';

  @override
  String get importExport_otherApps => 'Other Apps';

  @override
  String get importExport_pickFile => 'Pick Excel File';

  @override
  String get importExport_infoText =>
      'Export creates an Excel file with all transaction details. Import supports .xlsx files from other finance apps or manual spreadsheets.';

  @override
  String get plugins_subtitle => 'Extend Mudra Manager with powerful plugins';

  @override
  String get plugins_official => 'Official';

  @override
  String plugins_enabled(String name) {
    return '$name enabled';
  }

  @override
  String plugins_disabled(String name) {
    return '$name disabled';
  }

  @override
  String get plugins_configure => 'Configure Plugin';

  @override
  String plugins_activeCount(int active, int total) {
    return '$active of $total active';
  }

  @override
  String get plugins_toggleDesc => 'Toggle plugins to extend app features';

  @override
  String get plugins_default => 'Default';

  @override
  String get plugins_configureSettings => 'Configure plugin settings';

  @override
  String get plugins_creditCardReminders => 'Credit Card Reminders';

  @override
  String get plugins_remindBefore => 'Remind me before (days)';

  @override
  String get plugins_noCreditCards =>
      'No credit card accounts found. Add one first.';

  @override
  String get plugins_creditCardAccounts => 'Credit Card Accounts';

  @override
  String get plugins_billDay => 'Bill Day (1-31)';

  @override
  String get plugins_remindersConfigured => 'Credit card reminders configured';

  @override
  String get plugins_infoText =>
      'Plugins extend app features. Some plugins require additional permissions or configuration.';

  @override
  String get help_title => 'Help & Support';

  @override
  String get help_searchHint => 'Search help topics...';

  @override
  String get help_heroTitle => 'How can we help?';

  @override
  String get help_heroDesc => 'Browse guides or search for a topic';

  @override
  String get help_topics => 'Topics';

  @override
  String get help_tryDifferent => 'Try a different search term';

  @override
  String get help_howToUse => 'How to use';

  @override
  String get help_tips => 'Tips';

  @override
  String help_articleCount(int count) {
    return '$count articles';
  }

  @override
  String help_resultCount(int count) {
    return '$count results';
  }

  @override
  String get help_infoText =>
      'Can\'t find what you need? Visit About → Contact Support for direct help.';

  @override
  String get about_legalCount => '3 items';

  @override
  String get about_supportCount => '4 items';

  @override
  String about_packageCount(int count) {
    return '$count open source packages';
  }

  @override
  String get onboard_continue => 'Continue';

  @override
  String get onboard_restoreFromBackup => 'Restore from Backup';

  @override
  String get onboard_accountNameRequired => 'Account name is required';

  @override
  String get onboard_balanceRequired => 'Balance is required';

  @override
  String get onboard_enterValidNumber => 'Enter valid number';

  @override
  String get onboard_accountHint => 'e.g., Cash, Bank';

  @override
  String get onboard_browseAllCurrencies => 'Browse all currencies';

  @override
  String get onboard_toneTitle => 'How should Mudra talk to you?';

  @override
  String get onboard_toneDesc =>
      'Pick a personality. You can change this anytime.';

  @override
  String get onboard_categoriesTitle => 'Choose Your Categories';

  @override
  String get onboard_categoriesDesc =>
      'Pick packs that match your lifestyle. You can change these later.';

  @override
  String get onboard_startFresh => 'Start Fresh';

  @override
  String get onboard_startFreshDesc => 'No categories — add your own later';

  @override
  String get onboard_currencyWarning =>
      'Changing base currency later will archive existing transactions.';

  @override
  String get statistics_topCategory => 'Top Category';

  @override
  String get statistics_dailyAverage => 'Daily Average';

  @override
  String get statistics_perDay => 'per day';

  @override
  String statistics_percentOfExpenses(String percent) {
    return '$percent% of expenses';
  }

  @override
  String get sms_infoTitle => 'How SMS Import Works';

  @override
  String get sms_infoOnlyScans => 'Only scans bank and wallet SMS';

  @override
  String get sms_infoStaysOnDevice => 'All data stays on your device';

  @override
  String get sms_infoAutoCreates => 'Automatically creates transactions';

  @override
  String get sms_infoNoPersonal => 'No personal messages are read';

  @override
  String get dashboard_totalBalance => 'Total Balance';

  @override
  String get dashboard_netWorthLink => 'Net Worth';

  @override
  String get dashboard_showAccounts => 'Show accounts';

  @override
  String get dashboard_hideAccounts => 'Hide accounts';

  @override
  String dashboard_accountsTapExpand(int count) {
    return '$count accounts · Tap to expand';
  }

  @override
  String get notif_lowBalanceTitle => '⚠️ Low Balance Alert';

  @override
  String notif_lowBalanceBody(String account, String amount) {
    return 'Your balance in $account is $amount';
  }

  @override
  String get achieve_unlocked => 'Unlocked';

  @override
  String get achieve_inProgress => 'In Progress';

  @override
  String get achieve_trophyShelf => 'Trophy Shelf';

  @override
  String get achieve_streaks => 'Streaks';

  @override
  String get achieve_totalXP => 'Total XP';

  @override
  String get achieve_dailyCheckIn => 'Daily Check-in';

  @override
  String get achieve_budgetAdherence => 'Budget Adherence';

  @override
  String achieve_bestDays(int count) {
    return 'Best: $count days';
  }

  @override
  String achieve_noBadgesYet(String category) {
    return 'No $category badges yet';
  }

  @override
  String achieve_levelUpSnack(int level) {
    return '🎉 Level Up! You are now Level $level!';
  }

  @override
  String achieve_levelLabel(int level) {
    return 'Level $level';
  }

  @override
  String get achieve_catBudgeting => 'Budgeting';

  @override
  String get achieve_catSavings => 'Savings';

  @override
  String get achieve_catTracking => 'Tracking';

  @override
  String get achieve_catMilestones => 'Milestones';

  @override
  String get achieve_catEngagement => 'Engagement';

  @override
  String get achieve_catAll => 'All';

  @override
  String get alert_actionNeeded => 'Action Needed';

  @override
  String alert_billsDueTomorrow(int count) {
    return '$count bill(s) due tomorrow';
  }

  @override
  String get alert_upcomingBills => 'Upcoming Bills';

  @override
  String alert_billsDueInDays(int count) {
    return '$count bill(s) due in 2 days';
  }

  @override
  String get alert_budgetAlert => 'Budget Alert';

  @override
  String alert_budgetsExceeded(int count) {
    return '$count budget(s) exceeded';
  }

  @override
  String get alert_budgetWarning => 'Budget Warning';

  @override
  String alert_budgetsNearLimit(int count) {
    return '$count budget(s) near limit';
  }

  @override
  String get alert_goalProgress => 'Goal Progress';

  @override
  String alert_goalsAlmostComplete(int count) {
    return '$count goal(s) almost complete!';
  }

  @override
  String get analytics_cashFlowForecast => 'Cash Flow Forecast';

  @override
  String get analytics_thisMonthProjected => 'This month (projected)';

  @override
  String get analytics_savingOnAverage => 'You are saving on average';

  @override
  String get analytics_spendingExceedsIncome => 'Spending exceeds income';

  @override
  String get health_scoreBreakdown => 'Score Breakdown';

  @override
  String get health_savings => 'Savings';

  @override
  String get health_spending => 'Spending';

  @override
  String get health_debt => 'Debt';

  @override
  String get health_emergency => 'Emergency';

  @override
  String get health_liquidityRunway => 'Liquidity Runway';

  @override
  String health_balanceCoversMonths(String months) {
    return 'Your balance covers $months months of expenses';
  }

  @override
  String get health_days => 'days';

  @override
  String health_nDays(String n) {
    return '$n days';
  }

  @override
  String get health_safe => 'Safe';

  @override
  String get health_moderate => 'Moderate';

  @override
  String get health_risk => 'Risk';

  @override
  String get health_categoryHealth => 'Category Health';

  @override
  String get health_stable => 'Stable →';

  @override
  String get health_high => 'High ↑';

  @override
  String get health_reduced => 'Reduced ↓';

  @override
  String get health_whatYouCanDo => 'What You Can Do';

  @override
  String get health_verdictExcellent => 'you\'re in great shape';

  @override
  String get health_verdictGood => 'you\'re on track';

  @override
  String get health_verdictFair => 'room for improvement';

  @override
  String get health_verdictPoor => 'needs attention';

  @override
  String get health_provenanceLine =>
      'Based on this month\'s savings, spending, debt & emergency fund';

  @override
  String get health_of100 => 'of 100';

  @override
  String get health_errorLoading => 'Unable to load health data';

  @override
  String get analytics_cashFlowTitle => 'Cash Flow Forecast';

  @override
  String get analytics_currentMonth => 'Current Month';

  @override
  String get analytics_projected => 'Projected';

  @override
  String get analytics_forecast3Month => '3-Month Forecast';

  @override
  String get analytics_monthlyNet => 'Monthly Net';

  @override
  String get analytics_income => 'Income';

  @override
  String get analytics_expense => 'Expense';

  @override
  String get analytics_net => 'Net';

  @override
  String get analytics_avgMonthlyNet => 'Avg Monthly Net';

  @override
  String get analytics_noForecastData => 'Not enough data to forecast';

  @override
  String get analytics_spendingTrendsTitle => 'Spending Trends';

  @override
  String get analytics_predictedNextMonth => 'Predicted next month';

  @override
  String get analytics_anomaly => 'Anomaly';

  @override
  String get analytics_vsLastMonth => 'vs last month';

  @override
  String get analytics_risingCategories => 'Rising Categories';

  @override
  String get analytics_anomalyCategories => 'Anomaly Detected';

  @override
  String get analytics_allCategories => 'All Categories';

  @override
  String get analytics_noTrendData => 'Not enough data for trends';

  @override
  String get recap_vsLastYear => 'vs Last Year';

  @override
  String get common_income => 'Income';

  @override
  String get common_expense => 'Expense';

  @override
  String get common_transactions => 'Transactions';

  @override
  String get tax_title => 'Tax Estimation';

  @override
  String get debt_title => 'Debt Planner';

  @override
  String get debt_utilitySubtitle => 'Snowball & Avalanche strategies';

  @override
  String get debt_snowball => 'Snowball';

  @override
  String get debt_avalanche => 'Avalanche';

  @override
  String get debt_totalDebt => 'Total Debt';

  @override
  String get debt_monthsToFreedom => 'Months to Freedom';

  @override
  String get debt_interestPaid => 'Interest to Pay';

  @override
  String get debt_minPayment => 'Min Payment';

  @override
  String get debt_extraPayment => 'Extra Payment';

  @override
  String get debt_addDebt => 'Add Debt';

  @override
  String get debt_editDebt => 'Edit Debt';

  @override
  String get debt_noDebts => 'No debts added';

  @override
  String get debt_noDebtsDesc =>
      'Add your loans and credit cards to build a payoff plan.';

  @override
  String debt_activeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'debts',
      one: 'debt',
    );
    return '$count $_temp0';
  }

  @override
  String get debt_name => 'Debt Name';

  @override
  String get debt_nameHint => 'e.g., HDFC Credit Card';

  @override
  String get debt_nameRequired => 'Enter a name for this debt';

  @override
  String get debt_balance => 'Current Balance';

  @override
  String get debt_balanceRequired => 'Enter a valid balance';

  @override
  String get debt_interestRate => 'Interest Rate (APR %)';

  @override
  String get debt_interestRateRequired => 'Enter a valid interest rate';

  @override
  String get debt_minimumPayment => 'Minimum Payment';

  @override
  String get debt_minimumPaymentRequired => 'Enter a valid minimum payment';

  @override
  String get debt_extraPaymentOptional => 'Extra Payment (optional)';

  @override
  String get debt_extraPaymentHint => 'Additional amount you can pay monthly';

  @override
  String get debt_payoffOrder => 'Payoff Order';

  @override
  String debt_payoffOrderDesc(int position, String strategy) {
    return 'This debt will be paid off in position $position using the $strategy strategy.';
  }

  @override
  String get debt_archive => 'Archive';

  @override
  String get debt_archiveDesc => 'Hide from active payoff plan';

  @override
  String get debt_unarchive => 'Restore';

  @override
  String get debt_unarchiveDesc => 'Bring back into active payoff plan';

  @override
  String get debt_paidOff => 'Paid Off';

  @override
  String get debt_archived => 'Archived';

  @override
  String get debt_deleteDesc => 'Permanently remove this debt entry';

  @override
  String get debt_infoTitle => 'How debt payoff works';

  @override
  String get debt_infoDesc =>
      'Snowball pays off your smallest balance first for quick wins. Avalanche targets the highest interest rate first to save the most money. Add extra payment to speed up either plan.';

  @override
  String get tax_projected => 'Projected (year in progress)';

  @override
  String get tax_estimatedTax => 'Estimated Tax';

  @override
  String get tax_effectiveRate => 'Effective Rate';

  @override
  String get tax_monthlyTax => 'Monthly';

  @override
  String tax_fyProgress(int elapsed, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: 'days',
      one: 'day',
    );
    return '$elapsed of $total $_temp0';
  }

  @override
  String get tax_slabBreakdown => 'Slab Breakdown';

  @override
  String get tax_totalSlabTax => 'Total Slab Tax';

  @override
  String get tax_computation => 'Tax Computation';

  @override
  String get tax_grossIncome => 'Gross Income';

  @override
  String get tax_standardDeduction => 'Standard Deduction';

  @override
  String get tax_taxableIncome => 'Taxable Income';

  @override
  String get tax_baseTax => 'Tax on Income';

  @override
  String get tax_rebate87A => 'Rebate u/s 87A';

  @override
  String get tax_cess => 'Health & Education Cess (4%)';

  @override
  String get tax_totalTax => 'Total Tax Payable';

  @override
  String get tax_incomeBreakdown => 'Income Sources';

  @override
  String get tax_disclaimer =>
      'This is an estimate based on New Tax Regime (FY 2025-26). Actual tax may vary. Consult a tax professional for accurate filing.';

  @override
  String get tax_noData => 'Not enough data to estimate tax';

  @override
  String get tax_viewDetails => 'View Tax Estimate';

  @override
  String get tax_zeroTax => 'No tax liability 🎉';

  @override
  String get tax_newRegime => 'New Regime';

  @override
  String get tax_oldRegime => 'Old Regime';

  @override
  String get tax_regimeComparison => 'Which Regime Saves More?';

  @override
  String tax_regimeSavings(String regime) {
    return '$regime saves you';
  }

  @override
  String get tax_oldRegimeDisclaimer =>
      'Old Regime estimate uses standard deduction only. With HRA, 80C, 80D deductions, savings could be higher.';

  @override
  String get tax_assumptions => 'Assumptions';

  @override
  String get tax_assumeProjected =>
      'Income projected from current trend to full year';

  @override
  String get tax_assumeNoDeductions =>
      'No 80C, 80D, HRA or other deductions considered';

  @override
  String get tax_assumeNoTds => 'TDS already deducted is not accounted for';

  @override
  String get tax_assumeAllTaxable =>
      'All income categories treated as fully taxable';

  @override
  String get tax_assumeOldNoDeductions =>
      'Old regime estimate excludes section-specific deductions';

  @override
  String get tax_warnInsufficientData =>
      'Very few income transactions recorded';

  @override
  String get tax_warnHighVariance =>
      'Income varies significantly month-to-month';

  @override
  String get tax_warnSingleSource => 'Only one income source detected';

  @override
  String get tax_opportunities => 'Tax Optimization Opportunities';

  @override
  String get tax_oppSaveUpTo => 'Save up to';

  @override
  String get tax_oppRegime => 'Tax Regime';

  @override
  String get tax_oppRegimeDesc =>
      'Compare old vs new regime for potential savings';

  @override
  String get tax_oppNps => 'NPS Contribution';

  @override
  String get tax_oppNpsDesc =>
      'Not evaluated — additional deduction may be available';

  @override
  String get tax_opp80c => 'Section 80C Investments';

  @override
  String get tax_opp80cDesc =>
      'Not evaluated — deductions up to ₹1.5L may apply';

  @override
  String get tax_oppHra => 'HRA Exemption';

  @override
  String get tax_oppHraDesc => 'Not evaluated — potential benefit if renting';

  @override
  String get tax_oppHomeLoan => 'Home Loan Interest';

  @override
  String get tax_oppHomeLoanDesc =>
      'Not evaluated — Section 24 deduction may apply';

  @override
  String get tax_oppMedical => 'Medical Insurance';

  @override
  String get tax_oppMedicalDesc =>
      'Not evaluated — Section 80D deduction may apply';

  @override
  String get tax_editDeductions => 'Edit Deductions';

  @override
  String get tax_deductionProfile => 'Deduction Profile';

  @override
  String get tax_deductionInfo =>
      'Leave fields empty if unknown. Enter 0 if you explicitly have no investment in that category.';

  @override
  String get tax_deductionHintAnnual => 'Annual amount';

  @override
  String get tax_deductionHintMonthly => 'Monthly amount';

  @override
  String get tax_deductionEmployerNps => 'Employer NPS';

  @override
  String get tax_deductionRent => 'Rent Paid (Monthly)';

  @override
  String get category_merge => 'Merge Category';

  @override
  String get category_mergeInto => 'Merge into';

  @override
  String get category_mergeConfirm => 'Merge';

  @override
  String category_mergePreview(int count, String target) {
    return '$count items will be moved to $target';
  }

  @override
  String get category_mergeSuccess => 'Categories merged successfully';

  @override
  String get category_mergeSameError => 'Cannot merge a category into itself';

  @override
  String get category_mergeSelectTarget => 'Select target category';

  @override
  String get category_selectInstruction =>
      'Tap to select • Long press parent to select without subcategories';

  @override
  String get notif_morningInsightTitle => '☀️ Your morning money minute';

  @override
  String get notif_weeklyRecapNudgeTitle => '📊 Your weekly recap is ready';

  @override
  String get notif_yesterdaySpendTitle => '💰 Yesterday\'s spending';

  @override
  String get notif_weeklyRecapReadyTitle => '📊 Your weekly recap is waiting';

  @override
  String notif_underBudgetStreakTitle(int days) {
    return '🔥 $days days under budget!';
  }

  @override
  String get dashboard_bgSyncIssueTitle => 'Background sync may not be working';

  @override
  String get dashboard_bgSyncIssueDesc =>
      'Bills and alerts may be delayed. Try reopening the app.';

  @override
  String get onboard_whatDidYouSpend => 'What did you spend today?';

  @override
  String get onboard_addFewToStart =>
      'Add a few to see your dashboard come alive';

  @override
  String get onboard_skipAddLater => 'Skip — I\'ll add later';

  @override
  String get onboard_starterCoffee => 'Coffee / Tea';

  @override
  String get onboard_starterTransport => 'Transport';

  @override
  String get onboard_starterLunch => 'Lunch / Dinner';

  @override
  String get onboard_starterGroceries => 'Groceries';

  @override
  String onboard_starterAdded(int count) {
    return '$count expenses added!';
  }

  @override
  String get dashboard_listeningTitle => 'Listening for transactions...';

  @override
  String get dashboard_waitingForSms =>
      'Your next bank notification will appear here automatically';

  @override
  String get dashboard_meanwhile => 'Meanwhile, try:';

  @override
  String get dashboard_addExpense => 'Add Expense';

  @override
  String get dashboard_setBudget => 'Set Budget';

  @override
  String get dashboard_createGoal => 'Create Goal';

  @override
  String get dashboard_addAccount => 'Add Account';

  @override
  String get dashboard_testTip =>
      '💡 Tip: Send a small UPI payment to see auto-import in action!';

  @override
  String get dashboard_addFirstExpense => 'Add your first expense';

  @override
  String get dashboard_addFirstExpenseDesc =>
      'Tap to quickly log what you spent today';

  @override
  String dashboard_pctAheadOfLastMonth(String pct) {
    return '$pct% ahead of last month';
  }

  @override
  String dashboard_pctUnderLastMonth(String pct) {
    return '$pct% under last month';
  }

  @override
  String get dashboard_onTrackForPrefix => 'On track for ';

  @override
  String get dashboard_byMonthEnd => ' by month end';

  @override
  String get quickAdd_title => 'Quick Add';

  @override
  String get quickAdd_recentCategories => 'Recent categories';

  @override
  String get quickAdd_moreOptions => 'More options';

  @override
  String get mode_simple => 'Simple';

  @override
  String get mode_full => 'Full';

  @override
  String get mode_simpleDesc => 'Expenses, budgets & SMS tracking';

  @override
  String get mode_fullDesc =>
      'Everything — trips, goals, analytics, gamification';

  @override
  String get mode_switchToFull => 'Switch to Full Mode';

  @override
  String get mode_switchToSimple => 'Switch to Simple Mode';

  @override
  String get mode_pickTitle => 'How do you want to use Mudra?';

  @override
  String get mode_pickDesc => 'You can change this anytime in settings';

  @override
  String get backup_cloudBackup => 'Cloud Backup';

  @override
  String get backup_cloudRestore => 'Restore from Cloud';

  @override
  String get backup_signInGoogle => 'Sign in with Google';

  @override
  String backup_signedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get backup_uploadingToDrive => 'Uploading to Google Drive...';

  @override
  String get backup_uploadSuccess => 'Backup uploaded to Google Drive';

  @override
  String get backup_uploadFailed => 'Failed to upload backup';

  @override
  String get backup_cloudBackups => 'Cloud Backups';

  @override
  String get backup_noCloudBackups => 'No cloud backups found';

  @override
  String get backup_downloading => 'Downloading from Google Drive...';

  @override
  String get backup_signInRequired => 'Sign in to Google to use cloud backup';

  @override
  String get backup_signOut => 'Sign out';

  @override
  String get backup_cloudSubtitle => 'Encrypted backup to Google Drive';

  @override
  String get backup_autoBackup => 'Auto Backup';

  @override
  String get backup_autoBackupDesc =>
      'Automatic local backups, keeps last 7 days';

  @override
  String get backup_autoFrequency => 'Backup frequency';

  @override
  String get backup_autoNever => 'Off';

  @override
  String get backup_autoDaily => 'Daily';

  @override
  String get backup_autoWeekly => 'Weekly';

  @override
  String get backup_autoSetPassword =>
      'Set a backup password to enable auto backup';

  @override
  String backup_autoEnabled(String frequency) {
    return 'Auto backup enabled ($frequency)';
  }

  @override
  String backup_autoLastRun(String date) {
    return 'Last auto backup: $date';
  }

  @override
  String get backup_passwordSet => 'Backup password set';

  @override
  String get backup_proRequired => 'Pro feature';

  @override
  String get onboard_skip => 'Skip';

  @override
  String get onboard_languages => 'Languages';

  @override
  String get onboard_smartTrackingMergedDesc =>
      'Auto-import from bank SMS, set budgets, track goals — all in one place.';

  @override
  String get sms_celebrationTitle => 'Your first SMS transaction! 🎉';

  @override
  String get sms_celebrationBody =>
      'Mudra just auto-imported a transaction from your bank SMS. From now on, your expenses track themselves.';

  @override
  String get sms_celebrationCta => 'Awesome, let\'s go!';

  @override
  String get milestone_shareButton => 'Share to Story';

  @override
  String get milestone_goalReachedTitle => 'Goal Reached!';

  @override
  String milestone_goalReachedDesc(String amount) {
    return 'Saved $amount and hit the target 🌟';
  }

  @override
  String milestone_streakTitle(int days) {
    return '$days-Day Streak!';
  }

  @override
  String milestone_streakDesc(int days) {
    return 'Tracked expenses every day for $days days straight';
  }

  @override
  String get milestone_underBudgetTitle => 'Under Budget!';

  @override
  String get milestone_underBudgetDesc =>
      'Stayed within budget for the entire month 💪';

  @override
  String get account_creditLimit => 'Credit Limit';

  @override
  String get account_statementDay => 'Statement Day';

  @override
  String get account_dueDay => 'Due Day';

  @override
  String account_daysUntilDue(int days) {
    return '$days days until due';
  }

  @override
  String get account_dueToday => 'Due today!';

  @override
  String account_overdue(int days) {
    return 'Overdue by $days days';
  }

  @override
  String get subscription_title => 'Detected Subscriptions';

  @override
  String subscription_monthlyTotal(String amount) {
    return '$amount/month total';
  }

  @override
  String subscription_occurrences(int count) {
    return '$count charges in 4 months';
  }

  @override
  String get subscription_none => 'No recurring subscriptions detected yet';

  @override
  String subscription_dayOfMonth(int day) {
    return 'Around the ${day}th of each month';
  }

  @override
  String get subscription_trackAsRecurring => 'Track as recurring bill';

  @override
  String get cc_title => 'Credit Card Bills';

  @override
  String get cc_totalOutstanding => 'Total Outstanding';

  @override
  String cc_acrossCards(int count) {
    return 'Across $count cards';
  }

  @override
  String get cc_noCards => 'No credit cards added';

  @override
  String get cc_noCardsHint => 'Add a credit card account to track bills here';

  @override
  String get cc_minimumDue => 'Est. Min. Due';

  @override
  String get cc_minimumDueProvenance => 'Estimated from outstanding balance';

  @override
  String get cc_availableCredit => 'Available';

  @override
  String get cc_cycleSpend => 'Spent this cycle';

  @override
  String get cc_utilization => 'Credit Utilization';

  @override
  String get cc_nextStatement => 'Statement';

  @override
  String get cc_nextDue => 'Due';

  @override
  String get cc_payMinimum => 'Pay Minimum';

  @override
  String get cc_payFull => 'Pay Full';

  @override
  String get cc_utilitySubtitle => 'Due dates, outstanding & limits';

  @override
  String get cc_totalMinimumDue => 'Minimum Due This Cycle';

  @override
  String cc_overdueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count overdue',
      one: '1 overdue',
    );
    return '$_temp0';
  }

  @override
  String cc_dueSoonCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count due soon',
      one: '1 due soon',
    );
    return '$_temp0';
  }

  @override
  String cc_highUtilCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count above 80%',
      one: '1 above 80%',
    );
    return '$_temp0';
  }

  @override
  String get cc_allPaymentsCurrent => 'All payments current';

  @override
  String get cc_yourCards => 'Your Cards';

  @override
  String get plugins_remindMeBefore => 'Remind me before';

  @override
  String plugins_daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String plugins_billDueOn(int day, String suffix) {
    return 'Bill due on $day$suffix of every month';
  }

  @override
  String get plugins_addCreditCard => 'Add Credit Card';

  @override
  String get plugins_editCreditCard => 'Edit Credit Card';

  @override
  String get plugins_cardName => 'Card Name';

  @override
  String get plugins_cardNameHint => 'e.g., HDFC Regalia';

  @override
  String get plugins_billDayLabel => 'Bill Day';

  @override
  String get streak_savedTitle => 'Streak Saved!';

  @override
  String streak_savedBody(int days) {
    return 'You kept your $days-day streak alive! 🔥';
  }

  @override
  String get streak_keepGoing => 'Let\'s Keep Going';

  @override
  String briefing_available(String amount) {
    return 'Available: $amount';
  }

  @override
  String briefing_billDueToday(String name, String amount) {
    return '$name ($amount) is due today. Pay it now to avoid a missed payment.';
  }

  @override
  String get briefing_payNow => 'Pay Now';

  @override
  String briefing_budgetExceeded(String name, String amount) {
    return '$name is $amount over budget. Pause non-essential spending in this category.';
  }

  @override
  String get briefing_review => 'Review';

  @override
  String briefing_spendingDrift(String category, String percent) {
    return '$category spending is $percent above your normal pattern. Reduce $category this week.';
  }

  @override
  String get briefing_viewPattern => 'View Pattern';

  @override
  String briefing_billDueSoon(String name, int days) {
    return '$name is due in $days day(s). Make sure you have funds ready.';
  }

  @override
  String get briefing_viewBills => 'View Bills';

  @override
  String briefing_overspending(String amount) {
    return 'You\'ve spent $amount more than you earned this month. Cut discretionary spending to close the gap.';
  }

  @override
  String get briefing_viewBudget => 'View Budget';

  @override
  String briefing_improvement(int percent) {
    return 'You\'re spending $percent% less than this point last month. Keep it up.';
  }

  @override
  String briefing_greetingWithName(String greeting, String name) {
    return '$greeting, $name';
  }

  @override
  String get today_label => 'TODAY';

  @override
  String get today_noActionRequired => 'No action required';

  @override
  String get today_attentionRequired => 'Attention required';

  @override
  String get today_remainingAfterBills => 'Remaining after upcoming bills';

  @override
  String get today_balance => 'Balance';

  @override
  String today_breakdown(String balance, String bills) {
    return '$balance balance · $bills upcoming bills';
  }

  @override
  String today_billContext(String name, int days) {
    return '$name • $days days';
  }

  @override
  String today_billDueToday(String name) {
    return '$name • due today';
  }

  @override
  String get today_addBillPrompt => 'Add recurring bills for accurate capacity';

  @override
  String get health_budgets => 'Budgets';

  @override
  String get health_bills => 'Bills';

  @override
  String get health_goals => 'Goals';

  @override
  String get health_cards => 'Cards';

  @override
  String hero_spendingLess(String percent) {
    return 'You\'re spending $percent% less than last month — that\'s real progress 💪';
  }

  @override
  String hero_weekSaved(String amount) {
    return '$amount saved this week — not bad at all!';
  }

  @override
  String hero_savingsRate(String percent) {
    return '$percent% of your income is staying with you this month 🙌';
  }

  @override
  String hero_goalsAlmostDone(int count) {
    return 'So close! $count goal(s) almost at the finish line 🏁';
  }

  @override
  String get hero_zeroSpend => 'Zero spent today — your wallet thanks you ✨';

  @override
  String hero_todayUnderAvg(String today, String avg) {
    return '$today today — under your $avg daily average 👍';
  }

  @override
  String hero_todayVsAvg(String today, String avg) {
    return '$today today vs $avg daily average';
  }

  @override
  String get hero_offlinePrivacy =>
      'Your data never leaves this device — 100% offline, 100% yours';

  @override
  String get goal_whyOptional => 'Why? (optional)';

  @override
  String get goal_whyHint =>
      'e.g. Bangalore down payment before child starts school';

  @override
  String get goal_currentSavings => 'Current Savings';

  @override
  String get goal_currentExceedsTarget =>
      'Current savings cannot exceed target amount';

  @override
  String get goal_targetBelowSaved =>
      'New target is below current savings. Mark goal as completed instead.';

  @override
  String get goal_typeHouse => 'House';

  @override
  String get goal_typeVehicle => 'Vehicle';

  @override
  String get goal_typeTravel => 'Travel';

  @override
  String get goal_typeEducation => 'Education';

  @override
  String get goal_typeWedding => 'Wedding';

  @override
  String get goal_typeCustom => 'Custom';

  @override
  String get goal_sectionIdentity => 'Goal Identity';

  @override
  String get goal_sectionCurrentState => 'Current State';

  @override
  String get goal_sectionProjection => 'Projection';

  @override
  String get goal_currentTarget => 'Current Target';

  @override
  String get goal_adjustTarget => 'Adjust Target';

  @override
  String get goal_lastContribution => 'Last contribution';

  @override
  String get goal_viewHistory => 'View History →';

  @override
  String get goal_archive => 'Archive Goal';

  @override
  String get goal_archiveConfirmMessage =>
      'Archive this goal? It will be hidden from your active goals list.';

  @override
  String get goal_markComplete => 'Mark Complete';

  @override
  String get goal_markCompleteConfirmMessage =>
      'Mark this goal as fully funded? This sets the saved amount to your target and archives it.';

  @override
  String goal_basedOnAvg(Object amount) {
    return 'Based on $amount/month average';
  }

  @override
  String profile_dayStreakLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '$count day',
    );
    return '$_temp0';
  }

  @override
  String get txnList_spentThisMonth => 'Spent this month';

  @override
  String get tax_plannerTitle => 'Tax Planner';

  @override
  String get tax_startPlanning => 'Start Planning';

  @override
  String get tax_planningMode => 'Planning Mode';

  @override
  String get tax_plannedDeductions => 'Planned Deductions';

  @override
  String get tax_potentialSavings => 'Potential Savings';

  @override
  String get tax_addDeductionsPrompt =>
      'Add deductions below to see potential tax savings';

  @override
  String get tax_plannerDeductions => 'Deduction Planner';

  @override
  String get tax_planningImpact => 'Planning Impact';

  @override
  String get tax_currentTax => 'Current Tax';

  @override
  String get tax_projectedTax => 'Projected Tax';

  @override
  String get tax_totalSavings => 'Total Savings: ';

  @override
  String get tax_nps80CCD1B => 'NPS (80CCD1B)';

  @override
  String get tax_section80C => 'Section 80C';

  @override
  String get tax_section80D => 'Section 80D';

  @override
  String get tax_hraExemption => 'HRA Exemption';

  @override
  String get tax_homeLoanInterest => 'Home Loan Interest';

  @override
  String tax_upTo(int amount) {
    return 'Up to $amount';
  }

  @override
  String tax_remaining(int amount) {
    return '$amount remaining';
  }

  @override
  String get accessibility_doubleTapToSetMax =>
      'Double tap to set maximum value';

  @override
  String currencyFormat(double amount) {
    return '$amount';
  }

  @override
  String get insights_deepDive => 'Deep Dive';

  @override
  String get insights_noDataYet => 'No Data Yet';

  @override
  String get insights_addTransactionsPrompt =>
      'Add transactions to see your analytics';

  @override
  String get insights_viewAllAnalytics => 'View All Analytics';

  @override
  String get insights_yourFinancialCoach => 'Your Financial Coach';

  @override
  String get insights_coachDescription =>
      'Get personalized insights, predictions, and actionable recommendations to improve your financial health.';

  @override
  String get insights_howItWorks => 'How It Works';

  @override
  String get insights_aiSummary => 'AI Summary';

  @override
  String get insights_aiSummaryDesc =>
      'Your personalized financial overview and highlights';

  @override
  String get insights_quickWins => 'Quick Wins';

  @override
  String get insights_quickWinsDesc =>
      'Actionable recommendations to improve your finances';

  @override
  String get insights_predictions => 'Predictions';

  @override
  String get insights_predictionsDesc => 'Cash flow forecast and risk alerts';
}
