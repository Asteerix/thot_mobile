import 'package:thot/core/presentation/theme/app_colors.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thot/features/public/auth/shared/providers/auth_provider.dart';
import 'package:thot/features/app/content/shared/providers/post_repository_impl.dart';
import 'package:thot/core/di/service_locator.dart';
import 'package:thot/core/utils/safe_navigation.dart';
import 'package:thot/features/app/content/shared/models/post.dart';

class PostSearchDialog extends StatefulWidget {
  final Function(Post) onPostSelected;
  final String? initialQuery;
  final String? initialDomain;
  final bool excludeMyPosts;

  const PostSearchDialog({
    super.key,
    required this.onPostSelected,
    this.initialQuery,
    this.initialDomain,
    this.excludeMyPosts = true,
  });

  @override
  State<PostSearchDialog> createState() => _PostSearchDialogState();
}

class _PostSearchDialogState extends State<PostSearchDialog> {
  final _postRepository = ServiceLocator.instance.postRepository;
  final _queryController = TextEditingController();
  final _scrollController = ScrollController();

  List<Post> _results = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  String? _selectedDomain;
  int _selectedIndex = -1;
  Post? _selectedPost;
  Timer? _debounceTimer;

  static const _domains = [
    'politique',
    'economie',
    'science',
    'international',
    'juridique',
    'philosophie',
    'societe',
    'psychologie',
    'sport',
    'technologie'
  ];

  static const _domainLabels = {
    'politique': 'Politique',
    'economie': 'Économie',
    'science': 'Science',
    'international': 'International',
    'juridique': 'Juridique',
    'philosophie': 'Philosophie',
    'societe': 'Société',
    'psychologie': 'Psychologie',
    'sport': 'Sport',
    'technologie': 'Technologie',
  };

  @override
  void initState() {
    super.initState();
    _selectedDomain = widget.initialDomain;
    if (widget.initialQuery != null) {
      _queryController.text = widget.initialQuery!;
    }
    _loadPosts();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _queryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    print(
        '🔍 [POST_SEARCH] Loading posts - query: "${_queryController.text}", domain: $_selectedDomain');

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final query = _queryController.text.trim();
      final response = await _postRepository.getPosts(
        search: query.isEmpty ? null : query,
        type: 'posts',
        domain: _selectedDomain,
      );

      final posts = (response['posts'] as List)
          .map((p) => Post.fromJson(p as Map<String, dynamic>))
          .toList();

      final currentUserId = context.read<AuthProvider>().userProfile?.id;
      final filtered = widget.excludeMyPosts && currentUserId != null
          ? posts.where((p) => p.journalist?.id != currentUserId).toList()
          : posts;

      print('✅ [POST_SEARCH] Loaded ${filtered.length} posts');

      if (mounted) {
        setState(() {
          _results = filtered;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ [POST_SEARCH] Error: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _loadPosts();
    });
  }

  void _onPostTap(Post post, int index) {
    print('📌 [POST_SEARCH] Post tapped: ${post.title} (index: $index)');
    setState(() {
      _selectedIndex = index;
      _selectedPost = post;
    });
  }

  void _onConfirm() {
    if (_selectedPost == null) {
      print('⚠️ [POST_SEARCH] No post selected');
      return;
    }

    print('✅ [POST_SEARCH] Confirming selection: ${_selectedPost!.title}');
    Navigator.of(context).pop();
    widget.onPostSelected(_selectedPost!);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.swap_horiz,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Rechercher une publication',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close,
                        color: Colors.white70, size: 24),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _queryController,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Titre de la publication...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  prefixIcon:
                      Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
                  suffixIcon: _queryController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close,
                              color: Colors.white.withOpacity(0.7)),
                          onPressed: () {
                            _queryController.clear();
                            _loadPosts();
                          },
                        )
                      : null,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white, width: 2),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                ),
                onChanged: _onSearchChanged,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _loadPosts(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _domains.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final isAll = index == 0;
                  final domainKey = isAll ? null : _domains[index - 1];
                  final label =
                      isAll ? 'Tous' : (_domainLabels[domainKey] ?? domainKey!);
                  final isSelected = (isAll && _selectedDomain == null) ||
                      (!isAll && _selectedDomain == domainKey);

                  return ChoiceChip(
                    label: Text(
                      label,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withOpacity(0.7),
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    backgroundColor: Colors.white.withOpacity(0.05),
                    selectedColor: Colors.white.withOpacity(0.15),
                    side: BorderSide(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withOpacity(0.3),
                      width: isSelected ? 2 : 1,
                    ),
                    onSelected: (_) {
                      setState(() {
                        _selectedDomain = domainKey;
                      });
                      _loadPosts();
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : _hasError
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Erreur de chargement',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _errorMessage,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _loadPosts,
                                  child: const Text('Réessayer'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _results.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    color: Colors.white.withOpacity(0.3),
                                    size: 64,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Aucun résultat',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Essayez avec d\'autres mots-clés',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              itemCount: _results.length,
                              itemBuilder: (context, index) {
                                final post = _results[index];
                                final isSelected = index == _selectedIndex;

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: InkWell(
                                    onTap: () => _onPostTap(post, index),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.white.withOpacity(0.15)
                                            : Colors.white.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.white.withOpacity(0.3),
                                          width: isSelected ? 2 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: post.imageUrl != null
                                                ? Image.network(
                                                    post.imageUrl!,
                                                    width: 60,
                                                    height: 60,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (_, __, ___) =>
                                                            _buildPlaceholder(),
                                                  )
                                                : _buildPlaceholder(),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  post.title,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.person,
                                                      size: 12,
                                                      color: Colors.grey[500],
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        post.journalist?.name ??
                                                            'Inconnu',
                                                        style: TextStyle(
                                                          color:
                                                              Colors.grey[400],
                                                          fontSize: 12,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          if (isSelected)
                                            Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: const BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.check,
                                                color: Colors.black,
                                                size: 16,
                                              ),
                                            )
                                          else
                                            Container(
                                              width: 24,
                                              height: 24,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.white
                                                      .withOpacity(0.3),
                                                  width: 2,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _selectedPost != null ? _onConfirm : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedPost != null
                            ? Colors.white
                            : Colors.grey[800],
                        foregroundColor: _selectedPost != null
                            ? Colors.black
                            : Colors.grey[600],
                        disabledBackgroundColor: Colors.grey[800],
                        disabledForegroundColor: Colors.grey[600],
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _selectedPost != null
                                ? Icons.check_circle
                                : Icons.check_circle_outline,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedPost != null
                                  ? 'Continuer'
                                  : 'Sélectionnez une publication',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 60,
      height: 60,
      color: Colors.grey[900],
      child: const Icon(
        Icons.article,
        color: Colors.grey,
        size: 28,
      ),
    );
  }
}
