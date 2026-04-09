// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get onboard_manageYourMoneyDescription =>
      'पैसों को smart तरीके से manage करें, बिना किसी झंझट के।';

  @override
  String onboard_welcomeToApp(Object appName) {
    return '$appName में आपका स्वागत है';
  }

  @override
  String get onboard_TrackYourTransactions => 'खर्चे track करें';

  @override
  String get onboard_SeeWhereYourMoneyGoes =>
      'पैसा कहाँ जा रहा है, रोज़ देखें।';

  @override
  String get onboard_SetBudgetsAndGoals => 'Budget और Goals सेट करें';

  @override
  String get onboard_stayOnTrackAndAchieveYourDream =>
      'Track पर रहें, सपने पूरे करें।';

  @override
  String get onboard_GetStarted => 'चलो शुरू करें!';

  @override
  String get onboard_letsSetupYourAccount =>
      'चलिए, आपका account set up करते हैं।';

  @override
  String get onboard_howShouldWeCallYou => 'आपको क्या बुलाएं?';

  @override
  String get onboard_enterYourNameToPersonalizeYourExperience =>
      'अपना नाम डालें ताकि app आपके हिसाब से हो।';

  @override
  String get onboard_enterYourName => 'अपना नाम दर्ज करें';

  @override
  String get onboard_setupYourFirstAccount => 'पहला Account बनाएं';

  @override
  String get onboard_letsCreateYourFirstAccount =>
      'चलिए पहला account बनाते हैं (जैसे: Cash)।';

  @override
  String get onboard_accountName => 'खाते का नाम';

  @override
  String get onboard_initialBalance => 'शुरुआती शेष';

  @override
  String get onboard_youCanUpdateOtherDetailsLaterAsWell =>
      'बाकी details बाद में भी update कर सकते हैं।';

  @override
  String onboard_pleaseFillThe(Object inputName) {
    return 'कृपया \"$inputName\" भरें';
  }

  @override
  String onboard_pleaseEnterAValidNumberFor(Object hintText) {
    return 'कृपया \"$hintText\" के लिए एक मान्य संख्या दर्ज करें';
  }

  @override
  String get onboard_youAreAllSet => 'बस, सब तैयार है!';

  @override
  String get onboard_letsStartManagingYourMoneyWisely =>
      'अब पैसों को समझदारी से manage करें।';

  @override
  String get app_settings_appbar_title => 'ऐप सेटिंग्स';

  @override
  String get language_settings_appbar_title => 'भाषा चुनें';

  @override
  String get app_settings_language_title => 'भाषा';

  @override
  String get app_settings_language_subtitle => 'अपनी भाषा चुनें';

  @override
  String get app_settings_theme_mode_title => 'थीम मोड';

  @override
  String get app_settings_theme_mode_light => 'Light';

  @override
  String get app_settings_theme_mode_dark => 'Dark';

  @override
  String get app_settings_theme_mode_system_default => 'सिस्टम डिफ़ॉल्ट';

  @override
  String get app_settings_theme_mode_amoled => 'AMOLED डार्क';

  @override
  String get app_settings_theme_mode_subtitle => 'अपनी पसंदीदा थीम चुनें';

  @override
  String get app_settings_daily_reminder_title => 'Daily खर्च Reminder';

  @override
  String get home_screen_title => 'होम';

  @override
  String get transaction_screen_title => 'गतिविधि';

  @override
  String get statistics_screen_title => 'आँकड़े';

  @override
  String get profile_screen_title => 'प्रोफाइल';

  @override
  String get add_edit_transaction_screen_title => 'लेन-देन जोड़ें';

  @override
  String get transaction_list_screen_title => 'लेनदेन सूची';

  @override
  String get transaction_listViewGroupTodayLabel => 'आज';

  @override
  String get transaction_listViewGroupYesterdayLabel => 'कल';

  @override
  String get greeting_good_morning_text => 'सुप्रभात';

  @override
  String get greeting_good_afternoon_text => 'नमस्ते';

  @override
  String get greeting_good_evening_text => 'शुभ संध्या';

  @override
  String get greeting_good_night_text => 'शुभ रात्रि';

  @override
  String get greeting_hello_text => 'नमस्ते';

  @override
  String get transaction_type_income => 'आय';

  @override
  String get transaction_type_expense => 'खर्च';

  @override
  String get dashboard_add_transaction_text => 'लेन-देन जोड़ें';

  @override
  String get dashboard_add_transfer_text => 'Transfer';

  @override
  String get dashboard_cash_flow_text => 'Cash Flow';

  @override
  String get cash_flow_filter_type_day => 'दिन';

  @override
  String get cash_flow_filter_type_week => 'सप्ताह';

  @override
  String get cash_flow_filter_type_month => 'महीना';

  @override
  String get cash_flow_filter_type_year => 'वर्ष';

  @override
  String get dashboard_mini_budget_text => 'बजट';

  @override
  String get dashboard_mini_budget_not_found_text =>
      'कोई Budget नहीं है, एक बनाएं!';

  @override
  String get dashboard_mini_budget_add_text => 'बजट जोड़ें';

  @override
  String get transaction_list_cash_flow_screen_title => 'लेनदेन';

  @override
  String get transaction_list_filter_all => 'सभी';

  @override
  String get transaction_list_filter_income => 'आय';

  @override
  String get transaction_list_filter_expense => 'व्यय';

  @override
  String get transaction_list_pending_transaction_message_text =>
      '⚡ नए transactions मिले! अभी देखें';

  @override
  String get transaction_listPendingTransactionMessageActionLabel => 'समीक्षा';

  @override
  String get transaction_noTransactionFoundText => 'कोई transaction नहीं मिला।';

  @override
  String get transaction_deleteAlertTitleText => 'लेन-देन हटाएं?';

  @override
  String get transaction_deleteAlertBodyText => 'ये वापस नहीं होगा।';

  @override
  String get transaction_deleteButtonActionText => 'हटाएं';

  @override
  String get transaction_cancelButtonActionText => 'रद्द करें';

  @override
  String get transaction_filterCategoryText => 'लेन-देन फ़िल्टर करें';

  @override
  String transaction_noteDescriptionText(Object description) {
    return 'नोट: $description';
  }

  @override
  String get calendar_week_monday_initial_text => 'सो';

  @override
  String get calendar_week_tuesday_initial_text => 'मं';

  @override
  String get calendar_week_wednesday_initial_text => 'बु';

  @override
  String get calendar_week_thursday_initial_text => 'गु';

  @override
  String get calendar_week_friday_initial_text => 'शु';

  @override
  String get calendar_week_saturday_initial_text => 'श';

  @override
  String get calendar_week_sunday_initial_text => 'र';

  @override
  String get dashboard_netWorthTitle => 'कुल संपत्ति';

  @override
  String get budget_dashboardMiniCardBudgetTitleText => 'बजट';

  @override
  String get budget_dashboardMiniCardSpentTitleText => 'खर्च';

  @override
  String get budget_dashboardPageTitle => 'बजट विवरण';

  @override
  String get budget_dashboardNotFoundText => 'कोई Budget नहीं है, एक बनाएं!';

  @override
  String get budget_dashboardAddBudgetText => 'बजट जोड़ें';

  @override
  String get budget_categoriesTitle => 'श्रेणियाँ';

  @override
  String budget_dashboardPieChartLabelText(
      Object spentPercent, Object title, Object totalPercent) {
    return '$title ($totalPercent कुल का, $spentPercent खर्च का)';
  }

  @override
  String get budget_buttonDeleteTitleText => 'बजट हटाएं?';

  @override
  String get budget_buttonDeleteBodyText =>
      'Budget और उसके allocations हट जाएंगे, ये वापस नहीं होगा।';

  @override
  String get budget_buttonDeleteActionText => 'हटाएं';

  @override
  String get budget_buttonCancelActionText => 'रद्द करें';

  @override
  String get budget_buttonAddText => 'बजट जोड़ें';

  @override
  String get budget_buttonEditText => 'बजट संपादित करें';

  @override
  String get budget_budgetNameControllerText => 'बजट का नाम';

  @override
  String get budget_budgetAmountControllerText => 'कुल राशि';

  @override
  String get budget_recurrenceControllerText => 'पुनरावृत्ति';

  @override
  String get budget_nameRequiredHintText => 'बजट का नाम आवश्यक है';

  @override
  String get budget_amountRequiredHintText => 'वैध राशि आवश्यक है';

  @override
  String get budget_selectStartDateText => 'प्रारंभ तिथि चुनें';

  @override
  String budget_selectedStartDateText(Object startDate) {
    return 'शुरू: $startDate';
  }

  @override
  String get budget_selectEndDateText => 'समाप्ति तिथि चुनें';

  @override
  String budget_selectedEndDateText(Object endDate) {
    return 'समाप्ति: $endDate';
  }

  @override
  String get budget_categoryTitle => 'श्रेणियाँ और आवंटन चुनें';

  @override
  String get budget_allocateAmountText => 'राशि आवंटित करें';

  @override
  String get budget_categoryMessageInfoText =>
      'Category का amount खुद डालें, या खाली छोड़ दें — बाकी बराबर बंट जाएगा।';

  @override
  String budget_totalAllocatedBudgetText(Object totalAlloc) {
    return 'कुल आवंटित: $totalAlloc';
  }

  @override
  String get budget_recurrenceText => 'पुनरावृत्ति';

  @override
  String get budget_recurrenceNoneText => 'कोई नहीं';

  @override
  String get budget_recurrenceDailyText => 'दैनिक';

  @override
  String get budget_recurrenceWeeklyText => 'साप्ताहिक';

  @override
  String get budget_recurrenceMonthlyText => 'मासिक';

  @override
  String get budget_recurrenceYearlyText => 'वार्षिक';

  @override
  String get budget_saveButtonText => 'सहेजें';

  @override
  String get budget_updateButtonText => 'अपडेट करें';

  @override
  String get budget_pickBothDatesErrorText => 'दोनों तिथियाँ चुनें';

  @override
  String get budget_selectAtLeastOneCategoryErrorText =>
      'कम से कम एक श्रेणी चुनें';

  @override
  String get budget_allocatedAmountExceedsTotalBudgetText =>
      'आवंटित राशि कुल बजट से अधिक है';

  @override
  String get transaction_amountControllerText => 'राशि';

  @override
  String get transaction_descriptionControllerText => 'विवरण (वैकल्पिक)';

  @override
  String get transaction_amountControllerErrorText => 'राशि दर्ज करें';

  @override
  String get transaction_selectAccountLabel => 'खाता चुनें';

  @override
  String get transaction_selectCategoryLabel => 'श्रेणी चुनें';

  @override
  String get transaction_selectTagLabel => 'टैग चुनें';

  @override
  String get transaction_addNewCategoryText => 'नई श्रेणी जोड़ें';

  @override
  String get transaction_addNewTagText => 'नया टैग जोड़ें';

  @override
  String get transaction_tagNameControllerText => 'टैग नाम';

  @override
  String get transaction_saveTagButtonLabel => 'टैग सहेजें';

  @override
  String get transaction_saveTransactionButtonLabel => 'लेन-देन सहेजें';

  @override
  String get transaction_selectOneAccountErrorText => 'कम से कम एक खाता चुनें';

  @override
  String get transaction_selectOneCategoryErrorText =>
      'कम से कम एक श्रेणी चुनें';

  @override
  String get transaction_incomeButtonLabel => 'आय';

  @override
  String get transaction_expenseButtonLabel => 'व्यय';

  @override
  String get statistics_weTrimDownDecimalInfoText =>
      'Decimal हटा दिए हैं, ज़रूरत हो तो round off कर लें।';

  @override
  String get statistics_selectPeriodTodayText => 'आज';

  @override
  String get statistics_selectPeriodWeekText => 'सप्ताह';

  @override
  String get statistics_selectPeriodMonthText => 'महीना';

  @override
  String get statistics_selectPeriodYearText => 'वर्ष';

  @override
  String get statistics_chartLineIncomeText => 'आय';

  @override
  String get statistics_chartLineExpenseText => 'व्यय';

  @override
  String statistics_chartLineTodayHourText(Object hour) {
    return '$hourघं';
  }

  @override
  String get statistics_categoryNotPresentText => 'श्रेणी मौजूद नहीं है।';

  @override
  String get statistics_transactionNotPresentText => 'लेन-देन मौजूद नहीं हैं।';

  @override
  String get statistics_byCategoryTitleText => 'श्रेणी के अनुसार';

  @override
  String get statistics_recentTransactionsTitleText => 'हाल के लेनदेन';

  @override
  String get statistics_metricIncomeText => 'आय';

  @override
  String get statistics_metricExpenseText => 'व्यय';

  @override
  String get statistics_metricNetText => 'शुद्ध';

  @override
  String get statistics_showAllButtonText => 'सभी दिखाएँ';

  @override
  String get statistics_exportToPdfButtonText => 'पीडीएफ में निर्यात करें';

  @override
  String get statistics_exportToExcelButtonText => 'एक्सेल में निर्यात करें';

  @override
  String get profile_userProfileTitleText => 'उपयोगकर्ता प्रोफ़ाइल';

  @override
  String get profile_userProfileSubtitleText =>
      'प्रोफ़ाइल छवि, नाम और ईमेल बदलें';

  @override
  String get profile_nameControllerText => 'नाम';

  @override
  String get profile_nameControllerHintText => 'अपना नाम दर्ज करें';

  @override
  String get profile_nameRequiredHintText => 'नाम आवश्यक है';

  @override
  String get profile_emailControllerText => 'ईमेल';

  @override
  String get profile_emailControllerHintText => 'अपना ईमेल दर्ज करें';

  @override
  String get profile_phoneControllerText => 'फ़ोन';

  @override
  String get profile_phoneControllerHintText => 'अपना फ़ोन नंबर दर्ज करें';

  @override
  String get profile_weAreNotStoringInfoText =>
      'आपका सारा data इसी phone में है। कोई server नहीं, कोई cloud नहीं, कोई tracking नहीं।';

  @override
  String get profile_saveButtonText => 'सहेजें';

  @override
  String get profile_editUserProfileAppTitle =>
      'उपयोगकर्ता प्रोफ़ाइल संपादित करें';

  @override
  String get pendingTranx_reviewPendingTransactionsScreenTitle =>
      'लंबित लेन-देन';

  @override
  String get statistics_quickOverviewTitle => 'त्वरित अवलोकन';

  @override
  String get statistics_insightsTitle => 'अंतर्दृष्टि';

  @override
  String get statistics_detailedAnalysisTitle => 'विस्तृत विश्लेषण';

  @override
  String get statistics_categoryBreakdownSubtitle => 'श्रेणी विभाजन देखें';

  @override
  String get statistics_expenseTrendsTitle => 'व्यय रुझान';

  @override
  String get statistics_expenseTrendsSubtitle => 'पिछले 12 महीनों के रुझान';

  @override
  String get statistics_recentTransactionsSubtitle => 'पिछले 5 लेनदेन';

  @override
  String get statistics_categoryBreakdownTitle => 'श्रेणी विभाजन';

  @override
  String get statistics_recentTransactionsModalTitle => 'हाल के लेनदेन';

  @override
  String get transfer_screenTitle => 'पैसे Transfer करें';

  @override
  String get transfer_resetTooltip => 'रीसेट';

  @override
  String get transfer_selectAccountsLabel => 'ACCOUNTS चुनें';

  @override
  String get transfer_fromLabel => 'से';

  @override
  String get transfer_toLabel => 'को';

  @override
  String get transfer_detailsLabel => 'TRANSFER विवरण';

  @override
  String get transfer_amountLabel => 'राशि';

  @override
  String get transfer_amountValidationError => 'वैध राशि दर्ज करें';

  @override
  String get transfer_dateLabel => 'तारीख';

  @override
  String get transfer_noteLabel => 'नोट (वैकल्पिक)';

  @override
  String get transfer_buttonLabel => 'Transfer करें';

  @override
  String get transfer_updateButtonLabel => 'Transfer अपडेट करें';

  @override
  String get transfer_errorLoadingAccounts => 'Accounts load नहीं हो पाए';

  @override
  String get app_settings_themeModeModalTitle => 'थीम मोड';

  @override
  String get category_expenseLabel => 'व्यय';

  @override
  String get category_incomeLabel => 'आय';

  @override
  String get category_addTitle => 'श्रेणी जोड़ें';

  @override
  String get category_editTitle => 'श्रेणी संपादित करें';

  @override
  String get category_tapToChangeIcon => 'आइकॉन बदलने के लिए टैप करें';

  @override
  String get category_nameLabel => 'श्रेणी का नाम';

  @override
  String get category_nameRequired => 'आवश्यक';

  @override
  String get category_typeLabel => 'श्रेणी प्रकार';

  @override
  String get category_colorLabel => 'रंग';

  @override
  String get category_tapToChangeColor => 'रंग बदलने के लिए टैप करें';

  @override
  String get category_saveButton => 'श्रेणी सहेजें';

  @override
  String get category_updateButton => 'श्रेणी अपडेट करें';

  @override
  String get dashboard_incomeLabel => 'आय';

  @override
  String get dashboard_spentLabel => 'खर्च';

  @override
  String get dashboard_noDataLabel => 'कोई डेटा नहीं';

  @override
  String get dashboard_editLabel => 'संपादित करें';

  @override
  String get dashboard_archiveLabel => 'आर्काइव';

  @override
  String get currency_crore_short => 'क';

  @override
  String get currency_lakh_short => 'ला';

  @override
  String get currency_thousand_short => 'ह';

  @override
  String common_errorText(Object error) {
    return 'त्रुटि: $error';
  }

  @override
  String get statistics_expenseShort => 'व्यय';

  @override
  String get statistics_incomeShort => 'आय';

  @override
  String get transaction_categoryFilter => 'श्रेणी फ़िल्टर';

  @override
  String get transaction_dateFilter => 'दिनांक फ़िल्टर';

  @override
  String get transaction_allCategories => 'सभी श्रेणियाँ';

  @override
  String get transaction_applyFilters => 'फ़िल्टर लागू करें';

  @override
  String get sms_selectTransactions => 'लेनदेन चुनें';

  @override
  String get common_addLabel => 'जोड़ें';

  @override
  String get dashboard_removeLabel => 'हटाएं';

  @override
  String get dashboard_viewAllLabel => 'सभी देखें';

  @override
  String get common_noAccountsYet => 'अभी तक कोई खाता नहीं';

  @override
  String get common_loading => 'लोड हो रहा है...';

  @override
  String get common_editLabel => 'संपादित करें';

  @override
  String get common_deleteLabel => 'हटाएं';

  @override
  String get common_fromLabel => 'से';

  @override
  String get common_toLabel => 'को';

  @override
  String get theme_chooseThemeTitle => 'थीम चुनें';

  @override
  String get theme_applyThemeLabel => 'थीम लागू करें';

  @override
  String get theme_themeAppliedMessage => 'थीम लागू की गई!';

  @override
  String get backup_backupRestoreTitle => 'बैकअप और रिस्टोर';

  @override
  String get backup_backupDataTitle => 'डेटा बैकअप करें';

  @override
  String get backup_backupDataSubtitle =>
      'सभी डेटाबेस और सेटिंग्स निर्यात करें';

  @override
  String get backup_restoreBackupTitle => 'बैकअप रिस्टोर करें';

  @override
  String get backup_restoreBackupSubtitle => 'डेटाबेस और सेटिंग्स आयात करें';

  @override
  String get backup_includeAttachmentsTitle => 'अटैचमेंट शामिल करें?';

  @override
  String get backup_includeAttachmentsMessage =>
      'बैकअप में रसीद की छवियां शामिल करें? इससे फ़ाइल का आकार बढ़ेगा।';

  @override
  String get backup_yesLabel => 'हाँ';

  @override
  String get backup_noLabel => 'नहीं';

  @override
  String get backup_completedMessage => 'बैकअप पूरा हुआ';

  @override
  String get backup_restoreSuccessMessage => 'रिस्टोर सफल';

  @override
  String backup_lastBackupLabel(Object date) {
    return 'अंतिम बैकअप: $date';
  }

  @override
  String get backup_noBackupFoundLabel => 'कोई बैकअप नहीं मिला';

  @override
  String get categories_manageCategoriesTitle => 'श्रेणियाँ प्रबंधित करें';

  @override
  String get categories_noCategoriesFound => 'कोई श्रेणी नहीं मिली।';

  @override
  String categories_transactionCount(Object count, Object plural) {
    return '$count लेनदेन$plural';
  }

  @override
  String get categories_addCategoryLabel => 'श्रेणी जोड़ें';

  @override
  String get categories_deleteCategoryTitle => 'श्रेणी हटाएं';

  @override
  String get categories_deleteCategoryMessage =>
      'क्या आप वाकई इस श्रेणी को हटाना चाहते हैं?\nसभी संबंधित लेनदेन भी हटा दिए जाएंगे।';

  @override
  String get categories_categoryDeletedMessage =>
      'श्रेणी और उसके लेनदेन हटा दिए गए';

  @override
  String get accounts_manageAccountsTitle => 'खाते प्रबंधित करें';

  @override
  String get accounts_noAccountsAddedYet => 'अभी तक कोई खाता नहीं जोड़ा गया';

  @override
  String get accounts_addAccountLabel => 'खाता जोड़ें';

  @override
  String get accounts_deleteAccountTitle => 'खाता हटाएं';

  @override
  String accounts_deleteAccountMessage(Object accountName) {
    return 'क्या आप वाकई \"$accountName\" को हटाना चाहते हैं?';
  }

  @override
  String get accounts_archiveAccountTitle => 'खाता आर्काइव करें';

  @override
  String accounts_archiveAccountMessage(Object accountName) {
    return 'क्या आप वाकई \"$accountName\" को आर्काइव करना चाहते हैं?';
  }

  @override
  String get accounts_cancelLabel => 'रद्द करें';

  @override
  String get accounts_archiveLabel => 'आर्काइव';

  @override
  String accounts_accountArchivedMessage(Object accountName) {
    return '\"$accountName\" आर्काइव किया गया';
  }

  @override
  String get accounts_atLeastOneAccountRequired =>
      'जारी रखने के लिए कम से कम 1 खाता आवश्यक है';

  @override
  String get transaction_tripLabel => 'यात्रा';

  @override
  String get transaction_tripPartOfMessage =>
      'यह लेनदेन निम्नलिखित यात्रा(ओं) का हिस्सा है';

  @override
  String get sms_autoAddTooltip => 'स्वतः जोड़ें';

  @override
  String get sms_clearAllTooltip => 'सभी साफ़ करें';

  @override
  String get sms_importedFromSmsDescription => 'SMS से आयात किया गया';

  @override
  String get sms_selectAtLeastOneMessage => 'कृपया कम से कम एक SMS चुनें';

  @override
  String get dashboard_allTimeLabel => 'सभी समय';

  @override
  String get transaction_editTransactionTitle => 'लेन-देन संपादित करें';

  @override
  String get transaction_dateLabel => 'तारीख';

  @override
  String get transaction_addNoteHint => 'एक नोट जोड़ें';

  @override
  String get transaction_enterValidAmountError =>
      'कृपया एक वैध राशि दर्ज करें।';

  @override
  String get sms_noPendingTransactions => 'कोई लंबित लेनदेन नहीं';

  @override
  String get sms_approveLabel => 'अनुमोदन';

  @override
  String get sms_approveTransactionTitle => 'लेनदेन अनुमोदित करें';

  @override
  String get onboard_SmartSmsTracking => 'Smart SMS Tracking';

  @override
  String get onboard_SmartSmsTrackingDesc =>
      'Bank SMS से transactions अपने आप detect और import होंगे।';

  @override
  String get onboard_InsightsAndAnalytics => 'Insights और Analytics';

  @override
  String get onboard_InsightsAndAnalyticsDesc =>
      'Charts, trends और smart insights से अपनी spending habits समझें।';

  @override
  String get onboard_SecureAndPrivate => 'Safe और Private';

  @override
  String get onboard_SecureAndPrivateDesc =>
      'Data आपके phone में ही रहता है। कोई cloud नहीं, कोई tracking नहीं।';

  @override
  String get onboard_SmartAutoTracking => 'Smart Auto Tracking';

  @override
  String get onboard_SmartAutoTrackingDesc =>
      'Bank notifications से transactions अपने आप detect और import होंगे।';

  @override
  String get nav_activity => 'गतिविधि';

  @override
  String get nav_manage => 'प्रबंधन';

  @override
  String get nav_insights => 'विश्लेषण';

  @override
  String get common_save => 'सहेजें';

  @override
  String get common_cancel => 'रद्द करें';

  @override
  String get common_next => 'आगे';

  @override
  String get common_back => 'पीछे';

  @override
  String get common_undo => 'वापस करें';

  @override
  String get common_delete => 'हटाएं';

  @override
  String get common_edit => 'संपादित करें';

  @override
  String get common_add => 'जोड़ें';

  @override
  String get common_done => 'हो गया';

  @override
  String get common_close => 'बंद करें';

  @override
  String get common_confirm => 'पुष्टि करें';

  @override
  String get common_archive => 'संग्रह करें';

  @override
  String get common_create => 'बनाएं';

  @override
  String get common_update => 'अपडेट करें';

  @override
  String get common_remove => 'निकालें';

  @override
  String get common_search => 'खोजें';

  @override
  String get common_filter => 'फ़िल्टर';

  @override
  String get common_reset => 'रीसेट';

  @override
  String get common_apply => 'लागू करें';

  @override
  String get common_yes => 'हाँ';

  @override
  String get common_no => 'नहीं';

  @override
  String get common_ok => 'ठीक है';

  @override
  String get common_retry => 'पुनः प्रयास';

  @override
  String get common_noData => 'कोई डेटा नहीं';

  @override
  String get common_error => 'कुछ गड़बड़ हो गई';

  @override
  String get common_required => 'आवश्यक';

  @override
  String get title_budgets => 'बजट';

  @override
  String get title_goals => 'Goals';

  @override
  String get title_bills => 'बिल';

  @override
  String get title_groups => 'समूह';

  @override
  String get title_trips => 'यात्राएं';

  @override
  String get title_shared => 'साझा';

  @override
  String get title_achievements => 'उपलब्धियां';

  @override
  String get title_notifications => 'सूचनाएं';

  @override
  String get title_appearance => 'दिखावट';

  @override
  String get title_currency => 'मुद्रा';

  @override
  String get title_security => 'सुरक्षा';

  @override
  String get title_about => 'जानकारी';

  @override
  String get title_analytics => 'विश्लेषण';

  @override
  String get title_netWorth => 'कुल संपत्ति';

  @override
  String get title_financialHealth => 'वित्तीय स्वास्थ्य';

  @override
  String get title_spendingPersonality => 'खर्च की शैली';

  @override
  String get title_monthlyRecap => 'मासिक सारांश';

  @override
  String get title_compareMonths => 'महीनों की तुलना';

  @override
  String get title_smsImport => 'SMS आयात';

  @override
  String get title_backupShare => 'बैकअप और शेयर';

  @override
  String get title_exchangeRates => 'विनिमय दरें';

  @override
  String get title_recurringTransactions => 'आवर्ती लेनदेन';

  @override
  String get title_billControlCenter => 'बिल नियंत्रण केंद्र';

  @override
  String get title_plugins => 'प्लगइन';

  @override
  String get title_editCategory => 'श्रेणी संपादित करें';

  @override
  String get title_allCategories => 'सभी श्रेणियां';

  @override
  String get title_exportOptions => 'निर्यात विकल्प';

  @override
  String get title_dashboardLayout => 'डैशबोर्ड लेआउट';

  @override
  String get section_activeMoney => 'सक्रिय धन';

  @override
  String get section_planning => 'योजना';

  @override
  String get section_insights => 'अंतर्दृष्टि';

  @override
  String get section_coreSettings => 'मुख्य सेटिंग्स';

  @override
  String get section_appData => 'ऐप और डेटा';

  @override
  String get section_appearance => 'दिखावट';

  @override
  String get section_advanced => 'उन्नत';

  @override
  String get section_supportLegal => 'सहायता और कानूनी';

  @override
  String get section_active => 'सक्रिय';

  @override
  String get section_ongoing => 'चालू';

  @override
  String get section_archive => 'संग्रह';

  @override
  String get label_income => 'आय';

  @override
  String get label_expense => 'खर्च';

  @override
  String get label_balance => 'शेष';

  @override
  String get label_savings => 'बचत';

  @override
  String get label_total => 'कुल';

  @override
  String get label_amount => 'राशि';

  @override
  String get label_date => 'तारीख';

  @override
  String get label_category => 'श्रेणी';

  @override
  String get label_account => 'खाता';

  @override
  String get label_description => 'विवरण';

  @override
  String get label_type => 'प्रकार';

  @override
  String get label_transfer => 'ट्रांसफर';

  @override
  String get label_from => 'से';

  @override
  String get label_to => 'को';

  @override
  String get label_all => 'सभी';

  @override
  String get label_today => 'आज';

  @override
  String get label_yesterday => 'कल';

  @override
  String get label_thisWeek => 'इस सप्ताह';

  @override
  String get label_thisMonth => 'इस महीने';

  @override
  String get label_thisYear => 'इस साल';

  @override
  String get label_custom => 'कस्टम';

  @override
  String get label_daily => 'दैनिक';

  @override
  String get label_weekly => 'साप्ताहिक';

  @override
  String get label_monthly => 'मासिक';

  @override
  String get label_yearly => 'वार्षिक';

  @override
  String get label_none => 'कोई नहीं';

  @override
  String get trip_expenses => 'खर्चे';

  @override
  String get trip_settlements => 'निपटान';

  @override
  String get trip_balances => 'शेष राशि';

  @override
  String get trip_report => 'रिपोर्ट';

  @override
  String get trip_createTrip => 'यात्रा बनाएं';

  @override
  String get trip_createGroup => 'साझा समूह बनाएं';

  @override
  String get trip_editTrip => 'यात्रा संपादित करें';

  @override
  String get trip_editGroup => 'समूह संपादित करें';

  @override
  String get trip_archiveTrip => 'यात्रा संग्रह करें';

  @override
  String get trip_archiveGroup => 'समूह संग्रह करें';

  @override
  String get trip_allSettled => 'सब निपट गया!';

  @override
  String get trip_archiveToSettle => 'निपटान के लिए संग्रह करें';

  @override
  String get trip_trackTravel =>
      'Travel खर्चे dates और budget के साथ track करें';

  @override
  String get trip_splitBills => 'दोस्तों के साथ bill split करें';

  @override
  String get trip_live => 'लाइव';

  @override
  String get budget_spendingLimits => 'खर्च सीमा';

  @override
  String get budget_savingsProgress => 'बचत प्रगति';

  @override
  String get budget_upcomingRecurring => 'आगामी और आवर्ती';

  @override
  String get budget_tripsAndSplits => 'Trips और splits';

  @override
  String import_importing(int count) {
    return '$count लेनदेन आयात हो रहे हैं...';
  }

  @override
  String get import_dontClose => 'App बंद मत करें';

  @override
  String get import_complete => 'Import हो गया!';

  @override
  String get import_failed => 'Import नहीं हो पाया';

  @override
  String get import_imported => 'आयातित';

  @override
  String get import_duplicatesSkipped => 'डुप्लिकेट छोड़े गए';

  @override
  String get import_errorsSkipped => 'त्रुटियां/छोड़े गए';

  @override
  String get import_categoriesCreated => 'श्रेणियां बनाई गईं';

  @override
  String get import_previewImport => 'आयात पूर्वावलोकन';

  @override
  String get recap_yourMonthAtGlance => 'इस महीने का हाल';

  @override
  String get recap_trackProgressOverTime => 'Progress track करें';

  @override
  String recap_transactions(int count) {
    return '$count लेनदेन';
  }

  @override
  String get recap_downloadPdf => 'PDF डाउनलोड करें';

  @override
  String get comparison_current => 'वर्तमान';

  @override
  String comparison_byDay(int day) {
    return 'दिन $day तक';
  }

  @override
  String get comparison_topCategories => 'शीर्ष श्रेणियां';

  @override
  String get comparison_categoryImpact => 'श्रेणी प्रभाव';

  @override
  String get comparison_dailySpendingPace => 'Daily खर्च की रफ्तार';

  @override
  String comparison_projected(String amount) {
    return 'अनुमान: इस महीने $amount खर्च होंगे';
  }

  @override
  String get utility_customizeUtilities => 'उपयोगिताएं अनुकूलित करें';

  @override
  String get utility_addUtilities => 'उपयोगिताएं जोड़ें';

  @override
  String get profile_accounts => 'खाते';

  @override
  String get profile_manageAccounts => 'अपने खाते प्रबंधित करें';

  @override
  String get profile_categories => 'श्रेणियां';

  @override
  String get profile_manageCategories => 'अपनी श्रेणियां प्रबंधित करें';

  @override
  String get profile_language => 'भाषा';

  @override
  String get profile_notifications => 'सूचनाएं';

  @override
  String get profile_dailyWeeklySummaries => 'दैनिक और साप्ताहिक सारांश';

  @override
  String get profile_autoImport => 'ऑटो आयात';

  @override
  String get profile_autoImportDesc => 'Bank notifications से auto import';

  @override
  String get profile_importExport => 'आयात और निर्यात';

  @override
  String get profile_importExportDesc => 'Excel import और export';

  @override
  String get profile_backupRestore => 'बैकअप और पुनर्स्थापना';

  @override
  String get profile_manageData => 'अपना डेटा प्रबंधित करें';

  @override
  String get profile_themeDisplay => 'Theme, tone और display';

  @override
  String get profile_customizeWidgets => 'Widgets और cards customize करें';

  @override
  String get profile_manageExtensions => 'एक्सटेंशन प्रबंधित करें';

  @override
  String get profile_helpSupport => 'सहायता और समर्थन';

  @override
  String get profile_faqs => 'FAQs और feature guides';

  @override
  String get profile_aboutApp => 'ऐप के बारे में';

  @override
  String get profile_versionInfo => 'संस्करण और जानकारी';

  @override
  String get profile_pinFingerprint => 'PIN या फिंगरप्रिंट';

  @override
  String get profile_upgradePro => 'Pro में अपग्रेड करें';

  @override
  String get profile_unlimitedFeatures =>
      'Unlimited accounts, analytics और बहुत कुछ';

  @override
  String get profile_freeTier => 'मुफ्त योजना';

  @override
  String get profile_fullAccess => 'पूर्ण पहुँच';

  @override
  String get profile_proActive => 'Pro सक्रिय';

  @override
  String get profile_yourAchievements => 'आपकी उपलब्धियां';

  @override
  String get profile_bestStreak => 'सर्वश्रेष्ठ स्ट्रीक';

  @override
  String get trips_active => 'सक्रिय';

  @override
  String get trips_live => 'लाइव';

  @override
  String get trips_allSettled => 'सब निपट गया';

  @override
  String get tone_friendly_txnAdded =>
      'Done! Transaction save हो गया ✨|बन गया! सब note हो गया 👍|Save हो गया! आप track पर हैं ✨|Note हो गया! एक और track 📝';

  @override
  String get tone_friendly_txnUpdated =>
      'Update हो गया! 👍|Changes save हो गए! ✓|सब update! 👌';

  @override
  String get tone_friendly_txnDeleted =>
      'हट गया! Transaction remove 🗑️|Delete हो गया! एक कम|Remove! साफ़ 🗑️';

  @override
  String get tone_friendly_txnFailed => 'Save नहीं हो पाया, फिर try करें?';

  @override
  String get tone_friendly_enterAmount => 'कितना था? Amount डालें';

  @override
  String get tone_friendly_pickAccount => 'कौन सा account? एक चुनें';

  @override
  String get tone_friendly_pickCategory => 'किसके लिए था? Category चुनें';

  @override
  String get tone_friendly_fillAllFields => 'बस थोड़ा बाकी — सब fields भरें';

  @override
  String get tone_friendly_invalidAmount =>
      'ये सही नहीं लग रहा — सही amount डालें';

  @override
  String get tone_friendly_budgetCreated =>
      'Budget set! Track पर रहें 💪|Budget lock! Planning अच्छी है 💪|बढ़िया! Budget ready 📊';

  @override
  String get tone_friendly_budgetUpdated => 'Budget update हो गया!';

  @override
  String get tone_friendly_budgetDeleted => 'Budget हटा दिया';

  @override
  String get tone_friendly_goalCreated =>
      'Goal set! आप कर सकते हैं 🎯|नया goal! चलो पूरा करें 🎯|Goal lock! नज़र रखें 🎯';

  @override
  String get tone_friendly_goalUpdated => 'Goal update हो गया!';

  @override
  String get tone_friendly_goalDeleted => 'Goal हटा दिया';

  @override
  String get tone_friendly_accountCreated => 'Account बन गया! 🏦';

  @override
  String get tone_friendly_billAdded => 'Bill track हो रहा! Remind करेंगे 🔔';

  @override
  String get tone_friendly_billPaid =>
      'बढ़िया, bill paid! ✅|Bill done! एक tension कम ✅|Paid! राहत ✅';

  @override
  String get tone_friendly_backupSuccess => 'Backup हो गया! Data safe है 🛡️';

  @override
  String get tone_friendly_restoreSuccess => 'Restore हो गया! Welcome back 🎉';

  @override
  String get tone_friendly_noTransactions =>
      'अभी कुछ नहीं है\nपहला transaction डालकर शुरू करें|अभी खाली है\nTracking शुरू करें — बस एक sec|कोई transaction नहीं\nआपकी financial journey यहीं से शुरू';

  @override
  String get tone_friendly_noBudgets =>
      'कोई budget नहीं\nएक बनाएं, spending track होगी';

  @override
  String get tone_friendly_noGoals =>
      'कोई goal नहीं\nबड़ा सोचें — पहला goal set करें!';

  @override
  String get tone_friendly_genericError => 'कुछ गड़बड़ हो गई। फिर try करें?';

  @override
  String get tone_friendly_smsImportEnabled =>
      'Auto import on! Transactions track होंगे 📩';

  @override
  String get tone_friendly_dashboardAllCaughtUp =>
      'सब up to date! 🎉|कुछ pending नहीं — मज़े करें! ✨|सब ठीक है! दिन enjoy करें 🎉';

  @override
  String get tone_friendly_dailySummaryEmpty =>
      'कल कुछ record नहीं हुआ — zero-spend win या catch up का time!|कल शांत दिन था — wallet खुश!|कल कोई transaction नहीं — आज fresh start!';

  @override
  String tone_friendly_streakMessage(int days) {
    return '$days दिन की streak! जारी रखें! 🔥';
  }

  @override
  String tone_friendly_budgetExceededBy(String amount) {
    return 'Budget $amount से ज़्यादा हो गया 😬';
  }

  @override
  String get tone_professional_txnAdded =>
      'Transaction record हो गया।|Entry save हो गई।|Transaction log हो गया।';

  @override
  String get tone_professional_txnUpdated =>
      'Transaction update हो गया।|Changes apply हो गए।|Record update हो गया।';

  @override
  String get tone_professional_txnDeleted =>
      'Transaction delete हो गया।|Record remove हो गया।|Entry delete हो गई।';

  @override
  String get tone_professional_txnFailed =>
      'Transaction save नहीं हो पाया। फिर try करें।';

  @override
  String get tone_professional_enterAmount => 'सही amount डालें।';

  @override
  String get tone_professional_pickAccount => 'Account select करें।';

  @override
  String get tone_professional_pickCategory => 'Category select करें।';

  @override
  String get tone_professional_fillAllFields => 'सभी ज़रूरी fields भरें।';

  @override
  String get tone_professional_invalidAmount => 'गलत amount डाला गया।';

  @override
  String get tone_professional_budgetCreated =>
      'Budget बन गया।|Budget configure हो गया।|नया budget active है।';

  @override
  String get tone_professional_budgetUpdated => 'Budget update हो गया।';

  @override
  String get tone_professional_budgetDeleted => 'Budget delete हो गया।';

  @override
  String get tone_professional_goalCreated =>
      'Goal बन गया।|Savings goal configure हो गया।|नया goal active है।';

  @override
  String get tone_professional_goalUpdated => 'Goal update हो गया।';

  @override
  String get tone_professional_goalDeleted => 'Goal delete हो गया।';

  @override
  String get tone_professional_accountCreated => 'Account बन गया।';

  @override
  String get tone_professional_billAdded =>
      'Bill add हो गया। Remind किया जाएगा।';

  @override
  String get tone_professional_billPaid =>
      'Bill paid mark हो गया।|Payment record हो गया।|Bill settle हो गया।';

  @override
  String get tone_professional_backupSuccess => 'Backup पूरा हो गया।';

  @override
  String get tone_professional_restoreSuccess => 'Data restore हो गया।';

  @override
  String get tone_professional_noTransactions =>
      'कोई transaction record नहीं।\nपहली entry डालें।|कोई record नहीं।\nTransaction डालकर शुरू करें।|Transaction history खाली है।\nRecording शुरू करें।';

  @override
  String get tone_professional_noBudgets => 'कोई budget configure नहीं।';

  @override
  String get tone_professional_noGoals => 'कोई goal set नहीं।';

  @override
  String get tone_professional_genericError => 'Error आ गई।';

  @override
  String get tone_professional_smsImportEnabled => 'Auto-import on हो गया।';

  @override
  String get tone_professional_dashboardAllCaughtUp =>
      'सब up to date है।|कोई pending action नहीं।|सब current है।';

  @override
  String get tone_professional_dailySummaryEmpty =>
      'कल कोई transaction record नहीं।|कल कोई activity नहीं।|पिछले दिन कोई entry नहीं।';

  @override
  String tone_professional_streakMessage(int days) {
    return 'लगातार $days दिन tracking।';
  }

  @override
  String tone_professional_budgetExceededBy(String amount) {
    return 'Budget $amount से exceed हो गया।';
  }

  @override
  String get tone_motivational_txnAdded =>
      'बढ़िया! Transaction save हो गया! 💪|Log हो गया! आप रुक नहीं रहे 💪|एक और track! Momentum बनाए रखें! ✨|Save! हर entry एक कदम आगे! 🚀';

  @override
  String get tone_motivational_txnUpdated =>
      'अच्छा update! Sharp बने रहें! ✨|Update! Precision matters! ✨|Changes save! आप इस पर हैं! 👍';

  @override
  String get tone_motivational_txnDeleted =>
      'साफ़! एक कम tension|Remove! चीज़ें clean रखें! 💪|गया! जो ज़रूरी है उस पर focus';

  @override
  String get tone_motivational_txnFailed => 'नहीं हो पाया — एक और try दें!';

  @override
  String get tone_motivational_enterAmount =>
      'हर रुपया count होता है — amount डालें!';

  @override
  String get tone_motivational_pickAccount => 'Account चुनें, organized रहें!';

  @override
  String get tone_motivational_pickCategory =>
      'Category दें — बाद में खुद को thank करेंगे!';

  @override
  String get tone_motivational_fillAllFields => 'बस थोड़ा बाकी! सब भरें';

  @override
  String get tone_motivational_invalidAmount =>
      'ये amount सही नहीं लग रहा — फिर try!';

  @override
  String get tone_motivational_budgetCreated =>
      'Smart move! Budget set! 💪|Budget lock! Control आपके हाथ में! 💪|Discipline! Budget ready! 📊';

  @override
  String get tone_motivational_budgetUpdated =>
      'Budget adjust — flexible बने रहें!';

  @override
  String get tone_motivational_budgetDeleted => 'Budget हटा दिया';

  @override
  String get tone_motivational_goalCreated =>
      'Ambition! Goal set! 🎯|बड़े सपने यहीं से! Goal lock! 🎯|ये spirit! नया goal ready! 🚀';

  @override
  String get tone_motivational_goalUpdated => 'Goal refine — push करते रहें!';

  @override
  String get tone_motivational_goalDeleted =>
      'Goal हटा — नई priorities, नई plans';

  @override
  String get tone_motivational_accountCreated =>
      'Account बन गया! Organized हो रहे हैं! 🏦';

  @override
  String get tone_motivational_billAdded => 'Bill track! आप आगे हैं! 🔔';

  @override
  String get tone_motivational_billPaid =>
      'Bill paid! एक tension कम! ✅|Crush कर दिया! Bill done! ✅|Paid! Game से आगे! 💪';

  @override
  String get tone_motivational_backupSuccess =>
      'Backup हो गया! Progress safe! 🛡️';

  @override
  String get tone_motivational_restoreSuccess => 'Restore! वापस track पर! 🎉';

  @override
  String get tone_motivational_noTransactions =>
      'Fresh start! 🌟\nपहला transaction डालें — हर journey एक कदम से शुरू|खाली slate! 🌟\nपहली entry wait कर रही — चलो!|अभी कुछ नहीं! 💪\nएक transaction और आप रास्ते पर!';

  @override
  String get tone_motivational_noBudgets =>
      'कोई budget नहीं\nएक बनाएं — future self thank करेगा! 💪';

  @override
  String get tone_motivational_noGoals =>
      'कोई goal नहीं\nबड़ा सोचें — पहला goal set करें! 🎯';

  @override
  String get tone_motivational_genericError => 'कुछ गड़बड़ हो गई — फिर try!';

  @override
  String get tone_motivational_smsImportEnabled =>
      'Auto-import on! Finances खुद track होंगे! 📩';

  @override
  String get tone_motivational_dashboardAllCaughtUp =>
      'सब caught up — game से आगे! 🏆|कुछ pending नहीं — top पर हैं 💪|All clear! ये energy बनाए रखें 🏆';

  @override
  String get tone_motivational_dailySummaryEmpty =>
      'कल zero spend — wallet खुश! ✨|कल कुछ खर्च नहीं — willpower! 💪|No-spend day! ये win है! 🏆';

  @override
  String tone_motivational_streakMessage(int days) {
    return '$days दिन की streak! रुकने वाले नहीं! 🔥';
  }

  @override
  String tone_motivational_budgetExceededBy(String amount) {
    return '$amount ज़्यादा — course correct कर सकते हैं! 💪';
  }

  @override
  String get tone_calm_txnAdded => 'Note हो गया।|Record हो गया।|चुपचाप save।';

  @override
  String get tone_calm_txnUpdated => 'Update।|Adjust।|Changes save।';

  @override
  String get tone_calm_txnDeleted => 'छोड़ दिया।|हटा दिया।|जाने दिया।';

  @override
  String get tone_calm_txnFailed => 'नहीं हो पाया। एक बार और।';

  @override
  String get tone_calm_enterAmount => 'Amount चाहिए।';

  @override
  String get tone_calm_pickAccount => 'ये कहाँ belongs है, चुनें।';

  @override
  String get tone_calm_pickCategory => 'इसे एक purpose दें।';

  @override
  String get tone_calm_fillAllFields => 'कुछ चीज़ें अभी खाली हैं।';

  @override
  String get tone_calm_invalidAmount => 'Amount ठीक करना होगा।';

  @override
  String get tone_calm_budgetCreated => 'सीमा तय।|Budget बन गया।|Limits set।';

  @override
  String get tone_calm_budgetUpdated => 'Adjust हो गया।';

  @override
  String get tone_calm_budgetDeleted => 'छोड़ दिया।';

  @override
  String get tone_calm_goalCreated => 'इरादा तय।|नई दिशा।|Goal बोया।';

  @override
  String get tone_calm_goalUpdated => 'Refine हो गया।';

  @override
  String get tone_calm_goalDeleted => 'छोड़ दिया।';

  @override
  String get tone_calm_accountCreated => 'Account खुल गया।';

  @override
  String get tone_calm_billAdded => 'Note हो गया। Remind करेंगे।';

  @override
  String get tone_calm_billPaid => 'Settle हो गया।|Paid। एक कम।|हो गया। शांति।';

  @override
  String get tone_calm_backupSuccess => 'सुरक्षित रख लिया।';

  @override
  String get tone_calm_restoreSuccess => 'Restore हो गया। Welcome back।';

  @override
  String get tone_calm_noTransactions =>
      'साफ़ slate।\nजब तैयार हों, शुरू करें।|अभी कुछ नहीं।\nधीरे से शुरू करें।|खाली।\nनई शुरुआत इंतज़ार कर रही।';

  @override
  String get tone_calm_noBudgets => 'कोई सीमा नहीं।\nजब सही लगे, बनाएं।';

  @override
  String get tone_calm_noGoals => 'कोई इरादा नहीं।\nजब तैयार हों, set करें।';

  @override
  String get tone_calm_genericError => 'कुछ बदल गया। फिर try करें।';

  @override
  String get tone_calm_smsImportEnabled => 'चुपचाप transactions देख रहे हैं।';

  @override
  String get tone_calm_dashboardAllCaughtUp =>
      'सब ठीक है।|कुछ attention नहीं चाहिए।|सब शांत।';

  @override
  String get tone_calm_dailySummaryEmpty =>
      'शांत दिन। कुछ record नहीं।|कल स्थिर था। कोई entry नहीं।|कुछ खर्च नहीं। आराम का दिन।';

  @override
  String tone_calm_streakMessage(int days) {
    return '$days दिन mindful tracking।';
  }

  @override
  String tone_calm_budgetExceededBy(String amount) {
    return '$amount ऊपर। सोचने का पल।';
  }

  @override
  String get tone_friendly_insightBillsDueSoon => 'ध्यान दें — bills आ रहे हैं';

  @override
  String get tone_friendly_insightOverBudget => 'Budget पार हो गया';

  @override
  String get tone_friendly_insightNearBudget => 'Budget के करीब...';

  @override
  String get tone_friendly_insightOverspending => 'खर्च आमदनी से ज्यादा';

  @override
  String get tone_friendly_insightSpendingSpike => 'आज खर्च ज्यादा है';

  @override
  String get tone_friendly_insightWeekendAlert => 'Weekend खर्च alert';

  @override
  String get tone_friendly_insightGetStarted => 'चलो शुरू करें! 🚀';

  @override
  String get tone_friendly_insightGetStartedMessage =>
      'पहला transaction डालें — बस एक sec';

  @override
  String tone_friendly_insightBillsDueMessage(int count) {
    return '$count bill(s) जल्दी due हैं, भूलना मत!';
  }

  @override
  String tone_friendly_insightOverBudgetMessage(int count) {
    return '$count budget(s) इस महीने पार हो गए — एक नज़र डालें';
  }

  @override
  String tone_friendly_insightNearBudgetMessage(int count) {
    return '$count budget(s) 80% से ऊपर — अभी समय है';
  }

  @override
  String tone_friendly_insightOverspendingMessage(String amount) {
    return 'इस महीने income से $amount ज्यादा खर्च — थोड़ा slow करें';
  }

  @override
  String tone_friendly_insightSpendingSpikeMessage(String avg, String today) {
    return 'आप रोज़ $avg/day खर्च करते हैं। आज $today हो चुका।';
  }

  @override
  String tone_friendly_insightWeekendAlertMessage(String avg, String current) {
    return 'Weekend पर आमतौर पर $avg खर्च। इस बार $current हो चुका।';
  }

  @override
  String get tone_professional_insightBillsDueSoon => 'आगामी bills';

  @override
  String get tone_professional_insightOverBudget => 'Budget exceed';

  @override
  String get tone_professional_insightNearBudget => 'Budget limit के करीब';

  @override
  String get tone_professional_insightOverspending => 'खर्च income से ज्यादा';

  @override
  String get tone_professional_insightSpendingSpike => 'आज खर्च बढ़ा हुआ';

  @override
  String get tone_professional_insightWeekendAlert => 'Weekend खर्च बढ़ा';

  @override
  String get tone_professional_insightGetStarted => 'शुरू करें';

  @override
  String get tone_professional_insightGetStartedMessage =>
      'Tracking शुरू करने के लिए पहला transaction record करें।';

  @override
  String tone_professional_insightBillsDueMessage(int count) {
    return '$count bill(s) कुছ दिनों में due हैं।';
  }

  @override
  String tone_professional_insightOverBudgetMessage(int count) {
    return 'इस महीने $count budget(s) exceed हो गए।';
  }

  @override
  String tone_professional_insightNearBudgetMessage(int count) {
    return '$count budget(s) 80% से ऊपर।';
  }

  @override
  String tone_professional_insightOverspendingMessage(String amount) {
    return 'इस महीने खर्च income से $amount ज्यादा है।';
  }

  @override
  String tone_professional_insightSpendingSpikeMessage(
      String avg, String today) {
    return 'Daily average: $avg। आज: $today।';
  }

  @override
  String tone_professional_insightWeekendAlertMessage(
      String avg, String current) {
    return 'Weekend average: $avg। अभी: $current।';
  }

  @override
  String get tone_motivational_insightBillsDueSoon => 'Bills आ रहे हैं! 📋';

  @override
  String get tone_motivational_insightOverBudget => 'Budget पार — वापस आएं';

  @override
  String get tone_motivational_insightNearBudget => 'Limit के करीब';

  @override
  String get tone_motivational_insightOverspending => 'खर्च income से ज्यादा';

  @override
  String get tone_motivational_insightSpendingSpike => 'आज खर्च spike';

  @override
  String get tone_motivational_insightWeekendAlert => 'Weekend खर्च alert';

  @override
  String get tone_motivational_insightGetStarted => 'कुছ बड़ा बनाते हैं! 🚀';

  @override
  String get tone_motivational_insightGetStartedMessage =>
      'पहला transaction डालें — बस एक step!';

  @override
  String tone_motivational_insightBillsDueMessage(int count) {
    return '$count bill(s) जल्दी due — आगे रहें!';
  }

  @override
  String tone_motivational_insightOverBudgetMessage(int count) {
    return '$count budget(s) exceed — course-correct कर सकते हैं!';
  }

  @override
  String tone_motivational_insightNearBudgetMessage(int count) {
    return '$count budget(s) 80% से ऊपर — आप कर सकते हैं!';
  }

  @override
  String tone_motivational_insightOverspendingMessage(String amount) {
    return 'Income से $amount ज्यादा — छोटे adjustments बड़ा फर्क लाते हैं!';
  }

  @override
  String tone_motivational_insightSpendingSpikeMessage(
      String avg, String today) {
    return 'आमतौर पर $avg/day। आज $today — intentional रहें!';
  }

  @override
  String tone_motivational_insightWeekendAlertMessage(
      String avg, String current) {
    return 'Weekend avg: $avg। इस बार $current — aware रहें!';
  }

  @override
  String get tone_calm_insightBillsDueSoon => 'Bills आ रहे हैं';

  @override
  String get tone_calm_insightOverBudget => 'सीमा पार';

  @override
  String get tone_calm_insightNearBudget => 'सीमा के करीब';

  @override
  String get tone_calm_insightOverspending => 'खर्च आमदनी से ज्यादा';

  @override
  String get tone_calm_insightSpendingSpike => 'भारी दिन';

  @override
  String get tone_calm_insightWeekendAlert => 'Weekend खर्च';

  @override
  String get tone_calm_insightGetStarted => 'नई शुरुआत';

  @override
  String get tone_calm_insightGetStartedMessage =>
      'पहले transaction से शुरू करें।';

  @override
  String tone_calm_insightBillsDueMessage(int count) {
    return '$count bill(s) जल्दी आएंगे।';
  }

  @override
  String tone_calm_insightOverBudgetMessage(int count) {
    return '$count budget(s) पार। सोचें और adjust करें।';
  }

  @override
  String tone_calm_insightNearBudgetMessage(int count) {
    return '$count budget(s) 80% से ऊपर। सोच-समझ कर खर्च करें।';
  }

  @override
  String tone_calm_insightOverspendingMessage(String amount) {
    return 'आमदनी से $amount ज्यादा खर्च। रुकें।';
  }

  @override
  String tone_calm_insightSpendingSpikeMessage(String avg, String today) {
    return 'आमतौर पर $avg/day। आज $today।';
  }

  @override
  String tone_calm_insightWeekendAlertMessage(String avg, String current) {
    return 'आमतौर पर $avg। इस weekend $current।';
  }

  @override
  String tone_friendly_insightMoneyLeak(
      String category, int count, String total) {
    return '$category: इस महीने $count बार, कुल $total — छोटे खर्च भी जोड़ लेते हैं';
  }

  @override
  String tone_friendly_insightBestDay(
      String worst, String wAvg, String best, String bAvg, String saving) {
    return '${worst}s पर avg $wAvg vs ${best}s पर $bAvg — $saving बचा सकते हैं';
  }

  @override
  String tone_professional_insightMoneyLeak(
      String category, int count, String total) {
    return '$category: $count transactions, कुल $total इस महीने।';
  }

  @override
  String tone_professional_insightBestDay(
      String worst, String wAvg, String best, String bAvg, String saving) {
    return '${worst}s पर avg $wAvg vs ${best}s पर $bAvg। बचत की संभावना: $saving।';
  }

  @override
  String tone_motivational_insightMoneyLeak(
      String category, int count, String total) {
    return '$category: $count बार, $total — छोटी जीत बड़ा फर्क लाती है!';
  }

  @override
  String tone_motivational_insightBestDay(
      String worst, String wAvg, String best, String bAvg, String saving) {
    return '${worst}s पर $wAvg vs ${best}s पर $bAvg — $saving बचा सकते हैं!';
  }

  @override
  String tone_calm_insightMoneyLeak(String category, int count, String total) {
    return '$category: $count बार, $total। छोटी धाराएं नदी बनाती हैं।';
  }

  @override
  String tone_calm_insightBestDay(
      String worst, String wAvg, String best, String bAvg, String saving) {
    return '${worst}s: $wAvg। ${best}s: $bAvg। $saving बचा सकते हैं।';
  }

  @override
  String get tone_friendly_txnNotFound => 'Can\'t find that transaction';

  @override
  String get tone_friendly_futureDate => 'Pick today or earlier';

  @override
  String get tone_friendly_selectAccountAndCategory =>
      'Pick an account & category first';

  @override
  String get tone_friendly_addParticipant =>
      'Add at least one person to split with';

  @override
  String get tone_friendly_budgetExceededAdjust =>
      'You\'ve exceeded this budget. Maybe ease up a bit?';

  @override
  String get tone_friendly_budgetGreatDiscipline =>
      'Great discipline! You\'re well within your budget ✨';

  @override
  String get tone_friendly_comparisonSpentSame =>
      'Spending is about the same as last month — steady!';

  @override
  String get tone_friendly_accountUpdated => 'Account updated!';

  @override
  String get tone_friendly_accountDeleted => 'Account removed';

  @override
  String get tone_friendly_accountLocked =>
      'This account is locked — upgrade to Pro to use it 🔒';

  @override
  String get tone_friendly_categoryCreated => 'Category added!';

  @override
  String get tone_friendly_categoryDeleted => 'Category removed';

  @override
  String get tone_friendly_categoryNameRequired => 'Give it a name!';

  @override
  String get tone_friendly_billDeleted => 'Bill removed';

  @override
  String get tone_friendly_backupFailed => 'Backup didn\'t work — try again?';

  @override
  String get tone_friendly_restoreFailed =>
      'Restore failed — is the file okay?';

  @override
  String get tone_friendly_invalidBackupFile =>
      'That doesn\'t look like a valid backup file';

  @override
  String get tone_friendly_corruptBackup => 'This backup looks corrupted 😕';

  @override
  String get tone_friendly_settingsSaved => 'Saved! ✓';

  @override
  String get tone_friendly_reminderUpdated => 'Reminder updated ⏰';

  @override
  String get tone_friendly_biometricFailed =>
      'Authentication failed — try again';

  @override
  String get tone_friendly_incorrectPin => 'Wrong PIN — give it another shot';

  @override
  String get tone_friendly_notificationAccessDenied =>
      'Need notification access to auto-import transactions';

  @override
  String get tone_friendly_noBills =>
      'No bills tracked\\nAdd recurring bills so you never miss a payment';

  @override
  String get tone_friendly_noAccounts =>
      'No accounts yet\\nAdd one to start tracking';

  @override
  String get tone_friendly_noCategories => 'No categories yet';

  @override
  String get tone_friendly_noNotifications =>
      'All quiet here\\nNo notifications yet';

  @override
  String get tone_friendly_noData =>
      'Not enough data yet\\nKeep tracking to unlock insights';

  @override
  String get tone_friendly_noRecurring =>
      'No recurring transactions\\nAdd bills to auto-track them';

  @override
  String get tone_friendly_exportSuccess => 'Report exported! 📄';

  @override
  String get tone_friendly_purchaseFailed =>
      'Purchase didn\'t go through — try again?';

  @override
  String get tone_friendly_playNotAvailable =>
      'Google Play isn\'t available on this device';

  @override
  String get tone_friendly_deleteTitle => 'Are you sure?';

  @override
  String get tone_friendly_deleteCancel => 'Keep it';

  @override
  String get tone_friendly_deleteConfirm => 'Delete';

  @override
  String get tone_friendly_logoutTitle => 'Leaving already?';

  @override
  String get tone_friendly_logoutMessage =>
      'All your data will be cleared from this device.';

  @override
  String get tone_friendly_logoutConfirm => 'Logout';

  @override
  String get tone_friendly_currencyChanged => 'Base currency updated! 💱';

  @override
  String get tone_friendly_currencyChangeTitle => 'Change base currency?';

  @override
  String get tone_friendly_currencyChangeCancel => 'Keep it';

  @override
  String get tone_friendly_currencyPickerTitle => 'Choose Your Currency';

  @override
  String get tone_friendly_dashboardWelcomeBack =>
      'Welcome back! Let\'s see where you stand';

  @override
  String get tone_professional_txnNotFound => 'Transaction not found.';

  @override
  String get tone_professional_futureDate => 'Future dates are not permitted.';

  @override
  String get tone_professional_selectAccountAndCategory =>
      'Account and category are required.';

  @override
  String get tone_professional_addParticipant =>
      'At least one participant is required.';

  @override
  String get tone_professional_budgetExceededAdjust =>
      'Budget exceeded. Review spending or adjust the limit.';

  @override
  String get tone_professional_budgetGreatDiscipline =>
      'Well within budget. Good financial discipline.';

  @override
  String get tone_professional_comparisonSpentSame =>
      'Spending is consistent with last month.';

  @override
  String get tone_professional_accountUpdated => 'Account updated.';

  @override
  String get tone_professional_accountDeleted => 'Account removed.';

  @override
  String get tone_professional_accountLocked =>
      'Account locked. Pro subscription required.';

  @override
  String get tone_professional_categoryCreated => 'Category added.';

  @override
  String get tone_professional_categoryDeleted => 'Category removed.';

  @override
  String get tone_professional_categoryNameRequired =>
      'Category name is required.';

  @override
  String get tone_professional_billDeleted => 'Bill removed.';

  @override
  String get tone_professional_backupFailed =>
      'Backup failed. Please try again.';

  @override
  String get tone_professional_restoreFailed =>
      'Restore failed. Verify the backup file.';

  @override
  String get tone_professional_invalidBackupFile =>
      'Invalid backup file format.';

  @override
  String get tone_professional_corruptBackup => 'Backup file is corrupted.';

  @override
  String get tone_professional_settingsSaved => 'Settings saved.';

  @override
  String get tone_professional_reminderUpdated => 'Reminder time updated.';

  @override
  String get tone_professional_biometricFailed => 'Authentication failed.';

  @override
  String get tone_professional_incorrectPin => 'Incorrect PIN.';

  @override
  String get tone_professional_notificationAccessDenied =>
      'Notification access is required for auto-import.';

  @override
  String get tone_professional_noBills => 'No recurring bills.';

  @override
  String get tone_professional_noAccounts => 'No accounts configured.';

  @override
  String get tone_professional_noCategories => 'No categories defined.';

  @override
  String get tone_professional_noNotifications => 'No notifications.';

  @override
  String get tone_professional_noData =>
      'Insufficient data.\\nContinue recording transactions.';

  @override
  String get tone_professional_noRecurring =>
      'No recurring transactions configured.';

  @override
  String get tone_professional_exportSuccess => 'Report exported.';

  @override
  String get tone_professional_purchaseFailed =>
      'Purchase failed. Please retry.';

  @override
  String get tone_professional_playNotAvailable =>
      'Google Play Services unavailable.';

  @override
  String get tone_professional_deleteTitle => 'Confirm Deletion';

  @override
  String get tone_professional_deleteCancel => 'Cancel';

  @override
  String get tone_professional_deleteConfirm => 'Delete';

  @override
  String get tone_professional_logoutTitle => 'Confirm Logout';

  @override
  String get tone_professional_logoutMessage =>
      'All local data will be erased.';

  @override
  String get tone_professional_logoutConfirm => 'Logout';

  @override
  String get tone_professional_currencyChanged => 'Base currency updated.';

  @override
  String get tone_professional_currencyChangeTitle => 'Change Base Currency';

  @override
  String get tone_professional_currencyChangeCancel => 'Cancel';

  @override
  String get tone_professional_currencyPickerTitle => 'Select Currency';

  @override
  String get tone_professional_dashboardWelcomeBack =>
      'Welcome back. Here is your summary.';

  @override
  String get tone_motivational_txnNotFound =>
      'Can\'t find that one — it may have been removed';

  @override
  String get tone_motivational_futureDate =>
      'Let\'s stay in the present — pick today or earlier';

  @override
  String get tone_motivational_selectAccountAndCategory =>
      'Account & category first — you\'re almost done!';

  @override
  String get tone_motivational_addParticipant =>
      'Add at least one person to split with!';

  @override
  String get tone_motivational_budgetExceededAdjust =>
      'Over budget — but every day is a chance to reset! 💪';

  @override
  String get tone_motivational_budgetGreatDiscipline =>
      'Amazing discipline! You\'re way ahead! 🏆';

  @override
  String get tone_motivational_comparisonSpentSame =>
      'Holding steady! Consistent spending shows control 💪';

  @override
  String get tone_motivational_accountUpdated => 'Account updated!';

  @override
  String get tone_motivational_accountDeleted => 'Account removed';

  @override
  String get tone_motivational_accountLocked =>
      'This account is locked — Go Pro to unlock! 🔒';

  @override
  String get tone_motivational_categoryCreated => 'New category added!';

  @override
  String get tone_motivational_categoryDeleted => 'Category removed';

  @override
  String get tone_motivational_categoryNameRequired => 'Give it a name!';

  @override
  String get tone_motivational_billDeleted => 'Bill removed';

  @override
  String get tone_motivational_backupFailed =>
      'Backup didn\'t work — try again!';

  @override
  String get tone_motivational_restoreFailed =>
      'Restore failed — check the file and retry';

  @override
  String get tone_motivational_invalidBackupFile =>
      'That doesn\'t look like a valid backup';

  @override
  String get tone_motivational_corruptBackup => 'This backup seems damaged';

  @override
  String get tone_motivational_settingsSaved => 'Saved! ✓';

  @override
  String get tone_motivational_reminderUpdated => 'Reminder set! ⏰';

  @override
  String get tone_motivational_biometricFailed =>
      'Authentication failed — try again!';

  @override
  String get tone_motivational_incorrectPin =>
      'Wrong PIN — you\'ve got this, try again!';

  @override
  String get tone_motivational_notificationAccessDenied =>
      'Need notification access to auto-track transactions';

  @override
  String get tone_motivational_noBills =>
      'No bills tracked\\nStay ahead by adding your recurring bills';

  @override
  String get tone_motivational_noAccounts =>
      'No accounts yet\\nAdd one to start your financial journey!';

  @override
  String get tone_motivational_noCategories => 'No categories yet';

  @override
  String get tone_motivational_noNotifications =>
      'All clear!\\nNo notifications — you\'re on top of things';

  @override
  String get tone_motivational_noData =>
      'Keep going! 📈\\nMore data means better insights';

  @override
  String get tone_motivational_noRecurring =>
      'No recurring transactions\\nAutomate your bills to stay ahead!';

  @override
  String get tone_motivational_exportSuccess => 'Report exported! 📄';

  @override
  String get tone_motivational_purchaseFailed =>
      'Purchase didn\'t go through — try again!';

  @override
  String get tone_motivational_playNotAvailable =>
      'Google Play isn\'t available on this device';

  @override
  String get tone_motivational_deleteTitle => 'Are you sure?';

  @override
  String get tone_motivational_deleteCancel => 'Keep it';

  @override
  String get tone_motivational_deleteConfirm => 'Delete';

  @override
  String get tone_motivational_logoutTitle => 'Heading out?';

  @override
  String get tone_motivational_logoutMessage =>
      'All data on this device will be cleared.';

  @override
  String get tone_motivational_logoutConfirm => 'Logout';

  @override
  String get tone_motivational_currencyChanged =>
      'Currency switched! New chapter! 💱';

  @override
  String get tone_motivational_currencyChangeTitle => 'Ready to switch?';

  @override
  String get tone_motivational_currencyChangeCancel => 'Not yet';

  @override
  String get tone_motivational_currencyPickerTitle => 'Pick Your Currency! 🌍';

  @override
  String get tone_motivational_dashboardWelcomeBack =>
      'You\'re back! Let\'s keep the progress going! 🚀';

  @override
  String get tone_calm_txnNotFound => 'Not found. It may have moved on.';

  @override
  String get tone_calm_futureDate => 'Stay in the present.';

  @override
  String get tone_calm_selectAccountAndCategory =>
      'Account and category, please.';

  @override
  String get tone_calm_addParticipant => 'Add someone to share with.';

  @override
  String get tone_calm_budgetExceededAdjust =>
      'Past the boundary. Pause and reconsider.';

  @override
  String get tone_calm_budgetGreatDiscipline => 'Well within bounds. Peaceful.';

  @override
  String get tone_calm_comparisonSpentSame =>
      'Spending flows at the same pace.';

  @override
  String get tone_calm_accountUpdated => 'Adjusted.';

  @override
  String get tone_calm_accountDeleted => 'Closed.';

  @override
  String get tone_calm_accountLocked => 'This one is resting. Pro unlocks it.';

  @override
  String get tone_calm_categoryCreated => 'Added.';

  @override
  String get tone_calm_categoryDeleted => 'Removed.';

  @override
  String get tone_calm_categoryNameRequired => 'A name, please.';

  @override
  String get tone_calm_billDeleted => 'Released.';

  @override
  String get tone_calm_backupFailed => 'Couldn\'t save. Try again gently.';

  @override
  String get tone_calm_restoreFailed => 'Couldn\'t restore. Check the file.';

  @override
  String get tone_calm_invalidBackupFile => 'This file doesn\'t feel right.';

  @override
  String get tone_calm_corruptBackup => 'The file seems damaged.';

  @override
  String get tone_calm_settingsSaved => 'Saved.';

  @override
  String get tone_calm_reminderUpdated => 'Reminder adjusted.';

  @override
  String get tone_calm_biometricFailed => 'Not recognized. Try again.';

  @override
  String get tone_calm_incorrectPin => 'Not quite. Try again.';

  @override
  String get tone_calm_notificationAccessDenied =>
      'Permission needed for quiet tracking.';

  @override
  String get tone_calm_noBills => 'Nothing recurring.\\nPeaceful.';

  @override
  String get tone_calm_noAccounts => 'No accounts yet.\\nStart simply.';

  @override
  String get tone_calm_noCategories => 'No categories yet.';

  @override
  String get tone_calm_noNotifications => 'Silence.\\nNothing needs attention.';

  @override
  String get tone_calm_noData => 'Not enough yet.\\nIt will come with time.';

  @override
  String get tone_calm_noRecurring => 'Nothing recurring.\\nAdd when ready.';

  @override
  String get tone_calm_exportSuccess => 'Exported.';

  @override
  String get tone_calm_purchaseFailed =>
      'Purchase didn\'t complete. Try again.';

  @override
  String get tone_calm_playNotAvailable => 'Play Store not available here.';

  @override
  String get tone_calm_deleteTitle => 'Let go?';

  @override
  String get tone_calm_deleteCancel => 'Hold on';

  @override
  String get tone_calm_deleteConfirm => 'Release';

  @override
  String get tone_calm_logoutTitle => 'Moving on?';

  @override
  String get tone_calm_logoutMessage => 'Your data here will be cleared.';

  @override
  String get tone_calm_logoutConfirm => 'Leave';

  @override
  String get tone_calm_currencyChanged => 'Currency shifted.';

  @override
  String get tone_calm_currencyChangeTitle => 'A new currency?';

  @override
  String get tone_calm_currencyChangeCancel => 'Stay';

  @override
  String get tone_calm_currencyPickerTitle => 'Choose your currency';

  @override
  String get tone_calm_dashboardWelcomeBack => 'Welcome back.';

  @override
  String get notif_quietDayTitle => '📊 कल शांत दिन रहा';

  @override
  String get notif_heresYesterdayTitle => '📊 कल का हाल';

  @override
  String get notif_weekInReviewTitle => '📅 हफ्ते का सारांश';

  @override
  String get notif_yourWeekInReviewTitle => '📅 आपके हफ्ते का सारांश';

  @override
  String get notif_niceOneTitle => '🏆 शानदार!';

  @override
  String notif_streakDaysTitle(int days) {
    return '🔥 $days दिन लगातार!';
  }

  @override
  String notif_levelUpTitle(int level) {
    return '🎉 Level $level!';
  }

  @override
  String notif_budgetsOverLimitTitle(int count) {
    return '🚨 $count budget limit पार';
  }

  @override
  String notif_budgetsGettingTightTitle(int count) {
    return '⚠️ $count budget tight हो रहे हैं';
  }

  @override
  String notif_billDueTitle(String name, String label) {
    return '📅 $name $label को देय है';
  }

  @override
  String get notif_fundsGettingLowTitle => '📉 पैसे कम हो रहे हैं';

  @override
  String notif_categoryCreepingUpTitle(String category) {
    return '💡 $category बढ़ रहा है';
  }

  @override
  String get notif_bigDayTitle => '📈 बड़ा दिन रहा';

  @override
  String notif_smsFoundTitle(int count) {
    return '📱 $count SMS transactions मिले';
  }

  @override
  String get notif_smallSpendsTitle => '💧 छोटे खर्च जुड़ रहे हैं';

  @override
  String get notif_missYouTitle => '👋 आपकी याद आती है';

  @override
  String notif_daysUntrackedTitle(int days) {
    return '📊 $days दिन untracked';
  }

  @override
  String notif_streakEndedTitle(int days) {
    return '💔 $days दिन की streak टूटी';
  }

  @override
  String get notif_fewDaysUntrackedTitle => '📊 कुछ दिन untracked';

  @override
  String get insight_moneyLeakTitle => 'चुपचाप पैसा बह रहा है 💧';

  @override
  String insight_bestDayTitle(String day) {
    return '$day को सबसे ज़्यादा खर्च होता है';
  }

  @override
  String get bills_howBillsWorkTitle => 'बिल कैसे काम करते हैं';

  @override
  String get bills_howBillsWorkDesc =>
      'किराया, subscription और utility जैसे नियमित बिल track करें';

  @override
  String get bills_gotIt => 'समझ गया';

  @override
  String get bills_addBill => 'बिल जोड़ें';

  @override
  String get bills_markAsPaid => 'भुगतान किया';

  @override
  String get bills_deleteBill => 'बिल हटाएं';

  @override
  String get bills_addNewBill => 'नया बिल जोड़ें';

  @override
  String get bills_billName => 'बिल का नाम';

  @override
  String get bills_amount => 'राशि';

  @override
  String get bills_frequency => 'आवृत्ति';

  @override
  String get bills_monthly => 'मासिक';

  @override
  String get bills_quarterly => 'तिमाही';

  @override
  String get bills_yearly => 'वार्षिक';

  @override
  String get bills_dueDate => 'देय तारीख';

  @override
  String get goal_deleteGoalTitle => 'Goal हटाएं?';

  @override
  String get goal_editGoal => 'Goal संपादित करें';

  @override
  String get goal_deleteGoal => 'Goal हटाएं';

  @override
  String get goal_saved => 'बचाया';

  @override
  String get goal_target => 'लक्ष्य';

  @override
  String get goal_quickDeposit => 'जल्दी जमा करें';

  @override
  String get goal_targetDate => 'लक्ष्य तारीख';

  @override
  String get goal_milestones => 'पड़ाव';

  @override
  String get goal_recentActivity => 'हाल की गतिविधि';

  @override
  String get goal_addToGoal => 'Goal में जोड़ें';

  @override
  String get goal_goalReached => 'Goal पूरा हुआ! 🎉';

  @override
  String get goal_whatsThisAbout => 'यह goal किसलिए है?';

  @override
  String get goal_icon => 'आइकॉन';

  @override
  String get goal_color => 'रंग';

  @override
  String get dashboard_enableCards => 'Cards सक्षम करें';

  @override
  String get recurring_fixedExpenses => 'नियमित खर्च';

  @override
  String get goal_freePlanLimit =>
      'Free plan में 2 goals तक। Pro में unlimited।';

  @override
  String get goal_editGoalTitle => 'Goal संपादित करें';

  @override
  String get goal_newGoalTitle => 'नया Goal';

  @override
  String get goal_yourGoal => 'आपका Goal';

  @override
  String get goal_appearance => 'दिखावट';

  @override
  String get goal_goalName => 'Goal का नाम';

  @override
  String get goal_giveGoalName => 'अपने goal का नाम दें';

  @override
  String get goal_targetAmount => 'लक्ष्य राशि';

  @override
  String get goal_enterValidTarget => 'सही target राशि दर्ज करें';

  @override
  String get goal_alreadySaved => 'पहले से बचाया';

  @override
  String get goal_targetDateLabel => 'लक्ष्य तारीख';

  @override
  String get goal_setTargetDate => 'Target तारीख सेट करें (वैकल्पिक)';

  @override
  String get goal_smartInsight => 'Smart जानकारी';

  @override
  String get goal_onTrack => 'सही चल रहा है ✅';

  @override
  String get goal_onTrackDesc => 'यह goal आसानी से पूरा हो सकता है 👍';

  @override
  String get goal_needsEffort => 'मेहनत चाहिए';

  @override
  String get goal_needsEffortDesc => 'थोड़ी और बचत की ज़रूरत';

  @override
  String get goal_ambitious => 'महत्वाकांक्षी';

  @override
  String get goal_ambitiousDesc => 'Deadline बढ़ाने पर विचार करें';

  @override
  String get goal_addNote => 'नोट जोड़ें (वैकल्पिक)';

  @override
  String get goal_note => 'नोट';

  @override
  String get goal_updateGoal => 'Goal अपडेट करें';

  @override
  String get goal_createGoal => 'Goal बनाएं';

  @override
  String get profile_developerMode => 'Developer Mode सक्रिय! 🚀';

  @override
  String get profile_couldNotOpenLink => 'लिंक नहीं खुल सका';

  @override
  String get profile_about => 'बारे में';

  @override
  String get profile_unableToCheckUpdates => 'Updates check नहीं हो सका';

  @override
  String get profile_openSourceLicenses => 'Open Source Licenses';

  @override
  String get account_totalValue => 'कुल मूल्य';

  @override
  String get account_gainLoss => 'लाभ/हानि';

  @override
  String get account_holdings => 'Holdings';

  @override
  String get account_addHolding => 'Holding जोड़ें';

  @override
  String get account_addMissingTransaction => 'छूटा हुआ Transaction जोड़ें';

  @override
  String get account_whatWasThisFor => 'यह transaction किसलिए था?';

  @override
  String get budget_used => 'उपयोग किया';

  @override
  String get budget_selectAtLeastOneTag => 'कम से कम एक tag चुनें';

  @override
  String get budget_over => 'ज़्यादा';

  @override
  String get budget_left => 'बाकी';

  @override
  String get budget_breakdown => 'विवरण';

  @override
  String get budget_basicInfo => 'बुनियादी जानकारी';

  @override
  String get budget_duration => 'अवधि';

  @override
  String get budget_budgetType => 'Budget का प्रकार';

  @override
  String get budget_selectType => 'प्रकार चुनें';

  @override
  String get budget_categoryAllocation => 'Category Allocation';

  @override
  String get budget_totalBudget => 'कुल Budget';

  @override
  String get budget_allocated => 'आवंटित';

  @override
  String get budget_remaining => 'बाकी';

  @override
  String get budget_overBudget => 'Budget से ज़्यादा';

  @override
  String get budget_safeToSpend => 'खर्च करना सही';

  @override
  String get budget_startDate => 'शुरू की तारीख';

  @override
  String get budget_endDate => 'आखिरी तारीख';

  @override
  String get budget_selectTags => 'Tags चुनें';

  @override
  String get budget_tagInfo =>
      'चुने हुए tags वाले सभी खर्च इस budget में गिने जाएंगे।';

  @override
  String get budget_noTags =>
      'अभी कोई tag नहीं है। पहले transactions में tags जोड़ें।';

  @override
  String get budget_freePlanLimit =>
      'Free plan में 2 budgets बना सकते हैं। ज़्यादा के लिए Pro लें।';

  @override
  String budget_daysRemaining(Object count) {
    return '$count दिन';
  }

  @override
  String get budget_delete => 'हटाएं';

  @override
  String get budget_emotionUnderControl => 'खर्च control में है 💪';

  @override
  String get budget_emotionHalfway => 'महीने का आधा हिस्सा ✨';

  @override
  String get budget_emotionAlmostThere => 'थोड़ा संभलकर, ध्यान रखें ⚠️';

  @override
  String get budget_emotionExceeded => 'Budget पार हो गया, संभालें 🔴';

  @override
  String get budget_highlightLabel => 'ध्यान दें';

  @override
  String get budget_overBudgetSection => 'Budget से ज़्यादा';

  @override
  String get budget_activeBudgets => 'Active budgets';

  @override
  String get budget_onTrackSection => 'सही चल रहा है';

  @override
  String get budget_spendingPace => 'खर्च की रफ़्तार';

  @override
  String budget_dailyActual(Object amount) {
    return '$amount/दिन खर्च';
  }

  @override
  String budget_dailyAllowed(Object amount) {
    return '$amount/दिन सीमा';
  }

  @override
  String get budget_stepNote0 =>
      'Budget का नाम और कितना खर्च करना है सेट करें।';

  @override
  String get budget_stepNote1 => 'Budget कितनी बार repeat हो और dates चुनें।';

  @override
  String get budget_stepNote2 =>
      'कौन सी categories या tags track करनी हैं चुनें।';

  @override
  String get budget_autoDistributed => 'auto';

  @override
  String budget_categoriesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count categories',
      one: '1 category',
    );
    return '$_temp0';
  }

  @override
  String budget_tagsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tags',
      one: '1 tag',
    );
    return '$_temp0';
  }

  @override
  String get budget_typeCategoryWise => 'Category अनुसार';

  @override
  String get budget_typeTagWise => 'Tag अनुसार';

  @override
  String get budget_typeDayWise => 'रोज़ाना';

  @override
  String get budget_typeFestival => 'त्योहार';

  @override
  String get budget_typeTravel => 'यात्रा';

  @override
  String get budget_typeDescCategoryWise =>
      'खास categories के लिए budget सेट करें';

  @override
  String get budget_typeDescTagWise => 'खास tags के लिए budget सेट करें';

  @override
  String get budget_typeDescDayWise => 'रोज़ की खर्च सीमा सेट करें';

  @override
  String get budget_typeDescFestival => 'त्योहार और events के लिए budget';

  @override
  String get budget_typeDescTravel => 'यात्रा के खर्चों के लिए budget';

  @override
  String get budget_reviewTitle => 'देखें और Save करें';

  @override
  String get budget_selectCategories => 'Categories चुनें';

  @override
  String get budget_noActiveTrip =>
      'कोई active trip नहीं है। Travel budget के लिए पहले trip शुरू करें।';

  @override
  String get budget_stepNote3 =>
      'Save करने से पहले सब चेक करें। Edit करने के लिए tap करें।';

  @override
  String budget_categoryDeleteWarning(Object count) {
    return 'यह category $count budget(s) में है। हटाने से budget tracking प्रभावित होगी।';
  }

  @override
  String get budget_invalidCategories =>
      'कुछ categories हटा दी गई हैं। ठीक करने के लिए budget edit करें।';

  @override
  String get category_categoryName => 'श्रेणी का नाम';

  @override
  String get category_keywords => 'Keywords (अल्पविराम से अलग)';

  @override
  String get category_noneTopLevel => 'कोई नहीं (शीर्ष-स्तर)';

  @override
  String get common_searchCurrency => 'मुद्रा खोजें...';

  @override
  String get common_selectCategory => 'श्रेणी चुनें';

  @override
  String get common_noDescription => 'कोई विवरण नहीं';

  @override
  String get common_errors => 'त्रुटियां';

  @override
  String get dashboard_enableCardsDesc =>
      'Dashboard cards सक्षम करें अपना वित्तीय सारांश देखने के लिए';

  @override
  String get dashboard_customizeDashboard => 'Dashboard customize करें';

  @override
  String get dashboard_newToApp => 'Mudra Manager में नए हैं?';

  @override
  String get dashboard_tapToExploreHelp => 'Help guide देखने के लिए टैप करें';

  @override
  String get dashboard_tapToReviewTxn =>
      'Transactions review करने के लिए टैप करें';

  @override
  String get dashboard_autoImportPaused => 'Auto Import रुका हुआ';

  @override
  String get dashboard_enable => 'सक्षम करें';

  @override
  String get dashboard_enableAutoImport => 'Auto Import सक्षम करें';

  @override
  String get dashboard_autoTrackDesc =>
      'Bank notifications से transactions auto-track करें';

  @override
  String get profile_awesomeUser => 'शानदार User';

  @override
  String get profile_logout => 'लॉगआउट';

  @override
  String get profile_proActiveLabel => 'Pro सक्रिय';

  @override
  String get profile_freeTierLabel => 'Free Tier';

  @override
  String get profile_fullAccessLabel => 'पूरा Access';

  @override
  String get profile_upgradeToProLabel => 'Pro में Upgrade करें';

  @override
  String get profile_fullAccessEnjoy =>
      'पूरा access — सभी features का आनंद लें!';

  @override
  String profile_fullAccessDaysRemaining(int days) {
    return 'पूरा access — $days दिन बाकी';
  }

  @override
  String profile_fullAccessEndsIn(int days) {
    return 'पूरा access $days दिन में समाप्त';
  }

  @override
  String get profile_trialEnded =>
      'Trial खत्म — सभी features रखने के लिए upgrade करें';

  @override
  String get profile_unlimitedDesc =>
      'Unlimited accounts, analytics और बहुत कुछ';

  @override
  String get profile_expiredRenew => 'समाप्त — renew करने के लिए टैप करें';

  @override
  String get profile_expiresToday => 'आज समाप्त होगा';

  @override
  String get profile_renewsTomorrow => 'कल renew होगा';

  @override
  String profile_renewsInDays(int days) {
    return '$days दिन में renew होगा';
  }

  @override
  String get profile_activeSubscription => 'सक्रिय सदस्यता';

  @override
  String get profile_unknown => 'अज्ञात';

  @override
  String get profile_accountsLabel => 'खाते';

  @override
  String get profile_categoriesLabel => 'श्रेणियां';

  @override
  String get profile_budgetsLabel => 'बजट';

  @override
  String get profile_bestStreakLabel => 'सर्वश्रेष्ठ Streak';

  @override
  String get profile_yourAchievementsLabel => 'आपकी उपलब्धियां';

  @override
  String get profile_aboutMudra => 'Mudra Manager के बारे में';

  @override
  String get profile_aboutMudraDesc =>
      'आपका पर्सनल फाइनेंस साथी। खर्च track करें, budget संभालें';

  @override
  String get txnList_searchHint => 'Transactions खोजें...';

  @override
  String get txnList_category => 'श्रेणी';

  @override
  String get txnList_dateRange => 'तारीख सीमा';

  @override
  String get txnList_tag => 'Tag';

  @override
  String get txnList_allTransactions => 'सभी लेनदेन';

  @override
  String get txnList_tapStartEnd => 'शुरू और अंत तारीख टैप करें';

  @override
  String get txnList_scrollToLoad => 'और लोड करने के लिए scroll करें';

  @override
  String get txnList_month => 'महीना';

  @override
  String get txnList_previousMonth => 'पिछला महीना';

  @override
  String get txnList_resetToCurrentMonth => 'इस महीने पर वापस जाएं';

  @override
  String get txnList_selectMonth => 'महीना चुनें';

  @override
  String get txnList_nextMonth => 'अगला महीना';

  @override
  String get txnList_monthView => 'महीना दृश्य';

  @override
  String get txnList_subscriptionTagRemoved => 'Subscription tag हटाया गया';

  @override
  String get txnList_filterByTag => 'Tag से filter करें';

  @override
  String get txnList_noTagsYet =>
      'अभी कोई tag नहीं। पहले transactions में tag जोड़ें।';

  @override
  String get txnList_clear => 'साफ़ करें';

  @override
  String get txnList_filterOptions => 'Filter विकल्प';

  @override
  String get txnList_transactionType => 'Transaction प्रकार';

  @override
  String get txnList_allCategories => 'सभी श्रेणियां';

  @override
  String get txnList_selectDateRange => 'तारीख सीमा चुनें';

  @override
  String get txnList_clearDateRange => 'तारीख सीमा हटाएं';

  @override
  String get stats_today => 'आज';

  @override
  String get stats_week => 'हफ्ता';

  @override
  String get stats_month => 'महीना';

  @override
  String get stats_year => 'साल';

  @override
  String get stats_custom => 'कस्टम';

  @override
  String get stats_unableToLoad => 'Statistics लोड नहीं हो सका';

  @override
  String get stats_overview => 'सारांश';

  @override
  String get stats_income => 'आय';

  @override
  String get stats_expense => 'खर्च';

  @override
  String get stats_trends => 'रुझान';

  @override
  String get stats_spendingByDay => 'दिन के हिसाब से खर्च';

  @override
  String get stats_insights => 'जानकारी';

  @override
  String get stats_nextMonthForecast => 'अगले महीने का अनुमान';

  @override
  String get stats_topSpending => 'सबसे ज़्यादा खर्च';

  @override
  String get stats_12MonthTrend => '12 महीने का Trend';

  @override
  String stats_trendUp(Object category, Object percent) {
    return '$category बढ़ रहा है — कुल खर्च का $percent%';
  }

  @override
  String stats_trendDown(Object category) {
    return '$category इस महीने कम हो रहा है 📉';
  }

  @override
  String stats_topCategory(Object category, Object percent) {
    return '$category सबसे ज़्यादा है — $percent% खर्च';
  }

  @override
  String stats_weekendPeak(Object day) {
    return 'Weekend पर ज़्यादा खर्च — $day सबसे भारी';
  }

  @override
  String stats_weekdayPeak(Object day) {
    return 'Weekday में ज़्यादा खर्च — $day सबसे भारी';
  }

  @override
  String stats_peakAndQuiet(Object peak, Object quiet) {
    return '$peak सबसे भारी दिन, $quiet सबसे हल्का';
  }

  @override
  String get stats_categoryTrends => 'Category Trends';

  @override
  String get stats_spendingByTag => 'Tag अनुसार खर्च';

  @override
  String get stats_netWorth => 'Net Worth';

  @override
  String get stats_savings => 'बचत';

  @override
  String get stats_categoryImpact => 'CATEGORY प्रभाव';

  @override
  String get stats_net => 'नेट';

  @override
  String get stats_dailySpendingPace => 'रोज़ाना खर्च की रफ़्तार';

  @override
  String get stats_topCategories => 'शीर्ष Categories';

  @override
  String stats_projectedThisMonth(Object amount) {
    return 'अनुमान: इस महीने $amount';
  }

  @override
  String stats_byDay(Object day, Object amount, Object month) {
    return 'दिन $day तक: $month में $amount';
  }

  @override
  String get stats_steadyHeadline => 'स्थिर चल रहा है';

  @override
  String get stats_steadyDetail => 'आपका खर्च एकसमान है — यह अनुशासन है।';

  @override
  String get stats_doingGreatHeadline => 'बहुत अच्छा चल रहा है 🌟';

  @override
  String get stats_spendingUpHeadline => 'ध्यान दें — खर्च बढ़ रहा है';

  @override
  String get stats_downloadPdf => 'PDF Download करें';

  @override
  String get stats_generating => 'बन रहा है...';

  @override
  String get recap_income => 'आय';

  @override
  String get recap_expense => 'खर्च';

  @override
  String get recap_saved => 'बचाया';

  @override
  String get recap_belowAvg => 'औसत से कम';

  @override
  String get recap_aboveAvg => 'औसत से ज़्यादा';

  @override
  String get recap_recurring => 'Recurring';

  @override
  String get recap_oneTime => 'One-time';

  @override
  String get recap_recapTitle => 'Recap';

  @override
  String get notifSettings_dailySummary => 'दैनिक सारांश';

  @override
  String get notifSettings_weeklySummary => 'साप्ताहिक सारांश';

  @override
  String get notifSettings_comeBackNudges => 'वापसी की याद';

  @override
  String get notifSettings_streakReminder => 'Streak Reminder';

  @override
  String get notifSettings_smartAlerts => 'Smart Alerts';

  @override
  String get notifSettings_selectDay => 'दिन चुनें';

  @override
  String get notifSettings_summariesDesc =>
      'सारांश में खर्च, आय, शीर्ष श्रेणी और शेष दिखता है';

  @override
  String get notifSettings_reminderTime => 'Reminder का समय';

  @override
  String get notifSettings_sendTestNotif => 'Test Notification भेजें';

  @override
  String get notifSettings_testNotifSent => 'Test notification भेजी गई';

  @override
  String get notifSettings_dailyNudgeStreak => 'Streak बनाए रखने की दैनिक याद';

  @override
  String get notifSettings_summaryDay => 'सारांश का दिन';

  @override
  String get notifSettings_gentleReminders => 'ऐप पर वापस आने की हल्की याद';

  @override
  String get notifSettings_budgetWarningsDesc =>
      'Budget चेतावनी, खर्च spike, बिल reminder';

  @override
  String get notifSettings_localNotifDisclaimer =>
      'Notifications आपके device पर locally deliver होती हैं। कोई data बाहर नहीं जाता।';

  @override
  String get smsImport_autoImport => 'Auto Import';

  @override
  String get smsImport_permissions => 'अनुमतियां';

  @override
  String get smsImport_notifAccess => 'Notification Access';

  @override
  String get smsImport_notifAccessEnabled => 'Notification access सक्षम';

  @override
  String get smsImport_allowReadingNotif =>
      'Bank notifications पढ़ने की अनुमति दें';

  @override
  String get smsImport_autoDetectTxn =>
      'Notifications से transactions auto-detect करें';

  @override
  String get smsImport_privacyNote =>
      'Notifications are read locally on your device to detect transactions. Nothing is uploaded or shared.';

  @override
  String get smsImport_tools => 'टूल्स';

  @override
  String get smsImport_txnActivity => 'Transaction Activity';

  @override
  String get smsImport_viewDetectedTxn => 'सभी detect की गई transactions देखें';

  @override
  String get smsImport_clearHistory => 'Processing History साफ़ करें';

  @override
  String get smsImport_resetDetection => 'Detection history reset करें';

  @override
  String get smsImport_howItWorks => 'यह कैसे काम करता है';

  @override
  String get smsImport_readsBankNotif => 'Reads bank and wallet notifications';

  @override
  String get smsImport_dataStaysOnDevice => 'सारा data आपके device पर रहता है';

  @override
  String get smsImport_autoCreatesTxn => 'Transactions अपने आप बनाता है';

  @override
  String get smsImport_personalIgnored =>
      'Personal notifications नज़रअंदाज़ की जाती हैं';

  @override
  String get smsImport_noDataSent => 'कोई data किसी server को नहीं भेजा जाता';

  @override
  String get smsImport_active => 'सक्रिय';

  @override
  String get smsImport_inactive => 'निष्क्रिय';

  @override
  String get smsImport_grantAccess =>
      'शुरू करने के लिए notification access दें';

  @override
  String get smsImport_notAvailableIos => 'iOS पर उपलब्ध नहीं';

  @override
  String get smsImport_enableAccessFirst =>
      'पहले notification access सक्षम करें';

  @override
  String get smsImport_notifAccessRequired => 'Notification Access ज़रूरी';

  @override
  String get smsImport_notifAccessDesc =>
      'Mudra Manager को transactions auto-detect करने के लिए notification access चाहिए';

  @override
  String get smsImport_onlyBankRead =>
      'सिर्फ bank/wallet notifications पढ़ी जाती हैं';

  @override
  String get smsImport_personalNeverRead =>
      'Personal messages कभी नहीं पढ़े जाते';

  @override
  String get smsImport_openSettings => 'Settings खोलें';

  @override
  String get smsImport_clearHistoryConfirm => 'Processing History साफ़ करें?';

  @override
  String get smsImport_clearHistoryWarning =>
      'पहले detect की गई notifications फिर से process होंगी';

  @override
  String get smsImport_tapAgainSettings =>
      'System settings खोलने के लिए फिर टैप करें';

  @override
  String get upgrade_purchaseFailed =>
      'खरीदारी विफल हुई। कृपया पुनः प्रयास करें।';

  @override
  String get upgrade_purchasePending =>
      'Purchase pending। Payment पूरा होने पर Pro activate होगा।';

  @override
  String get upgrade_welcomePro => 'Pro में स्वागत है!';

  @override
  String get upgrade_allFeaturesUnlocked =>
      'सभी features unlock हो गए। आपके support के लिए धन्यवाद!';

  @override
  String get upgrade_startExploring => 'Explore शुरू करें';

  @override
  String get upgrade_yourProFeatures => 'आपके Pro features';

  @override
  String get upgrade_manageSubscription =>
      'Subscription manage करने के लिए Google Play Store > Subscriptions पर जाएं';

  @override
  String get upgrade_everythingInPro => 'Pro में सब कुछ';

  @override
  String get upgrade_chooseYourPlan => 'अपना plan चुनें';

  @override
  String get upgrade_yearly => 'वार्षिक';

  @override
  String get upgrade_save43 => '43% बचाएं';

  @override
  String get upgrade_monthly => 'मासिक';

  @override
  String get upgrade_continue => 'जारी रखें';

  @override
  String get upgrade_restorePurchases => 'Purchases restore करें';

  @override
  String get upgrade_renewsToday => 'आज renew होगा';

  @override
  String get upgrade_mudraManagerPro => 'Mudra Manager Pro';

  @override
  String get upgrade_unlockFullPower =>
      'अपने finances की पूरी ताकत unlock करें';

  @override
  String get day_monday => 'सोमवार';

  @override
  String get day_tuesday => 'मंगलवार';

  @override
  String get day_wednesday => 'बुधवार';

  @override
  String get day_thursday => 'गुरुवार';

  @override
  String get day_friday => 'शुक्रवार';

  @override
  String get day_saturday => 'शनिवार';

  @override
  String get day_sunday => 'रविवार';

  @override
  String get recap_dailySpending => 'दैनिक खर्च';

  @override
  String get recap_spendingPace => 'खर्च की गति';

  @override
  String get recap_recurringVsOneTime => 'नियमित vs एकबारगी';

  @override
  String get recap_topCategories => 'शीर्ष श्रेणियां';

  @override
  String get recap_mostFrequent => 'सबसे ज़्यादा बार';

  @override
  String get recap_incomeSources => 'आय के स्रोत';

  @override
  String get recap_byAccount => 'खाते के अनुसार';

  @override
  String get recap_budgetHealth => 'Budget स्वास्थ्य';

  @override
  String get recap_biggestExpenses => 'सबसे बड़े खर्च';

  @override
  String get recap_biggestIncome => 'सबसे बड़ी आय';

  @override
  String get recap_generating => 'तैयार हो रहा है...';

  @override
  String get recap_avgPerDay => 'औसत/दिन';

  @override
  String get recap_weekdayAvg => 'कार्यदिवस औसत';

  @override
  String get recap_weekendAvg => 'वीकेंड औसत';

  @override
  String get recap_budgets => 'बजट';

  @override
  String get recap_badges => 'बैज';

  @override
  String get recap_streak => 'Streak';

  @override
  String get recap_best => 'सर्वश्रेष्ठ';

  @override
  String get recap_savings => 'बचत';

  @override
  String get about_developerMode => 'Developer Mode सक्रिय!';

  @override
  String get about_couldNotOpenLink => 'लिंक नहीं खुल सका';

  @override
  String get about_title => 'बारे में';

  @override
  String get about_privacyDesc =>
      'सब कुछ आपके device पर रहता है। कोई account नहीं, कोई cloud नहीं।';

  @override
  String get about_legalTransparency => 'कानूनी और पारदर्शिता';

  @override
  String get about_privacyPolicy => 'Privacy Policy';

  @override
  String get about_privacyPolicyDesc => 'हम आपका data कैसे सुरक्षित रखते हैं';

  @override
  String get about_termsOfService => 'सेवा की शर्तें';

  @override
  String get about_termsDesc => 'App उपयोग की शर्तें';

  @override
  String get about_openSourceLicenses => 'Open Source Licenses';

  @override
  String get about_openSourceDesc =>
      'हमारे द्वारा उपयोग की गई third-party libraries';

  @override
  String get about_supportConnect => 'Support और Connect';

  @override
  String get about_checkForUpdates => 'Updates चेक करें';

  @override
  String get about_checkForUpdatesDesc => 'App version मैन्युअली चेक करें';

  @override
  String get about_latestVersion => 'आप latest version पर हैं';

  @override
  String get about_unableToCheck => 'Updates चेक नहीं हो सका';

  @override
  String get about_officialWebsite => 'आधिकारिक वेबसाइट';

  @override
  String get about_visitWebsite => 'mudramanager.com पर जाएं';

  @override
  String get about_contactSupport => 'Support से संपर्क करें';

  @override
  String get about_contactSupportDesc => 'मदद लें या समस्या बताएं';

  @override
  String get about_rateApp => 'App को Rate करें';

  @override
  String get about_rateAppDesc => 'Store पर अपना अनुभव साझा करें';

  @override
  String get about_developerModeSection => 'Developer Mode';

  @override
  String get about_mudraManager => 'Mudra Manager';

  @override
  String get about_secureFinancial => 'सुरक्षित वित्तीय नियंत्रण';

  @override
  String get about_loadingLicenses => 'Licenses लोड हो रहे हैं...';

  @override
  String get appearance_title => 'दिखावट';

  @override
  String get appearance_themeMode => 'Theme Mode';

  @override
  String get appearance_display => 'Display';

  @override
  String get appearance_toneVoice => 'Tone और Voice';

  @override
  String get appearance_changesApplyInstantly =>
      'Theme और display बदलाव तुरंत लागू होते हैं।';

  @override
  String get appearance_darkAppearance => 'Dark दिखावट';

  @override
  String get appearance_lightAppearance => 'Light दिखावट';

  @override
  String get appearance_accountStyle => 'Account शैली';

  @override
  String get appearance_cards => 'Cards';

  @override
  String get appearance_stack => 'Stack';

  @override
  String get appearance_bento => 'Bento';

  @override
  String get appearance_highContrast => 'High Contrast';

  @override
  String get appearance_highContrastDesc =>
      'कम दृष्टि के लिए पठनीयता बेहतर करता है';

  @override
  String get appearance_guestMode => 'Guest Mode';

  @override
  String get appearance_guestModeOnDesc => 'असली राशि छुपी हुई है';

  @override
  String get appearance_guestModeOffDesc => 'संवेदनशील वित्तीय data छुपाएं';

  @override
  String get appearance_lightMode => 'Light Mode';

  @override
  String get appearance_darkMode => 'Dark Mode';

  @override
  String get appearance_systemDefault => 'System Default';

  @override
  String get analytics_financialHealthScore => 'वित्तीय स्वास्थ्य Score';

  @override
  String get analytics_savingsRate => 'बचत दर';

  @override
  String get analytics_expenseRatio => 'खर्च अनुपात';

  @override
  String get analytics_insights => 'जानकारी';

  @override
  String get analytics_spendingPrediction => 'खर्च का अनुमान';

  @override
  String get analytics_nextMonth => 'अगला महीना';

  @override
  String get analytics_basedOnAvg => 'पिछले 3 महीनों के औसत पर आधारित';

  @override
  String get analytics_categoryTrends => 'श्रेणी रुझान';

  @override
  String get analytics_spendingByDay => 'दिन के हिसाब से खर्च';

  @override
  String get trip_notFound => 'Trip नहीं मिली';

  @override
  String get trip_notFoundMsg => 'Trip नहीं मिली';

  @override
  String get trip_tripLabel => 'Trip';

  @override
  String get trip_groupLabel => 'Group';

  @override
  String get trip_archiveTripTitle => 'Trip Archive करें';

  @override
  String get trip_archiveMsg =>
      'यह trip archive हो जाएगी। सारा data और settlement सुरक्षित रहेगा।';

  @override
  String get trip_archiveConfirm => 'Archive करें';

  @override
  String get trip_totalSpent => 'कुल खर्च';

  @override
  String get trip_splitExpense => 'खर्च बांटें';

  @override
  String get trip_allPeople => 'सभी लोग';

  @override
  String get trip_allCategories => 'सभी श्रेणियां';

  @override
  String get trip_uncategorized => 'बिना श्रेणी';

  @override
  String get trip_removeExpense => 'खर्च हटाएं';

  @override
  String get trip_removeFromTrip => 'इस खर्च को trip से हटाएं?';

  @override
  String get trip_removeFromGroup => 'इस खर्च को group से हटाएं?';

  @override
  String get trip_removeConfirm => 'हटाएं';

  @override
  String get trip_unknown => 'अज्ञात';

  @override
  String get trip_youPaid => 'आपने दिया';

  @override
  String get trip_noPendingSettlements =>
      'इस trip के लिए कोई pending settlement नहीं';

  @override
  String get trip_everyoneSquare => 'सबका हिसाब बराबर';

  @override
  String get trip_archiveGroupTitle => 'Group Archive करें';

  @override
  String get trip_archiveGroupMsg =>
      'यह group archive हो जाएगा। सारा data और settlement सुरक्षित रहेगा।';

  @override
  String get editTrip_addParticipant => 'प्रतिभागी जोड़ें';

  @override
  String get editTrip_name => 'नाम';

  @override
  String get editTrip_enterName => 'प्रतिभागी का नाम दर्ज करें';

  @override
  String get editTrip_finalizeTrip => 'Trip अंतिम करें';

  @override
  String get editTrip_closeGroup => 'Group बंद करें';

  @override
  String get editTrip_finalizeMsg =>
      'Trip समाप्त हो जाएगी। इसके बाद खर्च नहीं जोड़ सकते।';

  @override
  String get editTrip_closeGroupMsg =>
      'यह group बंद हो जाएगा। इसके बाद खर्च नहीं जोड़ सकते।';

  @override
  String get editTrip_finalize => 'अंतिम करें';

  @override
  String get editTrip_close => 'बंद करें';

  @override
  String get editTrip_groupNotFound => 'Group नहीं मिला';

  @override
  String get editTrip_groupNotFoundMsg => 'Group नहीं मिला';

  @override
  String get editTrip_editTrip => 'Trip संपादित करें';

  @override
  String get editTrip_editGroup => 'Group संपादित करें';

  @override
  String get editTrip_editSplitGroup => 'Split Group संपादित करें';

  @override
  String get editTrip_createTrip => 'Trip बनाएं';

  @override
  String get editTrip_createSplitGroup => 'Split Group बनाएं';

  @override
  String get editTrip_travelTrip => 'Travel Trip';

  @override
  String get editTrip_splitGroup => 'Split Group';

  @override
  String get editTrip_tripDetails => 'Trip विवरण';

  @override
  String get editTrip_groupDetails => 'Group विवरण';

  @override
  String get editTrip_tripName => 'Trip का नाम';

  @override
  String get editTrip_groupName => 'Group का नाम';

  @override
  String get editTrip_descriptionOptional => 'विवरण (वैकल्पिक)';

  @override
  String get editTrip_tripHint => 'दोस्तों के साथ beach vacation';

  @override
  String get editTrip_groupHint => 'दोस्तों के साथ खर्च बांटें';

  @override
  String get editTrip_budgetOptional => 'Budget (वैकल्पिक)';

  @override
  String get editTrip_currency => 'मुद्रा';

  @override
  String get editTrip_baseCurrencyDefault => 'Base currency (default)';

  @override
  String get editTrip_duration => 'अवधि';

  @override
  String get editTrip_warningDateChange => 'चेतावनी: तारीख बदलाव';

  @override
  String get expense_notFound => 'नहीं मिला';

  @override
  String get expense_notFoundMsg => 'खर्च नहीं मिला';

  @override
  String get expense_details => 'खर्च विवरण';

  @override
  String get expense_paidBy => 'किसने दिया';

  @override
  String get expense_you => 'You';

  @override
  String get expense_yourShare => 'आपका हिस्सा';

  @override
  String get expense_noteLabel => 'नोट';

  @override
  String get expense_editSplit => 'Split संपादित करें';

  @override
  String get expense_splitType => 'Split प्रकार';

  @override
  String get expense_equal => 'बराबर';

  @override
  String get expense_custom => 'कस्टम';

  @override
  String get expense_participants => 'प्रतिभागी';

  @override
  String get expense_autoFillRemaining => 'बाकी auto-fill करें';

  @override
  String get expense_deleteExpense => 'खर्च हटाएं';

  @override
  String get expense_deleteExpenseMsg => 'इससे सबका balance बदलेगा। जारी रखें?';

  @override
  String get billCenter_overdue => 'बकाया';

  @override
  String get billCenter_thisWeek => 'इस हफ्ते';

  @override
  String get billCenter_thisMonth => 'इस महीने';

  @override
  String get billCenter_later => 'बाद में';

  @override
  String get billCenter_totalUpcoming => 'कुल आगामी';

  @override
  String get billCenter_today => 'आज';

  @override
  String get billCenter_tomorrow => 'कल';

  @override
  String get billCenter_afterUpcoming => 'आगामी बिलों के बाद';

  @override
  String get billCenter_dueToday => 'आज देय';

  @override
  String get billCenter_paid => 'भुगतान किया';

  @override
  String get billCenter_pay => 'Pay';

  @override
  String get billCenter_existingTxnFound => 'मौजूदा Transaction मिला';

  @override
  String get billCenter_linkTransaction => 'यह Transaction जोड़ें';

  @override
  String get billCenter_createNewEntry => 'नई Entry बनाएं';

  @override
  String get comparison_steady => 'स्थिर चल रहा है';

  @override
  String get comparison_steadyDesc => 'आपका खर्च एक जैसा है — यही अनुशासन है।';

  @override
  String get comparison_doingGreat => 'बहुत अच्छा कर रहे हैं';

  @override
  String get comparison_headsUp => 'ध्यान दें — खर्च बढ़ा है';

  @override
  String get reconcile_title => 'मिलान करें';

  @override
  String get reconcile_info =>
      'अपने बैंक ऐप या पासबुक में दिखाई गई वर्तमान शेष राशि दर्ज करें। हम अंतर को स्वचालित रूप से समायोजित करेंगे।';

  @override
  String get reconcile_balanceInApp => 'ऐप में शेष';

  @override
  String get reconcile_actualBalance => 'वास्तविक बैंक शेष';

  @override
  String get reconcile_balanced => 'संतुलित!';

  @override
  String get reconcile_difference => 'अंतर';

  @override
  String reconcile_incomeAdjustment(String amount) {
    return '$amount का आय समायोजन जोड़ा जाएगा।';
  }

  @override
  String reconcile_expenseAdjustment(String amount) {
    return '$amount का व्यय समायोजन जोड़ा जाएगा।';
  }

  @override
  String get balanceHistory_currentBalance => 'वर्तमान शेष';

  @override
  String get balanceHistory_highest => 'सर्वाधिक';

  @override
  String get balanceHistory_lowest => 'न्यूनतम';

  @override
  String get balanceHistory_average => 'औसत';

  @override
  String get common_errorLoading => 'डेटा लोड करने में विफल';

  @override
  String get balanceHistory_trend => '30 दिन का रुझान';

  @override
  String get balanceHistory_growing => 'आपका बैलेंस बढ़ रहा है 📈';

  @override
  String get balanceHistory_declining => 'बैलेंस कम हुआ है — रिकवर करें 💪';

  @override
  String get balanceHistory_steady => 'स्थिर बना हुआ है ⚖️';

  @override
  String get account_editTitle => 'खाता संपादित करें';

  @override
  String get account_newTitle => 'नया खाता';

  @override
  String get account_name => 'खाते का नाम';

  @override
  String get account_typeLabel => 'खाता प्रकार';

  @override
  String get account_detailsLabel => 'विवरण';

  @override
  String get account_colorLabel => 'रंग';

  @override
  String get account_currencyLabel => 'मुद्रा';

  @override
  String get account_balance => 'शेष';

  @override
  String get account_outstanding => 'बकाया';

  @override
  String get account_last4 => 'अंतिम 4 अंक';

  @override
  String get account_last4Helper => 'SMS ऑटो-मैचिंग के लिए';

  @override
  String get account_initialBalance => 'प्रारंभिक शेष';

  @override
  String get account_cardPaidOff => 'कार्ड चुका हो तो 0 दर्ज करें';

  @override
  String get account_min4 => 'कम से कम 4 अंक';

  @override
  String get account_max4 => 'केवल अंतिम 4 अंक';

  @override
  String get iconPicker_title => 'आइकॉन चुनें';

  @override
  String get iconPicker_search => 'आइकॉन खोजें...';

  @override
  String get iconPicker_noResults => 'कोई आइकॉन नहीं मिला';

  @override
  String get colorPicker_title => 'रंग चुनें';

  @override
  String get color_red => 'लाल';

  @override
  String get color_pink => 'गुलाबी';

  @override
  String get color_purple => 'बैंगनी';

  @override
  String get color_indigo => 'नील';

  @override
  String get color_blue => 'नीला';

  @override
  String get color_cyan => 'सायन';

  @override
  String get color_teal => 'टील';

  @override
  String get color_green => 'हरा';

  @override
  String get color_orange => 'नारंगी';

  @override
  String get color_brown => 'भूरा';

  @override
  String get color_grey => 'सलेटी';

  @override
  String get accounts_totalBalance => 'कुल शेष';

  @override
  String get accounts_accountsCount => 'खाते';

  @override
  String get accounts_archived => 'संग्रहित';

  @override
  String get accounts_howItWorks => 'खाते कैसे काम करते हैं';

  @override
  String get accounts_howItWorksDesc =>
      'अपने सभी बैंक खाते, वॉलेट और नकद एक जगह प्रबंधित करें। कई खातों में शेष और लेनदेन ट्रैक करें।';

  @override
  String get accounts_primary => 'प्राथमिक';

  @override
  String get categories_label => 'श्रेणियाँ';

  @override
  String get categories_transactionsLabel => 'लेनदेन';

  @override
  String categories_deleteWithTransactions(String name, int count) {
    return 'यह \"$name\" और $count जुड़े लेनदेन स्थायी रूप से हटा देगा। यह क्रिया वापस नहीं हो सकती।';
  }

  @override
  String get categories_deleteAll => 'सब हटाएं';

  @override
  String get categories_edit => 'श्रेणी संपादित करें';

  @override
  String get categories_delete => 'श्रेणी हटाएं';

  @override
  String get categories_deleteSubtitle => 'सभी जुड़े लेनदेन हटा देता है';

  @override
  String get category_save => 'सहेजें';

  @override
  String get category_detailsLabel => 'विवरण';

  @override
  String get category_parentLabel => 'मूल श्रेणी';

  @override
  String get category_nameHint => 'श्रेणी का नाम';

  @override
  String get category_keywordsHint => 'कीवर्ड (अल्पविराम से अलग)';

  @override
  String get category_keywordsHelper => 'SMS ऑटो-डिटेक्शन के लिए';

  @override
  String get currency_title => 'मुद्रा';

  @override
  String get currency_baseCurrency => 'मूल मुद्रा';

  @override
  String get currency_baseDescription =>
      'सभी कुल, बजट और विश्लेषण इस मुद्रा का उपयोग करते हैं।';

  @override
  String get currency_exchangeRates => 'विनिमय दरें';

  @override
  String get currency_exchangeRatesDesc =>
      'रूपांतरण दरें देखें और संपादित करें';

  @override
  String get currency_archivedDesc => 'पिछली मुद्राओं के लेनदेन देखें';

  @override
  String exchange_unitInfo(String base) {
    return 'विदेशी मुद्रा की 1 इकाई = X $base। संपादित करने के लिए टैप करें।';
  }

  @override
  String get exchange_search => 'मुद्रा खोजें...';

  @override
  String exchange_rateUpdated(String code) {
    return '$code दर अपडेट हो गई';
  }

  @override
  String exchange_editRate(String code) {
    return '$code दर संपादित करें';
  }

  @override
  String get exchange_rateLabel => 'दर';

  @override
  String get exchange_invalidRate => 'एक वैध दर दर्ज करें';

  @override
  String get archived_transaction => 'लेनदेन';

  @override
  String get currency_changingCurrency => 'मुद्रा बदल रही है...';

  @override
  String get currency_pleaseWait =>
      'लेनदेन संग्रहित और सेटिंग्स अपडेट हो रही हैं';

  @override
  String get security_title => 'सुरक्षा';

  @override
  String get security_unprotected => 'असुरक्षित';

  @override
  String get security_basic => 'बुनियादी';

  @override
  String get security_strong => 'मजबूत';

  @override
  String get security_unprotectedDesc =>
      'अपने डेटा की सुरक्षा के लिए PIN या बायोमेट्रिक्स सक्षम करें';

  @override
  String security_protectionsActive(int count, int total) {
    return '$total में से $count सुरक्षा सक्रिय';
  }

  @override
  String get security_authentication => 'प्रमाणीकरण';

  @override
  String get security_pinLock => 'PIN लॉक';

  @override
  String get security_pinActive => '4 अंकों का PIN सक्रिय';

  @override
  String get security_pinSet => '4 अंकों का PIN सेट करें';

  @override
  String get security_biometric => 'बायोमेट्रिक अनलॉक';

  @override
  String get security_biometricDesc => 'फिंगरप्रिंट या Face ID';

  @override
  String get security_manage => 'प्रबंधन';

  @override
  String get security_changePin => 'PIN बदलें';

  @override
  String get security_changePinDesc => 'अपना 4 अंकों का PIN अपडेट करें';

  @override
  String get security_enablePinFirst => 'पहले PIN सक्षम करें';

  @override
  String get security_biometricEnabled => 'बायोमेट्रिक सक्षम';

  @override
  String get security_biometricDisabled => 'बायोमेट्रिक अक्षम';

  @override
  String get security_infoText =>
      'आपका PIN इस डिवाइस पर सुरक्षित रूप से संग्रहित है — यह कभी सर्वर तक नहीं पहुँचता।';

  @override
  String notifSettings_activeCount(int count) {
    return '3 में से $count सक्रिय';
  }

  @override
  String get notifSettings_summaryDesc =>
      'सारांश में खर्च, आय, शीर्ष श्रेणी और शेष दिखाता है';

  @override
  String get notifSettings_dailySummaryDesc => 'कल के खर्च का सारांश';

  @override
  String notifSettings_weeklySchedule(String day) {
    return 'हर $day सुबह 9:00 बजे';
  }

  @override
  String get smsImport_autoImporting => 'लेनदेन ऑटोमैटिक import हो रहे हैं';

  @override
  String get smsImport_enableToStart =>
      'Auto import सक्षम करें tracking शुरू करने के लिए';

  @override
  String get smsImport_iosRestriction =>
      'iOS प्लेटफॉर्म की सीमाओं के कारण Auto import केवल Android पर उपलब्ध है।';

  @override
  String get common_change => 'बदलें';

  @override
  String get goal_whatSavingFor => 'किसलिए बचत कर रहे हैं?';

  @override
  String get netWorth_totalLabel => 'कुल Net Worth';

  @override
  String get netWorth_notEnoughData => 'अभी पर्याप्त data नहीं';

  @override
  String get netWorth_assets => 'संपत्ति';

  @override
  String get netWorth_liabilities => 'देनदारी';

  @override
  String get netWorth_composition => 'संपत्ति संरचना';

  @override
  String get goal_milestoneStarted => 'शुरुआत';

  @override
  String get goal_milestoneStartedDesc => 'आपकी यात्रा शुरू हुई';

  @override
  String get goal_milestone25 => '25%';

  @override
  String get goal_milestone25Desc => 'एक चौथाई पूरा';

  @override
  String get goal_milestone50 => '50%';

  @override
  String get goal_milestone50Desc => 'आधा पूरा!';

  @override
  String get goal_milestone75 => '75%';

  @override
  String get goal_milestone75Desc => 'लगभग पहुंच गए';

  @override
  String get goal_milestone100 => '100%';

  @override
  String get goal_milestone100Desc => 'Goal पूरा हुआ! 🎉';

  @override
  String get goal_flexibleTimeline => 'लचीली समयसीमा';

  @override
  String get goal_amount => 'राशि';

  @override
  String get goal_emotionReached => 'Goal पूरा हो गया! 🎉';

  @override
  String get goal_emotionProgress => 'बढ़िया progress ✨';

  @override
  String goal_emotionMoreToGo(Object amount) {
    return 'बस $amount और चाहिए 💪';
  }

  @override
  String get goal_emotionSetTarget => 'Target सेट करें 🎯';

  @override
  String get goal_emotionWhatSaving => 'किसके लिए बचत कर रहे हैं?';

  @override
  String get goal_exceededTarget => 'Target से ज़्यादा बचा लिया! 🎉';

  @override
  String get goal_alreadyReached => 'Goal पहले से पूरा है! 🎉';

  @override
  String goal_progressLeft(Object percent, Object amount) {
    return '$percent% हो गया • $amount बाकी';
  }

  @override
  String goal_paceDaily(Object daily, Object monthly) {
    return 'इस रफ़्तार से $daily/दिन चाहिए।\nयानी $monthly/महीना।';
  }

  @override
  String goal_daysRemaining(Object count) {
    return '$count दिन बाकी';
  }

  @override
  String goal_daysLeft(Object count) {
    return '$count दिन बचे हैं';
  }

  @override
  String goal_startSaving(Object amount) {
    return '$amount बचाना शुरू करें';
  }

  @override
  String goal_goalsInProgress(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count goals चल रहे हैं',
      one: '1 goal चल रहा है',
    );
    return '$_temp0';
  }

  @override
  String get goal_completedSection => 'पूरा हो गया 🎉';

  @override
  String get goal_emotionAlmost => 'बस थोड़ा और 🚀';

  @override
  String get goal_emotionHalfway => 'आधा रास्ता 💪';

  @override
  String get goal_emotionEvery => 'हर बूंद मायने रखती है 🌱';

  @override
  String get goal_emotionHalfwayDone => 'आधा हो गया ✨';

  @override
  String get goal_emotionKeepPushing => 'जारी रखो 🔥';

  @override
  String get goal_emotionJustStarted => 'अभी शुरू हुआ है 🌱';

  @override
  String get goal_closestToCompletion => 'पूरा होने के सबसे करीब';

  @override
  String goal_acrossGoals(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count goals में',
      one: '1 goal में',
    );
    return '$_temp0';
  }

  @override
  String get goal_suffixSaved => 'बचाया';

  @override
  String get goal_suffixLeft => 'बाकी';

  @override
  String get goal_suffixDone => 'हो गया';

  @override
  String get goal_suffixAchieved => 'पूरा किया';

  @override
  String get goal_suffixToGo => 'और चाहिए';

  @override
  String get goal_needsAttention => 'ध्यान दें ⚠️';

  @override
  String get goal_aheadOfSchedule => 'समय से आगे 🎯';

  @override
  String goal_monthsLeft(Object count) {
    return '$count महीने बाकी';
  }

  @override
  String get goal_emotionDidIt => 'आपने कर दिखाया! 🎉';

  @override
  String get goal_emotionSoClose => 'बहुत करीब, जारी रखो! 💪';

  @override
  String get goal_emotionMomentum => 'रफ़्तार बन रही है 🔥';

  @override
  String get goal_emotionCatchUp => 'चलो पकड़ते हैं ⚡';

  @override
  String get goal_finishGoal => 'यह goal पूरा करो! 🚀';

  @override
  String get goal_behindPace => 'पीछे चल रहा है ⚠️';

  @override
  String goal_daysAgo(Object count) {
    return '$count दिन पहले';
  }

  @override
  String get common_today => 'आज';

  @override
  String get common_yesterday => 'कल';

  @override
  String get common_amount => 'राशि';

  @override
  String get accounts_edit => 'खाता संपादित करें';

  @override
  String get accounts_balanceHistory => 'शेष इतिहास';

  @override
  String get accounts_matchBank => 'Bank statement से मिलाएं';

  @override
  String get accounts_viewPortfolio => 'Portfolio देखें';

  @override
  String get accounts_setAsPrimary => 'प्राथमिक बनाएं';

  @override
  String get accounts_primaryDesc => 'Splits और trips के लिए default खाता';

  @override
  String get accounts_archive => 'Archive करें';

  @override
  String get accounts_archiveDesc => 'सक्रिय खातों से छुपाएं';

  @override
  String get accounts_unarchive => 'Unarchive करें';

  @override
  String get accounts_unarchiveDesc => 'सक्रिय खातों में वापस लाएं';

  @override
  String get accounts_deleteDesc => 'खाता स्थायी रूप से हटाएं';

  @override
  String get smsActivity_title => 'Transaction Activity';

  @override
  String get smsActivity_approved => 'स्वीकृत';

  @override
  String get smsActivity_pending => 'लंबित';

  @override
  String get smsActivity_rejected => 'अस्वीकृत';

  @override
  String get smsActivity_needsReview => 'Review ज़रूरी';

  @override
  String get smsActivity_duplicates => 'डुप्लीकेट';

  @override
  String get smsActivity_filterByStatus => 'Status से filter करें';

  @override
  String smsActivity_transactionCount(Object count) {
    return '$count Transactions';
  }

  @override
  String smsActivity_needsAttention(Object count) {
    return '$count पर ध्यान दें';
  }

  @override
  String smsActivity_resultCount(Object count) {
    return '$count परिणाम';
  }

  @override
  String get smsActivity_noActivities => 'कोई मिलती-जुलती activity नहीं';

  @override
  String get smsActivity_status => 'Status';

  @override
  String get smsActivity_confidence => 'विश्वसनीयता';

  @override
  String get smsActivity_account => 'खाता';

  @override
  String get smsActivity_bank => 'Bank';

  @override
  String get smsActivity_type => 'प्रकार';

  @override
  String get smsActivity_merchant => 'Merchant';

  @override
  String get smsActivity_balance => 'शेष';

  @override
  String get smsActivity_reference => 'Reference';

  @override
  String get smsActivity_duplicateLabel => 'DUPLICATE';

  @override
  String get smsActivity_transferLabel => 'TRANSFER';

  @override
  String get smsActivity_reject => 'अस्वीकार';

  @override
  String get smsActivity_approve => 'स्वीकार';

  @override
  String get smsActivity_transfer => 'Transfer';

  @override
  String get smsActivity_addAccount => 'खाता जोड़ें';

  @override
  String get smsActivity_duplicateWarning =>
      'यह duplicate transaction हो सकता है। Approve करने से पहले ध्यान से देखें।';

  @override
  String smsActivity_noAccountWarning(Object account) {
    return '\"$account\" से मिलता खाता नहीं मिला। Approve करने के लिए पहले जोड़ें।';
  }

  @override
  String get smsActivity_transferWarning =>
      'यह आपके खातों के बीच transfer लगता है। Approve करने पर transfer screen खुलेगा।';

  @override
  String get common_all => 'सभी';

  @override
  String get backup_lastBackup => 'आखिरी backup';

  @override
  String get backup_noBackups => 'अभी कोई backup नहीं';

  @override
  String get backup_createFirst =>
      'अपना data सुरक्षित करने के लिए पहला backup बनाएं';

  @override
  String get backup_actions => 'कार्रवाई';

  @override
  String get backup_history => 'इतिहास';

  @override
  String get backup_noHistory => 'कोई backup इतिहास नहीं';

  @override
  String get backup_infoText =>
      'Backups आपके password से encrypt होकर .mudra files में save होते हैं। Password सुरक्षित रखें — इसे recover नहीं किया जा सकता।';

  @override
  String get backup_justNow => 'अभी-अभी';

  @override
  String backup_minutesAgo(int count) {
    return '$count मिनट पहले';
  }

  @override
  String backup_hoursAgo(int count) {
    return '$count घंटे पहले';
  }

  @override
  String backup_daysAgo(int count) {
    return '$count दिन पहले';
  }

  @override
  String backup_recordCount(int count) {
    return '$count records';
  }

  @override
  String get account_changeCurrency => 'मुद्रा बदलें?';

  @override
  String account_resetTo(String code) {
    return '$code पर reset करें';
  }

  @override
  String get account_baseCurrencyInfo =>
      'इस खाते के transactions आपकी base currency में हैं।';

  @override
  String account_foreignCurrencyInfo(String code, String base) {
    return 'Transactions $code में record होंगे और $base में convert होंगे।';
  }

  @override
  String get account_warningNoConvert =>
      'मौजूदा balance अपने आप convert नहीं होगा।';

  @override
  String get account_warningNewCurrency =>
      'नए transactions नई मुद्रा में होंगे।';

  @override
  String get account_warningManualAdjust =>
      'आपको balance मैन्युअली adjust करना पड़ सकता है।';

  @override
  String get category_selectParent => 'मूल श्रेणी चुनें';

  @override
  String get appearance_colorTheme => 'Color Theme';

  @override
  String get appearance_amoledMode => 'AMOLED Mode';

  @override
  String appearance_toneActivated(String name) {
    return '$name tone सक्रिय';
  }

  @override
  String dashboard_cardsActive(int visible, int total) {
    return '$total में से $visible cards सक्रिय';
  }

  @override
  String get dashboard_dragToReorder =>
      'क्रम बदलने के लिए drag करें, दिखाने/छुपाने के लिए toggle करें';

  @override
  String get dashboard_smartOrdering => 'Smart क्रम';

  @override
  String get dashboard_catEssential => 'ज़रूरी';

  @override
  String get dashboard_catFinance => 'वित्त';

  @override
  String get dashboard_catAnalytics => 'विश्लेषण';

  @override
  String get dashboard_catActions => 'कार्रवाई';

  @override
  String get dashboard_catAI => 'AI जानकारी';

  @override
  String get dashboard_catContextual => 'संदर्भ आधारित';

  @override
  String get importExport_title => 'Import और Export';

  @override
  String get importExport_export => 'Export';

  @override
  String get importExport_import => 'Import';

  @override
  String get importExport_exportTitle => 'Transactions Export करें';

  @override
  String get importExport_exportDesc =>
      'अपने transactions Excel file में download करें।';

  @override
  String get importExport_exporting => 'Export हो रहा है...';

  @override
  String get importExport_exportAsExcel => 'Excel में Export करें';

  @override
  String get importExport_importTitle => 'Excel से Import करें';

  @override
  String get importExport_importDesc =>
      '.xlsx file से transactions import करें। Import से पहले preview और column mapping कर सकते हैं।';

  @override
  String get importExport_excelFormat => 'Excel (.xlsx)';

  @override
  String get importExport_bankStatement => 'Bank Statement';

  @override
  String get importExport_otherApps => 'अन्य Apps';

  @override
  String get importExport_pickFile => 'Excel File चुनें';

  @override
  String get importExport_infoText =>
      'Export सभी transaction details के साथ Excel file बनाता है। Import अन्य finance apps या manual spreadsheets से .xlsx files support करता है।';

  @override
  String get plugins_subtitle => 'Mudra Manager को powerful plugins से बढ़ाएं';

  @override
  String get plugins_official => 'Official';

  @override
  String plugins_enabled(String name) {
    return '$name सक्षम';
  }

  @override
  String plugins_disabled(String name) {
    return '$name अक्षम';
  }

  @override
  String get plugins_configure => 'Plugin configure करें';

  @override
  String plugins_activeCount(int active, int total) {
    return '$total में से $active सक्रिय';
  }

  @override
  String get plugins_toggleDesc =>
      'App features बढ़ाने के लिए plugins toggle करें';

  @override
  String get plugins_default => 'Default';

  @override
  String get plugins_configureSettings => 'Plugin settings configure करें';

  @override
  String get plugins_creditCardReminders => 'Credit Card Reminders';

  @override
  String get plugins_remindBefore => 'कितने दिन पहले याद दिलाएं';

  @override
  String get plugins_noCreditCards =>
      'कोई credit card account नहीं मिला। पहले एक जोड़ें।';

  @override
  String get plugins_creditCardAccounts => 'Credit Card खाते';

  @override
  String get plugins_billDay => 'Bill Day (1-31)';

  @override
  String get plugins_remindersConfigured => 'Credit card reminders set हो गए';

  @override
  String get plugins_infoText =>
      'Plugins app features बढ़ाते हैं। कुछ plugins को अतिरिक्त permissions या configuration चाहिए।';

  @override
  String get help_title => 'मदद और सहायता';

  @override
  String get help_searchHint => 'Help topics खोजें...';

  @override
  String get help_heroTitle => 'हम कैसे मदद कर सकते हैं?';

  @override
  String get help_heroDesc => 'Guides देखें या कोई topic खोजें';

  @override
  String get help_topics => 'विषय';

  @override
  String get help_tryDifferent => 'कोई और शब्द आज़माएं';

  @override
  String get help_howToUse => 'कैसे इस्तेमाल करें';

  @override
  String get help_tips => 'सुझाव';

  @override
  String help_articleCount(int count) {
    return '$count लेख';
  }

  @override
  String help_resultCount(int count) {
    return '$count परिणाम';
  }

  @override
  String get help_infoText =>
      'जो चाहिए वो नहीं मिला? About → Contact Support पर जाएं।';

  @override
  String get about_legalCount => '3 आइटम';

  @override
  String get about_supportCount => '4 आइटम';

  @override
  String about_packageCount(int count) {
    return '$count open source packages';
  }

  @override
  String get onboard_continue => 'आगे बढ़ें';

  @override
  String get onboard_restoreFromBackup => 'Backup से restore करें';

  @override
  String get onboard_accountNameRequired => 'खाते का नाम ज़रूरी है';

  @override
  String get onboard_balanceRequired => 'शेष ज़रूरी है';

  @override
  String get onboard_enterValidNumber => 'सही नंबर दर्ज करें';

  @override
  String get onboard_accountHint => 'जैसे Cash, Bank';

  @override
  String get onboard_browseAllCurrencies => 'सभी मुद्राएं देखें';

  @override
  String get onboard_toneTitle => 'Mudra आपसे कैसे बात करे?';

  @override
  String get onboard_toneDesc => 'एक शैली चुनें। बाद में बदल सकते हैं।';

  @override
  String get onboard_categoriesTitle => 'अपनी श्रेणियां चुनें';

  @override
  String get onboard_categoriesDesc =>
      'अपनी जीवनशैली से मिलते packs चुनें। बाद में बदल सकते हैं।';

  @override
  String get onboard_startFresh => 'नए सिरे से शुरू';

  @override
  String get onboard_startFreshDesc => 'कोई श्रेणी नहीं — बाद में खुद जोड़ें';

  @override
  String get onboard_currencyWarning =>
      'बाद में base currency बदलने पर मौजूदा transactions archive हो जाएंगे।';
}
