import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/db/models/user_profile.dart' show UserProfile;
import 'package:mudra_manager/l10n/app_localizations.dart' show AppLocalizations;
import 'package:mudra_manager/providers/user_profile_provider.dart';
import 'package:mudra_manager/theme/mudra_manager_avatar_icons.dart' show MudraManagerAvatarIcons;
import 'package:mudra_manager/util/snackbar_service.dart';

class EditUserProfileScreen extends ConsumerStatefulWidget {
  const EditUserProfileScreen({super.key});

  @override
  ConsumerState<EditUserProfileScreen> createState() => _EditUserProfileScreenState();
}

class _EditUserProfileScreenState extends ConsumerState<EditUserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  UserProfile _profile = UserProfile();
  bool _didInit = false;
  int _selectedAvatarIndex = 0;
  var iconDataList = MudraManagerAvatarIcons.iconDataList;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _loadProfile(UserProfile? profile) {
    _profile = profile ?? UserProfile();
    _nameController.text = _profile.name;
    _emailController.text = _profile.email ?? '';
    _phoneController.text = _profile.phone ?? '';
    _selectedAvatarIndex = _profile.avatarIndex ?? 0;
    _didInit = true;
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    var textTheme = Theme.of(context).textTheme;
    var color = Theme.of(context).colorScheme;
    final ctxt = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(ctxt.profile_editUserProfileAppTitle, style: textTheme.titleLarge)),
      body: profileAsync.when(
        data: (profile) {
          if (!_didInit) _loadProfile(profile);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      showModalBottomSheet(
                        context: context,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                        builder: (_) => Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(width: 40, height: 4, decoration: BoxDecoration(color: color.onSurfaceVariant.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2))),
                              SizedBox(height: 16),
                              Text('Choose Avatar', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                              SizedBox(height: 16),
                              GridView.builder(
                                shrinkWrap: true,
                                itemCount: iconDataList.length,
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, mainAxisSpacing: 12, crossAxisSpacing: 12),
                                itemBuilder: (_, index) => GestureDetector(
                                  onTap: () {
                                    HapticFeedback.mediumImpact();
                                    setState(() => _selectedAvatarIndex = index);
                                    context.pop();
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(color: _selectedAvatarIndex == index ? color.primaryContainer : color.surfaceContainerHighest, shape: BoxShape.circle),
                                    child: Icon(iconDataList[index], size: 28, color: _selectedAvatarIndex == index ? color.primary : color.onSurfaceVariant),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(shape: BoxShape.circle, color: color.primaryContainer),
                          child: CircleAvatar(radius: 48, backgroundColor: color.primary.withValues(alpha: 0.1), child: Icon(iconDataList[_selectedAvatarIndex], size: 48, color: color.primary)),
                        ),
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(color: color.primary, shape: BoxShape.circle),
                          child: Icon(Icons.edit, size: 16, color: color.onPrimary),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: ctxt.profile_nameControllerText, hintText: ctxt.profile_nameControllerHintText, prefixIcon: Icon(Icons.person), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: color.surfaceContainerHighest.withValues(alpha: 0.3)),
                    validator: (v) => v == null || v.isEmpty ? ctxt.profile_nameRequiredHintText : null,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(labelText: ctxt.profile_emailControllerText, hintText: ctxt.profile_emailControllerHintText, prefixIcon: Icon(Icons.email), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: color.surfaceContainerHighest.withValues(alpha: 0.3)),
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(labelText: ctxt.profile_phoneControllerText, hintText: ctxt.profile_phoneControllerHintText, prefixIcon: Icon(Icons.phone), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: color.surfaceContainerHighest.withValues(alpha: 0.3)),
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(color: color.primaryContainer.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.primary.withValues(alpha: 0.3))),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: color.primary, size: 20),
                        SizedBox(width: 12),
                        Expanded(child: Text(ctxt.profile_weAreNotStoringInfoText, style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant))),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  FilledButton(
                    onPressed: () async {
                      HapticFeedback.mediumImpact();
                      if (_formKey.currentState?.validate() ?? false) {
                        final updatedProfile = _profile
                          ..name = _nameController.text.trim()
                          ..email = _emailController.text.trim()
                          ..phone = _phoneController.text.trim()
                          ..avatarIndex = _selectedAvatarIndex
                          ..updateAt = DateTime.now();
                        await ref.read(userProfileServiceProvider).saveProfile(updatedProfile);
                        ref.invalidate(userProfileProvider);
                        if (context.mounted) {
                          SnackbarService.success('Profile updated successfully');
                          context.pop();
                        }
                      }
                    },
                    style: FilledButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 16), minimumSize: Size(double.infinity, 0), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: Text(ctxt.profile_saveButtonText),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
      ),
    );
  }
}
