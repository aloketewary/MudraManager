import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:flutter_boring_avatars/flutter_boring_avatars.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/user_profile.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/gamification/data/gamification_providers.dart';
import 'package:mudra_manager/features/profile/data/user_profile_provider.dart';
import 'package:mudra_manager/core/db/field_encryption_service.dart';
import 'package:mudra_manager/core/state/app_screen_state.dart';
import 'package:mudra_manager/shared/templates/screen_shell.dart';

class EditUserProfileScreen extends ConsumerStatefulWidget {
  const EditUserProfileScreen({super.key});

  @override
  ConsumerState<EditUserProfileScreen> createState() =>
      _EditUserProfileScreenState();
}

class _EditUserProfileScreenState extends ConsumerState<EditUserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  UserProfile _profile = UserProfile();
  bool _didInit = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _loadProfile(UserProfile? profile) {
    _profile = profile ?? UserProfile();
    _nameController.text = FieldEncryptionService.safeDisplay(profile?.name);
    _emailController.text = FieldEncryptionService.safeDisplay(profile?.email);
    _phoneController.text = FieldEncryptionService.safeDisplay(profile?.phone);
    _didInit = true;
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    final ctxt = AppLocalizations.of(context)!;
    final spacing = ref.watch(spacingProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ScreenShell(
      config: ScreenShellConfig(
        title: ctxt.profile_editUserProfileAppTitle,
        appBarMode: AppBarMode.standard,
        enableRefresh: false,
      ),
      actions: ScreenActions.empty,
      body: profileAsync.when(
        data: (profile) {
          if (!_didInit) _loadProfile(profile);
          return ListView(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.cardHorizontal,
              vertical: spacing.cardVertical,
            ),
            children: [
              // Hero Avatar
              _buildHeroAvatar(color, textTheme, isDark),
              SizedBox(height: spacing.sectionGap),

              // Personal Info
              _buildSectionHeader(
                  'Personal Info', LucideIcons.user, color, textTheme,),
              const SizedBox(height: 10),
              Form(
                key: _formKey,
                child: _buildFormCard(color, textTheme, spacing, ctxt),
              ),
              SizedBox(height: spacing.sectionGap),

              // Privacy Note
              _buildPrivacyNote(color, textTheme, spacing, ctxt),
              const SizedBox(height: 24),

              // Save Button
              _buildSaveButton(color, textTheme, spacing, ctxt),
              const SizedBox(height: 80),
            ],
          );
        },
        loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Column(children: [
              SkeletonLoader(
                  width: 80,
                  height: 80,
                  borderRadius: BorderRadius.all(Radius.circular(40)),),
              SizedBox(height: 24),
              SkeletonLoader(width: double.infinity, height: 48),
              SizedBox(height: 16),
              SkeletonLoader(width: double.infinity, height: 48),
            ],),),
        error: (e, _) => Center(child: Text(BuddyMessages.errorWith('$e'))),
      ),
    );
  }

  Widget _buildHeroAvatar(
    ColorScheme color,
    TextTheme textTheme,
    bool isDark,
  ) {
    final userLevelAsync = ref.watch(userLevelProvider);

    return Container(
      decoration: const BoxDecoration(),
      child: SafeArea(
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              userLevelAsync.maybeWhen(
                data: (level) {
                  if (level == null) {
                    return const SizedBox(width: 108, height: 108);
                  }
                  return TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeOutCubic,
                    tween: Tween(
                      begin: 0.0,
                      end: level.progressPercent.clamp(0.0, 1.0),
                    ),
                    builder: (context, value, _) => SizedBox(
                      width: 108,
                      height: 108,
                      child: CircularProgressIndicator(
                        value: value,
                        strokeWidth: 3.5,
                        strokeCap: StrokeCap.round,
                        backgroundColor: color.primary.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation(color.primary),
                      ),
                    ),
                  );
                },
                orElse: () => const SizedBox(width: 108, height: 108),
              ),
              SizedBox(
                width: 88,
                height: 88,
                child: ClipOval(
                  child: BoringAvatar(
                    name: _nameController.text.isEmpty
                        ? 'User'
                        : _nameController.text,
                    palette: BoringAvatarPalette([
                      color.primary,
                      color.tertiary,
                      color.primaryContainer,
                      color.tertiaryContainer,
                    ]),
                    type: BoringAvatarType.beam,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── SECTION HEADER ──
  Widget _buildSectionHeader(
    String title,
    IconData icon,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: color.primary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── GROUPED FORM CARD ──
  Widget _buildFormCard(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontal,
        vertical: spacing.cardVertical,
      ),
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: ctxt.profile_nameControllerText,
              hintText: ctxt.profile_nameControllerHintText,
              prefixIcon: const Icon(LucideIcons.user),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(spacing.radiusMedium),
              ),
              filled: true,
              fillColor: color.surfaceContainerHighest.withValues(alpha: 0.3),
            ),
            validator: (v) => v == null || v.isEmpty
                ? ctxt.profile_nameRequiredHintText
                : null,
            onChanged: (_) => setState(() {}),
          ),
          SizedBox(height: spacing.sectionGap),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: ctxt.profile_emailControllerText,
              hintText: ctxt.profile_emailControllerHintText,
              prefixIcon: const Icon(LucideIcons.mail),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(spacing.radiusMedium),
              ),
              filled: true,
              fillColor: color.surfaceContainerHighest.withValues(alpha: 0.3),
            ),
          ),
          SizedBox(height: spacing.sectionGap),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: ctxt.profile_phoneControllerText,
              hintText: ctxt.profile_phoneControllerHintText,
              prefixIcon: const Icon(LucideIcons.phone),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(spacing.radiusMedium),
              ),
              filled: true,
              fillColor: color.surfaceContainerHighest.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  // ── PRIVACY NOTE ──
  Widget _buildPrivacyNote(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(),
      color: color.primaryContainer.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        side: BorderSide(
          color: color.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(LucideIcons.shieldCheck, color: color.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                ctxt.profile_weAreNotStoringInfoText,
                style: textTheme.bodySmall?.copyWith(
                  color: color.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── SAVE BUTTON ──
  Widget _buildSaveButton(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    return FilledButton.icon(
      onPressed: () async {
        HapticFeedback.mediumImpact();
        if (_formKey.currentState?.validate() ?? false) {
          final router = GoRouter.of(context);
          final updatedProfile = _profile
            ..name = _nameController.text.trim()
            ..email = _emailController.text.trim()
            ..phone = _phoneController.text.trim()
            ..updateAt = DateTime.now();
          await ref
              .read(userProfileServiceProvider)
              .saveProfile(updatedProfile);
          ref.invalidate(userProfileProvider);
          SnackbarService.success(BuddyMessages.settingsSaved, spacing, );
          router.pop();
        }
      },
      icon: const Icon(LucideIcons.check),
      label: Text(ctxt.profile_saveButtonText),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        minimumSize: const Size(double.infinity, 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
        ),
      ),
    );
  }
}
