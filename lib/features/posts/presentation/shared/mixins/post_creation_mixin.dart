import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../../core/infrastructure/dependency_injection.dart';
import '../../../data/repositories/post_repository_impl.dart';
import '../../../../media/infrastructure/upload_service.dart';
mixin PostCreationMixin<T extends StatefulWidget> on State<T> {
  final titleController = TextEditingController();
  final contentController = TextEditingController();
  final titleFocus = FocusNode();
  final contentFocus = FocusNode();
  final scrollController = ScrollController();
  final formKey = GlobalKey<FormState>();
  late final PostRepositoryImpl postRepository;
  late final UploadService uploadService;
  bool isSubmitting = false;
  bool isLoading = false;
  bool isDirty = false;
  String? error;
  File? selectedMedia;
  String? existingMediaUrl;
  int wordCount = 0;
  int readingMinutes = 0;
  @override
  void initState() {
    super.initState();
    postRepository = ServiceLocator.instance.postRepository;
    uploadService = UploadService();
    titleController.addListener(onTextChanged);
    contentController.addListener(onTextChanged);
  }
  @override
  void dispose() {
    titleController.removeListener(onTextChanged);
    contentController.removeListener(onTextChanged);
    titleController.dispose();
    contentController.dispose();
    titleFocus.dispose();
    contentFocus.dispose();
    scrollController.dispose();
    super.dispose();
  }
  void onTextChanged() {
    setState(() {
      isDirty = true;
      wordCount = countWords(contentController.text);
      readingMinutes = (wordCount / 220).ceil().clamp(1, 60);
    });
  }
  int countWords(String text) {
    final words = text
        .replaceAll(RegExp(r"\s+"), " ")
        .trim()
        .split(" ")
        .where((w) => w.isNotEmpty)
        .toList();
    return words.isEmpty ? 0 : words.length;
  }
  void handleMediaSelected(File file) {
    setState(() {
      selectedMedia = file;
      existingMediaUrl = null;
      isDirty = true;
    });
  }
  void removeMedia() {
    setState(() {
      selectedMedia = null;
      existingMediaUrl = null;
      isDirty = true;
    });
  }
  bool validateForm() {
    return formKey.currentState?.validate() ?? false;
  }
  void setSubmitting(bool value) {
    setState(() {
      isSubmitting = value;
    });
  }
  void setError(String? value) {
    setState(() {
      error = value;
    });
  }
  void setLoading(bool value) {
    setState(() {
      isLoading = value;
    });
  }
}