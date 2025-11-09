import 'package:thot/core/themes/app_colors.dart';
import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:thot/features/authentication/application/providers/auth_provider.dart';
import 'package:thot/features/posts/data/repositories/post_repository_impl.dart';
import 'package:thot/core/infrastructure/dependency_injection.dart';
import 'package:thot/core/utils/safe_navigation.dart';
import 'package:thot/features/posts/domain/entities/post.dart';
class PostSearchDialog extends StatefulWidget {
  const PostSearchDialog({
    super.key,
    required this.onPostSelected,
    this.initialQuery,
    this.initialDomain,
    this.excludeMyPosts = true,
  });
  final Function(Post) onPostSelected;
  final String? initialQuery;
  final String? initialDomain;
  final bool excludeMyPosts;
  @override
  State<PostSearchDialog> createState() => _PostSearchDialogState();
}
class _PostSearchDialogState extends State<PostSearchDialog> {
  late final PostRepositoryImpl _postRepository;
  final _queryController = TextEditingController();
  final _searchFocus = FocusNode();
  final _scrollController = ScrollController();
  List<Post> _results = [];
  bool _loading = false;
  bool _error = false;
  String _errorMsg = '';
  String _query = '';
  String? _domain;
  bool _excludeMine = true;
  int _selectedIndex = -1;
  Post? _preview;
  Timer? _debounce;
  int _requestSeq = 0;
  final _cache = _LruCache<String, List<Post>>(capacity: 20);
  final _recentQueries = <String>{};
  static const _domains = <String>[
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
  static const _domainLabels = <String, String>{
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
  bool get _isWide {
    final w = MediaQuery.of(context).size.width;
    return w >= 720;
  }
  @override
  void initState() {
    super.initState();
    _postRepository = ServiceLocator.instance.postRepository;
    _excludeMine = widget.excludeMyPosts;
    if (widget.initialQuery?.isNotEmpty ?? false) {
      _queryController.text = widget.initialQuery!;
      _query = widget.initialQuery!;
    }
    _domain = widget.initialDomain;
    _loadDefault();
  }
  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.dispose();
    _searchFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  Future<void> _loadDefault() async {
    _setLoading(true);
    _error = false;
    _errorMsg = '';
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final me = auth.userProfile?.id;
    try {
      final cacheKey = _cacheKey('', _domain, _excludeMine, me);
      final cached = _cache.get(cacheKey);
      if (cached != null) {
        _setResults(cached);
        _setLoading(false);
        return;
      }
      final response = await _postRepository.getPosts(type: 'posts');
      final posts = (response['posts'] as List)
          .map((p) => Post.fromJson(p as Map<String, dynamic>))
          .toList();
      final filtered = _postFilter(posts, me);
      _cache.set(cacheKey, filtered);
      _setResults(filtered);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _searchNow(value);
    });
  }
  Future<void> _searchNow(String value) async {
    _query = value.trim();
    _selectedIndex = -1;
    _preview = null;
    if (_query.isEmpty) {
      await _loadDefault();
      return;
    }
    _setLoading(true);
    _error = false;
    _errorMsg = '';
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final me = auth.userProfile?.id;
    final int token = ++_requestSeq;
    try {
      final cacheKey = _cacheKey(_query, _domain, _excludeMine, me);
      final cached = _cache.get(cacheKey);
      if (cached != null) {
        if (token == _requestSeq && mounted) {
          _setResults(cached);
          _setLoading(false);
        }
        return;
      }
      final response =
          await _postRepository.getPosts(search: _query, type: 'posts');
      if (token != _requestSeq || !mounted) return;
      final posts = (response['posts'] as List)
          .map((p) => Post.fromJson(p as Map<String, dynamic>))
          .toList();
      final filtered = _postFilter(posts, me, query: _query);
      _cache.set(cacheKey, filtered);
      _setResults(filtered);
      if (_query.isNotEmpty) {
        _recentQueries.remove(_query);
        _recentQueries.add(_query);
        while (_recentQueries.length > 8) {
          _recentQueries.remove(_recentQueries.first);
        }
      }
    } catch (e) {
      if (token != _requestSeq || !mounted) return;
      _setError(e.toString());
    } finally {
      if (token == _requestSeq && mounted) _setLoading(false);
    }
  }
  List<Post> _postFilter(List<Post> posts, String? me, {String? query}) {
    Iterable<Post> list = posts;
    if (_domain != null && _domain!.isNotEmpty) {
      list = list.where((p) => p.domain.toString().split('.').last == _domain);
    }
    if (_excludeMine && me != null) {
      list = list.where((p) => p.journalist?.id != me);
    }
    final lowerQ = (query ?? '').toLowerCase();
    final meId = me;
    final sorted = list.toList()
      ..sort((a, b) {
        final amine = a.journalist?.id == meId;
        final bmine = b.journalist?.id == meId;
        if (amine != bmine) return amine ? 1 : -1;
        int score(Post p) {
          if (lowerQ.isEmpty) return 0;
          final t = (p.title).toLowerCase();
          int s = 0;
          if (t.startsWith(lowerQ)) s += 3;
          if (t.contains(lowerQ)) s += 1;
          return s;
        }
        final sa = score(a);
        final sb = score(b);
        return sb.compareTo(sa);
      });
    return sorted;
  }
  String _cacheKey(String q, String? d, bool excl, String? me) =>
      'q=$q|d=${d ?? ""}|ex=$excl|me=${me ?? ""}';
  void _setLoading(bool v) => setState(() => _loading = v);
  void _setResults(List<Post> list) => setState(() {
        _results = list;
        _error = false;
        _errorMsg = '';
      });
  void _setError(String msg) => setState(() {
        _error = true;
        _errorMsg = msg;
        _results = [];
      });
  void _select(Post post) {
    widget.onPostSelected(post);
    SafeNavigation.pop(context);
  }
  void _setPreview(Post p) => setState(() => _preview = p);
  void _moveSelection(int delta) {
    if (_results.isEmpty) return;
    setState(() {
      if (_selectedIndex < 0) {
        _selectedIndex = 0;
      } else {
        _selectedIndex = (_selectedIndex + delta).clamp(0, _results.length - 1);
      }
      _preview = _isWide ? _results[_selectedIndex] : _preview;
    });
    final itemExtent = 76.0;
    _scrollController.animateTo(
      (_selectedIndex * (itemExtent + 6))
          .toDouble()
          .clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
    );
  }
  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      SafeNavigation.pop(context);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _moveSelection(1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _moveSelection(-1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_selectedIndex >= 0 && _selectedIndex < _results.length) {
        _select(_results[_selectedIndex]);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }
  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final isSmall = screen.width < 380;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Focus(
        autofocus: true,
        onKeyEvent: _handleKey,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.all(isSmall ? 16 : 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(Icons.swap_horiz,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Rechercher une publication',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fermer',
                    onPressed: () => SafeNavigation.pop(context),
                    icon: Icon(Icons.close, color: Colors.white70, size: 28),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _SearchBar(
                controller: _queryController,
                focusNode: _searchFocus,
                loading: _loading,
                onChanged: _onSearchChanged,
                onSubmitted: _searchNow,
                onClear: () {
                  _queryController.clear();
                  _searchNow('');
                },
                recent: _recentQueries.toList().reversed.toList(),
                onTapSuggestion: (s) {
                  _queryController.text = s;
                  _searchNow(s);
                },
              ),
              const SizedBox(height: 16),
              _FiltersRow(
                domain: _domain,
                excludeMine: _excludeMine,
                onDomainTap: (d) {
                  setState(() => _domain = d);
                  (_query.isEmpty) ? _loadDefault() : _searchNow(_query);
                },
                onToggleExcludeMine: (v) {
                  setState(() => _excludeMine = v);
                  (_query.isEmpty) ? _loadDefault() : _searchNow(_query);
                },
              ),
              const SizedBox(height: 16),
              Flexible(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: _loading
                      ? const _LoadingList()
                      : _error
                          ? _ErrorView(
                              message: _errorMsg,
                              onRetry: () {
                                (_query.isEmpty)
                                    ? _loadDefault()
                                    : _searchNow(_query);
                              })
                          : _results.isEmpty
                              ? _EmptyState(
                                  query: _query,
                                  onClear: () {
                                    _queryController.clear();
                                    _searchNow('');
                                  },
                                )
                              : _isWide
                                  ? Row(
                                      children: [
                                        Expanded(
                                          flex: 11,
                                          child: _ResultsList(
                                            controller: _scrollController,
                                            results: _results,
                                            query: _query,
                                            selectedIndex: _selectedIndex,
                                            onHover: (i) => setState(
                                                () => _selectedIndex = i),
                                            onPreview: (p) => _setPreview(p),
                                            onTap: (p, i) {
                                              _selectedIndex = i;
                                              _select(p);
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          flex: 14,
                                          child: _PreviewPane(
                                            post: _preview ?? _results.first,
                                            query: _query,
                                            onSelect: _select,
                                          ),
                                        ),
                                      ],
                                    )
                                  : _ResultsList(
                                      controller: _scrollController,
                                      results: _results,
                                      query: _query,
                                      selectedIndex: _selectedIndex,
                                      onHover: (i) =>
                                          setState(() => _selectedIndex = i),
                                      onPreview: (p) {
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.black,
                                          shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.vertical(
                                                top: Radius.circular(20)),
                                          ),
                                          builder: (_) => DraggableScrollableSheet(
                                            initialChildSize: 0.75,
                                            minChildSize: 0.5,
                                            maxChildSize: 0.9,
                                            expand: false,
                                            builder: (context, scrollController) => Container(
                                              padding: const EdgeInsets.all(24),
                                              child: Column(
                                                children: [
                                                  Container(
                                                    width: 40,
                                                    height: 4,
                                                    margin: const EdgeInsets.only(bottom: 20),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white.withOpacity(0.3),
                                                      borderRadius: BorderRadius.circular(2),
                                                    ),
                                                  ),
                                                  Text(
                                                    'Aperçu',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 20,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 24),
                                                  Expanded(
                                                    child: _PreviewPane(
                                                      post: p,
                                                      query: _query,
                                                      onSelect: _select,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      onTap: (p, i) {
                                        _selectedIndex = i;
                                        _select(p);
                                      },
                                    ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.loading,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    required this.recent,
    required this.onTapSuggestion,
  });
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool loading;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;
  final List<String> recent;
  final ValueChanged<String> onTapSuggestion;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: controller,
          focusNode: focusNode,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Titre de la publication…',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (controller.text.isNotEmpty)
                  IconButton(
                    tooltip: 'Effacer',
                    onPressed: onClear,
                    icon: Icon(Icons.close, color: Colors.white.withOpacity(0.7)),
                  ),
                if (loading)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.7)),
                        )),
                  ),
              ],
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          textInputAction: TextInputAction.search,
        ),
        if (recent.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: recent.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => ActionChip(
                label: Text(recent[i],
                    style: const TextStyle(color: Colors.white, fontSize: 13)),
                backgroundColor: Colors.white.withOpacity(0.1),
                side: BorderSide(color: Colors.white.withOpacity(0.3)),
                onPressed: () => onTapSuggestion(recent[i]),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
class _FiltersRow extends StatelessWidget {
  const _FiltersRow({
    required this.domain,
    required this.excludeMine,
    required this.onDomainTap,
    required this.onToggleExcludeMine,
  });
  final String? domain;
  final bool excludeMine;
  final ValueChanged<String?> onDomainTap;
  final ValueChanged<bool> onToggleExcludeMine;
  static const _domains = _PostSearchDialogState._domains;
  static const _domainLabels = _PostSearchDialogState._domainLabels;
  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 400;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: isSmall ? 40 : 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemCount: _domains.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final isAll = index == 0;
              final key = isAll ? null : _domains[index - 1];
              final label = isAll ? 'Tous' : (_domainLabels[key] ?? key!);
              final selected =
                  (isAll && domain == null) || (!isAll && domain == key);
              return ChoiceChip(
                label: Text(label,
                    style: TextStyle(
                        color: selected ? Colors.white : Colors.white.withOpacity(0.7),
                        fontSize: isSmall ? 13 : 14,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
                selected: selected,
                backgroundColor: Colors.white.withOpacity(0.05),
                selectedColor: Colors.white.withOpacity(0.15),
                side: BorderSide(
                  color: selected ? Colors.white : Colors.white.withOpacity(0.3),
                  width: selected ? 2 : 1,
                ),
                onSelected: (_) => onDomainTap(key),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.visibility_off,
                color: Colors.white.withOpacity(0.7),
                size: 18),
              const SizedBox(width: 8),
              Text('Masquer mes posts',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmall ? 13 : 14)),
              const SizedBox(width: 8),
              Switch(
                value: excludeMine,
                onChanged: onToggleExcludeMine,
                activeColor: Colors.white,
                activeTrackColor: Colors.white.withOpacity(0.3),
                inactiveThumbColor: Colors.white.withOpacity(0.5),
                inactiveTrackColor: Colors.white.withOpacity(0.1),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
class _ResultsList extends StatelessWidget {
  const _ResultsList({
    required this.controller,
    required this.results,
    required this.query,
    required this.selectedIndex,
    required this.onHover,
    required this.onPreview,
    required this.onTap,
  });
  final ScrollController controller;
  final List<Post> results;
  final String query;
  final int selectedIndex;
  final ValueChanged<int> onHover;
  final ValueChanged<Post> onPreview;
  final void Function(Post, int) onTap;
  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 400;
    final maxHeight = MediaQuery.of(context).size.height * 0.55;
    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: ListView.separated(
        controller: controller,
        padding: EdgeInsets.symmetric(vertical: isSmall ? 4 : 8),
        itemCount: results.length,
        separatorBuilder: (_, __) => const SizedBox(height: 6),
        itemBuilder: (context, i) {
          final post = results[i];
          final selected = i == selectedIndex;
          return InkWell(
            onTap: () => onTap(post, i),
            onLongPress: () => onPreview(post),
            onHover: (_) => onHover(i),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.all(isSmall ? 12 : 14),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withOpacity(0.15)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? Colors.white : Colors.white.withOpacity(0.3),
                  width: selected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: post.imageUrl != null
                        ? Image.network(
                            post.imageUrl!,
                            width: isSmall ? 50 : 60,
                            height: isSmall ? 50 : 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: isSmall ? 50 : 60,
                              height: isSmall ? 50 : 60,
                              color: Colors.grey[900],
                              child: const Icon(Icons.broken_image,
                                  color: Colors.grey),
                            ),
                          )
                        : Container(
                            width: isSmall ? 50 : 60,
                            height: isSmall ? 50 : 60,
                            color: Colors.grey[900],
                            child: Icon(Icons.article,
                                color: Colors.grey[600]),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Highlight(text: post.title, query: query),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.person,
                                size: 12, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                post.journalist?.name ?? 'Inconnu',
                                style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: isSmall ? 11 : 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right, color: Colors.white38),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
class _PreviewPane extends StatelessWidget {
  const _PreviewPane(
      {required this.post, required this.query, required this.onSelect});
  final Post post;
  final String query;
  final ValueChanged<Post> onSelect;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: post.imageUrl != null
                ? Image.network(post.imageUrl!,
                    height: 180, width: double.infinity, fit: BoxFit.cover)
                : Container(
                    height: 180,
                    color: Colors.white.withOpacity(0.05),
                    child: Icon(Icons.image, color: Colors.white.withOpacity(0.3), size: 48)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.4)),
                ),
                child: Text(post.domain.toString().split('.').last,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
              ),
              const Spacer(),
              Icon(Icons.person, size: 16, color: Colors.white.withOpacity(0.7)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  post.journalist?.name ?? 'Inconnu',
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
              alignment: Alignment.centerLeft,
              child: _Highlight(text: post.title, query: query, size: 16)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => onSelect(post),
              icon: Icon(Icons.check_circle),
              label: const Text('Sélectionner cette publication'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.query, required this.onClear});
  final String query;
  final VoidCallback onClear;
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 320),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Icon(Icons.search_off, color: Colors.white.withOpacity(0.5), size: 40),
          ),
          const SizedBox(height: 16),
          Text(
              query.isEmpty
                  ? 'Aucune publication disponible'
                  : 'Aucun résultat trouvé',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(
              query.isEmpty
                  ? 'Il n\'y a pas de publications pour le moment'
                  : 'Essayez avec d\'autres mots-clés',
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14)),
          if (query.isNotEmpty) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onClear,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withOpacity(0.3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Effacer la recherche'),
            ),
          ],
        ],
      ),
    );
  }
}
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 320),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Icon(Icons.error_outline, color: Colors.red.shade300, size: 40),
          ),
          const SizedBox(height: 16),
          const Text('Une erreur est survenue',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(message,
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: Icon(Icons.refresh),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
class _LoadingList extends StatelessWidget {
  const _LoadingList();
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 420),
      child: ListView.separated(
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: 6),
        itemBuilder: (_, __) => _SkeletonTile(),
      ),
    );
  }
}
class _SkeletonTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final base = Colors.white.withOpacity(0.05);
    final hi = Colors.white.withOpacity(0.1);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          _SkeletonBox(
              width: 60, height: 60, base: base, highlight: hi, radius: 8),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonBox(width: 180, height: 14, base: base, highlight: hi),
                const SizedBox(height: 10),
                _SkeletonBox(width: 120, height: 12, base: base, highlight: hi),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
class _SkeletonBox extends StatefulWidget {
  const _SkeletonBox(
      {required this.width,
      required this.height,
      required this.base,
      required this.highlight,
      this.radius = 8});
  final double width;
  final double height;
  final Color base;
  final Color highlight;
  final double radius;
  @override
  State<_SkeletonBox> createState() => _SkeletonBoxState();
}
class _SkeletonBoxState extends State<_SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat(reverse: true);
  late final Animation<Color?> _a =
      ColorTween(begin: widget.base, end: widget.highlight)
          .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
            color: _a.value,
            borderRadius: BorderRadius.circular(widget.radius)),
      ),
    );
  }
}
class _Highlight extends StatelessWidget {
  const _Highlight({required this.text, required this.query, this.size = 14});
  final String text;
  final String query;
  final double size;
  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(text,
          style: TextStyle(color: Colors.white, fontSize: size, height: 1.3),
          maxLines: 2,
          overflow: TextOverflow.ellipsis);
    }
    final lower = text.toLowerCase();
    final q = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;
    while (true) {
      final idx = lower.indexOf(q, start);
      if (idx < 0) {
        spans.add(TextSpan(
            text: text.substring(start),
            style: TextStyle(color: Colors.white)));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(
            text: text.substring(start, idx),
            style: const TextStyle(color: Colors.white)));
      }
      spans.add(TextSpan(
          text: text.substring(idx, idx + q.length),
          style: TextStyle(color: AppColors.blue)));
      start = idx + q.length;
    }
    return RichText(
      text: TextSpan(
          style: TextStyle(fontSize: size, height: 1.3), children: spans),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
class _LruCache<K, V> {
  _LruCache({this.capacity = 20}) : assert(capacity > 0);
  final int capacity;
  final _map = <K, V>{};
  V? get(K key) {
    if (!_map.containsKey(key)) return null;
    final v = _map.remove(key) as V;
    _map[key] = v;
    return v;
  }
  void set(K key, V value) {
    if (_map.length >= capacity && !_map.containsKey(key)) {
      _map.remove(_map.keys.first);
    }
    _map.remove(key);
    _map[key] = value;
  }
}