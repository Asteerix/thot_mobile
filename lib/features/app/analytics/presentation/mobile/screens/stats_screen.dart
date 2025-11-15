import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:thot/features/app/content/shared/providers/post_repository_impl.dart';
import 'package:thot/core/di/service_locator.dart';

class StatsScreen extends StatefulWidget {
  final String journalistId;
  final bool isCurrentUser;
  const StatsScreen({
    super.key,
    required this.journalistId,
    this.isCurrentUser = true,
  });
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late final PostRepositoryImpl _postRepository =
      ServiceLocator.instance.postRepository;
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String? _error;
  String _selectedPeriod = '7d';

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final stats = await _postRepository.getJournalistStats(
        widget.journalistId,
        period: _selectedPeriod,
      );
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            HapticFeedback.selectionClick();
            context.pop();
          },
        ),
        title: const Text(
          'Statistiques',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _loadStats,
                  color: Colors.white,
                  backgroundColor: Colors.black,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildPeriodSelector(),
                      const SizedBox(height: 24),
                      _buildStatsGrid(),
                      const SizedBox(height: 24),
                      _buildContentCard(),
                      const SizedBox(height: 24),
                      _buildPoliticalCard(),
                      const SizedBox(height: 24),
                      _buildAudienceCard(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 24),
            const Text(
              'Erreur de chargement',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadStats,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Réessayer',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final periods = {
      '7d': '7j',
      '30d': '30j',
      '3m': '3m',
      '1y': '1an',
    };
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: periods.entries.map((entry) {
          final isSelected = _selectedPeriod == entry.key;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedPeriod = entry.key);
                _loadStats();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  entry.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color:
                        isSelected ? Colors.black : Colors.white.withOpacity(0.6),
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatsGrid() {
    final views = (_stats?['views'] as num?)?.toInt() ?? 0;
    final likes = (_stats?['likes'] as num?)?.toInt() ?? 0;
    final comments = (_stats?['comments'] as num?)?.toInt() ?? 0;
    final followers = (_stats?['followers'] as num?)?.toInt() ?? 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard('Vues', views, Icons.visibility)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('J\'aime', likes, Icons.favorite)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _buildStatCard('Commentaires', comments, Icons.comment)),
            const SizedBox(width: 12),
            Expanded(
                child: _buildStatCard('Abonnés', followers, Icons.people)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, int value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: Colors.white.withOpacity(0.6), size: 20),
              Text(
                _formatNumber(value),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentCard() {
    final publications = (_stats?['postes'] as num?)?.toInt() ?? 0;
    final shorts = (_stats?['shorts'] as num?)?.toInt() ?? 0;
    final questions = (_stats?['questions'] as num?)?.toInt() ?? 0;
    final total = publications + shorts + questions;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Contenus créés',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$total total',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildContentRow(
              'Publications', publications, Icons.article, Colors.blue),
          const SizedBox(height: 12),
          _buildContentRow(
              'Shorts', shorts, Icons.play_circle_filled, Colors.red),
          const SizedBox(height: 12),
          _buildContentRow(
              'Questions', questions, Icons.help_outline, Colors.purple),
        ],
      ),
    );
  }

  Widget _buildContentRow(String label, int value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoliticalCard() {
    final politicalData =
        _stats?['politicalOrientation'] as Map<String, dynamic>?;
    final avgOrientation =
        politicalData?['averageOrientation'] as String? ?? 'neutral';
    final postsByOrientation =
        politicalData?['postsByOrientation'] as Map<String, dynamic>? ?? {};
    final totalPosts =
        (politicalData?['totalAnalyzedPosts'] as num?)?.toInt() ?? 0;

    if (totalPosts == 0) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.bar_chart,
                  color: Colors.white.withOpacity(0.3), size: 48),
              const SizedBox(height: 16),
              Text(
                'Aucune donnée politique',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final ec = (postsByOrientation['extremely_conservative'] as num?)?.toInt() ?? 0;
    final c = (postsByOrientation['conservative'] as num?)?.toInt() ?? 0;
    final n = (postsByOrientation['neutral'] as num?)?.toInt() ?? 0;
    final p = (postsByOrientation['progressive'] as num?)?.toInt() ?? 0;
    final ep = (postsByOrientation['extremely_progressive'] as num?)?.toInt() ?? 0;

    final orientationLabel = _getOrientationLabel(avgOrientation);
    final orientationColor = _getOrientationColor(avgOrientation);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Courant politique',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  orientationColor.withOpacity(0.3),
                  orientationColor.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: orientationColor.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getOrientationIcon(avgOrientation),
                  color: orientationColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  orientationLabel,
                  style: TextStyle(
                    color: orientationColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Répartition ($totalPosts publication${totalPosts > 1 ? 's' : ''})',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Row(
                children: [
                  if (ec > 0)
                    Expanded(
                      flex: ec,
                      child: Container(color: const Color(0xFF0D47A1)),
                    ),
                  if (c > 0)
                    Expanded(
                      flex: c,
                      child: Container(color: const Color(0xFF1976D2)),
                    ),
                  if (n > 0)
                    Expanded(
                      flex: n,
                      child: Container(color: const Color(0xFF9E9E9E)),
                    ),
                  if (p > 0)
                    Expanded(
                      flex: p,
                      child: Container(color: const Color(0xFFEF5350)),
                    ),
                  if (ep > 0)
                    Expanded(
                      flex: ep,
                      child: Container(color: const Color(0xFFD32F2F)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (ec > 0)
                _buildLegend(
                    'T.Conservateur', ec, const Color(0xFF0D47A1)),
              if (c > 0) _buildLegend('Conservateur', c, const Color(0xFF1976D2)),
              if (n > 0) _buildLegend('Neutre', n, const Color(0xFF9E9E9E)),
              if (p > 0) _buildLegend('Progressiste', p, const Color(0xFFEF5350)),
              if (ep > 0)
                _buildLegend('T.Progressiste', ep, const Color(0xFFD32F2F)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$count $label',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudienceCard() {
    final followers = (_stats?['followers'] as num?)?.toInt() ?? 0;
    final following = (_stats?['following'] as num?)?.toInt() ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Audience',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildAudienceItem('Abonnés', followers, Icons.group),
              ),
              Container(
                width: 1,
                height: 60,
                color: Colors.white.withOpacity(0.2),
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              Expanded(
                child: _buildAudienceItem(
                    'Abonnements', following, Icons.person_add),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAudienceItem(String label, int value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.6), size: 28),
        const SizedBox(height: 12),
        Text(
          _formatNumber(value),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _getOrientationLabel(String orientation) {
    switch (orientation) {
      case 'extremely_conservative':
        return 'Très conservateur';
      case 'conservative':
        return 'Conservateur';
      case 'neutral':
        return 'Neutre';
      case 'progressive':
        return 'Progressiste';
      case 'extremely_progressive':
        return 'Très progressiste';
      default:
        return 'Neutre';
    }
  }

  Color _getOrientationColor(String orientation) {
    switch (orientation) {
      case 'extremely_conservative':
        return const Color(0xFF0D47A1);
      case 'conservative':
        return const Color(0xFF1976D2);
      case 'neutral':
        return const Color(0xFF9E9E9E);
      case 'progressive':
        return const Color(0xFFEF5350);
      case 'extremely_progressive':
        return const Color(0xFFD32F2F);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  IconData _getOrientationIcon(String orientation) {
    switch (orientation) {
      case 'extremely_conservative':
        return Icons.keyboard_double_arrow_left;
      case 'conservative':
        return Icons.chevron_left;
      case 'neutral':
        return Icons.remove;
      case 'progressive':
        return Icons.chevron_right;
      case 'extremely_progressive':
        return Icons.keyboard_double_arrow_right;
      default:
        return Icons.remove;
    }
  }
}
