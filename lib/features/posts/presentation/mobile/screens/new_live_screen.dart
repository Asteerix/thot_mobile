import 'package:thot/core/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thot/features/posts/data/repositories/post_repository_impl.dart';
import 'package:thot/core/constants/app_constants.dart';
import 'package:thot/core/constants/validation_constants.dart';
import 'package:thot/core/extensions/context_extensions.dart';
import 'package:thot/core/navigation/route_names.dart';
import 'package:thot/core/infrastructure/dependency_injection.dart';
import 'package:thot/features/posts/domain/entities/post.dart';
import 'package:thot/core/utils/error_message_helper.dart';
import 'package:thot/core/utils/safe_navigation.dart';
class NewLiveScreen extends StatefulWidget {
  final String journalistId;
  final String? postId;
  final bool isEditing;
  const NewLiveScreen({
    super.key,
    required this.journalistId,
    this.postId,
    this.isEditing = false,
  });
  @override
  State<NewLiveScreen> createState() => _NewLiveScreenState();
}
class _NewLiveScreenState extends State<NewLiveScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  late final PostRepositoryImpl _postRepository;
  bool _isSubmitting = false;
  bool _isLoading = false;
  String? _error;
  DateTime? _scheduledDate;
  TimeOfDay? _scheduledTime;
  List<String> _relatedPosts = [];
  @override
  void initState() {
    super.initState();
    _postRepository = ServiceLocator.instance.postRepository;
    if (widget.isEditing && widget.postId != null) {
      _loadExistingPost();
    }
  }
  Future<void> _loadExistingPost() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final post = await _postRepository.getPost(widget.postId!);
      if (!mounted) return;
      setState(() {
        _titleController.text = post['title'];
        _descriptionController.text = post['description'];
        _relatedPosts = List<String>.from(post['relatedPosts'] ?? []);
        if (post['scheduledAt'] != null) {
          final scheduledAt = DateTime.parse(post['scheduledAt']);
          _scheduledDate = scheduledAt;
          _scheduledTime = TimeOfDay.fromDateTime(scheduledAt);
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ErrorMessageHelper.getUserFriendlyMessage(e);
        _isLoading = false;
      });
    }
  }
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.blue,
              onPrimary: Colors.white,
              surface: Colors.black,
              onSurface: Colors.white,
            ),
            dialogTheme: DialogThemeData(backgroundColor: Theme.of(context).colorScheme.surface),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() {
        _scheduledDate = date;
        _error = null;
      });
      if (_scheduledTime == null) {
        _selectTime();
      }
    }
  }
  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _scheduledTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.blue,
              onPrimary: Colors.white,
              surface: Colors.black,
              onSurface: Colors.white,
            ),
            dialogTheme: DialogThemeData(backgroundColor: Theme.of(context).colorScheme.surface),
          ),
          child: child!,
        );
      },
    );
    if (time != null) {
      setState(() {
        _scheduledTime = time;
        _error = null;
      });
    }
  }
  Future<void> _submitLive() async {
    if (!_formKey.currentState!.validate()) return;
    if (_scheduledDate == null || _scheduledTime == null) {
      setState(() {
        _error = 'Veuillez sélectionner une date et une heure';
      });
      return;
    }
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final scheduledDateTime = DateTime(
        _scheduledDate!.year,
        _scheduledDate!.month,
        _scheduledDate!.day,
        _scheduledTime!.hour,
        _scheduledTime!.minute,
      );
      final data = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'type': PostTypes.live,
        'relatedPosts': _relatedPosts,
        'scheduledAt': scheduledDateTime.toIso8601String(),
        'journalistId': widget.journalistId,
      };
      Map<String, dynamic> result;
      if (widget.isEditing) {
        result = await _postRepository.updatePost(widget.postId!, data);
      } else {
        result = await _postRepository.createPost(data);
      }
      if (!mounted) return;
      String? postId;
      if (result['_id'] != null) {
        postId = result['_id'];
      } else if (result['data'] != null && result['data']['_id'] != null) {
        postId = result['data']['_id'];
      }
      if (postId != null && !widget.isEditing) {
        GoRouter.of(context).pushReplacement(
          '/post/$postId',
          extra: {
            'postId': postId,
            'isFromProfile': false,
            'filterType': PostType.live,
            'isFromFeed': true,
          },
        );
      } else {
        SafeNavigation.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ErrorMessageHelper.getUserFriendlyMessage(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
  Future<void> _searchRelatedPosts() async {
    final result = await showSearch(
      context: context,
      delegate: PostSearchDelegate(),
    );
    if (result != null && !_relatedPosts.contains(result)) {
      setState(() {
        _relatedPosts.add(result);
      });
    }
  }
  Widget _buildSchedulePicker() {
    String dateText = _scheduledDate == null
        ? 'Sélectionner une date'
        : '${_scheduledDate!.day}/${_scheduledDate!.month}/${_scheduledDate!.year}';
    String timeText = _scheduledTime == null
        ? 'Sélectionner une heure'
        : '${_scheduledTime!.hour}:${_scheduledTime!.minute.toString().padLeft(2, '0')}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Programmation du live :',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: UIConstants.paddingM),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _selectDate,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: Icon(Icons.calendar_today),
                label: Text(dateText),
              ),
            ),
            const SizedBox(width: UIConstants.paddingM),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _selectTime,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(Icons.access_time),
                label: Text(timeText),
              ),
            ),
          ],
        ),
      ],
    );
  }
  Widget _buildRelatedPosts() {
    if (_relatedPosts.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Publications en opposition :',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: UIConstants.paddingS),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _relatedPosts.length,
          itemBuilder: (context, index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                title: Text(
                  _relatedPosts[index],
                  style: const TextStyle(color: Colors.white),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () {
                    setState(() {
                      _relatedPosts.removeAt(index);
                    });
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          widget.isEditing ? 'Modifier le live' : 'Nouveau live',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(UIConstants.paddingM),
          children: [
            TextFormField(
              controller: _titleController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Titre',
                hintText: 'Entrez le titre de votre live',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                hintStyle: TextStyle(color: AppColors.textSecondary),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: AppColors.blue),
                  borderRadius: BorderRadius.circular(8),
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: AppColors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: AppColors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLength: ValidationConstants.maxTitleLength,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return ErrorMessages.requiredField;
                }
                return null;
              },
            ),
            const SizedBox(height: UIConstants.paddingM),
            TextFormField(
              controller: _descriptionController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'Décrivez votre live...',
                alignLabelWithHint: true,
                labelStyle: TextStyle(color: AppColors.textSecondary),
                hintStyle: TextStyle(color: AppColors.textSecondary),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: AppColors.blue),
                  borderRadius: BorderRadius.circular(8),
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: AppColors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: AppColors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLength: ValidationConstants.maxContentLength,
              maxLines: 5,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return ErrorMessages.requiredField;
                }
                return null;
              },
            ),
            const SizedBox(height: UIConstants.paddingM),
            _buildSchedulePicker(),
            const SizedBox(height: UIConstants.paddingM),
            OutlinedButton.icon(
              onPressed: _searchRelatedPosts,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.search),
              label: const Text('Ajouter une publication en opposition'),
            ),
            const SizedBox(height: UIConstants.paddingM),
            _buildRelatedPosts(),
            if (_error != null) ...[
              const SizedBox(height: UIConstants.paddingM),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.red),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: UIConstants.paddingL),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitLive,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      widget.isEditing
                          ? 'Enregistrer les modifications'
                          : 'Programmer le live',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
class PostSearchDelegate extends SearchDelegate<String> {
  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: AppColors.textSecondary),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: Colors.white),
      ),
      scaffoldBackgroundColor: Colors.black,
    );
  }
  @override
  TextStyle? get searchFieldStyle => const TextStyle(color: Colors.white);
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear, color: Colors.white),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }
  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.white),
      onPressed: () {
        close(context, '');
      },
    );
  }
  @override
  Widget buildResults(BuildContext context) {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(
            'Résultat $index pour "$query"',
            style: const TextStyle(color: Colors.white),
          ),
          onTap: () {
            close(context, 'Résultat $index');
          },
        );
      },
    );
  }
  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context);
  }
}