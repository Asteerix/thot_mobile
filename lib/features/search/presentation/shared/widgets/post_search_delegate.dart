import 'package:thot/core/themes/app_colors.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
typedef SearchFn = Future<List<PostSearchResult>> Function(
  String query, {
  required PostSearchFilter filter,
});
enum PostSearchFilter { all, authors, tags, recent, popular }
class PostSearchResult {
  final String title;
  final String? subtitle;
  final String? leadingUrl;
  final String? trailingLabel;
  final String id;
  PostSearchResult({
    required this.title,
    required this.id,
    this.subtitle,
    this.leadingUrl,
    this.trailingLabel,
  });
}
class PostSearchDelegate extends SearchDelegate<String?> {
  PostSearchDelegate({
    required this.search,
    this.recentTerms = const <String>[],
    this.trending = const <String>[],
    this.initialFilter = PostSearchFilter.all,
    this.seedColor = AppColors.primary,
  }) : _filter = initialFilter;
  final SearchFn search;
  final List<String> recentTerms;
  final List<String> trending;
  final PostSearchFilter initialFilter;
  final Color seedColor;
  PostSearchFilter _filter;
  Timer? _debounce;
  final ValueNotifier<bool> _loading = ValueNotifier(false);
  final ValueNotifier<List<PostSearchResult>?> _results = ValueNotifier(null);
  final ValueNotifier<Object?> _error = ValueNotifier(null);
  @override
  void dispose() {
    _debounce?.cancel();
    _loading.dispose();
    _results.dispose();
    _error.dispose();
    super.dispose();
  }
  @override
  ThemeData appBarTheme(BuildContext context) {
    final base = Theme.of(context);
    final scheme =
        ColorScheme.fromSeed(seedColor: seedColor, brightness: Brightness.dark);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.black,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.black,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.grey[400]),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
    );
  }
  @override
  String? get searchFieldLabel => 'Rechercher des posts…';
  @override
  TextStyle? get searchFieldStyle => const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w500,
        letterSpacing: .1,
      );
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      ValueListenableBuilder<bool>(
        valueListenable: _loading,
        builder: (_, loading, __) {
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: loading
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : const SizedBox(width: 0, height: 0),
          );
        },
      ),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        child: query.isEmpty
            ? const SizedBox(width: 0, height: 0)
            : IconButton(
                key: const ValueKey('clear'),
                icon: Icon(Icons.close),
                tooltip: 'Effacer',
                onPressed: () {
                  query = '';
                  _results.value = null;
                  _error.value = null;
                  _loading.value = false;
                  showSuggestions(context);
                },
              ),
      ),
    ];
  }
  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      tooltip: 'Fermer',
      onPressed: () {
        HapticFeedback.selectionClick();
        _debounce?.cancel();
        close(context, null);
      },
    );
  }
  void _triggerSearch() {
    _debounce?.cancel();
    final q = query.trim();
    if (q.isEmpty) {
      _results.value = null;
      _error.value = null;
      _loading.value = false;
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      _loading.value = true;
      _error.value = null;
      try {
        final data = await search(q, filter: _filter);
        _results.value = data;
      } catch (e) {
        _error.value = e;
        _results.value = const <PostSearchResult>[];
      } finally {
        _loading.value = false;
      }
    });
  }
  @override
  void showResults(BuildContext context) {
    HapticFeedback.lightImpact();
    super.showResults(context);
    _triggerSearch();
  }
  @override
  void showSuggestions(BuildContext context) {
    super.showSuggestions(context);
    _triggerSearch();
  }
  @override
  void close(BuildContext context, String? result) {
    _debounce?.cancel();
    super.close(context, result);
  }
  @override
  Widget buildResults(BuildContext context) {
    return _Body(
      query: query,
      filter: _filter,
      onFilterChanged: (f) {
        _filter = f;
        _triggerSearch();
      },
      results: _results,
      loading: _loading,
      error: _error,
      emptyLabel: 'Aucun résultat pour "$query".',
      onTapResult: (result) => close(context, result.id),
      recentTerms: recentTerms,
      trending: trending,
    );
  }
  @override
  Widget buildSuggestions(BuildContext context) {
    return _Body(
      query: query,
      filter: _filter,
      onFilterChanged: (f) {
        _filter = f;
        _triggerSearch();
      },
      results: _results,
      loading: _loading,
      error: _error,
      emptyLabel:
          query.isEmpty ? 'Tapez pour rechercher.' : 'Aucune suggestion.',
      onTapResult: (result) {
        query = result.title;
        showResults(context);
      },
      recentTerms: recentTerms,
      trending: trending,
    );
  }
}
class _Body extends StatelessWidget {
  const _Body({
    required this.query,
    required this.filter,
    required this.onFilterChanged,
    required this.results,
    required this.loading,
    required this.error,
    required this.emptyLabel,
    required this.onTapResult,
    required this.recentTerms,
    required this.trending,
  });
  final String query;
  final PostSearchFilter filter;
  final ValueChanged<PostSearchFilter> onFilterChanged;
  final ValueNotifier<List<PostSearchResult>?> results;
  final ValueNotifier<bool> loading;
  final ValueNotifier<Object?> error;
  final String emptyLabel;
  final ValueChanged<PostSearchResult> onTapResult;
  final List<String> recentTerms;
  final List<String> trending;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FiltersBar(filter: filter, onChanged: onFilterChanged),
        Divider(height: 1, thickness: 1, color: Colors.grey[900]),
        Expanded(
          child: ValueListenableBuilder<Object?>(
            valueListenable: error,
            builder: (_, err, __) {
              if (err != null) {
                return _EmptyState(
                  icon: Icons.error_outline,
                  label: 'Erreur inattendue.',
                  hint: 'Vérifiez votre connexion puis réessayez.',
                );
              }
              return ValueListenableBuilder<List<PostSearchResult>?>(
                valueListenable: results,
                builder: (_, data, __) {
                  final isLoading = loading.value;
                  if (query.isEmpty && (data == null || data.isEmpty)) {
                    return _IdleSuggestions(
                      recentTerms: recentTerms,
                      trending: trending,
                      onTap: (term) {
                        final dummyResult = PostSearchResult(
                          id: term,
                          title: term,
                        );
                        onTapResult(dummyResult);
                      },
                    );
                  }
                  if (isLoading) {
                    return const _SkeletonList();
                  }
                  if (data == null) {
                    return _EmptyState(
                      icon: Icons.search,
                      label: emptyLabel,
                      hint: '',
                    );
                  }
                  if (data.isEmpty) {
                    return _EmptyState(
                      icon: Icons.search_off,
                      label: 'Aucun résultat',
                      hint: 'Affinez les mots-clés ou changez le filtre.',
                    );
                  }
                  return Scrollbar(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: data.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        thickness: 1,
                        color: Colors.grey[900],
                      ),
                      itemBuilder: (_, i) {
                        final item = data[i];
                        return _ResultTile(
                          title: item.title,
                          subtitle: item.subtitle,
                          leadingUrl: item.leadingUrl,
                          trailingLabel: item.trailingLabel,
                          query: query,
                          onTap: () => onTapResult(item),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
class _FiltersBar extends StatelessWidget {
  const _FiltersBar({required this.filter, required this.onChanged});
  final PostSearchFilter filter;
  final ValueChanged<PostSearchFilter> onChanged;
  @override
  Widget build(BuildContext context) {
    final entries = <(String, PostSearchFilter)>[
      ('Tous', PostSearchFilter.all),
      ('Auteurs', PostSearchFilter.authors),
      ('Tags', PostSearchFilter.tags),
      ('Récent', PostSearchFilter.recent),
      ('Populaire', PostSearchFilter.popular),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: entries.map((e) {
          final selected = e.$2 == filter;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              selected: selected,
              onSelected: (_) {
                HapticFeedback.lightImpact();
                onChanged(e.$2);
              },
              label: Text(e.$1),
              showCheckmark: false,
              visualDensity: VisualDensity.compact,
            ),
          );
        }).toList(),
      ),
    );
  }
}
class _ResultTile extends StatelessWidget {
  const _ResultTile({
    required this.title,
    this.subtitle,
    this.leadingUrl,
    this.trailingLabel,
    required this.query,
    required this.onTap,
  });
  final String title;
  final String? subtitle;
  final String? leadingUrl;
  final String? trailingLabel;
  final String query;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: leadingUrl == null
          ? const CircleAvatar(child: Icon(Icons.article))
          : CircleAvatar(
              backgroundImage: NetworkImage(leadingUrl!),
              backgroundColor: Colors.grey[800],
              onBackgroundImageError: (_, __) {},
            ),
      title: RichText(
        text: _highlightOccurrences(
          text: title,
          pattern: query,
          highlightStyle: theme.textTheme.titleMedium!.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
          normalStyle: theme.textTheme.titleMedium!,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall!
                  .copyWith(color: Colors.grey[400]),
            ),
      trailing: trailingLabel == null
          ? null
          : Text(
              trailingLabel!,
              style: theme.textTheme.labelMedium!
                  .copyWith(color: Colors.grey[400]),
            ),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
    );
  }
  TextSpan _highlightOccurrences({
    required String text,
    required String pattern,
    required TextStyle highlightStyle,
    required TextStyle normalStyle,
  }) {
    if (pattern.isEmpty) return TextSpan(text: text, style: normalStyle);
    final lcText = text.toLowerCase();
    final lcPattern = pattern.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;
    while (true) {
      final index = lcText.indexOf(lcPattern, start);
      if (index < 0) {
        spans.add(TextSpan(text: text.substring(start), style: normalStyle));
        break;
      }
      if (index > start) {
        spans.add(
            TextSpan(text: text.substring(start, index), style: normalStyle));
      }
      spans.add(TextSpan(
          text: text.substring(index, index + lcPattern.length),
          style: highlightStyle));
      start = index + lcPattern.length;
    }
    return TextSpan(children: spans);
  }
}
class _EmptyState extends StatelessWidget {
  const _EmptyState(
      {required this.icon, required this.label, required this.hint});
  final IconData icon;
  final String label;
  final String hint;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.grey[500]),
            const SizedBox(height: 12),
            Text(label, style: theme.textTheme.titleMedium),
            if (hint.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(hint,
                  style: theme.textTheme.bodySmall!
                      .copyWith(color: Colors.grey[400])),
            ],
          ],
        ),
      ),
    );
  }
}
class _SkeletonList extends StatelessWidget {
  const _SkeletonList();
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 8,
      itemBuilder: (_, __) {
        return const _SkeletonTile();
      },
    );
  }
}
class _SkeletonTile extends StatelessWidget {
  const _SkeletonTile();
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
            color: Colors.grey[800], shape: BoxShape.circle),
      ),
      title: _skeletonBar(widthFactor: .8),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: _skeletonBar(widthFactor: .5),
      ),
    );
  }
  Widget _skeletonBar({required double widthFactor}) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: SizedBox(
        height: 14,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: const BorderRadius.all(Radius.circular(6)),
          ),
        ),
      ),
    );
  }
}
class _IdleSuggestions extends StatelessWidget {
  const _IdleSuggestions({
    required this.recentTerms,
    required this.trending,
    required this.onTap,
  });
  final List<String> recentTerms;
  final List<String> trending;
  final ValueChanged<String> onTap;
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      children: [
        if (recentTerms.isNotEmpty) ...[
          const _SectionTitle('Récents'),
          Wrap(
            spacing: 8,
            runSpacing: -6,
            children: recentTerms
                .map((t) => InputChip(
                      label: Text(t),
                      onPressed: () => onTap(t),
                      visualDensity: VisualDensity.compact,
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
        ],
        if (trending.isNotEmpty) ...[
          const _SectionTitle('Tendances'),
          Wrap(
            spacing: 8,
            runSpacing: -6,
            children: trending
                .map((t) => ActionChip(
                      label: Text(t),
                      onPressed: () => onTap(t),
                      visualDensity: VisualDensity.compact,
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }
}
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
      child: Text(
        text,
        style: theme.textTheme.labelLarge!.copyWith(
          color: Colors.grey[400],
          letterSpacing: .3,
        ),
      ),
    );
  }
}