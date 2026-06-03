// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get onboard_manageYourMoneyDescription =>
      '100% hors ligne. Vos données ne quittent jamais votre appareil.';

  @override
  String onboard_welcomeToApp(Object appName) {
    return 'Bienvenue sur $appName';
  }

  @override
  String get onboard_TrackYourTransactions =>
      'Suivi automatique par SMS bancaire';

  @override
  String get onboard_SeeWhereYourMoneyGoes =>
      'Importation automatique des SMS et notifications bancaires. Fonctionne avec plus de 50 banques.';

  @override
  String get onboard_SetBudgetsAndGoals =>
      'Budgets, objectifs et alertes intelligentes';

  @override
  String get onboard_stayOnTrackAndAchieveYourDream =>
      'Recevez des avertissements avant de trop dépenser. Économisez pour ce qui compte.';

  @override
  String get onboard_GetStarted => 'Commencer !';

  @override
  String get onboard_letsSetupYourAccount => 'Configurons votre compte.';

  @override
  String get onboard_howShouldWeCallYou =>
      'Comment devrions-nous vous appeler ?';

  @override
  String get onboard_enterYourNameToPersonalizeYourExperience =>
      'Entrez votre nom pour personnaliser votre expérience.';

  @override
  String get onboard_enterYourName => 'Entrez votre nom';

  @override
  String get onboard_setupYourFirstAccount => 'Configurez votre premier compte';

  @override
  String get onboard_letsCreateYourFirstAccount =>
      'Créons votre premier compte (disons : Espèces).';

  @override
  String get onboard_accountName => 'Nom du compte';

  @override
  String get onboard_initialBalance => 'Solde initial';

  @override
  String get onboard_youCanUpdateOtherDetailsLaterAsWell =>
      'Vous pourrez également mettre à jour d\'autres détails plus tard.';

  @override
  String onboard_pleaseFillThe(Object inputName) {
    return 'Veuillez remplir le champ \"$inputName\"';
  }

  @override
  String onboard_pleaseEnterAValidNumberFor(Object hintText) {
    return 'Veuillez entrer un nombre valide pour \"$hintText\"';
  }

  @override
  String get onboard_youAreAllSet => 'Tout est prêt !';

  @override
  String get onboard_letsStartManagingYourMoneyWisely =>
      'Commençons à gérer votre argent judicieusement.';

  @override
  String get app_settings_appbar_title => 'Paramètres de l\'application';

  @override
  String get language_settings_appbar_title => 'Choisir la langue';

  @override
  String get app_settings_language_title => 'Langue';

  @override
  String get app_settings_language_subtitle => 'Choisissez votre langue';

  @override
  String get app_settings_theme_mode_title => 'Mode thématique';

  @override
  String get app_settings_theme_mode_light => 'Clair';

  @override
  String get app_settings_theme_mode_dark => 'Sombre';

  @override
  String get app_settings_theme_mode_system_default => 'Par défaut du système';

  @override
  String get app_settings_theme_mode_amoled => 'AMOLED';

  @override
  String get app_settings_theme_mode_subtitle =>
      'Choisissez votre thème préféré';

  @override
  String get app_settings_daily_reminder_title =>
      'Rappel de dépenses quotidiennes';

  @override
  String get home_screen_title => 'Accueil';

  @override
  String get transaction_screen_title => 'Activité';

  @override
  String get statistics_screen_title => 'Statistiques';

  @override
  String get profile_screen_title => 'Profil';

  @override
  String get add_edit_transaction_screen_title => 'Ajouter une transaction';

  @override
  String get transaction_list_screen_title => 'Liste des transactions';

  @override
  String get transaction_listViewGroupTodayLabel => 'Aujourd\'hui';

  @override
  String get transaction_listViewGroupYesterdayLabel => 'Hier';

  @override
  String get greeting_good_morning_text => 'Bonjour';

  @override
  String get greeting_good_afternoon_text => 'Bon après-midi';

  @override
  String get greeting_good_evening_text => 'Bonsoir';

  @override
  String get greeting_good_night_text => 'Bonne nuit';

  @override
  String get greeting_hello_text => 'Bonjour';

  @override
  String get transaction_type_income => 'Revenu';

  @override
  String get transaction_type_expense => 'Dépense';

  @override
  String get dashboard_add_transaction_text => 'Ajouter une transaction';

  @override
  String get dashboard_add_transfer_text => 'Transfert';

  @override
  String get dashboard_cash_flow_text => 'Flux de trésorerie';

  @override
  String get cash_flow_filter_type_day => 'Jour';

  @override
  String get cash_flow_filter_type_week => 'Semaine';

  @override
  String get cash_flow_filter_type_month => 'Mois';

  @override
  String get cash_flow_filter_type_year => 'Année';

  @override
  String get dashboard_mini_budget_text => 'Budget';

  @override
  String get dashboard_mini_budget_not_found_text =>
      'Aucun budget défini, ajoutez-en un !';

  @override
  String get dashboard_mini_budget_add_text => 'Ajouter un budget';

  @override
  String get transaction_list_cash_flow_screen_title => 'Transactions';

  @override
  String get transaction_list_filter_all => 'Tout';

  @override
  String get transaction_list_filter_income => 'Revenu';

  @override
  String get transaction_list_filter_expense => 'Dépense';

  @override
  String get transaction_list_pending_transaction_message_text =>
      '⚡ Nouvelles transactions trouvées ! Vérifiez maintenant';

  @override
  String get transaction_listPendingTransactionMessageActionLabel => 'Vérifier';

  @override
  String get transaction_noTransactionFoundText =>
      'Aucune transaction trouvée.';

  @override
  String get transaction_deleteAlertTitleText => 'Supprimer la transaction ?';

  @override
  String get transaction_deleteAlertBodyText =>
      'Cette action ne peut pas être annulée.';

  @override
  String get transaction_deleteButtonActionText => 'Supprimer';

  @override
  String get transaction_cancelButtonActionText => 'Annuler';

  @override
  String get transaction_filterCategoryText => 'Filtrer les transactions';

  @override
  String transaction_noteDescriptionText(Object description) {
    return 'note : $description';
  }

  @override
  String get calendar_week_monday_initial_text => 'L';

  @override
  String get calendar_week_tuesday_initial_text => 'M';

  @override
  String get calendar_week_wednesday_initial_text => 'M';

  @override
  String get calendar_week_thursday_initial_text => 'J';

  @override
  String get calendar_week_friday_initial_text => 'V';

  @override
  String get calendar_week_saturday_initial_text => 'S';

  @override
  String get calendar_week_sunday_initial_text => 'D';

  @override
  String get dashboard_netWorthTitle => 'Valeur nette';

  @override
  String get budget_dashboardMiniCardBudgetTitleText => 'Budget';

  @override
  String get budget_dashboardMiniCardSpentTitleText => 'Dépensé';

  @override
  String get budget_dashboardPageTitle => 'Détails des budgets';

  @override
  String get budget_dashboardNotFoundText =>
      'Aucun budget défini, ajoutez-en un !';

  @override
  String get budget_dashboardAddBudgetText => 'Ajouter un budget';

  @override
  String get budget_categoriesTitle => 'Catégories';

  @override
  String budget_dashboardPieChartLabelText(
      Object spentPercent, Object title, Object totalPercent) {
    return '$title ($totalPercent du total, $spentPercent des dépenses)';
  }

  @override
  String get budget_buttonDeleteTitleText => 'Supprimer le budget ?';

  @override
  String get budget_buttonDeleteBodyText =>
      'Cela supprimera le budget et ses allocations, cette action ne peut pas être annulée.';

  @override
  String get budget_buttonDeleteActionText => 'Supprimer';

  @override
  String get budget_buttonCancelActionText => 'Annuler';

  @override
  String get budget_buttonAddText => 'Ajouter un budget';

  @override
  String get budget_buttonEditText => 'Modifier le budget';

  @override
  String get budget_budgetNameControllerText => 'Nom du budget';

  @override
  String get budget_budgetAmountControllerText => 'Montant total';

  @override
  String get budget_recurrenceControllerText => 'Récurrence';

  @override
  String get budget_nameRequiredHintText => 'Le nom du budget est requis';

  @override
  String get budget_amountRequiredHintText => 'Un montant valide est requis';

  @override
  String get budget_selectStartDateText => 'Sélectionner la date de début';

  @override
  String budget_selectedStartDateText(Object startDate) {
    return 'Début : $startDate';
  }

  @override
  String get budget_selectEndDateText => 'Sélectionner la date de fin';

  @override
  String budget_selectedEndDateText(Object endDate) {
    return 'Fin : $endDate';
  }

  @override
  String get budget_categoryTitle =>
      'Sélectionner les catégories et allocations';

  @override
  String get budget_allocateAmountText => 'Allouer un montant';

  @override
  String get budget_categoryMessageInfoText =>
      'Vous pouvez saisir manuellement les allocations par catégorie, ou les laisser vides pour répartir automatiquement le montant restant de manière égale.';

  @override
  String budget_totalAllocatedBudgetText(Object totalAlloc) {
    return 'Total alloué : $totalAlloc';
  }

  @override
  String get budget_recurrenceText => 'Récurrence';

  @override
  String get budget_recurrenceNoneText => 'Aucune';

  @override
  String get budget_recurrenceDailyText => 'Quotidien';

  @override
  String get budget_recurrenceWeeklyText => 'Hebdomadaire';

  @override
  String get budget_recurrenceMonthlyText => 'Mensuel';

  @override
  String get budget_recurrenceYearlyText => 'Annuel';

  @override
  String get budget_saveButtonText => 'enregistrer';

  @override
  String get budget_updateButtonText => 'mettre à jour';

  @override
  String get budget_pickBothDatesErrorText => 'Choisissez les deux dates';

  @override
  String get budget_selectAtLeastOneCategoryErrorText =>
      'Sélectionnez au moins une catégorie';

  @override
  String get budget_allocatedAmountExceedsTotalBudgetText =>
      'Le montant alloué dépasse le budget total';

  @override
  String get transaction_amountControllerText => 'Montant';

  @override
  String get transaction_descriptionControllerText =>
      'Description (facultatif)';

  @override
  String get transaction_amountControllerErrorText => 'Entrez le montant';

  @override
  String get transaction_selectAccountLabel => 'Sélectionner un compte';

  @override
  String get transaction_selectCategoryLabel => 'Sélectionner une catégorie';

  @override
  String get transaction_selectTagLabel => 'Sélectionner une étiquette';

  @override
  String get transaction_addNewCategoryText =>
      'Ajouter une \nnouvelle catégorie';

  @override
  String get transaction_addNewTagText => 'Ajouter une nouvelle étiquette';

  @override
  String get transaction_tagNameControllerText => 'Nom de l\'étiquette';

  @override
  String get transaction_saveTagButtonLabel => 'Enregistrer l\'étiquette';

  @override
  String get transaction_saveTransactionButtonLabel =>
      'Enregistrer la transaction';

  @override
  String get transaction_selectOneAccountErrorText =>
      'Sélectionnez au moins un compte';

  @override
  String get transaction_selectOneCategoryErrorText =>
      'Sélectionnez au moins une catégorie';

  @override
  String get transaction_incomeButtonLabel => 'REVENU';

  @override
  String get transaction_expenseButtonLabel => 'DÉPENSE';

  @override
  String get statistics_weTrimDownDecimalInfoText =>
      'Nous arrondissons les décimales, veuillez arrondir si nécessaire.';

  @override
  String get statistics_selectPeriodTodayText => 'Aujourd\'hui';

  @override
  String get statistics_selectPeriodWeekText => 'Semaine';

  @override
  String get statistics_selectPeriodMonthText => 'Mois';

  @override
  String get statistics_selectPeriodYearText => 'Année';

  @override
  String get statistics_chartLineIncomeText => 'Revenu';

  @override
  String get statistics_chartLineExpenseText => 'Dépense';

  @override
  String statistics_chartLineTodayHourText(Object hour) {
    return '${hour}h';
  }

  @override
  String get statistics_categoryNotPresentText => 'Catégorie non présente.';

  @override
  String get statistics_transactionNotPresentText =>
      'Transactions non présentes.';

  @override
  String get statistics_byCategoryTitleText => 'Par catégorie';

  @override
  String get statistics_recentTransactionsTitleText => 'Transactions récentes';

  @override
  String get statistics_metricIncomeText => 'Revenu';

  @override
  String get statistics_metricExpenseText => 'Dépense';

  @override
  String get statistics_metricNetText => 'Net';

  @override
  String get statistics_showAllButtonText => 'Tout afficher';

  @override
  String get statistics_exportToPdfButtonText => 'Exporter en PDF';

  @override
  String get statistics_exportToExcelButtonText => 'Exporter vers Excel';

  @override
  String get profile_userProfileTitleText => 'Profil de l\'utilisateur';

  @override
  String get profile_userProfileSubtitleText =>
      'Changer l\'image de profil, le nom et l\'e-mail';

  @override
  String get profile_nameControllerText => 'Nom';

  @override
  String get profile_nameControllerHintText => 'Entrez votre nom';

  @override
  String get profile_nameRequiredHintText => 'Le nom est requis';

  @override
  String get profile_emailControllerText => 'E-mail';

  @override
  String get profile_emailControllerHintText => 'Entrez votre e-mail';

  @override
  String get profile_phoneControllerText => 'Téléphone';

  @override
  String get profile_phoneControllerHintText =>
      'Entrez votre numéro de téléphone';

  @override
  String get profile_weAreNotStoringInfoText =>
      'Toutes vos données restent sur cet appareil. Pas de serveurs, pas de cloud, pas de suivi.';

  @override
  String get profile_saveButtonText => 'enregistrer';

  @override
  String get profile_editUserProfileAppTitle =>
      'Modifier le profil de l\'utilisateur';

  @override
  String get pendingTranx_reviewPendingTransactionsScreenTitle =>
      'Transactions en attente';

  @override
  String get statistics_quickOverviewTitle => 'Aperçu rapide';

  @override
  String get statistics_insightsTitle => 'Aperçus';

  @override
  String get statistics_detailedAnalysisTitle => 'Analyse détaillée';

  @override
  String get statistics_categoryBreakdownSubtitle =>
      'Voir la répartition par catégorie';

  @override
  String get statistics_expenseTrendsTitle => 'Tendances des dépenses';

  @override
  String get statistics_expenseTrendsSubtitle =>
      'Tendances des 12 derniers mois';

  @override
  String get statistics_recentTransactionsSubtitle =>
      '5 dernières transactions';

  @override
  String get statistics_categoryBreakdownTitle => 'Répartition par catégorie';

  @override
  String get statistics_recentTransactionsModalTitle => 'Transactions récentes';

  @override
  String get transfer_screenTitle => 'Transférer des fonds';

  @override
  String get transfer_resetTooltip => 'Réinitialiser';

  @override
  String get transfer_selectAccountsLabel => 'SÉLECTIONNER LES COMPTES';

  @override
  String get transfer_fromLabel => 'DE';

  @override
  String get transfer_toLabel => 'À';

  @override
  String get transfer_detailsLabel => 'DÉTAILS DU TRANSFERT';

  @override
  String get transfer_amountLabel => 'Montant';

  @override
  String get transfer_amountValidationError => 'Entrez un montant valide';

  @override
  String get transfer_dateLabel => 'Date';

  @override
  String get transfer_noteLabel => 'Note (facultatif)';

  @override
  String get transfer_buttonLabel => 'Transférer';

  @override
  String get transfer_updateButtonLabel => 'Mettre à jour le transfert';

  @override
  String get transfer_errorLoadingAccounts =>
      'Erreur lors du chargement des comptes';

  @override
  String get app_settings_themeModeModalTitle => 'Mode thématique';

  @override
  String get category_expenseLabel => 'DÉPENSE';

  @override
  String get category_incomeLabel => 'REVENU';

  @override
  String get category_addTitle => 'Ajouter une catégorie';

  @override
  String get category_editTitle => 'Modifier la catégorie';

  @override
  String get category_tapToChangeIcon => 'Appuyez pour changer d\'icône';

  @override
  String get category_nameLabel => 'Nom de la catégorie';

  @override
  String get category_nameRequired => 'Requis';

  @override
  String get category_typeLabel => 'Type de catégorie';

  @override
  String get category_colorLabel => 'Couleur';

  @override
  String get category_tapToChangeColor => 'APPUYEZ POUR CHANGER DE COULEUR';

  @override
  String get category_saveButton => 'ENREGISTRER LA CATÉGORIE';

  @override
  String get category_updateButton => 'METTRE À JOUR LA CATÉGORIE';

  @override
  String get dashboard_incomeLabel => 'Revenu';

  @override
  String get dashboard_spentLabel => 'Dépensé';

  @override
  String get dashboard_noDataLabel => 'Aucune donnée';

  @override
  String get dashboard_editLabel => 'Modifier';

  @override
  String get dashboard_archiveLabel => 'Archiver';

  @override
  String get currency_crore_short => 'Cr';

  @override
  String get currency_lakh_short => 'L';

  @override
  String get currency_thousand_short => 'k';

  @override
  String common_errorText(Object error) {
    return 'Erreur : $error';
  }

  @override
  String get statistics_expenseShort => 'Dép.';

  @override
  String get statistics_incomeShort => 'Rev.';

  @override
  String get transaction_categoryFilter => 'Filtre de catégorie';

  @override
  String get transaction_dateFilter => 'Filtre de date';

  @override
  String get transaction_allCategories => 'Toutes les catégories';

  @override
  String get transaction_applyFilters => 'APPLIQUER LES FILTRES';

  @override
  String get sms_selectTransactions => 'Sélectionner les transactions';

  @override
  String get common_addLabel => 'Ajouter';

  @override
  String get dashboard_removeLabel => 'Supprimer';

  @override
  String get dashboard_viewAllLabel => 'Tout voir';

  @override
  String get common_noAccountsYet => 'Pas encore de comptes';

  @override
  String get common_loading => 'Chargement...';

  @override
  String get common_editLabel => 'Modifier';

  @override
  String get common_deleteLabel => 'Supprimer';

  @override
  String get common_fromLabel => 'De';

  @override
  String get common_toLabel => 'À';

  @override
  String get theme_chooseThemeTitle => 'Choisir le thème';

  @override
  String get theme_applyThemeLabel => 'Appliquer le thème';

  @override
  String get theme_themeAppliedMessage => 'Thème appliqué !';

  @override
  String get backup_backupRestoreTitle => 'Sauvegarde et Restauration';

  @override
  String get backup_backupDataTitle => 'Sauvegarder les données';

  @override
  String get backup_backupDataSubtitle =>
      'Exporter toute la base de données et les paramètres';

  @override
  String get backup_restoreBackupTitle => 'Restaurer une sauvegarde';

  @override
  String get backup_restoreBackupSubtitle =>
      'Importer la base de données et les paramètres';

  @override
  String get backup_includeAttachmentsTitle => 'Inclure les pièces jointes ?';

  @override
  String get backup_includeAttachmentsMessage =>
      'Inclure les images de reçus dans la sauvegarde ? Cela augmentera la taille du fichier.';

  @override
  String get backup_yesLabel => 'Oui';

  @override
  String get backup_noLabel => 'Non';

  @override
  String get backup_completedMessage => 'Sauvegarde terminée';

  @override
  String get backup_restoreSuccessMessage => 'Restauration réussie';

  @override
  String backup_lastBackupLabel(Object date) {
    return 'Dernière sauvegarde : $date';
  }

  @override
  String get backup_noBackupFoundLabel => 'Aucune sauvegarde trouvée';

  @override
  String get categories_manageCategoriesTitle => 'Gérer les catégories';

  @override
  String get categories_noCategoriesFound => 'Aucune catégorie trouvée.';

  @override
  String categories_transactionCount(Object count, Object plural) {
    return '$count transaction$plural';
  }

  @override
  String get categories_addCategoryLabel => 'Ajouter une catégorie';

  @override
  String get categories_deleteCategoryTitle => 'Supprimer la catégorie';

  @override
  String get categories_deleteCategoryMessage =>
      'Êtes-vous sûr de vouloir supprimer cette catégorie ?\nToutes les transactions associées seront également supprimées.';

  @override
  String get categories_categoryDeletedMessage =>
      'La catégorie et ses transactions ont été supprimées';

  @override
  String get accounts_manageAccountsTitle => 'Gérer les comptes';

  @override
  String get accounts_noAccountsAddedYet =>
      'Aucun compte ajouté pour l\'instant';

  @override
  String get accounts_addAccountLabel => 'Ajouter un compte';

  @override
  String get accounts_deleteAccountTitle => 'Supprimer le compte';

  @override
  String accounts_deleteAccountMessage(Object accountName) {
    return 'Êtes-vous sûr de vouloir supprimer \"$accountName\" ?';
  }

  @override
  String get accounts_archiveAccountTitle => 'Archiver le compte';

  @override
  String accounts_archiveAccountMessage(Object accountName) {
    return 'Êtes-vous sûr de vouloir archiver \"$accountName\" ?';
  }

  @override
  String get accounts_cancelLabel => 'Annuler';

  @override
  String get accounts_archiveLabel => 'Archiver';

  @override
  String accounts_accountArchivedMessage(Object accountName) {
    return '\"$accountName\" archivé';
  }

  @override
  String get accounts_atLeastOneAccountRequired =>
      'Au moins 1 compte est requis pour continuer';

  @override
  String get transaction_tripLabel => 'VOYAGE';

  @override
  String get transaction_tripPartOfMessage =>
      'Cette transaction fait partie du/des voyage(s) ci-dessous';

  @override
  String get sms_autoAddTooltip => 'Ajout automatique';

  @override
  String get sms_clearAllTooltip => 'Tout effacer';

  @override
  String get sms_importedFromSmsDescription => 'Importé automatiquement';

  @override
  String get sms_selectAtLeastOneMessage =>
      'Veuillez sélectionner au moins une transaction';

  @override
  String get dashboard_allTimeLabel => 'Depuis le début';

  @override
  String get transaction_editTransactionTitle => 'Modifier la transaction';

  @override
  String get transaction_addExpenseTitle => 'Ajouter une dépense';

  @override
  String get transaction_addIncomeTitle => 'Ajouter un revenu';

  @override
  String get transaction_accountRequired => 'Le compte est requis';

  @override
  String get transaction_categoryRequired => 'La catégorie est requise';

  @override
  String get transaction_dateLabel => 'Date';

  @override
  String get transaction_addNoteHint => 'Ajouter une note';

  @override
  String get transaction_enterValidAmountError =>
      'Veuillez entrer un montant valide.';

  @override
  String get sms_noPendingTransactions => 'Aucune transaction en attente';

  @override
  String get sms_approveLabel => 'Approuver';

  @override
  String get sms_approveTransactionTitle => 'Approuver la transaction';

  @override
  String get onboard_SmartSmsTracking => 'Suivi intelligent par SMS';

  @override
  String get onboard_SmartSmsTrackingDesc =>
      'Détectez et importez automatiquement les transactions à partir de vos messages SMS bancaires.';

  @override
  String get onboard_InsightsAndAnalytics => 'Aperçus et Analyses';

  @override
  String get onboard_InsightsAndAnalyticsDesc =>
      'Comprenez vos habitudes de dépense avec des graphiques détaillés, des tendances et des aperçus intelligents.';

  @override
  String get onboard_SecureAndPrivate => 'Sûr et Privé';

  @override
  String get onboard_SecureAndPrivateDesc =>
      'Vos données restent sur votre appareil. Pas de cloud, pas de suivi — juste un stockage local chiffré.';

  @override
  String get onboard_SmartAutoTracking => 'Suivi automatique intelligent';

  @override
  String get onboard_SmartAutoTrackingDesc =>
      'Détectez et importez automatiquement les transactions à partir de vos notifications bancaires.';

  @override
  String get nav_activity => 'Activité';

  @override
  String get nav_manage => 'Gérer';

  @override
  String get nav_insights => 'Aperçus';

  @override
  String get common_save => 'Enregistrer';

  @override
  String get common_cancel => 'Annuler';

  @override
  String get common_next => 'Suivant';

  @override
  String get common_back => 'Retour';

  @override
  String get common_undo => 'Annuler';

  @override
  String get common_delete => 'Supprimer';

  @override
  String get common_edit => 'Modifier';

  @override
  String get common_add => 'Ajouter';

  @override
  String get common_done => 'Terminé';

  @override
  String get common_close => 'Fermer';

  @override
  String get common_confirm => 'Confirmer';

  @override
  String get common_archive => 'Archiver';

  @override
  String get common_create => 'Créer';

  @override
  String get common_update => 'Mettre à jour';

  @override
  String get common_remove => 'Supprimer';

  @override
  String get common_search => 'Rechercher';

  @override
  String get common_filter => 'Filtrer';

  @override
  String get common_reset => 'Réinitialiser';

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
  String get common_viewDetails => 'Voir les détails';

  @override
  String get common_apply => 'Appliquer';

  @override
  String get common_yes => 'Oui';

  @override
  String get common_no => 'Non';

  @override
  String get common_ok => 'OK';

  @override
  String get common_retry => 'Réessayer';

  @override
  String get common_noData => 'Aucune donnée';

  @override
  String get common_error => 'Une erreur est survenue';

  @override
  String get common_required => 'Requis';

  @override
  String get common_maybeLater => 'Maybe later';

  @override
  String get title_budgets => 'Budgets';

  @override
  String get title_goals => 'Objectifs';

  @override
  String get title_bills => 'Factures';

  @override
  String get title_groups => 'Groupes';

  @override
  String get title_trips => 'Voyages';

  @override
  String get title_shared => 'Partagé';

  @override
  String get title_achievements => 'Succès';

  @override
  String get title_notifications => 'Notifications';

  @override
  String get title_appearance => 'Apparence';

  @override
  String get title_currency => 'Devise';

  @override
  String get title_security => 'Sécurité';

  @override
  String get title_about => 'À propos';

  @override
  String get title_analytics => 'Analyses';

  @override
  String get title_netWorth => 'Valeur nette';

  @override
  String get title_financialHealth => 'Santé financière';

  @override
  String get title_spendingPersonality => 'Personnalité dépensière';

  @override
  String get title_monthlyRecap => 'Récapitulatif mensuel';

  @override
  String get title_compareMonths => 'Comparer les mois';

  @override
  String get title_smsImport => 'Importation SMS';

  @override
  String get title_backupShare => 'Sauvegarde et partage';

  @override
  String get title_exchangeRates => 'Taux de change';

  @override
  String get title_recurringTransactions => 'Transactions récurrentes';

  @override
  String get title_billControlCenter => 'Centre de contrôle des factures';

  @override
  String get title_plugins => 'Extensions';

  @override
  String get title_editCategory => 'Modifier la catégorie';

  @override
  String get title_allCategories => 'Toutes les catégories';

  @override
  String get title_exportOptions => 'Options d\'exportation';

  @override
  String get title_dashboardLayout => 'Disposition du tableau de bord';

  @override
  String get section_activeMoney => 'Argent actif';

  @override
  String get section_planning => 'Planification';

  @override
  String get section_insights => 'Aperçus';

  @override
  String get section_coreSettings => 'Paramètres de base';

  @override
  String get section_appData => 'Application et données';

  @override
  String get section_appearance => 'Apparence';

  @override
  String get section_advanced => 'Avancé';

  @override
  String get section_supportLegal => 'Support et légal';

  @override
  String get section_active => 'Actif';

  @override
  String get section_ongoing => 'En cours';

  @override
  String get section_archive => 'Archive';

  @override
  String get label_income => 'Revenu';

  @override
  String get label_expense => 'Dépense';

  @override
  String get label_balance => 'Solde';

  @override
  String get label_savings => 'Économies';

  @override
  String get label_total => 'Total';

  @override
  String get label_amount => 'Montant';

  @override
  String get label_date => 'Date';

  @override
  String get label_category => 'Catégorie';

  @override
  String get label_account => 'Compte';

  @override
  String get label_description => 'Description';

  @override
  String get label_type => 'Type';

  @override
  String get label_transfer => 'Transfert';

  @override
  String get label_from => 'De';

  @override
  String get label_to => 'À';

  @override
  String get label_all => 'Tout';

  @override
  String get label_today => 'Aujourd\'hui';

  @override
  String get label_yesterday => 'Hier';

  @override
  String get label_thisWeek => 'Cette semaine';

  @override
  String get label_thisMonth => 'Ce mois-ci';

  @override
  String get label_thisYear => 'Cette année';

  @override
  String get label_custom => 'Personnalisé';

  @override
  String get label_daily => 'Quotidien';

  @override
  String get label_weekly => 'Hebdomadaire';

  @override
  String get label_monthly => 'Mensuel';

  @override
  String get label_yearly => 'Annuel';

  @override
  String get label_none => 'Aucun';

  @override
  String get label_frequency => 'Fréquence';

  @override
  String get label_repeatEvery => 'Répéter tous les';

  @override
  String get label_days => 'jours';

  @override
  String get label_weeks => 'semaines';

  @override
  String get label_months => 'mois';

  @override
  String get label_years => 'ans';

  @override
  String get trip_expenses => 'Dépenses';

  @override
  String get trip_settlements => 'Règlements';

  @override
  String get trip_balances => 'Soldes';

  @override
  String get trip_report => 'Rapport';

  @override
  String get trip_createTrip => 'Créer un voyage';

  @override
  String get trip_createGroup => 'Créer un groupe partagé';

  @override
  String get trip_editTrip => 'Modifier le voyage';

  @override
  String get trip_editGroup => 'Modifier le groupe';

  @override
  String get trip_archiveTrip => 'Archiver le voyage';

  @override
  String get trip_archiveGroup => 'Archiver le groupe';

  @override
  String get trip_allSettled => 'Tout est réglé !';

  @override
  String get trip_archiveToSettle => 'Archiver pour régler';

  @override
  String get trip_trackTravel =>
      'Suivez les dépenses de voyage avec dates et budget';

  @override
  String get trip_splitBills => 'Partagez les factures avec des amis';

  @override
  String get trip_live => 'En direct';

  @override
  String get budget_spendingLimits => 'Limites de dépenses';

  @override
  String get budget_savingsProgress => 'Progression des économies';

  @override
  String get budget_upcomingRecurring => 'À venir et récurrent';

  @override
  String get budget_tripsAndSplits => 'Voyages et partages';

  @override
  String import_importing(int count) {
    return 'Importation de $count transactions...';
  }

  @override
  String get import_dontClose => 'Veuillez ne pas fermer l\'application';

  @override
  String get import_complete => 'Importation terminée !';

  @override
  String get import_failed => 'Échec de l\'importation';

  @override
  String get import_imported => 'Importé';

  @override
  String get import_duplicatesSkipped => 'Doublons ignorés';

  @override
  String get import_errorsSkipped => 'Erreurs/ignorés';

  @override
  String get import_categoriesCreated => 'Catégories créées';

  @override
  String get import_previewImport => 'Aperçu de l\'importation';

  @override
  String get recap_yourMonthAtGlance => 'Votre mois en un coup d\'œil';

  @override
  String get recap_trackProgressOverTime =>
      'Suivez vos progrès au fil du temps';

  @override
  String recap_transactions(int count) {
    return '$count transactions';
  }

  @override
  String get recap_downloadPdf => 'Télécharger le PDF';

  @override
  String get comparison_current => 'Actuel';

  @override
  String comparison_byDay(int day) {
    return 'Au jour $day';
  }

  @override
  String get comparison_topCategories => 'Principales catégories';

  @override
  String get comparison_categoryImpact => 'IMPACT PAR CATÉGORIE';

  @override
  String get comparison_dailySpendingPace => 'Rythme de dépenses quotidien';

  @override
  String comparison_projected(String amount) {
    return 'Prévision : $amount ce mois-ci';
  }

  @override
  String get utility_customizeUtilities => 'Personnaliser les utilitaires';

  @override
  String get utility_addUtilities => 'Ajouter des utilitaires';

  @override
  String get utility_analyticsSubtitle =>
      'Score de santé, tendances et prévisions';

  @override
  String get utility_cashFlowSubtitle => 'Projections des revenus vs dépenses';

  @override
  String get utility_spendingTrendsSubtitle => 'Modes de dépense par catégorie';

  @override
  String get utility_taxSubtitle => 'Estimez votre impôt sur le revenu';

  @override
  String get profile_accounts => 'Comptes';

  @override
  String get profile_manageAccounts => 'Gérer vos comptes';

  @override
  String get profile_categories => 'Catégories';

  @override
  String get profile_manageCategories => 'Gérer vos catégories';

  @override
  String get profile_language => 'Langue';

  @override
  String get profile_notifications => 'Notifications';

  @override
  String get profile_dailyWeeklySummaries =>
      'Résumés quotidiens et hebdomadaires';

  @override
  String get profile_autoImport => 'Importation automatique';

  @override
  String get profile_autoImportDesc =>
      'Importation automatique des notifications bancaires';

  @override
  String get profile_importExport => 'Import & Export';

  @override
  String get profile_importExportDesc => 'Import & export Excel';

  @override
  String get profile_backupRestore => 'Sauvegarde et Restauration';

  @override
  String get profile_manageData => 'Gérer vos données';

  @override
  String get profile_themeDisplay => 'Thème, ton et affichage';

  @override
  String get profile_customizeWidgets => 'Personnaliser les widgets et cartes';

  @override
  String get profile_manageExtensions => 'Gérer les extensions';

  @override
  String get profile_helpSupport => 'Aide et support';

  @override
  String get profile_faqs => 'FAQ et guides des fonctionnalités';

  @override
  String get profile_aboutApp => 'À propos de l\'application';

  @override
  String get profile_versionInfo => 'Version et infos';

  @override
  String get profile_pinFingerprint => 'Code PIN ou empreinte digitale';

  @override
  String get profile_upgradePro => 'Passer à la version Pro';

  @override
  String get profile_unlimitedFeatures =>
      'Comptes illimités, analyses et plus encore';

  @override
  String get profile_freeTier => 'Version gratuite';

  @override
  String get profile_fullAccess => 'Accès complet';

  @override
  String get profile_proActive => 'Pro actif';

  @override
  String get profile_yourAchievements => 'Vos succès';

  @override
  String get profile_bestStreak => 'Meilleure série';

  @override
  String get trips_active => 'ACTIF';

  @override
  String get trips_live => 'En direct';

  @override
  String get trips_allSettled => 'Tout est réglé';

  @override
  String get tone_friendly_txnAdded =>
      'C\'est fait ! Transaction enregistrée ✨|Compris ! Tout est noté 👍|Enregistré ! Vous assurez ✨|Noté ! Un de plus de suivi 📝';

  @override
  String get tone_friendly_txnUpdated =>
      'Mis à jour ! C\'est parfait 👍|Changements enregistrés ! ✓|Tout est à jour ! 👌';

  @override
  String get tone_friendly_txnDeleted =>
      'Disparu ! Transaction supprimée 🗑️|Supprimé ! Un de moins à suivre|Enlevé ! Table rase 🗑️';

  @override
  String get tone_friendly_txnFailed =>
      'Hmm, je n\'ai pas pu enregistrer ça. Réessayez ?';

  @override
  String get tone_friendly_enterAmount =>
      'C\'était combien ? Entrez un montant';

  @override
  String get tone_friendly_pickAccount =>
      'Quel compte ? Choisissez-en un pour continuer';

  @override
  String get tone_friendly_pickCategory =>
      'C\'était pour quoi ? Choisissez une catégorie';

  @override
  String get tone_friendly_fillAllFields =>
      'Presque fini — remplissez tous les champs';

  @override
  String get tone_friendly_invalidAmount =>
      'Ça n\'a pas l\'air correct — entrez un montant valide';

  @override
  String get tone_friendly_budgetCreated =>
      'Budget défini ! Restons sur la bonne voie 💪|Budget verrouillé ! Vous planifiez à l\'avance 💪|Super ! Le budget est prêt à rouler 📊';

  @override
  String get tone_friendly_budgetUpdated => 'Budget mis à jour !';

  @override
  String get tone_friendly_budgetDeleted => 'Budget supprimé';

  @override
  String get tone_friendly_goalCreated =>
      'Objectif fixé ! Vous allez y arriver 🎯|Nouvel objectif ! Faisons en sorte que ça arrive 🎯|Objectif verrouillé ! Les yeux sur le prix 🎯';

  @override
  String get tone_friendly_goalUpdated => 'Objectif mis à jour !';

  @override
  String get tone_friendly_goalDeleted => 'Objectif supprimé';

  @override
  String get tone_friendly_accountCreated => 'Compte ajouté ! 🏦';

  @override
  String get tone_friendly_billAdded =>
      'Facture suivie ! Je vous le rappellerai 🔔';

  @override
  String get tone_friendly_billPaid =>
      'Super, facture marquée comme payée ! ✅|Facture faite ! Une de moins à s\'inquiéter ✅|Payée ! Quel soulagement ✅';

  @override
  String get tone_friendly_backupSuccess =>
      'Sauvegarde effectuée ! Vos données sont en sécurité 🛡️';

  @override
  String get tone_friendly_restoreSuccess =>
      'Restauré ! Bon retour parmi nous 🎉';

  @override
  String get tone_friendly_noTransactions =>
      'Rien ici pour l\'instant\nAjoutez votre première transaction pour commencer|Vide pour le moment\nCommencez le suivi — ça ne prend qu\'une seconde|Pas encore de transactions\nVotre voyage financier commence par une saisie';

  @override
  String get tone_friendly_noBudgets =>
      'Pas encore de budgets\nConfigurez-en un pour suivre vos denses';

  @override
  String get tone_friendly_noGoals =>
      'Pas encore d\'objectifs\nVoyez grand — fixez votre premier objectif !';

  @override
  String get tone_friendly_genericError =>
      'Un problème est survenu. Réessayer ?';

  @override
  String get tone_friendly_smsImportEnabled =>
      'L\'importation automatique est activée ! Je suivrai vos transactions 📩';

  @override
  String get tone_friendly_dashboardAllCaughtUp =>
      'Vous êtes à jour ! 🎉|Rien ne nécessite votre attention — super ! ✨|Tout va bien ici ! Profitez de votre journée 🎉';

  @override
  String get tone_friendly_dailySummaryEmpty =>
      'Rien d\'enregistré hier — soit une victoire sans dépense, soit il est temps de rattraper le retard !|Journée calme hier — votre portefeuille vous remercie !|Pas de transactions hier — nouveau départ aujourd\'hui !';

  @override
  String tone_friendly_streakMessage(int days) {
    return '$days jours de suite ! Continuez comme ça ! 🔥';
  }

  @override
  String tone_friendly_budgetExceededBy(String amount) {
    return 'Vous avez dépassé votre budget de $amount 😬';
  }

  @override
  String get tone_professional_txnAdded =>
      'Transaction enregistrée.|Entrée sauvegardée avec succès.|Transaction journalisée.';

  @override
  String get tone_professional_txnUpdated =>
      'Transaction mise à jour.|Changements appliqués.|Enregistrement mis à jour avec succès.';

  @override
  String get tone_professional_txnDeleted =>
      'Transaction supprimée.|Enregistrement retiré.|Entrée supprimée avec succès.';

  @override
  String get tone_professional_txnFailed =>
      'Échec de l\'enregistrement de la transaction. Veuillez réessayer.';

  @override
  String get tone_professional_enterAmount =>
      'Veuillez entrer un montant valide.';

  @override
  String get tone_professional_pickAccount =>
      'Veuillez sélectionner un compte.';

  @override
  String get tone_professional_pickCategory =>
      'Veuillez sélectionner une catégorie.';

  @override
  String get tone_professional_fillAllFields =>
      'Tous les champs obligatoires doivent être remplis.';

  @override
  String get tone_professional_invalidAmount => 'Montant invalide saisi.';

  @override
  String get tone_professional_budgetCreated =>
      'Budget créé.|Budget configuré avec succès.|Le nouveau budget est actif.';

  @override
  String get tone_professional_budgetUpdated => 'Budget mis à jour.';

  @override
  String get tone_professional_budgetDeleted => 'Budget supprimé.';

  @override
  String get tone_professional_goalCreated =>
      'Objectif créé.|Objectif d\'épargne configuré.|Le nouvel objectif est actif.';

  @override
  String get tone_professional_goalUpdated => 'Objectif mis à jour.';

  @override
  String get tone_professional_goalDeleted => 'Objectif supprimé.';

  @override
  String get tone_professional_accountCreated => 'Compte ajouté.';

  @override
  String get tone_professional_billAdded =>
      'Facture ajoutée. Des rappels seront envoyés.';

  @override
  String get tone_professional_billPaid =>
      'Facture marquée comme payée.|Paiement enregistré.|Facture réglée.';

  @override
  String get tone_professional_backupSuccess =>
      'Sauvegarde terminée avec succès.';

  @override
  String get tone_professional_restoreSuccess =>
      'Données restaurées avec succès.';

  @override
  String get tone_professional_noTransactions =>
      'Aucune transaction enregistrée.\nAjoutez votre première entrée.|Aucun enregistrement trouvé.\nCommencez par ajouter une transaction.|L\'historique des transactions est vide.\nCommencez l\'enregistrement.';

  @override
  String get tone_professional_noBudgets => 'Aucun budget configuré.';

  @override
  String get tone_professional_noGoals => 'Aucun objectif fixé.';

  @override
  String get tone_professional_genericError => 'Une erreur est survenue.';

  @override
  String get tone_professional_smsImportEnabled =>
      'Importation automatique activée.';

  @override
  String get tone_professional_dashboardAllCaughtUp =>
      'Tous les éléments sont à jour.|Aucune action en attente.|Tout est à jour.';

  @override
  String get tone_professional_dailySummaryEmpty =>
      'Aucune transaction enregistrée hier.|Hier, il n\'y a eu aucune activité enregistrée.|Aucune entrée pour la journée précédente.';

  @override
  String tone_professional_streakMessage(int days) {
    return '$days jours consécutifs de suivi.';
  }

  @override
  String tone_professional_budgetExceededBy(String amount) {
    return 'Budget dépassé de $amount.';
  }

  @override
  String get tone_motivational_txnAdded =>
      'Excellent travail ! Transaction enregistrée ! 💪|C\'est noté ! Vous assurez 💪|Un de plus de suivi ! Gardez le rythme ! ✨|Enregistré ! Chaque saisie est un pas en avant ! 🚀';

  @override
  String get tone_motivational_txnUpdated =>
      'Belle mise à jour ! On reste affûté ! ✨|Mis à jour ! La précision est la clé ! ✨|Changements enregistrés ! Vous gérez ! 👍';

  @override
  String get tone_motivational_txnDeleted =>
      'C\'est nettoyé ! Une chose de moins à gérer|Supprimé ! On garde les choses au propre ! 💪|Parti ! Concentrez-vous sur ce qui compte';

  @override
  String get tone_motivational_txnFailed => 'Ça n\'est pas passé — réessayez !';

  @override
  String get tone_motivational_enterAmount =>
      'Chaque euro compte — entrez le montant !';

  @override
  String get tone_motivational_pickAccount =>
      'Choisissez un compte pour rester organisé !';

  @override
  String get tone_motivational_pickCategory =>
      'Catégorisez — vous vous remercierez plus tard !';

  @override
  String get tone_motivational_fillAllFields =>
      'Presque là ! Remplissez tout pour continuer';

  @override
  String get tone_motivational_invalidAmount =>
      'Ce montant ne semble pas correct — réessayez !';

  @override
  String get tone_motivational_budgetCreated =>
      'Bien joué ! Le budget est fixé ! 💪|Budget verrouillé ! Vous prenez le contrôle ! 💪|C\'est ça la discipline ! Budget prêt ! 📊';

  @override
  String get tone_motivational_budgetUpdated =>
      'Budget ajusté — on reste flexible !';

  @override
  String get tone_motivational_budgetDeleted => 'Budget supprimé';

  @override
  String get tone_motivational_goalCreated =>
      'J\'adore cette ambition ! Objectif fixé ! 🎯|Les grands rêves commencent ici ! Objectif verrouillé ! 🎯|C\'est l\'esprit ! Nouvel objectif prêt ! 🚀';

  @override
  String get tone_motivational_goalUpdated =>
      'Objectif affiné — continuez à pousser !';

  @override
  String get tone_motivational_goalDeleted =>
      'Objectif supprimé — nouvelles priorités, nouveaux plans';

  @override
  String get tone_motivational_accountCreated =>
      'Compte ajouté ! Vous vous organisez ! 🏦';

  @override
  String get tone_motivational_billAdded =>
      'Facture suivie ! Vous avez une longueur d\'avance ! 🔔';

  @override
  String get tone_motivational_billPaid =>
      'Facture payée ! Une chose de moins à s\'inquiéter ! ✅|Écrasé ! La facture est payée ! ✅|Payé et terminé ! Vous avez une longueur d\'avance ! 💪';

  @override
  String get tone_motivational_backupSuccess =>
      'Sauvegardé ! Vos progrès sont en sécurité ! 🛡️';

  @override
  String get tone_motivational_restoreSuccess =>
      'Restauré ! De retour sur les rails ! 🎉';

  @override
  String get tone_motivational_noTransactions =>
      'Nouveau départ ! 🌟\nAjoutez votre première transaction — chaque voyage commence par un pas|Table rase ! 🌟\nVotre première saisie attend — c\'est parti !|Rien pour l\'instant ! 💪\nUne transaction et vous êtes en route !';

  @override
  String get tone_motivational_noBudgets =>
      'Pas encore de budgets\nConfigurez-en un — votre futur moi vous remerciera ! 💪';

  @override
  String get tone_motivational_noGoals =>
      'Pas encore d\'objectifs\nRêvez grand — fixez votre premier objectif ! 🎯';

  @override
  String get tone_motivational_genericError =>
      'Un problème est survenu — réessayez !';

  @override
  String get tone_motivational_smsImportEnabled =>
      'Importation automatique activée ! Vos finances se suivent toutes seules maintenant ! 📩';

  @override
  String get tone_motivational_dashboardAllCaughtUp =>
      'Tout est à jour — vous avez une longueur d\'avance ! 🏆|Rien en attente — vous assurez 💪|Tout est clair ! Gardez cette énergie 🏆';

  @override
  String get tone_motivational_dailySummaryEmpty =>
      'Zéro dépense hier — votre portefeuille vous remercie ! ✨|Rien de dépensé hier — c\'est ça la volonté ! 💪|Une journée sans dépense ! C\'est une victoire ! 🏆';

  @override
  String tone_motivational_streakMessage(int days) {
    return 'Série de $days jours ! Inarrêtable ! 🔥';
  }

  @override
  String tone_motivational_budgetExceededBy(String amount) {
    return 'Dépassé de $amount — vous pouvez corriger le tir ! 💪';
  }

  @override
  String get tone_calm_txnAdded => 'Noté.|Enregistré.|Sauvegardé discrètement.';

  @override
  String get tone_calm_txnUpdated =>
      'Mis à jour.|Ajusté.|Changements enregistrés.';

  @override
  String get tone_calm_txnDeleted => 'Libéré.|Retiré.|Laissé de côté.';

  @override
  String get tone_calm_txnFailed => 'Ça n\'a pas marché. Réessayez doucement.';

  @override
  String get tone_calm_enterAmount => 'Un montant est nécessaire.';

  @override
  String get tone_calm_pickAccount => 'Choisissez où cela appartient.';

  @override
  String get tone_calm_pickCategory => 'Donnez-lui un but.';

  @override
  String get tone_calm_fillAllFields => 'Quelques champs sont encore vides.';

  @override
  String get tone_calm_invalidAmount => 'Le montant doit être ajusté.';

  @override
  String get tone_calm_budgetCreated =>
      'Limite fixée.|Budget en place.|Limites définies.';

  @override
  String get tone_calm_budgetUpdated => 'Ajusté.';

  @override
  String get tone_calm_budgetDeleted => 'Libéré.';

  @override
  String get tone_calm_goalCreated =>
      'Intention fixée.|Une nouvelle direction.|Objectif planté.';

  @override
  String get tone_calm_goalUpdated => 'Affiné.';

  @override
  String get tone_calm_goalDeleted => 'Libéré.';

  @override
  String get tone_calm_accountCreated => 'Compte ouvert.';

  @override
  String get tone_calm_billAdded => 'Noté. Vous en serez rappelé.';

  @override
  String get tone_calm_billPaid =>
      'Réglé.|Payé. Un de moins.|Fait. Tranquillité d\'esprit.';

  @override
  String get tone_calm_backupSuccess => 'En sécurité.';

  @override
  String get tone_calm_restoreSuccess => 'Restauré. Bon retour.';

  @override
  String get tone_calm_noTransactions =>
      'Une table rase.\nCommencez quand vous êtes prêt.|Rien ici pour l\'instant.\nCommencez doucement.|Vide.\nUn nouveau départ vous attend.';

  @override
  String get tone_calm_noBudgets =>
      'Pas encore de limites.\nFixez-en une quand vous le sentirez bien.';

  @override
  String get tone_calm_noGoals =>
      'Pas encore d\'intentions.\nFixez-en une quand vous serez prêt.';

  @override
  String get tone_calm_genericError => 'Quelque chose a bougé. Réessayez.';

  @override
  String get tone_calm_smsImportEnabled =>
      'Surveille discrètement vos transactions.';

  @override
  String get tone_calm_dashboardAllCaughtUp =>
      'Tout est en ordre.|Rien ne nécessite votre attention.|Tout va bien.';

  @override
  String get tone_calm_dailySummaryEmpty =>
      'Une journée calme. Rien d\'enregistré.|Hier était paisible. Aucune saisie.|Rien de dépensé. Une journée de repos.';

  @override
  String tone_calm_streakMessage(int days) {
    return '$days jours de suivi attentif.';
  }

  @override
  String tone_calm_budgetExceededBy(String amount) {
    return 'Dépassé de $amount. Un moment de réflexion.';
  }

  @override
  String get tone_friendly_insightBillsDueSoon =>
      'Attention — factures en approche';

  @override
  String get tone_friendly_insightOverBudget => 'Budget dépassé';

  @override
  String get tone_friendly_insightNearBudget => 'On s\'en approche...';

  @override
  String get tone_friendly_insightOverspending =>
      'Les dépenses dépassent les revenus';

  @override
  String get tone_friendly_insightSpendingSpike =>
      'Pic de dépenses aujourd\'hui';

  @override
  String get tone_friendly_insightWeekendAlert => 'Alerte dépenses du week-end';

  @override
  String get tone_friendly_insightGetStarted => 'C\'est parti ! 🚀';

  @override
  String get tone_friendly_insightGetStartedMessage =>
      'Ajoutez votre première transaction — ça ne prend qu\'une seconde';

  @override
  String tone_friendly_insightBillsDueMessage(int count) {
    return '$count facture(s) bientôt dues, n\'oubliez pas !';
  }

  @override
  String tone_friendly_insightOverBudgetMessage(int count) {
    return '$count budget(s) ont été dépassés ce mois-ci — jetez-y un œil';
  }

  @override
  String tone_friendly_insightNearBudgetMessage(int count) {
    return '$count budget(s) à plus de 80 % — il est encore temps de ralentir';
  }

  @override
  String tone_friendly_insightOverspendingMessage(String amount) {
    return 'Vous avez dépensé $amount de plus que vos revenus ce mois-ci — vous devriez peut-être ralentir';
  }

  @override
  String tone_friendly_insightSpendingSpikeMessage(String avg, String today) {
    return 'D\'habitude vous dépensez $avg/jour. Aujourd\'hui on est déjà à $today.';
  }

  @override
  String tone_friendly_insightWeekendAlertMessage(String avg, String current) {
    return 'D\'habitude vous dépensez $avg le week-end. Celui-ci est déjà à $current.';
  }

  @override
  String get tone_professional_insightBillsDueSoon => 'Factures à venir';

  @override
  String get tone_professional_insightOverBudget => 'Budget dépassé';

  @override
  String get tone_professional_insightNearBudget =>
      'Limite du budget approchant';

  @override
  String get tone_professional_insightOverspending =>
      'Les dépenses dépassent les revenus';

  @override
  String get tone_professional_insightSpendingSpike =>
      'Dépenses élevées aujourd\'hui';

  @override
  String get tone_professional_insightWeekendAlert =>
      'Dépenses du week-end élevées';

  @override
  String get tone_professional_insightGetStarted => 'Commencer';

  @override
  String get tone_professional_insightGetStartedMessage =>
      'Enregistrez votre première transaction pour commencer le suivi.';

  @override
  String tone_professional_insightBillsDueMessage(int count) {
    return '$count facture(s) dues dans les prochains jours.';
  }

  @override
  String tone_professional_insightOverBudgetMessage(int count) {
    return '$count budget(s) dépassés ce mois-ci.';
  }

  @override
  String tone_professional_insightNearBudgetMessage(int count) {
    return '$count budget(s) à plus de 80 % d\'utilisation.';
  }

  @override
  String tone_professional_insightOverspendingMessage(String amount) {
    return 'Les dépenses dépassent les revenus de $amount ce mois-ci.';
  }

  @override
  String tone_professional_insightSpendingSpikeMessage(
      String avg, String today) {
    return 'Moyenne quotidienne : $avg. Aujourd\'hui : $today.';
  }

  @override
  String tone_professional_insightWeekendAlertMessage(
      String avg, String current) {
    return 'Moyenne du week-end : $avg. Actuel : $current.';
  }

  @override
  String get tone_motivational_insightBillsDueSoon => 'Factures à venir ! 📋';

  @override
  String get tone_motivational_insightOverBudget =>
      'Budget dépassé — temps de se ressaisir';

  @override
  String get tone_motivational_insightNearBudget => 'Presque à la limite';

  @override
  String get tone_motivational_insightOverspending =>
      'Les dépenses dépassent les revenus';

  @override
  String get tone_motivational_insightSpendingSpike =>
      'Pic de dépenses aujourd\'hui';

  @override
  String get tone_motivational_insightWeekendAlert =>
      'Alerte dépenses du week-end';

  @override
  String get tone_motivational_insightGetStarted =>
      'Construisons quelque chose de grand ! 🚀';

  @override
  String get tone_motivational_insightGetStartedMessage =>
      'Ajoutez votre première transaction — vous n\'êtes qu\'à un pas !';

  @override
  String tone_motivational_insightBillsDueMessage(int count) {
    return '$count facture(s) bientôt dues — gardez une longueur d\'avance !';
  }

  @override
  String tone_motivational_insightOverBudgetMessage(int count) {
    return '$count budget(s) dépassés — vous pouvez corriger le tir !';
  }

  @override
  String tone_motivational_insightNearBudgetMessage(int count) {
    return '$count budget(s) à plus de 80 % — vous gérez, restez attentif !';
  }

  @override
  String tone_motivational_insightOverspendingMessage(String amount) {
    return '$amount au-dessus des revenus — les petits ajustements font une grande différence !';
  }

  @override
  String tone_motivational_insightSpendingSpikeMessage(
      String avg, String today) {
    return 'D\'habitude $avg/jour. Aujourd\'hui $today — soyez intentionnel !';
  }

  @override
  String tone_motivational_insightWeekendAlertMessage(
      String avg, String current) {
    return 'Moyenne week-end : $avg. Celui-ci est à $current — restez conscient !';
  }

  @override
  String get tone_calm_insightBillsDueSoon => 'Factures en approche';

  @override
  String get tone_calm_insightOverBudget => 'Au-delà de la ligne';

  @override
  String get tone_calm_insightNearBudget => 'Proche de la limite';

  @override
  String get tone_calm_insightOverspending =>
      'Les sorties dépassent les entrées';

  @override
  String get tone_calm_insightSpendingSpike => 'Une journée plus lourde';

  @override
  String get tone_calm_insightWeekendAlert => 'Dépenses du week-end';

  @override
  String get tone_calm_insightGetStarted => 'Un nouveau départ';

  @override
  String get tone_calm_insightGetStartedMessage =>
      'Commencez par votre première transaction.';

  @override
  String tone_calm_insightBillsDueMessage(int count) {
    return '$count facture(s) arrivant bientôt.';
  }

  @override
  String tone_calm_insightOverBudgetMessage(int count) {
    return '$count budget(s) dépassés. Réfléchissez et ajustez.';
  }

  @override
  String tone_calm_insightNearBudgetMessage(int count) {
    return '$count budget(s) à plus de 80 %. Une dépense attentive aide.';
  }

  @override
  String tone_calm_insightOverspendingMessage(String amount) {
    return '$amount de plus dépensé que gagné. Un moment de pause.';
  }

  @override
  String tone_calm_insightSpendingSpikeMessage(String avg, String today) {
    return 'D\'habitude $avg/jour. Aujourd\'hui, $today.';
  }

  @override
  String tone_calm_insightWeekendAlertMessage(String avg, String current) {
    return 'D\'habitude $avg. Ce week-end, $current.';
  }

  @override
  String tone_friendly_insightMoneyLeak(
      String category, int count, String total) {
    return '$category : $count fois ce mois-ci, $total au total — les petits coups s\'additionnent';
  }

  @override
  String tone_friendly_insightBestDay(
      String worst, String wAvg, String best, String bAvg, String saving) {
    return '$wAvg en moyenne les ${worst}s contre $bAvg les ${best}s — c\'est $saving que vous pourriez garder';
  }

  @override
  String tone_professional_insightMoneyLeak(
      String category, int count, String total) {
    return '$category : $count transactions, $total au total ce mois-ci.';
  }

  @override
  String tone_professional_insightBestDay(
      String worst, String wAvg, String best, String bAvg, String saving) {
    return '$wAvg en moyenne les ${worst}s contre $bAvg les ${best}s. Économie potentielle : $saving.';
  }

  @override
  String tone_motivational_insightMoneyLeak(
      String category, int count, String total) {
    return '$category : $count fois, $total — de petites victoires s\'ajoutent si vous réduisez !';
  }

  @override
  String tone_motivational_insightBestDay(
      String worst, String wAvg, String best, String bAvg, String saving) {
    return '$wAvg les ${worst}s contre $bAvg les ${best}s — $saving d\'économies potentielles !';
  }

  @override
  String tone_calm_insightMoneyLeak(String category, int count, String total) {
    return '$category : $count fois, $total. Les petits ruisseaux font les grandes rivières.';
  }

  @override
  String tone_calm_insightBestDay(
      String worst, String wAvg, String best, String bAvg, String saving) {
    return '${worst}s : $wAvg. ${best}s : $bAvg. $saving à garder.';
  }

  @override
  String get tone_friendly_txnNotFound =>
      'Impossible de trouver cette transaction';

  @override
  String get tone_friendly_futureDate =>
      'Choisissez aujourd\'hui ou une date antérieure';

  @override
  String get tone_friendly_selectAccountAndCategory =>
      'Choisissez d\'abord un compte et une catégorie';

  @override
  String get tone_friendly_addParticipant =>
      'Ajoutez au moins une personne avec qui partager';

  @override
  String get tone_friendly_budgetExceededAdjust =>
      'Vous avez dépassé ce budget. Peut-être devriez-vous lever le pied ?';

  @override
  String get tone_friendly_budgetGreatDiscipline =>
      'Belle discipline ! Vous respectez bien votre budget ✨';

  @override
  String get tone_friendly_comparisonSpentSame =>
      'Les dépenses sont à peu près les mêmes que le mois dernier — stable !';

  @override
  String get tone_friendly_accountUpdated => 'Compte mis à jour !';

  @override
  String get tone_friendly_accountDeleted => 'Compte supprimé';

  @override
  String get tone_friendly_accountLocked =>
      'Ce compte est verrouillé — passez à la version Pro pour l\'utiliser 🔒';

  @override
  String get tone_friendly_categoryCreated => 'Catégorie ajoutée !';

  @override
  String get tone_friendly_categoryDeleted => 'Catégorie supprimée';

  @override
  String get tone_friendly_categoryNameRequired => 'Donnez-lui un nom !';

  @override
  String get tone_friendly_billDeleted => 'Facture supprimée';

  @override
  String get tone_friendly_backupFailed =>
      'La sauvegarde n\'a pas fonctionné — réessayez ?';

  @override
  String get tone_friendly_restoreFailed =>
      'Échec de la restauration — le fichier est-il correct ?';

  @override
  String get tone_friendly_invalidBackupFile =>
      'Cela ne semble pas être un fichier de sauvegarde valide';

  @override
  String get tone_friendly_corruptBackup =>
      'Cette sauvegarde semble corrompue 😕';

  @override
  String get tone_friendly_settingsSaved => 'Enregistré ! ✓';

  @override
  String get tone_friendly_reminderUpdated => 'Rappel mis à jour ⏰';

  @override
  String get tone_friendly_biometricFailed =>
      'Échec de l\'authentification — réessayez';

  @override
  String get tone_friendly_incorrectPin => 'Mauvais code PIN — réessayez';

  @override
  String get tone_friendly_notificationAccessDenied =>
      'Besoin de l\'accès aux notifications pour importer automatiquement les transactions';

  @override
  String get tone_friendly_noBills =>
      'Aucune facture suivie\nAjoutez des factures récurrentes pour ne jamais manquer un paiement';

  @override
  String get tone_friendly_noAccounts =>
      'Pas encore de comptes\nAjoutez-en un pour commencer le suivi';

  @override
  String get tone_friendly_noCategories => 'Pas encore de catégories';

  @override
  String get tone_friendly_noNotifications =>
      'Tout est calme ici\nPas encore de notifications';

  @override
  String get tone_friendly_noData =>
      'Pas encore assez de données\nContinuez le suivi pour débloquer des aperçus';

  @override
  String get tone_friendly_noRecurring =>
      'Aucune transaction récurrente\nAjoutez des factures pour les suivre automatiquement';

  @override
  String get tone_friendly_exportSuccess => 'Rapport exporté ! 📄';

  @override
  String get tone_friendly_purchaseFailed =>
      'L\'achat n\'a pas abouti — réessayez ?';

  @override
  String get tone_friendly_playNotAvailable =>
      'Google Play n\'est pas disponible sur cet appareil';

  @override
  String get tone_friendly_deleteTitle => 'Êtes-vous sûr ?';

  @override
  String get tone_friendly_deleteCancel => 'Le garder';

  @override
  String get tone_friendly_deleteConfirm => 'Supprimer';

  @override
  String get tone_friendly_logoutTitle => 'Déjà sur le départ ?';

  @override
  String get tone_friendly_logoutMessage =>
      'Toutes vos données seront effacées de cet appareil.';

  @override
  String get tone_friendly_logoutConfirm => 'Se déconnecter';

  @override
  String get tone_friendly_currencyChanged => 'Devise de base mise à jour ! 💱';

  @override
  String get tone_friendly_currencyChangeTitle => 'Changer la devise de base ?';

  @override
  String get tone_friendly_currencyChangeCancel => 'La garder';

  @override
  String get tone_friendly_currencyPickerTitle => 'Choisissez votre devise';

  @override
  String get tone_friendly_dashboardWelcomeBack =>
      'Bon retour ! Voyons où vous en êtes';

  @override
  String get tone_professional_txnNotFound => 'Transaction non trouvée.';

  @override
  String get tone_professional_futureDate =>
      'Les dates futures ne sont pas autorisées.';

  @override
  String get tone_professional_selectAccountAndCategory =>
      'Le compte et la catégorie sont obligatoires.';

  @override
  String get tone_professional_addParticipant =>
      'Au moins un participant est requis.';

  @override
  String get tone_professional_budgetExceededAdjust =>
      'Budget dépassé. Examinez les dépenses ou ajustez la limite.';

  @override
  String get tone_professional_budgetGreatDiscipline =>
      'Bien en deçà du budget. Bonne discipline financière.';

  @override
  String get tone_professional_comparisonSpentSame =>
      'Les dépenses sont cohérentes avec le mois dernier.';

  @override
  String get tone_professional_accountUpdated => 'Compte mis à jour.';

  @override
  String get tone_professional_accountDeleted => 'Compte supprimé.';

  @override
  String get tone_professional_accountLocked =>
      'Compte verrouillé. Abonnement Pro requis.';

  @override
  String get tone_professional_categoryCreated => 'Catégorie ajoutée.';

  @override
  String get tone_professional_categoryDeleted => 'Catégorie supprimée.';

  @override
  String get tone_professional_categoryNameRequired =>
      'Le nom de la catégorie est requis.';

  @override
  String get tone_professional_billDeleted => 'Facture supprimée.';

  @override
  String get tone_professional_backupFailed =>
      'Échec de la sauvegarde. Veuillez réessayer.';

  @override
  String get tone_professional_restoreFailed =>
      'Échec de la restauration. Vérifiez le fichier de sauvegarde.';

  @override
  String get tone_professional_invalidBackupFile =>
      'Format de fichier de sauvegarde invalide.';

  @override
  String get tone_professional_corruptBackup =>
      'Le fichier de sauvegarde est corrompu.';

  @override
  String get tone_professional_settingsSaved => 'Paramètres enregistrés.';

  @override
  String get tone_professional_reminderUpdated =>
      'Heure de rappel mise à jour.';

  @override
  String get tone_professional_biometricFailed =>
      'Échec de l\'authentification.';

  @override
  String get tone_professional_incorrectPin => 'Code PIN incorrect.';

  @override
  String get tone_professional_notificationAccessDenied =>
      'L\'accès aux notifications est requis pour l\'importation automatique.';

  @override
  String get tone_professional_noBills => 'Aucune facture récurrente.';

  @override
  String get tone_professional_noAccounts => 'Aucun compte configuré.';

  @override
  String get tone_professional_noCategories => 'Aucune catégorie définie.';

  @override
  String get tone_professional_noNotifications => 'Aucune notification.';

  @override
  String get tone_professional_noData =>
      'Données insuffisantes.\nContinuez à enregistrer des transactions.';

  @override
  String get tone_professional_noRecurring =>
      'Aucune transaction récurrente configurée.';

  @override
  String get tone_professional_exportSuccess => 'Rapport exporté.';

  @override
  String get tone_professional_purchaseFailed =>
      'Échec de l\'achat. Veuillez réessayer.';

  @override
  String get tone_professional_playNotAvailable =>
      'Services Google Play indisponibles.';

  @override
  String get tone_professional_deleteTitle => 'Confirmer la suppression';

  @override
  String get tone_professional_deleteCancel => 'Annuler';

  @override
  String get tone_professional_deleteConfirm => 'Supprimer';

  @override
  String get tone_professional_logoutTitle => 'Confirmer la déconnexion';

  @override
  String get tone_professional_logoutMessage =>
      'Toutes les données locales seront effacées.';

  @override
  String get tone_professional_logoutConfirm => 'Se déconnecter';

  @override
  String get tone_professional_currencyChanged => 'Devise de base mise à jour.';

  @override
  String get tone_professional_currencyChangeTitle =>
      'Changer la devise de base';

  @override
  String get tone_professional_currencyChangeCancel => 'Annuler';

  @override
  String get tone_professional_currencyPickerTitle => 'Sélectionner la devise';

  @override
  String get tone_professional_dashboardWelcomeBack =>
      'Bon retour. Voici votre résumé.';

  @override
  String get tone_motivational_txnNotFound =>
      'Impossible de trouver celle-là — elle a peut-être été supprimée';

  @override
  String get tone_motivational_futureDate =>
      'Restons dans le présent — choisissez aujourd\'hui ou avant';

  @override
  String get tone_motivational_selectAccountAndCategory =>
      'Compte et catégorie d\'abord — vous avez presque fini !';

  @override
  String get tone_motivational_addParticipant =>
      'Ajoutez au moins une personne avec qui partager !';

  @override
  String get tone_motivational_budgetExceededAdjust =>
      'Budget dépassé — mais chaque jour est une chance de repartir à zéro ! 💪';

  @override
  String get tone_motivational_budgetGreatDiscipline =>
      'Discipline incroyable ! Vous avez une sacrée avance ! 🏆';

  @override
  String get tone_motivational_comparisonSpentSame =>
      'C\'est stable ! Des dépenses constantes montrent du contrôle 💪';

  @override
  String get tone_motivational_accountUpdated => 'Compte mis à jour !';

  @override
  String get tone_motivational_accountDeleted => 'Compte supprimé';

  @override
  String get tone_motivational_accountLocked =>
      'Ce compte est verrouillé — passez en Pro pour le déverrouiller ! 🔒';

  @override
  String get tone_motivational_categoryCreated =>
      'Nouvelle catégorie ajoutée !';

  @override
  String get tone_motivational_categoryDeleted => 'Catégorie supprimée';

  @override
  String get tone_motivational_categoryNameRequired => 'Donnez-lui un nom !';

  @override
  String get tone_motivational_billDeleted => 'Facture supprimée';

  @override
  String get tone_motivational_backupFailed =>
      'La sauvegarde n\'a pas fonctionné — réessayez !';

  @override
  String get tone_motivational_restoreFailed =>
      'Échec de la restauration — vérifiez le fichier et réessayez';

  @override
  String get tone_motivational_invalidBackupFile =>
      'Cela ne semble pas être une sauvegarde valide';

  @override
  String get tone_motivational_corruptBackup =>
      'Cette sauvegarde semble endommagée';

  @override
  String get tone_motivational_settingsSaved => 'Enregistré ! ✓';

  @override
  String get tone_motivational_reminderUpdated => 'Rappel fixé ! ⏰';

  @override
  String get tone_motivational_biometricFailed =>
      'Échec de l\'authentification — réessayez !';

  @override
  String get tone_motivational_incorrectPin =>
      'Mauvais code PIN — vous allez y arriver, réessayez !';

  @override
  String get tone_motivational_notificationAccessDenied =>
      'Besoin de l\'accès aux notifications pour suivre automatiquement les transactions';

  @override
  String get tone_motivational_noBills =>
      'Aucune facture suivie\nGardez une longueur d\'avance en ajoutant vos factures récurrentes';

  @override
  String get tone_motivational_noAccounts =>
      'Pas encore de comptes\nAjoutez-en un pour commencer votre voyage financier !';

  @override
  String get tone_motivational_noCategories => 'Pas encore de catégories';

  @override
  String get tone_motivational_noNotifications =>
      'Tout est clair !\nAucune notification — vous gérez la situation';

  @override
  String get tone_motivational_noData =>
      'Continuez ! 📈\nPlus de données signifie de meilleurs aperçus';

  @override
  String get tone_motivational_noRecurring =>
      'Aucune transaction récurrente\nAutomatisez vos factures pour garder une longueur d\'avance !';

  @override
  String get tone_motivational_exportSuccess => 'Rapport exporté ! 📄';

  @override
  String get tone_motivational_purchaseFailed =>
      'L\'achat n\'a pas abouti — réessayez !';

  @override
  String get tone_motivational_playNotAvailable =>
      'Google Play n\'est pas disponible sur cet appareil';

  @override
  String get tone_motivational_deleteTitle => 'Êtes-vous sûr ?';

  @override
  String get tone_motivational_deleteCancel => 'Le garder';

  @override
  String get tone_motivational_deleteConfirm => 'Supprimer';

  @override
  String get tone_motivational_logoutTitle => 'Vous partez ?';

  @override
  String get tone_motivational_logoutMessage =>
      'Toutes les données sur cet appareil seront effacées.';

  @override
  String get tone_motivational_logoutConfirm => 'Se déconnecter';

  @override
  String get tone_motivational_currencyChanged =>
      'Devise changée ! Nouveau chapitre ! 💱';

  @override
  String get tone_motivational_currencyChangeTitle => 'Prêt à changer ?';

  @override
  String get tone_motivational_currencyChangeCancel => 'Pas encore';

  @override
  String get tone_motivational_currencyPickerTitle =>
      'Choisissez votre devise ! 🌍';

  @override
  String get tone_motivational_dashboardWelcomeBack =>
      'Vous êtes de retour ! Continuons à progresser ! 🚀';

  @override
  String get tone_calm_txnNotFound =>
      'Non trouvé. Il se peut qu\'il soit parti.';

  @override
  String get tone_calm_futureDate => 'Restez dans le présent.';

  @override
  String get tone_calm_selectAccountAndCategory =>
      'Compte et catégorie, s\'il vous plaît.';

  @override
  String get tone_calm_addParticipant =>
      'Ajoutez quelqu\'un avec qui partager.';

  @override
  String get tone_calm_budgetExceededAdjust =>
      'Au-delà de la limite. Faites une pause et reconsidérez.';

  @override
  String get tone_calm_budgetGreatDiscipline =>
      'Bien dans les limites. Paisible.';

  @override
  String get tone_calm_comparisonSpentSame =>
      'Les dépenses s\'écoulent au même rythme.';

  @override
  String get tone_calm_accountUpdated => 'Ajusté.';

  @override
  String get tone_calm_accountDeleted => 'Fermé.';

  @override
  String get tone_calm_accountLocked =>
      'Celui-ci est au repos. Le mode Pro le déverrouille.';

  @override
  String get tone_calm_categoryCreated => 'Ajouté.';

  @override
  String get tone_calm_categoryDeleted => 'Supprimé.';

  @override
  String get tone_calm_categoryNameRequired => 'Un nom, s\'il vous plaît.';

  @override
  String get tone_calm_billDeleted => 'Libéré.';

  @override
  String get tone_calm_backupFailed =>
      'Impossible d\'enregistrer. Réessayez doucement.';

  @override
  String get tone_calm_restoreFailed =>
      'Impossible de restaurer. Vérifiez le fichier.';

  @override
  String get tone_calm_invalidBackupFile => 'Ce fichier ne semble pas correct.';

  @override
  String get tone_calm_corruptBackup => 'Le fichier semble endommagé.';

  @override
  String get tone_calm_settingsSaved => 'Enregistré.';

  @override
  String get tone_calm_reminderUpdated => 'Rappel ajusté.';

  @override
  String get tone_calm_biometricFailed => 'Non reconnu. Réessayez.';

  @override
  String get tone_calm_incorrectPin => 'Pas tout à fait. Réessayez.';

  @override
  String get tone_calm_notificationAccessDenied =>
      'Permission requise pour un suivi discret.';

  @override
  String get tone_calm_noBills => 'Rien de récurrent.\nPaisible.';

  @override
  String get tone_calm_noAccounts =>
      'Pas encore de comptes.\nCommencez simplement.';

  @override
  String get tone_calm_noCategories => 'Pas encore de catégories.';

  @override
  String get tone_calm_noNotifications =>
      'Silence.\nRien ne nécessite votre attention.';

  @override
  String get tone_calm_noData =>
      'Pas encore assez.\nCela viendra avec le temps.';

  @override
  String get tone_calm_noRecurring =>
      'Rien de récurrent.\nAjoutez quand vous serez prêt.';

  @override
  String get tone_calm_exportSuccess => 'Exporté.';

  @override
  String get tone_calm_purchaseFailed => 'L\'achat n\'a pas abouti. Réessayez.';

  @override
  String get tone_calm_playNotAvailable => 'Play Store non disponible ici.';

  @override
  String get tone_calm_deleteTitle => 'Laisser partir ?';

  @override
  String get tone_calm_deleteCancel => 'Attendez';

  @override
  String get tone_calm_deleteConfirm => 'Libérer';

  @override
  String get tone_calm_logoutTitle => 'On bouge ?';

  @override
  String get tone_calm_logoutMessage => 'Vos données ici seront effacées.';

  @override
  String get tone_calm_logoutConfirm => 'Partir';

  @override
  String get tone_calm_currencyChanged => 'Devise modifiée.';

  @override
  String get tone_calm_currencyChangeTitle => 'Une nouvelle devise ?';

  @override
  String get tone_calm_currencyChangeCancel => 'Rester';

  @override
  String get tone_calm_currencyPickerTitle => 'Choisissez votre devise';

  @override
  String get tone_calm_dashboardWelcomeBack => 'Bon retour.';

  @override
  String get notif_quietDayTitle => '📊 Journée calme hier';

  @override
  String get notif_heresYesterdayTitle => '📊 Voici hier';

  @override
  String get notif_weekInReviewTitle => '📅 Semaine en revue';

  @override
  String get notif_yourWeekInReviewTitle => '📅 Votre semaine en revue';

  @override
  String get notif_niceOneTitle => '🏆 Bien joué !';

  @override
  String notif_streakDaysTitle(int days) {
    return '🔥 $days jours de suite !';
  }

  @override
  String notif_levelUpTitle(int level) {
    return '🎉 Niveau $level !';
  }

  @override
  String notif_budgetsOverLimitTitle(int count) {
    return '🚨 $count budget(s) au-dessus de la limite';
  }

  @override
  String notif_budgetsGettingTightTitle(int count) {
    return '⚠️ $count budget(s) deviennent serrés';
  }

  @override
  String notif_billDueTitle(String name, String label) {
    return '📅 $name est dû le $label';
  }

  @override
  String get notif_fundsGettingLowTitle => '📉 Les fonds baissent';

  @override
  String notif_categoryCreepingUpTitle(String category) {
    return '💡 $category augmente';
  }

  @override
  String get notif_bigDayTitle => '📈 Wow, grosse journée';

  @override
  String notif_smsFoundTitle(int count) {
    return '📱 $count transactions SMS trouvées';
  }

  @override
  String get notif_smallSpendsTitle => '💧 Les petites dépenses s\'accumulent';

  @override
  String get notif_missYouTitle => '👋 Vous nous manquez';

  @override
  String notif_daysUntrackedTitle(int days) {
    return '📊 $days jours non suivis';
  }

  @override
  String notif_streakEndedTitle(int days) {
    return '💔 Série de $days jours terminée';
  }

  @override
  String get notif_fewDaysUntrackedTitle => '📊 Quelques jours non suivis';

  @override
  String notif_budgetExceededBody(String name) {
    return '$name a dépassé le budget — temps de vérifier';
  }

  @override
  String notif_budgetExceededBodyMulti(String names) {
    return '$names ont dépassé le budget';
  }

  @override
  String notif_budgetWarningBody(String name) {
    return '$name approche de la limite';
  }

  @override
  String notif_budgetWarningBodyMulti(String names) {
    return '$names approchent de leurs limites';
  }

  @override
  String notif_budgetWarningPctBody(String name, String pct) {
    return '$name : $pct% utilisé';
  }

  @override
  String notif_billPaidAutoTitle(String name) {
    return '✅ $name — match auto';
  }

  @override
  String notif_billPaidRecordedTitle(String name) {
    return '✅ $name — enregistré';
  }

  @override
  String get notif_smsLoggedTitle => '✅ Transaction enregistrée';

  @override
  String get notif_smsNeedsReviewTitle => '👀 Nécessite votre vérification';

  @override
  String notif_smsLoggedBody(String amount, String sender) {
    return '$amount de $sender — enregistré auto';
  }

  @override
  String notif_smsLoggedBodyNoAmount(String sender) {
    return 'De $sender — enregistré auto';
  }

  @override
  String notif_smsNeedsReviewBody(String sender) {
    return 'Transaction de $sender — appuyez pour vérifier';
  }

  @override
  String get notif_smsGotItTitle => '✅ Compris !';

  @override
  String get notif_smsAllCaughtUpTitle => '✅ Tout est à jour !';

  @override
  String get notif_smsAlmostThereTitle => '📋 Presque fini !';

  @override
  String get notif_smsNeedHelpTitle => '👋 Hé, j\'ai besoin d\'aide !';

  @override
  String notif_streakOnLineTitle(int days) {
    return '🔥 Série de $days jours en jeu !';
  }

  @override
  String get notif_quickActionTitle => '⚡ 5 secondes suffisent';

  @override
  String get notif_dailyReminderTitle => '📊 Votre journée en chiffres';

  @override
  String get notif_dailyReminderBody =>
      'Voici comment s\'est passé hier — jetez un coup d\'œil';

  @override
  String get notif_weeklyReminderTitle => '📅 Votre semaine résumée';

  @override
  String get notif_weeklyReminderBody =>
      'Voyons comment s\'est passée la semaine — appuyez pour vérifier';

  @override
  String get notif_goalStatusTitle => '🎯 Statut de l\'objectif mensuel';

  @override
  String notif_goalStatusBody(int count, String name, String pct) {
    return 'Vous avez $count objectifs actifs. $name est terminé à $pct% !';
  }

  @override
  String notif_streakCountingTitle(int days) {
    return '🔥 $days jours et ça continue !';
  }

  @override
  String notif_achievementBody(String title, int xp) {
    return '$title — c\'est +$xp XP pour vous';
  }

  @override
  String get notif_levelUpBody =>
      'Vous venez de monter de niveau — continuez !';

  @override
  String get notif_streakMilestoneBody =>
      'C\'est du dévouement — votre série est en feu';

  @override
  String get notif_weeklyZeroBody =>
      'Zéro dépense cette semaine — c\'est impressionnant 💪';

  @override
  String get insight_moneyLeakTitle => 'Petite fuite d\'argent 💧';

  @override
  String insight_bestDayTitle(String day) {
    return 'Les ${day}s vous coûtent le plus cher';
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
  String get bills_howBillsWorkTitle => 'Comment fonctionnent les factures';

  @override
  String get bills_howBillsWorkDesc =>
      'Suivez les factures récurrentes comme le loyer, les abonnements et les services publics. Recevez des rappels avant les dates d\'échéance et marquez les factures comme payées.';

  @override
  String get bills_gotIt => 'Compris';

  @override
  String get bills_addBill => 'Ajouter une facture';

  @override
  String get bills_markAsPaid => 'Marquer comme payée';

  @override
  String get bills_deleteBill => 'Supprimer la facture';

  @override
  String get bills_addNewBill => 'Ajouter une nouvelle facture';

  @override
  String get bills_billName => 'Nom de la facture';

  @override
  String get bills_amount => 'Montant';

  @override
  String get bills_frequency => 'Fréquence';

  @override
  String get bills_monthly => 'Mensuel';

  @override
  String get bills_quarterly => 'Trimestriel';

  @override
  String get bills_yearly => 'Annuel';

  @override
  String get bills_dueDate => 'Date d\'échéance';

  @override
  String get goal_deleteGoalTitle => 'Supprimer l\'objectif ?';

  @override
  String get goal_editGoal => 'Modifier l\'objectif';

  @override
  String get goal_deleteGoal => 'Supprimer l\'objectif';

  @override
  String get goal_saved => 'Économisé';

  @override
  String get goal_target => 'Cible';

  @override
  String get goal_quickDeposit => 'Dépôt rapide';

  @override
  String get goal_targetDate => 'Date cible';

  @override
  String get goal_milestones => 'Jalons';

  @override
  String get goal_recentActivity => 'Activité récente';

  @override
  String get goal_addToGoal => 'Ajouter à l\'objectif';

  @override
  String get goal_goalReached => 'Objectif atteint !';

  @override
  String get goal_whatsThisAbout => 'De quoi s\'agit-il pour cet objectif ?';

  @override
  String get goal_icon => 'Icône';

  @override
  String get goal_color => 'Couleur';

  @override
  String get dashboard_enableCards => 'Activer les cartes';

  @override
  String get recurring_fixedExpenses => 'Dépenses fixes';

  @override
  String get goal_freePlanLimit =>
      'Le plan gratuit permet jusqu\'à 2 objectifs. Passez à Pro pour un nombre illimité.';

  @override
  String get goal_editGoalTitle => 'Modifier l\'objectif';

  @override
  String get goal_newGoalTitle => 'Nouvel objectif';

  @override
  String get goal_yourGoal => 'Votre objectif';

  @override
  String get goal_appearance => 'Apparence';

  @override
  String get goal_goalName => 'Nom de l\'objectif';

  @override
  String get goal_giveGoalName => 'Donnez un nom à votre objectif';

  @override
  String get goal_targetAmount => 'Montant cible';

  @override
  String get goal_enterValidTarget => 'Entrez un montant cible valide';

  @override
  String get goal_alreadySaved => 'Déjà économisé';

  @override
  String get goal_targetDateLabel => 'Date cible';

  @override
  String get goal_setTargetDate => 'Fixer une date cible (facultatif)';

  @override
  String get goal_smartInsight => 'Aperçu intelligent';

  @override
  String get goal_onTrack => 'Sur la bonne voie';

  @override
  String get goal_onTrackDesc => 'Cet objectif est tout à fait réalisable 👍';

  @override
  String get goal_needsEffort => 'Nécessite des efforts';

  @override
  String get goal_needsEffortDesc =>
      'Nécessite un peu plus de discipline d\'épargne';

  @override
  String get goal_ambitious => 'Ambitieux';

  @override
  String get goal_ambitiousDesc => 'Envisagez de repousser la date limite';

  @override
  String get goal_addNote => 'Ajouter une note (facultatif)';

  @override
  String get goal_note => 'Note';

  @override
  String get goal_updateGoal => 'Mettre à jour l\'objectif';

  @override
  String get goal_createGoal => 'Créer l\'objectif';

  @override
  String get profile_developerMode => 'Mode développeur activé ! 🚀';

  @override
  String get profile_couldNotOpenLink => 'Impossible d\'ouvrir le lien';

  @override
  String get profile_about => 'À propos';

  @override
  String get profile_unableToCheckUpdates =>
      'Impossible de vérifier les mises à jour';

  @override
  String get profile_openSourceLicenses => 'Licences open source';

  @override
  String get account_totalValue => 'Valeur totale';

  @override
  String get account_gainLoss => 'Gain/Perte';

  @override
  String get account_holdings => 'Avoirs';

  @override
  String get account_addHolding => 'Ajouter un avoir';

  @override
  String get account_addMissingTransaction =>
      'Ajouter une transaction manquante';

  @override
  String get account_whatWasThisFor => 'C\'était pour quoi cette transaction ?';

  @override
  String get budget_used => 'Utilisé';

  @override
  String get budget_selectAtLeastOneTag =>
      'Veuillez sélectionner au moins une étiquette';

  @override
  String get budget_over => 'au-dessus';

  @override
  String get budget_left => 'restant';

  @override
  String get budget_breakdown => 'RÉPARTITION';

  @override
  String get budget_basicInfo => 'Informations de base';

  @override
  String get budget_duration => 'Durée';

  @override
  String get budget_budgetType => 'Type de budget';

  @override
  String get budget_selectType => 'Sélectionner le type';

  @override
  String get budget_categoryAllocation => 'Allocation par catégorie';

  @override
  String get budget_totalBudget => 'Budget total';

  @override
  String get budget_allocated => 'Alloué';

  @override
  String get budget_remaining => 'Restant';

  @override
  String get budget_overBudget => 'Hors budget';

  @override
  String get budget_safeToSpend => 'Sûr à dépenser';

  @override
  String get budget_startDate => 'Date de début';

  @override
  String get budget_endDate => 'Date de fin';

  @override
  String get budget_selectTags => 'Sélectionner les étiquette';

  @override
  String get budget_tagInfo =>
      'Toutes les dépenses avec les étiquettes sélectionnées seront comptabilisées dans ce budget.';

  @override
  String get budget_noTags =>
      'Pas encore d\'étiquettes. Ajoutez d\'abord des étiquettes à vos transactions.';

  @override
  String get budget_freePlanLimit =>
      'Le plan gratuit permet jusqu\'à 2 budgets. Passez à Pro pour un nombre illimité.';

  @override
  String budget_daysRemaining(Object count) {
    return '$count jours';
  }

  @override
  String get budget_delete => 'Supprimer';

  @override
  String get budget_emotionUnderControl => 'Dépenses sous contrôle 💪';

  @override
  String get budget_emotionHalfway => 'À la moitié du mois ✨';

  @override
  String get budget_emotionAlmostThere => 'Ça devient serré, soyez prudent ⚠️';

  @override
  String get budget_emotionExceeded =>
      'Budget dépassé, il est temps d\'ajuster 🔴';

  @override
  String get budget_highlightLabel => 'Nécessite une attention particulière';

  @override
  String get budget_overBudgetSection => 'Hors budget';

  @override
  String get budget_activeBudgets => 'Budgets actifs';

  @override
  String get budget_onTrackSection => 'Sur la bonne voie';

  @override
  String get budget_spendingPace => 'Rythme des dépenses';

  @override
  String budget_dailyActual(Object amount) {
    return '$amount/jour réel';
  }

  @override
  String budget_dailyAllowed(Object amount) {
    return '$amount/jour autorisé';
  }

  @override
  String get budget_stepNote0 =>
      'Donnez un nom à votre budget et fixez le montant que vous souhaitez dépenser.';

  @override
  String get budget_stepNote1 =>
      'Choisissez la fréquence de répétition de ce budget et sélectionnez les dates.';

  @override
  String get budget_stepNote2 =>
      'Choisissez les catégories ou les étiquettes que ce budget doit suivre.';

  @override
  String get budget_autoDistributed => 'auto';

  @override
  String budget_categoriesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count catégories',
      one: '1 catégorie',
    );
    return '$_temp0';
  }

  @override
  String budget_tagsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count étiquettes',
      one: '1 étiquette',
    );
    return '$_temp0';
  }

  @override
  String get budget_typeCategoryWise => 'Par catégorie';

  @override
  String get budget_typeTagWise => 'Par étiquette';

  @override
  String get budget_typeDayWise => 'Quotidien';

  @override
  String get budget_typeFestival => 'Festival';

  @override
  String get budget_typeTravel => 'Voyage';

  @override
  String get budget_typeDescCategoryWise =>
      'Définir des budgets pour des catégories de dépenses spécifiques';

  @override
  String get budget_typeDescTagWise =>
      'Définir des budgets pour des étiquettes spécifiques';

  @override
  String get budget_typeDescDayWise =>
      'Définir une limite de dépense quotidienne';

  @override
  String get budget_typeDescFestival =>
      'Budget pour les festivals et événements spéciaux';

  @override
  String get budget_typeDescTravel => 'Budget pour les frais de voyage';

  @override
  String get budget_reviewTitle => 'Vérifier et enregistrer';

  @override
  String get budget_selectCategories => 'Sélectionner des catégories';

  @override
  String get budget_noActiveTrip =>
      'Aucun voyage actif. Commencez d\'abord un voyage pour utiliser le budget voyage.';

  @override
  String get budget_stepNote3 =>
      'Vérifiez tout avant d\'enregistrer. Appuyez sur n\'importe quelle section pour la modifier.';

  @override
  String budget_categoryDeleteWarning(Object count) {
    return 'Cette catégorie est utilisée dans $count budget(s). Sa suppression affectera le suivi du budget.';
  }

  @override
  String get budget_invalidCategories =>
      'Certaines catégories ont été supprimées. Modifiez ce budget pour corriger.';

  @override
  String budget_pastBudgets(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'budgets passés',
      one: 'budget passé',
    );
    return '$count $_temp0';
  }

  @override
  String get category_categoryName => 'Nom de la catégorie';

  @override
  String get category_keywords => 'Mots-clés (séparés par des virgules)';

  @override
  String get category_noneTopLevel => 'Aucun (niveau supérieur)';

  @override
  String get common_searchCurrency => 'Rechercher une devise...';

  @override
  String get common_selectCategory => 'Sélectionner une catégorie';

  @override
  String get common_noDescription => 'Pas de description';

  @override
  String get common_errors => 'Erreurs';

  @override
  String get dashboard_enableCardsDesc =>
      'Activez les cartes du tableau de bord pour voir votre aperçu financier';

  @override
  String get dashboard_customizeDashboard => 'Personnaliser le tableau de bord';

  @override
  String get dashboard_newToApp => 'Nouveau sur Mudra Manager ?';

  @override
  String get dashboard_tapToExploreHelp =>
      'Appuyez pour explorer le guide d\'aide';

  @override
  String get dashboard_tapToReviewTxn =>
      'Appuyez pour vérifier les transactions';

  @override
  String get dashboard_autoImportPaused => 'Importation automatique en pause';

  @override
  String get dashboard_enable => 'Activer';

  @override
  String get dashboard_enableAutoImport => 'Activer l\'importation automatique';

  @override
  String get dashboard_autoTrackDesc =>
      'Suivi automatique des transactions à partir des notifications bancaires';

  @override
  String get profile_awesomeUser => 'Utilisateur génial';

  @override
  String get profile_logout => 'Déconnexion';

  @override
  String get profile_proActiveLabel => 'Pro Actif';

  @override
  String get profile_freeTierLabel => 'Version gratuite';

  @override
  String get profile_fullAccessLabel => 'Accès complet';

  @override
  String get profile_upgradeToProLabel => 'Passer à la version Pro';

  @override
  String get profile_fullAccessEnjoy =>
      'Accès complet — profitez de toutes les fonctionnalités !';

  @override
  String profile_fullAccessDaysRemaining(int days) {
    return 'Accès complet — $days jours restants';
  }

  @override
  String profile_fullAccessEndsIn(int days) {
    return 'L\'accès complet se termine dans $days jours';
  }

  @override
  String get profile_trialEnded =>
      'Période d\'essai terminée — passez à la version supérieure pour conserver toutes les fonctionnalités';

  @override
  String get profile_unlimitedDesc =>
      'Comptes illimités, analyses et plus encore';

  @override
  String get profile_expiredRenew => 'Expiré — appuyez pour renouveler';

  @override
  String get profile_expiresToday => 'Expire aujourd\'hui';

  @override
  String get profile_renewsTomorrow => 'Renouvelle demain';

  @override
  String profile_renewsInDays(int days) {
    return 'Renouvelle dans $days jours';
  }

  @override
  String get profile_activeSubscription => 'Abonnement actif';

  @override
  String get profile_unknown => 'Inconnu';

  @override
  String get profile_accountsLabel => 'Comptes';

  @override
  String get profile_categoriesLabel => 'Catégories';

  @override
  String get profile_budgetsLabel => 'Budgets';

  @override
  String get profile_bestStreakLabel => 'Meilleure série';

  @override
  String get profile_yourAchievementsLabel => 'Vos succès';

  @override
  String get profile_aboutMudra => 'À propos de Mudra Manager';

  @override
  String get profile_aboutMudraDesc =>
      'Votre compagnon de finance personnelle. Suivez vos dépenses, gérez vos budgets et obtenez des aperçus sur vos habitudes de dépenses.';

  @override
  String get txnList_searchHint => 'Rechercher des transactions...';

  @override
  String get txnList_category => 'Catégorie';

  @override
  String get txnList_dateRange => 'Plage de dates';

  @override
  String get txnList_tag => 'Étiquette';

  @override
  String get txnList_allTransactions => 'Toutes les transactions';

  @override
  String get txnList_tapStartEnd => 'Appuyez sur la date de début et de fin';

  @override
  String get txnList_scrollToLoad => 'Faites défiler pour charger plus';

  @override
  String get txnList_month => 'Mois';

  @override
  String get txnList_previousMonth => 'Mois précédent';

  @override
  String get txnList_resetToCurrentMonth => 'Réinitialiser au mois en cours';

  @override
  String get txnList_selectMonth => 'Sélectionner le mois';

  @override
  String get txnList_nextMonth => 'Mois suivant';

  @override
  String get txnList_monthView => 'Vue mensuelle';

  @override
  String get txnList_subscriptionTagRemoved =>
      'Étiquette d\'abonnement supprimée';

  @override
  String get txnList_filterByTag => 'Filtrer par étiquette';

  @override
  String get txnList_noTagsYet =>
      'Pas encore d\'étiquettes. Ajoutez d\'abord des étiquettes à vos transactions.';

  @override
  String get txnList_clear => 'Effacer';

  @override
  String get txnList_filterOptions => 'Options de filtrage';

  @override
  String get txnList_transactionType => 'Type de transaction';

  @override
  String get txnList_allCategories => 'Toutes les catégories';

  @override
  String get txnList_selectDateRange => 'Sélectionner la plage de dates';

  @override
  String get txnList_clearDateRange => 'Effacer la plage de dates';

  @override
  String get txnList_convertToTransfer => 'Convertir en transfert';

  @override
  String get txnList_convertToTransferDesc =>
      'C\'était en réalité un transfert entre vos comptes';

  @override
  String get txnList_convertedToTransfer => 'Converti en transfert';

  @override
  String get stats_today => 'Aujourd\'hui';

  @override
  String get stats_week => 'Semaine';

  @override
  String get stats_month => 'Mois';

  @override
  String get stats_year => 'Année';

  @override
  String get stats_custom => 'Personnalisé';

  @override
  String get stats_unableToLoad => 'Impossible de charger les statistiques';

  @override
  String get stats_overview => 'Aperçu';

  @override
  String get stats_trends => 'Tendances';

  @override
  String get stats_spendingByDay => 'Dépenses par jour';

  @override
  String get stats_insights => 'Aperçus';

  @override
  String get stats_nextMonthForecast => 'Prévisions pour le mois prochain';

  @override
  String get stats_topSpending => 'Dépenses principales';

  @override
  String get stats_12MonthTrend => 'Tendance sur 12 mois';

  @override
  String stats_trendUp(Object category, Object percent) {
    return '$category est en hausse — $percent% des dépenses totales';
  }

  @override
  String stats_trendDown(Object category) {
    return '$category est en baisse ce mois-ci 📉';
  }

  @override
  String stats_topCategory(Object category, Object percent) {
    return '$category est votre catégorie principale — $percent% des dépenses';
  }

  @override
  String stats_weekendPeak(Object day) {
    return 'Vous dépensez plus le week-end — le $day est votre jour de pic';
  }

  @override
  String stats_weekdayPeak(Object day) {
    return 'Les jours de semaine coûtent plus cher — le $day est votre plus gros jour';
  }

  @override
  String stats_peakAndQuiet(Object peak, Object quiet) {
    return '$peak est votre jour de pic de dépenses, $quiet est le plus calme';
  }

  @override
  String get stats_categoryTrends => 'Tendances par catégorie';

  @override
  String get stats_spendingByTag => 'Dépenses par étiquette';

  @override
  String get stats_netWorth => 'Valeur nette';

  @override
  String get stats_savings => 'Économies';

  @override
  String get stats_categoryImpact => 'IMPACT PAR CATÉGORIE';

  @override
  String get stats_income => 'Revenu';

  @override
  String get stats_expense => 'Dépense';

  @override
  String get stats_net => 'Net';

  @override
  String get stats_dailySpendingPace => 'Rythme de dépenses quotidien';

  @override
  String get stats_topCategories => 'Principales catégories';

  @override
  String stats_projectedThisMonth(Object amount) {
    return 'Prévision : $amount ce mois-ci';
  }

  @override
  String stats_byDay(Object day, Object amount, Object month) {
    return 'Au jour $day : $amount en $month';
  }

  @override
  String get stats_steadyHeadline => 'On garde le cap';

  @override
  String get stats_steadyDetail =>
      'Vos dépenses sont constantes — c\'est de la discipline.';

  @override
  String get stats_doingGreatHeadline => 'Vous vous en sortez très bien 🌟';

  @override
  String get stats_spendingUpHeadline =>
      'Attention — les dépenses sont en hausse';

  @override
  String get stats_downloadPdf => 'Télécharger le PDF';

  @override
  String get stats_generating => 'Génération...';

  @override
  String get recap_belowAvg => 'Sous la moyenne';

  @override
  String get recap_aboveAvg => 'Au-dessus de la moyenne';

  @override
  String get recap_recurring => 'Récurrent';

  @override
  String get recap_oneTime => 'Ponctuel';

  @override
  String get recap_recapTitle => 'Récapitulatif';

  @override
  String get notifSettings_dailySummary => 'Résumé quotidien';

  @override
  String get notifSettings_weeklySummary => 'Résumé hebdomadaire';

  @override
  String get notifSettings_comeBackNudges => 'Rappels de retour';

  @override
  String get notifSettings_streakReminder => 'Rappel de série';

  @override
  String get notifSettings_smartAlerts => 'Alertes intelligentes';

  @override
  String get notifSettings_selectDay => 'Sélectionner le jour';

  @override
  String get notifSettings_summariesDesc =>
      'Les résumés affichent les dépenses, les revenus, la catégorie principale et le solde';

  @override
  String get notifSettings_reminderTime => 'Heure du rappel';

  @override
  String get notifSettings_sendTestNotif => 'Envoyer une notification de test';

  @override
  String get notifSettings_testNotifSent => 'Notification de test envoyée';

  @override
  String get notifSettings_dailyNudgeStreak =>
      'Rappel quotidien pour garder votre série';

  @override
  String get notifSettings_summaryDay => 'Jour du résumé';

  @override
  String get notifSettings_gentleReminders =>
      'Rappels doux si vous n\'avez pas ouvert l\'application';

  @override
  String get notifSettings_budgetWarningsDesc =>
      'Avertissements de budget, pics de dépenses, rappels de factures';

  @override
  String get notifSettings_localNotifDisclaimer =>
      'Les notifications sont délivrées localement sur votre appareil. Aucune donnée n\'est envoyée à un serveur.';

  @override
  String get smsImport_autoImport => 'Importation automatique';

  @override
  String get smsImport_permissions => 'Autorisations';

  @override
  String get smsImport_notifAccess => 'Accès aux notifications';

  @override
  String get smsImport_notifAccessEnabled => 'Accès aux notifications activé';

  @override
  String get smsImport_allowReadingNotif =>
      'Autoriser la lecture des notifications bancaires';

  @override
  String get smsImport_autoDetectTxn =>
      'Détection automatique des transactions à partir des notifications';

  @override
  String get smsImport_privacyNote =>
      'Les notifications sont lues localement sur votre appareil pour détecter les transactions. Rien n\'est jamais téléchargé ou partagé.';

  @override
  String get smsImport_tools => 'Outils';

  @override
  String get smsImport_txnActivity => 'Activité de transaction';

  @override
  String get smsImport_viewDetectedTxn =>
      'Voir toutes les transactions détectées';

  @override
  String get smsImport_clearHistory => 'Effacer l\'historique de traitement';

  @override
  String get smsImport_resetDetection =>
      'Réinitialiser l\'historique de détection';

  @override
  String get smsImport_howItWorks => 'Comment ça marche';

  @override
  String get smsImport_readsBankNotif =>
      'Lit les notifications des banques et portefeuilles';

  @override
  String get smsImport_dataStaysOnDevice =>
      'Toutes les données restent sur votre appareil';

  @override
  String get smsImport_autoCreatesTxn =>
      'Crée automatiquement des transactions';

  @override
  String get smsImport_personalIgnored =>
      'Les notifications personnelles sont ignorées';

  @override
  String get smsImport_noDataSent => 'Aucune donnée envoyée à un serveur';

  @override
  String get smsImport_active => 'Actif';

  @override
  String get smsImport_inactive => 'Inactif';

  @override
  String get smsImport_grantAccess =>
      'Accordez l\'accès aux notifications pour commencer';

  @override
  String get smsImport_notAvailableIos => 'Non disponible sur iOS';

  @override
  String get smsImport_enableAccessFirst =>
      'Activez d\'abord l\'accès aux notifications';

  @override
  String get smsImport_notifAccessRequired => 'Accès aux notifications requis';

  @override
  String get smsImport_notifAccessDesc =>
      'Mudra Manager a besoin de l\'accès aux notifications pour détecter automatiquement les transactions de vos applications bancaires et de portefeuille.';

  @override
  String get smsImport_onlyBankRead =>
      'Seules les notifications de banque/portefeuille sont lues';

  @override
  String get smsImport_personalNeverRead =>
      'Les messages personnels ne sont jamais lus';

  @override
  String get smsImport_openSettings => 'Ouvrir les paramètres';

  @override
  String get smsImport_clearHistoryConfirm =>
      'Effacer l\'historique de traitement ?';

  @override
  String get smsImport_clearHistoryWarning =>
      'Les notifications précédemment détectées seront traitées à nouveau, ce qui peut créer des transactions en double.';

  @override
  String get smsImport_tapAgainSettings =>
      'Appuyez à nouveau pour ouvrir les paramètres système';

  @override
  String get upgrade_purchaseFailed => 'L\'achat a échoué. Veuillez réessayer.';

  @override
  String get upgrade_purchasePending =>
      'Achat en attente. Le mode Pro s\'activera une fois le paiement terminé.';

  @override
  String get upgrade_welcomePro => 'Bienvenue en mode Pro !';

  @override
  String get upgrade_allFeaturesUnlocked =>
      'Toutes les fonctionnalités sont maintenant déverrouillées. Merci pour votre soutien !';

  @override
  String get upgrade_startExploring => 'Commencer l\'exploration';

  @override
  String get upgrade_yourProFeatures => 'Vos fonctionnalités Pro';

  @override
  String get upgrade_manageSubscription =>
      'Pour gérer votre abonnement, allez sur Google Play Store > Abonnements.';

  @override
  String get upgrade_everythingInPro => 'Tout dans Pro';

  @override
  String get upgrade_chooseYourPlan => 'Choisissez votre plan';

  @override
  String get upgrade_yearly => 'Annuel';

  @override
  String get upgrade_save43 => 'Économisez 43 %';

  @override
  String get upgrade_monthly => 'Mensuel';

  @override
  String get upgrade_continue => 'Continuer';

  @override
  String get upgrade_restorePurchases => 'Restaurer les achats';

  @override
  String get upgrade_renewsToday => 'Renouvelé aujourd\'hui';

  @override
  String get upgrade_mudraManagerPro => 'Mudra Manager Pro';

  @override
  String get upgrade_unlockFullPower =>
      'Déverrouillez toute la puissance de vos finances';

  @override
  String upgrade_unlockAccountsTitle(int count) {
    return 'Unlock all $count accounts';
  }

  @override
  String upgrade_accountsFreePlanLimit(int max) {
    return 'Free plan includes $max accounts. Upgrade to Pro to use all your accounts.';
  }

  @override
  String get day_monday => 'Lundi';

  @override
  String get day_tuesday => 'Mardi';

  @override
  String get day_wednesday => 'Mercredi';

  @override
  String get day_thursday => 'Jeudi';

  @override
  String get day_friday => 'Vendredi';

  @override
  String get day_saturday => 'Samedi';

  @override
  String get day_sunday => 'Dimanche';

  @override
  String get recap_income => 'Revenu';

  @override
  String get recap_expense => 'Dépense';

  @override
  String get recap_saved => 'Économisé';

  @override
  String get recap_dailySpending => 'Dépenses quotidiennes';

  @override
  String get recap_spendingPace => 'Rythme de dépenses';

  @override
  String get recap_recurringVsOneTime => 'Récurrent vs Ponctuel';

  @override
  String get recap_topCategories => 'Principales catégories';

  @override
  String get recap_mostFrequent => 'Plus fréquents';

  @override
  String get recap_incomeSources => 'Sources de revenus';

  @override
  String get recap_byAccount => 'Par compte';

  @override
  String get recap_budgetHealth => 'Santé du budget';

  @override
  String get recap_biggestExpenses => 'Plus grosses dépenses';

  @override
  String get recap_biggestIncome => 'Plus gros revenus';

  @override
  String get recap_generating => 'Génération...';

  @override
  String get recap_avgPerDay => 'Moy./jour';

  @override
  String get recap_weekdayAvg => 'Moy. semaine';

  @override
  String get recap_weekendAvg => 'Moy. week-end';

  @override
  String get recap_budgets => 'Budgets';

  @override
  String get recap_badges => 'Badges';

  @override
  String get recap_streak => 'Série';

  @override
  String get recap_best => 'Meilleur';

  @override
  String get recap_savings => 'Économies';

  @override
  String get about_developerMode => 'Mode développeur activé !';

  @override
  String get about_couldNotOpenLink => 'Impossible d\'ouvrir le lien';

  @override
  String get about_title => 'À propos';

  @override
  String get about_privacyDesc =>
      'Tout reste sur votre appareil. Pas de comptes, pas de cloud, pas de collecte de données. Vos finances n\'appartiennent qu\'à vous.';

  @override
  String get about_legalTransparency => 'Légal et Transparence';

  @override
  String get about_privacyPolicy => 'Politique de confidentialité';

  @override
  String get about_privacyPolicyDesc => 'Comment nous protégeons vos données';

  @override
  String get about_termsOfService => 'Conditions d\'utilisation';

  @override
  String get about_termsDesc => 'Conditions d\'utilisation de l\'application';

  @override
  String get about_openSourceLicenses => 'Licences open source';

  @override
  String get about_openSourceDesc => 'Bibliothèques tierces que nous utilisons';

  @override
  String get about_supportConnect => 'Support et Contact';

  @override
  String get about_checkForUpdates => 'Vérifier les mises à jour';

  @override
  String get about_checkForUpdatesDesc =>
      'Vérifier manuellement la version de l\'application';

  @override
  String get about_latestVersion => 'Vous utilisez la dernière version';

  @override
  String get about_unableToCheck => 'Impossible de vérifier les mises à jour';

  @override
  String get about_officialWebsite => 'Site officiel';

  @override
  String get about_visitWebsite => 'Visitez mudramanager.com';

  @override
  String get about_contactSupport => 'Contacter le support';

  @override
  String get about_contactSupportDesc =>
      'Obtenir de l\'aide ou signaler des problèmes';

  @override
  String get about_rateApp => 'Évaluer l\'application';

  @override
  String get about_rateAppDesc =>
      'Partagez votre expérience sur le magasin d\'applications';

  @override
  String get about_developerModeSection => 'Mode développeur';

  @override
  String get about_mudraManager => 'Mudra Manager';

  @override
  String get about_secureFinancial => 'Commande financière sécurisée';

  @override
  String get about_loadingLicenses => 'Chargement des licences...';

  @override
  String get appearance_title => 'Apparence';

  @override
  String get appearance_themeMode => 'Mode thématique';

  @override
  String get appearance_display => 'Affichage';

  @override
  String get appearance_toneVoice => 'Ton et voix';

  @override
  String get appearance_changesApplyInstantly =>
      'Les changements de thème et d\'affichage s\'appliquent instantanément.';

  @override
  String get appearance_darkAppearance => 'Apparence sombre';

  @override
  String get appearance_lightAppearance => 'Apparence claire';

  @override
  String get appearance_accountStyle => 'Style de compte';

  @override
  String get appearance_cards => 'Cartes';

  @override
  String get appearance_stack => 'Pile';

  @override
  String get appearance_bento => 'Bento';

  @override
  String get appearance_highContrast => 'Contraste élevé';

  @override
  String get appearance_highContrastDesc =>
      'Améliore la lisibilité pour les malvoyants';

  @override
  String get appearance_guestMode => 'Mode invité';

  @override
  String get appearance_guestModeOnDesc => 'Les montants réels sont masqués';

  @override
  String get appearance_guestModeOffDesc =>
      'Masquer les données financières sensibles';

  @override
  String get appearance_lightMode => 'Mode clair';

  @override
  String get appearance_darkMode => 'Mode sombre';

  @override
  String get appearance_systemDefault => 'Par défaut du système';

  @override
  String get analytics_financialHealthScore => 'Score de santé financière';

  @override
  String get analytics_savingsRate => 'Taux d\'épargne';

  @override
  String get analytics_expenseRatio => 'Ratio de dépenses';

  @override
  String get analytics_insights => 'Aperçus';

  @override
  String get analytics_spendingPrediction => 'Prédiction de dépenses';

  @override
  String get analytics_nextMonth => 'Mois prochain';

  @override
  String get analytics_basedOnAvg => 'Basé sur la moyenne des 3 derniers mois';

  @override
  String get analytics_categoryTrends => 'Tendances par catégorie';

  @override
  String get analytics_spendingByDay => 'Dépenses par jour';

  @override
  String get trip_notFound => 'Voyage non trouvé';

  @override
  String get trip_notFoundMsg => 'Voyage non trouvé';

  @override
  String get trip_tripLabel => 'Voyage';

  @override
  String get trip_groupLabel => 'Groupe';

  @override
  String get trip_archiveTripTitle => 'Archiver le voyage';

  @override
  String get trip_archiveMsg =>
      'Ce voyage sera déplacé vers les archives. Toutes les données et les règlements seront conservés.';

  @override
  String get trip_archiveConfirm => 'Archiver';

  @override
  String get trip_totalSpent => 'Total dépensé';

  @override
  String get trip_splitExpense => 'Partager la dépense';

  @override
  String get trip_allPeople => 'Toutes les personnes';

  @override
  String get trip_allCategories => 'Toutes les catégories';

  @override
  String get trip_uncategorized => 'Non catégorisé';

  @override
  String get trip_removeExpense => 'Supprimer la dépense';

  @override
  String get trip_removeFromTrip => 'Supprimer cette dépense du voyage ?';

  @override
  String get trip_removeFromGroup => 'Supprimer cette dépense du groupe ?';

  @override
  String get trip_removeConfirm => 'Supprimer';

  @override
  String get trip_unknown => 'Inconnu';

  @override
  String get trip_youPaid => 'Vous avez payé';

  @override
  String get trip_noPendingSettlements =>
      'Aucun règlement en attente pour ce voyage';

  @override
  String get trip_everyoneSquare => 'Tout le monde est quitte';

  @override
  String get trip_archiveGroupTitle => 'Archiver le groupe';

  @override
  String get trip_archiveGroupMsg =>
      'Ce groupe sera déplacé vers les archives. Toutes les données et les règlements seront conservés.';

  @override
  String get editTrip_addParticipant => 'Ajouter un participant';

  @override
  String get editTrip_name => 'Nom';

  @override
  String get editTrip_enterName => 'Entrez le nom du participant';

  @override
  String get editTrip_finalizeTrip => 'Finaliser le voyage';

  @override
  String get editTrip_closeGroup => 'Fermer le groupe';

  @override
  String get editTrip_finalizeMsg =>
      'Ceci marquera le voyage comme terminé. Vous ne pourrez plus ajouter de dépenses après cela.';

  @override
  String get editTrip_closeGroupMsg =>
      'Ceci fermera le groupe. Vous ne pourrez plus ajouter de dépenses après cela.';

  @override
  String get editTrip_finalize => 'Finaliser';

  @override
  String get editTrip_close => 'Fermer';

  @override
  String get editTrip_groupNotFound => 'Groupe non trouvé';

  @override
  String get editTrip_groupNotFoundMsg => 'Groupe non trouvé';

  @override
  String get editTrip_editTrip => 'Modifier le voyage';

  @override
  String get editTrip_editGroup => 'Modifier le groupe';

  @override
  String get editTrip_editSplitGroup => 'Modifier le groupe de partage';

  @override
  String get editTrip_createTrip => 'Créer un voyage';

  @override
  String get editTrip_createSplitGroup => 'Créer un groupe de partage';

  @override
  String get editTrip_travelTrip => 'Voyage de tourisme';

  @override
  String get editTrip_splitGroup => 'Groupe de partage';

  @override
  String get editTrip_tripDetails => 'Détails du voyage';

  @override
  String get editTrip_groupDetails => 'Détails du groupe';

  @override
  String get editTrip_tripName => 'Nom du voyage';

  @override
  String get editTrip_groupName => 'Nom du groupe';

  @override
  String get editTrip_descriptionOptional => 'Description (facultatif)';

  @override
  String get editTrip_tripHint => 'Vacances à la plage avec des amis';

  @override
  String get editTrip_groupHint => 'Partager les dépenses avec des amis';

  @override
  String get editTrip_budgetOptional => 'Budget (facultatif)';

  @override
  String get editTrip_currency => 'Devise';

  @override
  String get editTrip_baseCurrencyDefault => 'Devise de base (par défaut)';

  @override
  String get editTrip_duration => 'Durée';

  @override
  String get editTrip_warningDateChange => 'Avertissement : Changement de date';

  @override
  String get expense_notFound => 'Non trouvé';

  @override
  String get expense_notFoundMsg => 'Dépense non trouvée';

  @override
  String get expense_details => 'Détails de la dépense';

  @override
  String get expense_paidBy => 'Payé par';

  @override
  String get expense_you => 'Vous';

  @override
  String get expense_yourShare => 'Votre part';

  @override
  String get expense_noteLabel => 'Note';

  @override
  String get expense_editSplit => 'Modifier le partage';

  @override
  String get expense_splitType => 'Type de partage';

  @override
  String get expense_equal => 'Égal';

  @override
  String get expense_custom => 'Personnalisé';

  @override
  String get expense_participants => 'Participants';

  @override
  String get expense_autoFillRemaining => 'Remplissage automatique du reste';

  @override
  String get expense_deleteExpense => 'Supprimer la dépense';

  @override
  String get expense_deleteExpenseMsg =>
      'Ceci ajustera le solde de chacun. Continuer ?';

  @override
  String get billCenter_overdue => 'En retard';

  @override
  String get billCenter_thisWeek => 'Cette semaine';

  @override
  String get billCenter_thisMonth => 'Ce mois-ci';

  @override
  String get billCenter_later => 'Plus tard';

  @override
  String get billCenter_totalUpcoming => 'Total à venir';

  @override
  String get billCenter_today => 'Aujourd\'hui';

  @override
  String get billCenter_tomorrow => 'Demain';

  @override
  String get billCenter_afterUpcoming => 'Après les factures à venir';

  @override
  String get billCenter_dueToday => 'Dû aujourd\'hui';

  @override
  String get billCenter_paid => 'Payé';

  @override
  String get billCenter_pay => 'Payer';

  @override
  String get billCenter_existingTxnFound => 'Transaction existante trouvée';

  @override
  String get billCenter_linkTransaction => 'Lier cette transaction';

  @override
  String get billCenter_createNewEntry => 'Créer une nouvelle entrée';

  @override
  String get comparison_steady => 'On garde le cap';

  @override
  String get comparison_steadyDesc =>
      'Vos dépenses sont constantes — c\'est de la discipline.';

  @override
  String get comparison_doingGreat => 'Vous vous en sortez très bien';

  @override
  String get comparison_headsUp => 'Attention — les dépenses sont en hausse';

  @override
  String get reconcile_title => 'Rapprocher';

  @override
  String get reconcile_info =>
      'Entrez le solde actuel affiché dans votre application bancaire ou votre livret. Nous ajusterons la différence automatiquement.';

  @override
  String get reconcile_balanceInApp => 'Solde dans l\'application';

  @override
  String get reconcile_actualBalance => 'Solde bancaire réel';

  @override
  String get reconcile_balanced => 'Équilibré !';

  @override
  String get reconcile_difference => 'Différence';

  @override
  String reconcile_incomeAdjustment(String amount) {
    return 'Un ajustement de revenu de $amount sera ajouté.';
  }

  @override
  String reconcile_expenseAdjustment(String amount) {
    return 'Un ajustement de dépense de $amount sera ajouté.';
  }

  @override
  String get balanceHistory_currentBalance => 'Solde actuel';

  @override
  String get balanceHistory_highest => 'Le plus haut';

  @override
  String get balanceHistory_lowest => 'Le plus bas';

  @override
  String get balanceHistory_average => 'Moyenne';

  @override
  String get common_errorLoading => 'Échec du chargement des données';

  @override
  String get balanceHistory_trend => 'Tendance sur 30 jours';

  @override
  String get balanceHistory_growing => 'Votre solde augmente 📈';

  @override
  String get balanceHistory_declining => 'Le solde a chuté — récupérons 💪';

  @override
  String get balanceHistory_steady => 'Se maintient stable ⚖️';

  @override
  String get account_editTitle => 'Modifier le compte';

  @override
  String get account_newTitle => 'Nouveau compte';

  @override
  String get account_name => 'Nom du compte';

  @override
  String get account_typeLabel => 'Type de compte';

  @override
  String get account_detailsLabel => 'Détails';

  @override
  String get account_colorLabel => 'Couleur';

  @override
  String get account_currencyLabel => 'Devise';

  @override
  String get account_balance => 'Solde';

  @override
  String get account_outstanding => 'Encours';

  @override
  String get account_last4 => '4 derniers chiffres';

  @override
  String get account_last4Helper => 'Pour le rapprochement automatique par SMS';

  @override
  String get account_initialBalance => 'Solde initial';

  @override
  String get account_cardPaidOff => 'Entrez 0 si la carte est remboursée';

  @override
  String get account_min4 => 'Au moins 4 chiffres';

  @override
  String get account_max4 => 'Seulement les 4 derniers chiffres';

  @override
  String get iconPicker_title => 'Choisir une icône';

  @override
  String get iconPicker_search => 'Rechercher des icônes...';

  @override
  String get iconPicker_noResults => 'Aucune icône trouvée';

  @override
  String get colorPicker_title => 'Choisir une couleur';

  @override
  String get color_red => 'Rouge';

  @override
  String get color_pink => 'Rose';

  @override
  String get color_purple => 'Violet';

  @override
  String get color_indigo => 'Indigo';

  @override
  String get color_blue => 'Bleu';

  @override
  String get color_cyan => 'Cyan';

  @override
  String get color_teal => 'Teal';

  @override
  String get color_green => 'Vert';

  @override
  String get color_orange => 'Orange';

  @override
  String get color_brown => 'Marron';

  @override
  String get color_grey => 'Gris';

  @override
  String get accounts_totalBalance => 'Solde total';

  @override
  String get accounts_accountsCount => 'comptes';

  @override
  String get accounts_archived => 'Archivé';

  @override
  String get accounts_howItWorks => 'Comment fonctionnent les comptes';

  @override
  String get accounts_howItWorksDesc =>
      'Gérez tous vos comptes bancaires, portefeuilles et espèces en un seul endroit. Suivez les soldes et les transactions sur plusieurs comptes.';

  @override
  String get accounts_primary => 'Principal';

  @override
  String get categories_label => 'catégories';

  @override
  String get categories_transactionsLabel => 'transactions';

  @override
  String categories_deleteWithTransactions(String name, int count) {
    return 'Ceci supprimera définitivement \"$name\" et $count transactions liées. Cette action ne peut pas être annulée.';
  }

  @override
  String get categories_deleteAll => 'Tout supprimer';

  @override
  String get categories_edit => 'Modifier la catégorie';

  @override
  String get categories_delete => 'Supprimer la catégorie';

  @override
  String get categories_deleteSubtitle =>
      'Supprime toutes les transactions liées';

  @override
  String get category_save => 'Enregistrer';

  @override
  String get category_detailsLabel => 'Détails';

  @override
  String get category_parentLabel => 'Catégorie parente';

  @override
  String get category_nameHint => 'Nom de la catégorie';

  @override
  String get category_keywordsHint => 'Mots-clés (séparés par des virgules)';

  @override
  String get category_keywordsHelper =>
      'Pour l\'auto-détection par SMS (ex: swiggy, zomato)';

  @override
  String get currency_title => 'Devise';

  @override
  String get currency_baseCurrency => 'Devise de base';

  @override
  String get currency_baseDescription =>
      'Tous les totaux, budgets et analyses utilisent cette devise.';

  @override
  String get currency_exchangeRates => 'Taux de change';

  @override
  String get currency_exchangeRatesDesc =>
      'Voir et modifier les taux de conversion';

  @override
  String get currency_archivedDesc =>
      'Voir les transactions des devises précédentes';

  @override
  String exchange_unitInfo(String base) {
    return 'unité de devise étrangère = X $base. Appuyez sur n\'importe quel taux pour le modifier.';
  }

  @override
  String get exchange_search => 'Rechercher une devise...';

  @override
  String exchange_rateUpdated(String code) {
    return 'Taux $code mis à jour';
  }

  @override
  String exchange_editRate(String code) {
    return 'Modifier le taux $code';
  }

  @override
  String get exchange_rateLabel => 'Taux';

  @override
  String get exchange_invalidRate => 'Entrez un taux valide';

  @override
  String get archived_transaction => 'Transaction';

  @override
  String get currency_changingCurrency => 'Changement de devise...';

  @override
  String get currency_pleaseWait =>
      'Archivage des transactions et mise à jour des paramètres';

  @override
  String get security_title => 'Sécurité';

  @override
  String get security_unprotected => 'Non protégé';

  @override
  String get security_basic => 'Basique';

  @override
  String get security_strong => 'Forte';

  @override
  String get security_unprotectedDesc =>
      'Activez le code PIN ou la biométrie pour protéger vos données';

  @override
  String security_protectionsActive(int count, int total) {
    return '$count protections sur $total actives';
  }

  @override
  String get security_authentication => 'Authentification';

  @override
  String get security_pinLock => 'Verrouillage PIN';

  @override
  String get security_pinActive => 'Code PIN à 4 chiffres actif';

  @override
  String get security_pinSet => 'Définir un code PIN à 4 chiffres';

  @override
  String get security_biometric => 'Déverrouillage biométrique';

  @override
  String get security_biometricDesc => 'Empreinte digitale ou Face ID';

  @override
  String get security_manage => 'Gérer';

  @override
  String get security_changePin => 'Changer le code PIN';

  @override
  String get security_changePinDesc =>
      'Mettre à jour votre code PIN à 4 chiffres';

  @override
  String get security_enablePinFirst => 'Activez d\'abord le code PIN';

  @override
  String get security_biometricEnabled => 'Biométrie activée';

  @override
  String get security_biometricDisabled => 'Biométrie désactivée';

  @override
  String get security_infoText =>
      'Votre code PIN est stocké en toute sécurité sur cet appareil — il ne touche jamais un serveur. Les chiffres sont randomisés lors de la saisie pour une protection supplémentaire.';

  @override
  String notifSettings_activeCount(int count) {
    return '$count sur 5 actives';
  }

  @override
  String get notifSettings_summaryDesc =>
      'Les résumés affichent les dépenses, les revenus, la catégorie principale et le solde';

  @override
  String get notifSettings_dailySummaryDesc => 'Aperçu des dépenses d\'hier';

  @override
  String notifSettings_weeklySchedule(String day) {
    return 'Chaque $day à 9h00';
  }

  @override
  String get smsImport_autoImporting =>
      'Les transactions sont importées automatiquement';

  @override
  String get smsImport_enableToStart =>
      'Activez l\'importation automatique pour commencer le suivi';

  @override
  String get smsImport_iosRestriction =>
      'L\'importation automatique n\'est disponible que sur Android en raison des restrictions de la plateforme iOS.';

  @override
  String get common_change => 'Changer';

  @override
  String get goal_whatSavingFor => 'Pour quoi économisez-vous ?';

  @override
  String get netWorth_totalLabel => 'Valeur nette totale';

  @override
  String get netWorth_notEnoughData => 'Pas encore assez de données';

  @override
  String get netWorth_assets => 'Actifs';

  @override
  String get netWorth_liabilities => 'Passifs';

  @override
  String get netWorth_composition => 'Composition du patrimoine';

  @override
  String get goal_milestoneStarted => 'Démarré';

  @override
  String get goal_milestoneStartedDesc => 'Votre voyage a commencé';

  @override
  String get goal_milestone25 => '25%';

  @override
  String get goal_milestone25Desc => 'Un quart du chemin fait';

  @override
  String get goal_milestone50 => '50%';

  @override
  String get goal_milestone50Desc => 'À mi-chemin !';

  @override
  String get goal_milestone75 => '75%';

  @override
  String get goal_milestone75Desc => 'Presque arrivé';

  @override
  String get goal_milestone100 => '100%';

  @override
  String get goal_milestone100Desc => 'Objectif atteint ! 🎉';

  @override
  String get goal_flexibleTimeline => 'Échéancier flexible';

  @override
  String get goal_amount => 'Montant';

  @override
  String get goal_emotionReached => 'Objectif atteint ! 🎉';

  @override
  String get goal_emotionProgress => 'Belle progression ✨';

  @override
  String goal_emotionMoreToGo(Object amount) {
    return 'Plus que $amount à épargner 💪';
  }

  @override
  String get goal_emotionSetTarget => 'Fixez votre cible 🎯';

  @override
  String get goal_emotionWhatSaving => 'Pour quoi économisez-vous ?';

  @override
  String get goal_exceededTarget => 'Vous avez dépassé votre cible ! 🎉';

  @override
  String get goal_alreadyReached => 'Objectif déjà atteint ! 🎉';

  @override
  String goal_progressLeft(Object percent, Object amount) {
    return '$percent% effectué • $amount restant';
  }

  @override
  String goal_paceDaily(Object daily, Object monthly) {
    return 'À ce rythme, vous avez besoin de $daily/jour pour atteindre votre objectif.\nC\'est $monthly/mois.';
  }

  @override
  String goal_daysRemaining(Object count) {
    return '$count jours restants';
  }

  @override
  String goal_daysLeft(Object count) {
    return '$count jours restants';
  }

  @override
  String goal_startSaving(Object amount) {
    return 'Commencer à épargner $amount';
  }

  @override
  String goal_goalsInProgress(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count objectifs en cours',
      one: '1 objectif en cours',
    );
    return '$_temp0';
  }

  @override
  String get goal_completedSection => 'Terminé 🎉';

  @override
  String get goal_emotionAlmost => 'Presque arrivé 🚀';

  @override
  String get goal_emotionHalfway => 'À mi-chemin 💪';

  @override
  String get goal_emotionEvery => 'Chaque geste compte 🌱';

  @override
  String get goal_emotionHalfwayDone => 'À moitié fait ✨';

  @override
  String get goal_emotionKeepPushing => 'Continuez comme ça 🔥';

  @override
  String get goal_emotionJustStarted => 'Vient de commencer 🌱';

  @override
  String get goal_closestToCompletion => 'Le plus proche de la fin';

  @override
  String goal_acrossGoals(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'sur $count objectifs',
      one: 'sur 1 objectif',
    );
    return '$_temp0';
  }

  @override
  String get goal_suffixSaved => 'épargné';

  @override
  String get goal_suffixLeft => 'restant';

  @override
  String get goal_suffixDone => 'fait';

  @override
  String get goal_suffixAchieved => 'réalisé';

  @override
  String get goal_suffixToGo => 'à faire';

  @override
  String get goal_needsAttention => 'Nécessite une attention particulière ⚠️';

  @override
  String get goal_aheadOfSchedule => 'En avance sur le planning 🎯';

  @override
  String goal_monthsLeft(Object count) {
    return '$count mois restants';
  }

  @override
  String get goal_emotionDidIt => 'Vous l\'avez fait ! 🎉';

  @override
  String get goal_emotionSoClose => 'Si proche, continuez ! 💪';

  @override
  String get goal_emotionMomentum => 'On prend de l\'élan 🔥';

  @override
  String get goal_emotionCatchUp => 'Rattrapons le retard ⚡';

  @override
  String get goal_finishGoal => 'Terminez cet objectif ! 🚀';

  @override
  String get goal_onTrackStatus => 'Sur la bonne voie ✅';

  @override
  String get goal_behindPace => 'En retard sur le rythme ⚠️';

  @override
  String goal_daysAgo(Object count) {
    return 'Il y a $count jours';
  }

  @override
  String get common_today => 'Aujourd\'hui';

  @override
  String get common_yesterday => 'Hier';

  @override
  String get common_amount => 'Montant';

  @override
  String get accounts_edit => 'Modifier le compte';

  @override
  String get accounts_balanceHistory => 'Historique du solde';

  @override
  String get accounts_matchBank => 'Faire correspondre avec le relevé bancaire';

  @override
  String get accounts_viewPortfolio => 'Voir le portefeuille';

  @override
  String get accounts_setAsPrimary => 'Définir comme principal';

  @override
  String get accounts_primaryDesc =>
      'Compte par défaut pour les partages et voyages';

  @override
  String get accounts_archive => 'Archiver';

  @override
  String get accounts_archiveDesc => 'Masquer des comptes actifs';

  @override
  String get accounts_unarchive => 'Désarchiver';

  @override
  String get accounts_unarchiveDesc => 'Restaurer dans les comptes actifs';

  @override
  String get accounts_deleteDesc => 'Supprimer définitivement le compte';

  @override
  String get smsActivity_title => 'Activité des transactions';

  @override
  String get smsActivity_approved => 'Approuvé';

  @override
  String get smsActivity_pending => 'En attente';

  @override
  String get smsActivity_rejected => 'Rejeté';

  @override
  String get smsActivity_needsReview => 'À vérifier';

  @override
  String get smsActivity_duplicates => 'Doublons';

  @override
  String get smsActivity_filterByStatus => 'Filtrer par statut';

  @override
  String smsActivity_transactionCount(Object count) {
    return '$count transactions';
  }

  @override
  String smsActivity_needsAttention(Object count) {
    return '$count nécessite votre attention';
  }

  @override
  String smsActivity_resultCount(Object count) {
    return '$count résultats';
  }

  @override
  String get smsActivity_noActivities => 'Aucune activité correspondante';

  @override
  String get smsActivity_status => 'Statut';

  @override
  String get smsActivity_confidence => 'Confiance';

  @override
  String get smsActivity_account => 'Compte';

  @override
  String get smsActivity_bank => 'Banque';

  @override
  String get smsActivity_type => 'Type';

  @override
  String get smsActivity_merchant => 'Marchand';

  @override
  String get smsActivity_balance => 'Solde';

  @override
  String get smsActivity_reference => 'Référence';

  @override
  String get smsActivity_duplicateLabel => 'DOUBLON';

  @override
  String get smsActivity_transferLabel => 'TRANSFERT';

  @override
  String get smsActivity_reject => 'Rejeter';

  @override
  String get smsActivity_approve => 'Approuver';

  @override
  String get smsActivity_transfer => 'Transfert';

  @override
  String get smsActivity_addAccount => 'Ajouter compte';

  @override
  String get smsActivity_duplicateWarning =>
      'Ceci peut être une transaction en doublon. Vérifiez attentivement avant d\'approuver.';

  @override
  String smsActivity_noAccountWarning(Object account) {
    return 'Aucun compte trouvé correspondant à \"$account\". Ajoutez-en un pour approuver.';
  }

  @override
  String get smsActivity_transferWarning =>
      'Ceci ressemble à un transfert entre vos comptes. Approuver ouvrira l\'écran de transfert.';

  @override
  String get common_all => 'Tout';

  @override
  String get backup_lastBackup => 'Dernière sauvegarde';

  @override
  String get backup_noBackups => 'Pas encore de sauvegardes';

  @override
  String get backup_createFirst =>
      'Créez votre première sauvegarde pour protéger vos données';

  @override
  String get backup_actions => 'Actions';

  @override
  String get backup_history => 'Historique';

  @override
  String get backup_noHistory => 'Pas d\'historique de sauvegarde';

  @override
  String get backup_infoText =>
      'Les sauvegardes sont chiffrées avec votre mot de passe et enregistrées sous forme de fichiers .mudra. Gardez votre mot de passe en sécurité — il ne peut pas être récupéré.';

  @override
  String get backup_justNow => 'À l\'instant';

  @override
  String backup_minutesAgo(int count) {
    return 'Il y a $count min';
  }

  @override
  String backup_hoursAgo(int count) {
    return 'Il y a $count h';
  }

  @override
  String backup_daysAgo(int count) {
    return 'Il y a $count j';
  }

  @override
  String backup_recordCount(int count) {
    return '$count enregistrements';
  }

  @override
  String get account_changeCurrency => 'Changer de devise ?';

  @override
  String account_resetTo(String code) {
    return 'Réinitialiser à $code';
  }

  @override
  String get account_baseCurrencyInfo =>
      'Les transactions de ce compte utilisent votre devise de base.';

  @override
  String account_foreignCurrencyInfo(String code, String base) {
    return 'Les transactions seront enregistrées en $code et converties en $base pour les totaux.';
  }

  @override
  String get account_warningNoConvert =>
      'Les soldes existants ne seront PAS convertis automatiquement.';

  @override
  String get account_warningNewCurrency =>
      'Les nouvelles transactions utiliseront la nouvelle devise.';

  @override
  String get account_warningManualAdjust =>
      'Vous devrez peut-être ajuster manuellement le solde.';

  @override
  String get category_selectParent => 'Sélectionner la catégorie parente';

  @override
  String get appearance_colorTheme => 'Thème de couleur';

  @override
  String get appearance_amoledMode => 'Mode AMOLED';

  @override
  String appearance_toneActivated(String name) {
    return 'Ton $name activé';
  }

  @override
  String dashboard_cardsActive(int visible, int total) {
    return '$visible cartes sur $total actives';
  }

  @override
  String get dashboard_dragToReorder =>
      'Faites glisser pour réorganiser, basculez pour afficher ou masquer';

  @override
  String get dashboard_smartOrdering => 'Classement intelligent';

  @override
  String get dashboard_catEssential => 'Essentiel';

  @override
  String get dashboard_catFinance => 'Finance';

  @override
  String get dashboard_catAnalytics => 'Analyses';

  @override
  String get dashboard_catActions => 'Actions';

  @override
  String get dashboard_catAI => 'Aperçus IA';

  @override
  String get dashboard_catContextual => 'Contextuel';

  @override
  String get importExport_title => 'Import & Export';

  @override
  String get importExport_export => 'Exportation';

  @override
  String get importExport_import => 'Importation';

  @override
  String get importExport_exportTitle => 'Exporter les transactions';

  @override
  String get importExport_exportDesc =>
      'Téléchargez vos transactions sous forme de fichier Excel.';

  @override
  String get importExport_exporting => 'Exportation en cours...';

  @override
  String get importExport_exportAsExcel => 'Exporter au format Excel';

  @override
  String get importExport_importTitle => 'Importer depuis Excel';

  @override
  String get importExport_importDesc =>
      'Importez des transactions à partir d\'un fichier .xlsx. Vous pourrez prévisualiser et mapper les colonnes avant l\'importation.';

  @override
  String get importExport_excelFormat => 'Excel (.xlsx)';

  @override
  String get importExport_bankStatement => 'Relevé bancaire';

  @override
  String get importExport_otherApps => 'Autres applications';

  @override
  String get importExport_pickFile => 'Choisir un fichier Excel';

  @override
  String get importExport_infoText =>
      'L\'exportation crée un fichier Excel avec tous les détails des transactions. L\'importation prend en charge les fichiers .xlsx d\'autres applications de finance ou des feuilles de calcul manuelles.';

  @override
  String get plugins_subtitle =>
      'Étendez Mudra Manager avec des extensions puissantes';

  @override
  String get plugins_official => 'Officiel';

  @override
  String plugins_enabled(String name) {
    return '$name activé';
  }

  @override
  String plugins_disabled(String name) {
    return '$name désactivé';
  }

  @override
  String get plugins_configure => 'Configurer l\'extension';

  @override
  String plugins_activeCount(int active, int total) {
    return '$active sur $total actives';
  }

  @override
  String get plugins_toggleDesc =>
      'Activez les extensions pour étendre les fonctionnalités de l\'application';

  @override
  String get plugins_default => 'Par défaut';

  @override
  String get plugins_configureSettings =>
      'Configurer les paramètres de l\'extension';

  @override
  String get plugins_creditCardReminders => 'Rappels de carte de crédit';

  @override
  String get plugins_remindBefore => 'Me rappeler avant (jours)';

  @override
  String get plugins_noCreditCards =>
      'Aucun compte de carte de crédit trouvé. Ajoutez-en un d\'abord.';

  @override
  String get plugins_creditCardAccounts => 'Comptes de carte de crédit';

  @override
  String get plugins_billDay => 'Jour de facturation (1-31)';

  @override
  String get plugins_remindersConfigured =>
      'Rappels de carte de crédit configurés';

  @override
  String get plugins_infoText =>
      'Les extensions étendent les fonctionnalités de l\'application. Certaines extensions nécessitent des autorisations ou une configuration supplémentaires.';

  @override
  String get help_title => 'Aide et Support';

  @override
  String get help_searchHint => 'Rechercher des sujets d\'aide...';

  @override
  String get help_heroTitle => 'Comment pouvons-nous vous aider ?';

  @override
  String get help_heroDesc => 'Parcourez les guides ou recherchez un sujet';

  @override
  String get help_topics => 'Sujets';

  @override
  String get help_tryDifferent => 'Essayez un autre terme de recherche';

  @override
  String get help_howToUse => 'Comment utiliser';

  @override
  String get help_tips => 'Conseils';

  @override
  String help_articleCount(int count) {
    return '$count articles';
  }

  @override
  String help_resultCount(int count) {
    return '$count résultats';
  }

  @override
  String get help_infoText =>
      'Vous ne trouvez pas ce dont vous avez besoin ? Visitez À propos → Contacter le support pour une aide directe.';

  @override
  String get about_legalCount => '3 éléments';

  @override
  String get about_supportCount => '4 éléments';

  @override
  String about_packageCount(int count) {
    return '$count paquets open source';
  }

  @override
  String get onboard_continue => 'Continuer';

  @override
  String get onboard_restoreFromBackup => 'Restaurer depuis une sauvegarde';

  @override
  String get onboard_accountNameRequired => 'Le nom du compte est requis';

  @override
  String get onboard_balanceRequired => 'Le solde est requis';

  @override
  String get onboard_enterValidNumber => 'Entrez un nombre valide';

  @override
  String get onboard_accountHint => 'ex: Espèces, Banque';

  @override
  String get onboard_browseAllCurrencies => 'Parcourir toutes les devises';

  @override
  String get onboard_toneTitle => 'Comment Mudra doit-il vous parler ?';

  @override
  String get onboard_toneDesc =>
      'Choisissez une personnalité. Vous pouvez la changer à tout moment.';

  @override
  String get onboard_categoriesTitle => 'Choisissez vos catégories';

  @override
  String get onboard_categoriesDesc =>
      'Choisissez les packs qui correspondent à votre style de vie. Vous pouvez les changer plus tard.';

  @override
  String get onboard_startFresh => 'Partir de zéro';

  @override
  String get onboard_startFreshDesc =>
      'Aucune catégorie — ajoutez les vôtres plus tard';

  @override
  String get onboard_currencyWarning =>
      'Changer la devise de base plus tard archivera les transactions existantes.';

  @override
  String get statistics_topCategory => 'Catégorie principale';

  @override
  String get statistics_dailyAverage => 'Moyenne quotidienne';

  @override
  String get statistics_perDay => 'par jour';

  @override
  String statistics_percentOfExpenses(String percent) {
    return '$percent% des dépenses';
  }

  @override
  String get sms_infoTitle => 'Comment fonctionne l\'importation SMS';

  @override
  String get sms_infoOnlyScans =>
      'Scanne uniquement les SMS des banques et portefeuilles';

  @override
  String get sms_infoStaysOnDevice =>
      'Toutes les données restent sur votre appareil';

  @override
  String get sms_infoAutoCreates => 'Crée automatiquement des transactions';

  @override
  String get sms_infoNoPersonal => 'Aucun message personnel n\'est lu';

  @override
  String get dashboard_totalBalance => 'Solde total';

  @override
  String get dashboard_netWorthLink => 'Valeur nette';

  @override
  String get dashboard_showAccounts => 'Afficher les comptes';

  @override
  String get dashboard_hideAccounts => 'Masquer les comptes';

  @override
  String dashboard_accountsTapExpand(int count) {
    return '$count comptes · Appuyez pour agrandir';
  }

  @override
  String get notif_lowBalanceTitle => '⚠️ Alerte solde bas';

  @override
  String notif_lowBalanceBody(String account, String amount) {
    return 'Votre solde sur $account est de $amount';
  }

  @override
  String get achieve_unlocked => 'Déverrouillé';

  @override
  String get achieve_inProgress => 'En cours';

  @override
  String get achieve_trophyShelf => 'Étagère à trophées';

  @override
  String get achieve_streaks => 'Séries';

  @override
  String get achieve_totalXP => 'XP total';

  @override
  String get achieve_dailyCheckIn => 'Pointage quotidien';

  @override
  String get achieve_budgetAdherence => 'Respect du budget';

  @override
  String achieve_bestDays(int count) {
    return 'Meilleur : $count jours';
  }

  @override
  String achieve_noBadgesYet(String category) {
    return 'Pas encore de badges $category';
  }

  @override
  String achieve_levelUpSnack(int level) {
    return '🎉 Niveau supérieur ! Vous êtes maintenant au niveau $level !';
  }

  @override
  String achieve_levelLabel(int level) {
    return 'Niveau $level';
  }

  @override
  String get achieve_catBudgeting => 'Budgétisation';

  @override
  String get achieve_catSavings => 'Épargne';

  @override
  String get achieve_catTracking => 'Suivi';

  @override
  String get achieve_catMilestones => 'Jalons';

  @override
  String get achieve_catEngagement => 'Engagement';

  @override
  String get achieve_catAll => 'Tout';

  @override
  String get alert_actionNeeded => 'Action requise';

  @override
  String alert_billsDueTomorrow(int count) {
    return '$count facture(s) due(s) demain';
  }

  @override
  String get alert_upcomingBills => 'Factures à venir';

  @override
  String alert_billsDueInDays(int count) {
    return '$count facture(s) due(s) dans 2 jours';
  }

  @override
  String get alert_budgetAlert => 'Alerte budget';

  @override
  String alert_budgetsExceeded(int count) {
    return '$count budget(s) dépassé(s)';
  }

  @override
  String get alert_budgetWarning => 'Avertissement budget';

  @override
  String alert_budgetsNearLimit(int count) {
    return '$count budget(s) proches de la limite';
  }

  @override
  String get alert_goalProgress => 'Progression des objectifs';

  @override
  String alert_goalsAlmostComplete(int count) {
    return '$count objectif(s) presque terminés !';
  }

  @override
  String get analytics_cashFlowForecast => 'Prévision des flux de trésorerie';

  @override
  String get analytics_thisMonthProjected => 'Ce mois-ci (prévision)';

  @override
  String get analytics_savingOnAverage => 'Vous économisez en moyenne';

  @override
  String get analytics_spendingExceedsIncome =>
      'Les dépenses dépassent les revenus';

  @override
  String get health_scoreBreakdown => 'Détail du score';

  @override
  String get health_savings => 'Épargne';

  @override
  String get health_spending => 'Dépenses';

  @override
  String get health_debt => 'Dette';

  @override
  String get health_emergency => 'Urgence';

  @override
  String get health_liquidityRunway => 'Marge de liquidité';

  @override
  String health_balanceCoversMonths(String months) {
    return 'Votre solde couvre $months mois de dépenses';
  }

  @override
  String get health_days => 'jours';

  @override
  String health_nDays(String n) {
    return '$n jours';
  }

  @override
  String get health_safe => 'Sûr';

  @override
  String get health_moderate => 'Modéré';

  @override
  String get health_risk => 'Risqué';

  @override
  String get health_categoryHealth => 'Santé par catégorie';

  @override
  String get health_stable => 'Stable →';

  @override
  String get health_high => 'Élevé ↑';

  @override
  String get health_reduced => 'Réduit ↓';

  @override
  String get health_whatYouCanDo => 'Ce que vous pouvez faire';

  @override
  String get health_verdictExcellent => 'vous êtes en excellente forme';

  @override
  String get health_verdictGood => 'vous êtes sur la bonne voie';

  @override
  String get health_verdictFair => 'peut mieux faire';

  @override
  String get health_verdictPoor => 'nécessite une attention particulière';

  @override
  String get health_of100 => 'sur 100';

  @override
  String get health_errorLoading =>
      'Impossible de charger les données de santé';

  @override
  String get analytics_cashFlowTitle => 'Prévision des flux de trésorerie';

  @override
  String get analytics_currentMonth => 'Mois en cours';

  @override
  String get analytics_projected => 'Prévision';

  @override
  String get analytics_forecast3Month => 'Prévision sur 3 mois';

  @override
  String get analytics_monthlyNet => 'Net mensuel';

  @override
  String get analytics_income => 'Revenu';

  @override
  String get analytics_expense => 'Dépense';

  @override
  String get analytics_net => 'Net';

  @override
  String get analytics_avgMonthlyNet => 'Net mensuel moyen';

  @override
  String get analytics_noForecastData => 'Pas assez de données pour prévoir';

  @override
  String get analytics_spendingTrendsTitle => 'Tendances des dépenses';

  @override
  String get analytics_predictedNextMonth => 'Prévu le mois prochain';

  @override
  String get analytics_anomaly => 'Anomalie';

  @override
  String get analytics_vsLastMonth => 'vs mois dernier';

  @override
  String get analytics_risingCategories => 'Catégories en hausse';

  @override
  String get analytics_anomalyCategories => 'Anomalie détectée';

  @override
  String get analytics_allCategories => 'Toutes les catégories';

  @override
  String get analytics_noTrendData => 'Pas assez de données pour les tendances';

  @override
  String get recap_vsLastYear => 'vs l\'année dernière';

  @override
  String get common_income => 'Revenu';

  @override
  String get common_expense => 'Dépense';

  @override
  String get common_transactions => 'Transactions';

  @override
  String get tax_title => 'Estimation de l\'impôt';

  @override
  String get tax_projected => 'Prévision (année en cours)';

  @override
  String get tax_estimatedTax => 'Impôt estimé';

  @override
  String get tax_effectiveRate => 'Taux effectif';

  @override
  String get tax_monthlyTax => 'Mensuel';

  @override
  String tax_fyProgress(int elapsed, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: 'jours',
      one: 'jour',
    );
    return '$elapsed sur $total $_temp0';
  }

  @override
  String get tax_slabBreakdown => 'Détail par tranche';

  @override
  String get tax_totalSlabTax => 'Impôt total par tranche';

  @override
  String get tax_computation => 'Calcul de l\'impôt';

  @override
  String get tax_grossIncome => 'Revenu brut';

  @override
  String get tax_standardDeduction => 'Déduction forfaitaire';

  @override
  String get tax_taxableIncome => 'Revenu imposable';

  @override
  String get tax_baseTax => 'Impôt sur le revenu';

  @override
  String get tax_rebate87A => 'Remise u/s 87A';

  @override
  String get tax_cess => 'Prélèvement santé et éducation (4%)';

  @override
  String get tax_totalTax => 'Impôt total à payer';

  @override
  String get tax_incomeBreakdown => 'Sources de revenus';

  @override
  String get tax_disclaimer =>
      'Il s\'agit d\'une estimation basée sur le nouveau régime fiscal (FY 2025-26). L\'impôt réel peut varier. Consultez un professionnel de la fiscalité pour une déclaration précise.';

  @override
  String get tax_noData => 'Pas assez de données pour estimer l\'impôt';

  @override
  String get tax_viewDetails => 'Voir l\'estimation de l\'impôt';

  @override
  String get tax_zeroTax => 'Aucune dette fiscale 🎉';

  @override
  String get tax_newRegime => 'Nouveau régime';

  @override
  String get tax_oldRegime => 'Ancien régime';

  @override
  String get tax_regimeComparison =>
      'Quel régime permet d\'économiser le plus ?';

  @override
  String tax_regimeSavings(String regime) {
    return '$regime vous fait économiser';
  }

  @override
  String get tax_oldRegimeDisclaimer =>
      'L\'estimation de l\'ancien régime utilise uniquement la déduction forfaitaire. Avec les déductions HRA, 80C, 80D, les économies pourraient être plus élevées.';

  @override
  String get category_merge => 'Fusionner la catégorie';

  @override
  String get category_mergeInto => 'Fusionner dans';

  @override
  String get category_mergeConfirm => 'Fusionner';

  @override
  String category_mergePreview(int count, String target) {
    return '$count éléments seront déplacés vers $target';
  }

  @override
  String get category_mergeSuccess => 'Catégories fusionnées avec succès';

  @override
  String get category_mergeSameError =>
      'Impossible de fusionner une catégorie avec elle-même';

  @override
  String get category_mergeSelectTarget => 'Sélectionner la catégorie cible';

  @override
  String get category_selectInstruction =>
      'Tap to select • Long press parent to select without subcategories';

  @override
  String get notif_morningInsightTitle => '☀️ Votre minute argent du matin';

  @override
  String get notif_weeklyRecapNudgeTitle =>
      '📊 Votre récapitulatif hebdomadaire est prêt';

  @override
  String get notif_yesterdaySpendTitle => '💰 Dépenses d\'hier';

  @override
  String get notif_weeklyRecapReadyTitle =>
      '📊 Votre récapitulatif hebdomadaire vous attend';

  @override
  String notif_underBudgetStreakTitle(int days) {
    return '🔥 $days jours sous le budget !';
  }

  @override
  String get dashboard_bgSyncIssueTitle =>
      'La synchronisation en arrière-plan peut ne pas fonctionner';

  @override
  String get dashboard_bgSyncIssueDesc =>
      'Les factures et alertes peuvent être retardées. Essayez de rouvrir l\'application.';

  @override
  String get onboard_whatDidYouSpend => 'Qu\'avez-vous dépensé aujourd\'hui ?';

  @override
  String get onboard_addFewToStart =>
      'Ajoutez-en quelques-unes pour voir votre tableau de bord s\'animer';

  @override
  String get onboard_skipAddLater => 'Passer — j\'ajouterai plus tard';

  @override
  String get onboard_starterCoffee => 'Café / Thé';

  @override
  String get onboard_starterTransport => 'Transport';

  @override
  String get onboard_starterLunch => 'Déjeuner / Dîner';

  @override
  String get onboard_starterGroceries => 'Courses';

  @override
  String onboard_starterAdded(int count) {
    return '$count dépenses ajoutées !';
  }

  @override
  String get dashboard_listeningTitle => 'À l\'écoute des transactions...';

  @override
  String get dashboard_waitingForSms =>
      'Votre prochaine notification bancaire apparaîtra ici automatiquement';

  @override
  String get dashboard_meanwhile => 'En attendant, essayez :';

  @override
  String get dashboard_addExpense => 'Ajouter une dépense';

  @override
  String get dashboard_setBudget => 'Définir le budget';

  @override
  String get dashboard_createGoal => 'Créer un objectif';

  @override
  String get dashboard_addAccount => 'Ajouter un compte';

  @override
  String get dashboard_testTip =>
      '💡 Conseil : Envoyez un petit paiement UPI pour voir l\'importation automatique en action !';

  @override
  String get dashboard_addFirstExpense => 'Ajoutez votre première dépense';

  @override
  String get dashboard_addFirstExpenseDesc =>
      'Appuyez pour enregistrer rapidement ce que vous avez dépensé aujourd\'hui';

  @override
  String get quickAdd_title => 'Ajout rapide';

  @override
  String get quickAdd_recentCategories => 'Catégories récentes';

  @override
  String get quickAdd_moreOptions => 'Plus d\'options';

  @override
  String get mode_simple => 'Simple';

  @override
  String get mode_full => 'Complet';

  @override
  String get mode_simpleDesc => 'Dépenses, budgets et suivi SMS';

  @override
  String get mode_fullDesc =>
      'Tout — voyages, objectifs, analyses, gamification';

  @override
  String get mode_switchToFull => 'Passer en mode complet';

  @override
  String get mode_switchToSimple => 'Passer en mode simple';

  @override
  String get mode_pickTitle => 'Comment voulez-vous utiliser Mudra ?';

  @override
  String get mode_pickDesc =>
      'Vous pouvez changer cela à tout moment dans les paramètres';

  @override
  String get backup_cloudBackup => 'Sauvegarde Cloud';

  @override
  String get backup_cloudRestore => 'Restaurer depuis le Cloud';

  @override
  String get backup_signInGoogle => 'Se connecter avec Google';

  @override
  String backup_signedInAs(String email) {
    return 'Connecté en tant que $email';
  }

  @override
  String get backup_uploadingToDrive => 'Téléchargement sur Google Drive...';

  @override
  String get backup_uploadSuccess => 'Sauvegarde téléchargée sur Google Drive';

  @override
  String get backup_uploadFailed => 'Échec du téléchargement de la sauvegarde';

  @override
  String get backup_cloudBackups => 'Sauvegardes Cloud';

  @override
  String get backup_noCloudBackups => 'Aucune sauvegarde cloud trouvée';

  @override
  String get backup_downloading => 'Téléchargement depuis Google Drive...';

  @override
  String get backup_signInRequired =>
      'Connectez-vous à Google pour utiliser la sauvegarde cloud';

  @override
  String get backup_signOut => 'Se déconnecter';

  @override
  String get backup_cloudSubtitle => 'Sauvegarde chiffrée sur Google Drive';

  @override
  String get backup_autoBackup => 'Sauvegarde automatique';

  @override
  String get backup_autoBackupDesc =>
      'Sauvegardes locales automatiques, conserve les 7 derniers jours';

  @override
  String get backup_autoFrequency => 'Fréquence de sauvegarde';

  @override
  String get backup_autoNever => 'Désactivé';

  @override
  String get backup_autoDaily => 'Quotidien';

  @override
  String get backup_autoWeekly => 'Hebdomadaire';

  @override
  String get backup_autoSetPassword =>
      'Définissez un mot de passe de sauvegarde pour activer la sauvegarde automatique';

  @override
  String backup_autoEnabled(String frequency) {
    return 'Sauvegarde automatique activée ($frequency)';
  }

  @override
  String backup_autoLastRun(String date) {
    return 'Dernière sauvegarde automatique : $date';
  }

  @override
  String get backup_passwordSet => 'Mot de passe de sauvegarde défini';

  @override
  String get backup_proRequired => 'Fonctionnalité Pro';

  @override
  String get onboard_skip => 'Passer';

  @override
  String get onboard_languages => 'Langues';

  @override
  String get onboard_smartTrackingMergedDesc =>
      'Importation automatique depuis les SMS bancaires, définition de budgets, suivi d\'objectifs — tout au même endroit.';

  @override
  String get sms_celebrationTitle => 'Votre première transaction par SMS ! 🎉';

  @override
  String get sms_celebrationBody =>
      'Mudra vient d\'importer automatiquement une transaction à partir de votre SMS bancaire. Désormais, vos dépenses se suivent toutes seules.';

  @override
  String get sms_celebrationCta => 'Génial, c\'est parti !';

  @override
  String get milestone_shareButton => 'Partager en Story';

  @override
  String get milestone_goalReachedTitle => 'Objectif atteint !';

  @override
  String milestone_goalReachedDesc(String amount) {
    return '$amount économisés et l\'objectif a été atteint 🌟';
  }

  @override
  String milestone_streakTitle(int days) {
    return 'Série de $days jours !';
  }

  @override
  String milestone_streakDesc(int days) {
    return 'Dépenses suivies chaque jour pendant $days jours consécutifs';
  }

  @override
  String get milestone_underBudgetTitle => 'Sous le budget !';

  @override
  String get milestone_underBudgetDesc =>
      'Resté dans le budget pendant tout le mois 💪';

  @override
  String get account_creditLimit => 'Limite de crédit';

  @override
  String get account_statementDay => 'Jour du relevé';

  @override
  String get account_dueDay => 'Jour d\'échéance';

  @override
  String account_daysUntilDue(int days) {
    return '$days jours avant l\'échéance';
  }

  @override
  String get account_dueToday => 'Dû aujourd\'hui !';

  @override
  String account_overdue(int days) {
    return 'En retard de $days jours';
  }

  @override
  String get subscription_title => 'Abonnements détectés';

  @override
  String subscription_monthlyTotal(String amount) {
    return '$amount/mois au total';
  }

  @override
  String subscription_occurrences(int count) {
    return '$count prélèvements en 4 mois';
  }

  @override
  String get subscription_none =>
      'Aucun abonnement récurrent détecté pour l\'instant';

  @override
  String subscription_dayOfMonth(int day) {
    return 'Vers le $day de chaque mois';
  }

  @override
  String get subscription_trackAsRecurring => 'Suivre comme facture récurrente';

  @override
  String get cc_title => 'Factures de carte de crédit';

  @override
  String get cc_totalOutstanding => 'Total des encours';

  @override
  String cc_acrossCards(int count) {
    return 'Sur $count cartes';
  }

  @override
  String get cc_noCards => 'Aucune carte de crédit ajoutée';

  @override
  String get cc_noCardsHint =>
      'Ajoutez un compte de carte de crédit pour suivre les factures ici';

  @override
  String get cc_minimumDue => 'Min. dû';

  @override
  String get cc_cycleSpend => 'Dépenses du cycle';

  @override
  String get cc_utilization => 'Utilisation du crédit';

  @override
  String get cc_nextStatement => 'Relevé';

  @override
  String get cc_nextDue => 'Échéance';

  @override
  String get cc_payMinimum => 'Payer le minimum';

  @override
  String get cc_payFull => 'Payer la totalité';

  @override
  String get cc_utilitySubtitle => 'Échéances, encours et limites';

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
}
