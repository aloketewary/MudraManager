// lib/screens/edit_user_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/db/models/user_profile.dart' show UserProfile;
import 'package:mudra_manager/providers/user_profile_provider.dart';
import 'package:mudra_manager/screens/reusable/common_button.dart';
import 'package:mudra_manager/screens/reusable/common_text_input_field.dart'
    show CommonTextInputField;
import 'package:mudra_manager/theme/mudra_manager_avatar_icons.dart'
    show MudraManagerAvatarIcons;

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

  UserProfile _profile = UserProfile(); // default empty profile
  bool _didInit = false;
  int _selectedAvatarIndex = 0; // Index from your avatar list
  var iconDataList = MudraManagerAvatarIcons.iconDataList;

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: iconDataList.length, // Assuming 10 avatar options
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemBuilder: (_, index) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedAvatarIndex = index;
                });
                Navigator.pop(context);
              },
              child: CircleAvatar(child: Icon(iconDataList[index], size: 28)),
            );
          },
        );
      },
    );
  }

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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Edit User Profile",
          style: textTheme.titleLarge?.copyWith(color: color.onPrimary),
        ),
      ),
      body: profileAsync.when(
        data: (profile) {
          if (!_didInit) _loadProfile(profile);

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 48,
                        child: Icon(
                          iconDataList[_selectedAvatarIndex],
                          size: 48,
                        ),
                      ),
                      GestureDetector(
                        onTap: _showAvatarPicker,
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: color.secondary,
                          child: Icon(
                            Icons.edit,
                            size: 14,
                            color: color.onSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  CommonTextInputField(
                    controller: _nameController,
                    labelText: 'Name',
                    hintText: 'Enter your name',
                    iconData: Icons.person,
                  ),
                  CommonTextInputField(
                    controller: _emailController,
                    labelText: 'Email',
                    hintText: 'Enter your email',
                    iconData: Icons.email,
                  ),
                  CommonTextInputField(
                    controller: _phoneController,
                    labelText: 'Phone',
                    hintText: 'Enter your phone number',
                    iconData: Icons.phone,
                  ),
                  Center(
                    child: Text(
                      "We are not storing any data, all data is in your device!",
                      style: textTheme.bodySmall,
                    ),
                  ),
                  const Spacer(),
                  CommonButton(
                    text: 'save',
                    backGroundColor: color.secondary,
                    textColor: color.onSecondary,
                    onPressed: () async {
                      if (_formKey.currentState?.validate() ?? false) {
                        final updatedProfile =
                            _profile
                              ..name = _nameController.text.trim()
                              ..email = _emailController.text.trim()
                              ..phone = _phoneController.text.trim()
                              ..avatarIndex = _selectedAvatarIndex
                              ..updateAt = DateTime.now();

                        await ref
                            .read(userProfileServiceProvider)
                            .saveProfile(updatedProfile);

                        ref.invalidate(userProfileProvider); // Refresh UI

                        if (context.mounted) Navigator.pop(context);
                      }
                    },
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
