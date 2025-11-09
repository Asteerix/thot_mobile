import 'package:flutter/material.dart';
import 'package:thot/features/posts/domain/entities/post.dart';
import 'package:thot/features/posts/presentation/shared/widgets/feed_item.dart';
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}
class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Post> _searchResults = [];
  List<String> _recentSearches = [];
  bool _isLoading = false;
  bool _showResults = false;
  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }
  Future<void> _loadRecentSearches() async {
    setState(() {
      _recentSearches = ['Flutter', 'Dart', 'Testing'];
    });
  }
  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _isLoading = true;
      _showResults = true;
    });
    try {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _searchResults = [];
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Rechercher...',
            border: InputBorder.none,
          ),
          onSubmitted: _performSearch,
        ),
      ),
      body: _showResults ? _buildSearchResults() : _buildRecentSearches(),
    );
  }
  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_searchResults.isEmpty) {
      return const Center(
        child: Text('Aucun résultat trouvé'),
      );
    }
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final post = _searchResults[index];
        return FeedItem(
          post: post,
          onTap: () {
          },
        );
      },
    );
  }
  Widget _buildRecentSearches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Recherches récentes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _recentSearches.length,
            itemBuilder: (context, index) {
              final search = _recentSearches[index];
              return ListTile(
                leading: Icon(Icons.history),
                title: Text(search),
                onTap: () {
                  _searchController.text = search;
                  _performSearch(search);
                },
              );
            },
          ),
        ),
      ],
    );
  }
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}