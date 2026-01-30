import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mudra_manager/db/models/tag.dart' show Tag;
import 'package:mudra_manager/providers/tag_provider.dart';

class InlineTagSelector extends ConsumerStatefulWidget {
  final List<Tag> selectedTags;
  final ValueChanged<Tag> onChanged;
  final List<Tag> allTags;

  const InlineTagSelector({
    super.key,
    required this.selectedTags,
    required this.onChanged,
    required this.allTags,
  });

  @override
  ConsumerState<InlineTagSelector> createState() => _InlineTagSelectorState();
}

class _InlineTagSelectorState extends ConsumerState<InlineTagSelector> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  void _addTag(String name) async {
    if (name.trim().isEmpty) return;

    final existing = widget.allTags.firstWhere(
      (tag) => tag.name.toLowerCase() == name.toLowerCase(),
      orElse: () => Tag()..id = -1,
    );

    if (existing.id != -1) {
      if (!widget.selectedTags.contains(existing)) {
        widget.onChanged(existing);
      }
      return;
    }

    final tagService = ref.read(tagServiceProvider);
    final newTag = await tagService.createTag(name);

    setState(() {
      widget.allTags.add(newTag);
    });

    widget.onChanged(newTag);
    _controller.clear();
  }


  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: 'Add tag',
          isDense: true,
          border: OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _addTag(_controller.text),
          ),
        ),
        onSubmitted: _addTag,
      ),
    );
  }
}
