// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get onboard_manageYourMoneyDescription =>
      'अपने पैसे को स्मार्ट तरीके से और सहजता से प्रबंधित करें।';

  @override
  String onboard_welcomeToApp(Object appName) {
    return ' $appName में आपका स्वागत है';
  }

  @override
  String get onboard_TrackYourTransactions => 'अपने लेनदेन को ट्रैक करें';

  @override
  String get onboard_SeeWhereYourMoneyGoes =>
      'देखें कि आपका पैसा कहाँ जाता है, हर दिन।';

  @override
  String get onboard_SetBudgetsAndGoals => 'बजट और लक्ष्य निर्धारित करें';

  @override
  String get onboard_stayOnTrackAndAchieveYourDream =>
      'पटरी पर रहें और अपने सपनों को प्राप्त करें।';

  @override
  String get onboard_GetStarted => 'शुरू हो जाओ!';

  @override
  String get onboard_letsSetupYourAccount => 'चलिए, आपका खाता सेट अप करते हैं।';

  @override
  String get onboard_howShouldWeCallYou => 'हम आपको कैसे बुलाएं?';

  @override
  String get onboard_enterYourNameToPersonalizeYourExperience =>
      'अपने अनुभव को व्यक्तिगत बनाने के लिए अपना नाम दर्ज करें।';

  @override
  String get onboard_enterYourName => 'अपना नाम दर्ज करें';

  @override
  String get onboard_setupYourFirstAccount => 'अपना पहला खाता सेटअप करें';

  @override
  String get onboard_letsCreateYourFirstAccount =>
      'आइए अपना पहला खाता बनाते हैं (मान लीजिए: नकद)।';

  @override
  String get onboard_accountName => 'खाते का नाम';

  @override
  String get onboard_initialBalance => 'शुरुआती शेष';

  @override
  String get onboard_youCanUpdateOtherDetailsLaterAsWell =>
      'आप बाद में भी अन्य विवरण अपडेट कर सकते हैं।';

  @override
  String onboard_pleaseFillThe(Object inputName) {
    return 'कृपया \"$inputName\" भरें';
  }

  @override
  String onboard_pleaseEnterAValidNumberFor(Object hintText) {
    return 'कृपया \"$hintText\" के लिए एक मान्य संख्या दर्ज करें';
  }

  @override
  String get onboard_youAreAllSet => 'आप सब तैयार हैं!';

  @override
  String get onboard_letsStartManagingYourMoneyWisely =>
      'आइए अपने पैसे का बुद्धिमानी से प्रबंधन करना शुरू करें।';

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
  String get app_settings_theme_mode_light => 'प्रकाश';

  @override
  String get app_settings_theme_mode_dark => 'गहरा';

  @override
  String get app_settings_theme_mode_system_default => 'सिस्टम डिफ़ॉल्ट';

  @override
  String get app_settings_theme_mode_amoled => 'AMOLED डार्क';

  @override
  String get app_settings_theme_mode_subtitle => 'अपनी पसंदीदा थीम चुनें';

  @override
  String get app_settings_daily_reminder_title => 'दैनिक व्यय अनुस्मारक';

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
  String get greeting_good_afternoon_text => 'सुसंध्या';

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
  String get dashboard_add_transfer_text => 'स्थानांतरण';

  @override
  String get dashboard_cash_flow_text => 'नकदी प्रवाह';

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
      'कोई बजट परिभाषित नहीं है, एक जोड़ें!';

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
      '⚡ नए लेनदेन मिले! अभी समीक्षा करें';

  @override
  String get transaction_listPendingTransactionMessageActionLabel => 'समीक्षा';

  @override
  String get transaction_noTransactionFoundText => 'कोई लेन-देन नहीं मिला।';

  @override
  String get transaction_deleteAlertTitleText => 'लेन-देन हटाएं?';

  @override
  String get transaction_deleteAlertBodyText =>
      'यह क्रिया पूर्ववत नहीं की जा सकती है।';

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
  String get dashboard_netWorthTitle => 'निवल मूल्य';

  @override
  String get budget_dashboardMiniCardBudgetTitleText => 'बजट';

  @override
  String get budget_dashboardMiniCardSpentTitleText => 'खर्च';

  @override
  String get budget_dashboardPageTitle => 'बजट विवरण';

  @override
  String get budget_dashboardNotFoundText =>
      'कोई बजट परिभाषित नहीं है, एक जोड़ें!';

  @override
  String get budget_dashboardAddBudgetText => 'बजट जोड़ें';

  @override
  String get budget_categoriesTitle => 'श्रेणियाँ';

  @override
  String budget_dashboardPieChartLabelText(
    Object spentPercent,
    Object title,
    Object totalPercent,
  ) {
    return '$title ($totalPercent कुल का, $spentPercent खर्च का)';
  }

  @override
  String get budget_buttonDeleteTitleText => 'बजट हटाएं?';

  @override
  String get budget_buttonDeleteBodyText =>
      'यह बजट और उसके आवंटन को हटा देगा, यह क्रिया पूर्ववत नहीं की जा सकती है।';

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
      'आप मैन्युअल रूप से श्रेणी आवंटन दर्ज कर सकते हैं, या शेष राशि को समान रूप से स्वतः वितरित करने के लिए उन्हें खाली छोड़ सकते हैं।';

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
      'हम दशमलव स्थानों को कम करते हैं, यदि आवश्यक हो तो राउंड ऑफ करें।';

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
      'हम कोई डेटा संग्रहीत नहीं कर रहे हैं, सारा डेटा आपके डिवाइस में है!';

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
  String get transfer_screenTitle => 'धन स्थानांतरण';

  @override
  String get transfer_resetTooltip => 'रीसेट';

  @override
  String get transfer_selectAccountsLabel => 'खाते चुनें';

  @override
  String get transfer_fromLabel => 'से';

  @override
  String get transfer_toLabel => 'को';

  @override
  String get transfer_detailsLabel => 'स्थानांतरण विवरण';

  @override
  String get transfer_amountLabel => 'राशि';

  @override
  String get transfer_amountValidationError => 'वैध राशि दर्ज करें';

  @override
  String get transfer_dateLabel => 'तारीख';

  @override
  String get transfer_noteLabel => 'नोट (वैकल्पिक)';

  @override
  String get transfer_buttonLabel => 'स्थानांतरण';

  @override
  String get transfer_updateButtonLabel => 'स्थानांतरण अपडेट करें';

  @override
  String get transfer_errorLoadingAccounts => 'खाते लोड करने में त्रुटि';

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
  String get common_loading => 'लोड हो रहा है';

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
}
