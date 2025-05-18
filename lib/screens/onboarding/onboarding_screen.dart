import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:mudra_manager/db/models/account.dart'
    show Account, AccountType, GetAccountCollection;
import 'package:mudra_manager/db/models/category.dart'
    show Category, CategoryType, GetCategoryCollection;
import 'package:mudra_manager/db/models/user_profile.dart'
    show GetUserProfileCollection, UserProfile;
import 'package:mudra_manager/l10n/app_localizations.dart';
import 'package:mudra_manager/models/onboarding_page_model.dart'
    show onboardingData;
import 'package:mudra_manager/providers/isar_provider.dart';
import 'package:mudra_manager/providers/l10n_provider.dart'
    show LanguageService;
import 'package:mudra_manager/providers/shared_preference_provider.dart';
import 'package:mudra_manager/screens/home_screen.dart';
import 'package:mudra_manager/screens/onboarding/onboarding_background.dart'
    show OnboardingBackground;
import 'package:mudra_manager/screens/reusable/common_text_input_field.dart';
import 'package:mudra_manager/util/localization_extension.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _controller = PageController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _accountController = TextEditingController(
    text: 'Cash',
  );
  final TextEditingController _balanceController = TextEditingController();
  int _currentPage = 0;
  final List<Category> defaultCategories = [
    Category.create(name: 'Salary', categoryType: CategoryType.income)
      ..iconName = 'attach_money'
      ..colorValue = Colors.green.toARGB32(),
    Category.create(name: 'Investment', categoryType: CategoryType.income)
      ..iconName = 'trending_up'
      ..colorValue = Colors.teal.toARGB32(),
    Category.create(name: 'Savings', categoryType: CategoryType.income)
      ..iconName = 'savings'
      ..colorValue = Colors.yellow.toARGB32(),
    Category.create(name: 'Food', categoryType: CategoryType.expense)
      ..iconName = 'fastfood'
      ..colorValue = Colors.orange.toARGB32(),
    Category.create(name: 'Transport', categoryType: CategoryType.expense)
      ..iconName = 'directions_car'
      ..colorValue = Colors.purple.toARGB32(),
    Category.create(name: 'Health', categoryType: CategoryType.expense)
      ..iconName = 'local_hospital'
      ..colorValue = Colors.red.toARGB32(),
    Category.create(name: 'Shopping', categoryType: CategoryType.expense)
      ..iconName = 'shopping_bag'
      ..colorValue = Colors.redAccent.toARGB32(),
    Category.create(name: 'Groceries', categoryType: CategoryType.expense)
      ..iconName = 'local_grocery_store'
      ..colorValue = Colors.orange.toARGB32(),
  ];

  Future<void> createDefaultCategories(Isar isar) async {
    final existing =
        await isar.categorys.where().findAll(); // check if already created
    if (existing.isNotEmpty) return;

    await isar.writeTxn(() async {
      await isar.categorys.putAll(defaultCategories);
    });
  }

  void _onNext(BuildContext context) {
    final ctxt = AppLocalizations.of(context)!;
    final isNamePage = _currentPage == onboardingData.length - 3;
    final isAccountPage = _currentPage == onboardingData.length - 2;

    final currentPage = onboardingData[_currentPage];
    if (currentPage.needsInput && isNamePage) {
      final text = _nameController.text.trim();
      String hintText =
          ctxt.translate(currentPage.inputHint ?? '').toLowerCase();
      if (text.isEmpty) {
        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ctxt.onboard_pleaseFillThe(hintText))),
        );
        return; // Stop here
      }
    }
    if (currentPage.needsInput && isAccountPage) {
      final text = _accountController.text.trim();
      final balanceText = _balanceController.text.trim();

      if (text.isEmpty) {
        String hintText =
            ctxt.translate(currentPage.inputHint ?? '').toLowerCase();
        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ctxt.onboard_pleaseFillThe(hintText))),
        );
        return; // Stop here
      }
      if (balanceText.isEmpty) {
        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ctxt.onboard_pleaseFillThe(
                ctxt.onboard_initialBalance.toLowerCase(),
              ),
            ),
          ),
        );
        return; // Stop here
      }
      // Try parsing as a double (allows for decimal numbers)
      final balance = double.tryParse(balanceText.trim());

      if (balance == null) {
        String hintText =
            ctxt.translate(currentPage.inputHint ?? '').toLowerCase();
        // Show error if it's not a valid number
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ctxt.onboard_pleaseEnterAValidNumberFor(hintText)),
          ),
        );
        return; // Stop here
      }
    }
    if (_currentPage < onboardingData.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    final name = _nameController.text.trim();
    final account = _accountController.text.trim();
    final balanceText = _balanceController.text.trim();

    final isar = await ref.read(isarServiceProvider).getInstance();

    await isar.writeTxn(() async {
      await isar.userProfiles.put(UserProfile()..name = name);

      await isar.accounts.put(
        Account()
          ..name = account
          ..accountType = AccountType.cash
          ..colorValue = Colors.yellowAccent.toARGB32()
          ..accountNumber = '0000'
          ..initialBalance = double.parse(balanceText),
      );
    });
    await createDefaultCategories(isar);
    if (context.mounted) {
      SharedPrefsUtil.instance.setOnboardingComplete();
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNamePage = _currentPage == onboardingData.length - 3;
    final isAccountPage = _currentPage == onboardingData.length - 2;
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ctxt = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          const OnboardingBackground(),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: onboardingData.length,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    itemBuilder: (context, index) {
                      final data = onboardingData[index];
                      return Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(data.icon, size: 120, color: color.onPrimary),
                            const SizedBox(height: 30),
                            Text(
                              AppLocalizations.of(
                                context,
                              )!.translate(data.title),
                              style: textTheme.titleLarge?.copyWith(
                                color: color.onPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 30,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 15),
                            Text(
                              ctxt.translate(data.description),
                              style: textTheme.titleMedium?.copyWith(
                                color: color.onPrimary,
                                fontWeight: FontWeight.normal,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (data.needsInput) SizedBox(height: 15),
                            if (data.needsInput)
                              CommonTextInputField(
                                controller:
                                    isNamePage
                                        ? _nameController
                                        : _accountController,
                                labelText: ctxt.translate(data.inputHint ?? ''),
                                iconData:
                                    isNamePage
                                        ? Icons.person_outline
                                        : Icons.wallet,
                              ),

                            if (isAccountPage) SizedBox(height: 15),
                            if (isAccountPage)
                              CommonTextInputField(
                                controller: _balanceController,
                                labelText: ctxt.onboard_initialBalance,
                                iconData: Icons.account_balance_wallet,
                                inputType: TextInputType.numberWithOptions(
                                  signed: true,
                                  decimal: true,
                                ),
                              ),
                            if (isAccountPage)
                              Text(
                                ctxt.onboard_youCanUpdateOtherDetailsLaterAsWell,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: color.onPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      ...List.generate(
                        onboardingData.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 20 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color:
                                _currentPage == index
                                    ? color.onPrimary
                                    : color.onSecondary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () => _onNext(context),
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(18),
                          backgroundColor: Colors.black,
                        ),
                        child: const Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 64,
            right: 10,
            child: IconButton(
              icon: Icon(Icons.language, color: color.onPrimary),
              onPressed: () => LanguageService.showLanguagePicker(context, ref),
            ),
          ),
        ],
      ),
    );
  }
}
