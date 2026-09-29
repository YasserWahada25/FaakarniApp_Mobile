import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../models/post.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/form_fields.dart';
import '../../widgets/common/network_picture.dart';
import '../../widgets/common/upload_area.dart';
import '../../widgets/posts/post_widgets.dart';

/// Web `/posts/create` and `/posts/edit/:id`.
class PostFormScreen extends StatefulWidget {
  const PostFormScreen({super.key, this.post});

  /// `null` → creation, otherwise edition.
  final Post? post;

  @override
  State<PostFormScreen> createState() => _PostFormScreenState();
}

class _PostFormScreenState extends State<PostFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _content = TextEditingController(text: widget.post?.content);
  late String? _imageUrl = widget.post?.imageUrl;

  bool get _isEdit => widget.post != null;
  bool get _valid => _content.text.trim().length >= AppConstants.postMinLength;

  @override
  void dispose() {
    _content.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.pop();
  }

  void _reset() => setState(() {
        _content.clear();
        _imageUrl = null;
      });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Post' : 'Create New Post')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: AppSpacing.screen,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              PostsHeader(
                title: _isEdit ? 'Edit Post' : 'Create New Post',
                subtitle: _isEdit ? 'Update your story' : 'Share your story with the community',
                icon: Icons.edit_note_rounded,
              ),
              const SizedBox(height: AppSpacing.xl),
              LabeledField(
                label: 'Content',
                required: true,
                child: TextFormField(
                  controller: _content,
                  minLines: 6,
                  maxLines: 12,
                  maxLength: AppConstants.postMaxLength,
                  onChanged: (_) => setState(() {}),
                  validator: (v) => (v ?? '').trim().length < AppConstants.postMinLength
                      ? 'Post must be at least ${AppConstants.postMinLength} characters long'
                      : null,
                  decoration: const InputDecoration(
                    hintText: 'Write your post here... Share your thoughts, experiences, or insights. '
                        '(Minimum 10 characters required)',
                  ),
                ),
              ),
              LabeledField(
                label: 'Add Image',
                hint: '(Optional)',
                child: _imageUrl == null
                    ? const UploadArea(title: 'Tap to upload an image', subtitle: 'PNG, JPG, GIF up to 5MB')
                    : Stack(
                        children: [
                          NetworkPicture(url: _imageUrl!, height: AppSizes.headerImageHeight, width: double.infinity, borderRadius: AppRadius.mdAll),
                          Positioned(
                            right: AppSpacing.sm,
                            top: AppSpacing.sm,
                            child: IconButton.filled(
                              tooltip: 'Remove image',
                              style: IconButton.styleFrom(backgroundColor: AppColors.error),
                              onPressed: () => setState(() => _imageUrl = null),
                              icon: const Icon(Icons.delete_outline_rounded),
                            ),
                          ),
                        ],
                      ),
              ),
              if (_content.text.isNotEmpty) ...[
                Text('Preview', style: text.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                AppCard(child: Text(_content.text, style: text.bodyMedium?.copyWith(color: PostColors.text))),
                const SizedBox(height: AppSpacing.xl),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _reset,
                      icon: const Icon(Icons.restart_alt_rounded),
                      label: const Text('Clear'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _valid ? _submit : null,
                      icon: const Icon(Icons.send_rounded),
                      label: Text(_isEdit ? 'Update Post' : 'Publish Post'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
