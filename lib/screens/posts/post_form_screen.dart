import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/session/auth_session.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../models/post.dart';
import '../../services/post_service.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/dialogs.dart';
import '../../widgets/common/form_fields.dart';
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
  bool _saving = false;

  /// Post-Service rejects image strings over 5 MB (base64 adds a third).
  static const int _maxImageChars = 5 * 1024 * 1024;

  bool get _isEdit => widget.post != null;
  bool get _valid => _content.text.trim().length >= AppConstants.postMinLength;

  @override
  void dispose() {
    _content.dispose();
    super.dispose();
  }

  /// Same storage as the web app: the image is sent inline as a `data:` URL.
  Future<void> _pickImage() async {
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1280, imageQuality: 80);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final ext = file.name.split('.').last.toLowerCase();
      final mime = switch (ext) {
        'png' => 'image/png',
        'gif' => 'image/gif',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      };
      final dataUrl = 'data:$mime;base64,${base64Encode(bytes)}';
      if (!mounted) return;
      if (dataUrl.length > _maxImageChars) {
        showAppSnackBar(context, 'Image is too large. Maximum size is 5MB.');
        return;
      }
      setState(() => _imageUrl = dataUrl);
    } catch (e) {
      if (mounted) showAppSnackBar(context, "Impossible d'ouvrir la galerie.");
    }
  }

  Future<void> _submit() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final service = PostService.instance;
    try {
      // The service takes the author from the JWT.
      if (!await AuthSession.instance.ensureSignedIn()) {
        throw const ApiException('Connectez-vous pour publier.');
      }
      final content = _content.text.trim();
      if (_isEdit) {
        await service.update(widget.post!.id, content: content, imageUrl: _imageUrl);
      } else {
        await service.create(content: content, imageUrl: _imageUrl);
      }
      if (!mounted) return;
      showAppSnackBar(context, _isEdit ? 'Post updated successfully!' : 'Post published successfully!');
      context.pop();
    } catch (e) {
      if (mounted) showAppSnackBar(context, ApiException.describe(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
                    hintText:
                        'Write your post here... Share your thoughts, experiences, or insights. '
                        '(Minimum 10 characters required)',
                  ),
                ),
              ),
              LabeledField(
                label: 'Add Image',
                hint: '(Optional)',
                child: _imageUrl == null
                    ? UploadArea(
                        title: 'Tap to upload an image',
                        subtitle: 'PNG, JPG, GIF up to 5MB',
                        onTap: _saving ? null : _pickImage,
                      )
                    : Stack(
                        children: [
                          PostImage(
                            source: _imageUrl!,
                            height: AppSizes.headerImageHeight,
                            borderRadius: AppRadius.mdAll,
                          ),
                          Positioned(
                            right: AppSpacing.sm,
                            top: AppSpacing.sm,
                            child: IconButton.filled(
                              tooltip: 'Remove image',
                              style: IconButton.styleFrom(backgroundColor: AppColors.error),
                              onPressed: _saving ? null : () => setState(() => _imageUrl = null),
                              icon: const Icon(Icons.delete_outline_rounded),
                            ),
                          ),
                        ],
                      ),
              ),
              if (_content.text.isNotEmpty) ...[
                Text('Preview', style: text.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                AppCard(
                  child: Text(_content.text, style: text.bodyMedium?.copyWith(color: PostColors.text)),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : _reset,
                      icon: const Icon(Icons.restart_alt_rounded),
                      label: const Text('Clear'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _valid && !_saving ? _submit : null,
                      icon: _saving
                          ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.send_rounded),
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
