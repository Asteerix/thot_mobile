import 'package:thot/core/themes/app_colors.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../shared/widgets/stat_card.dart';
import '../../shared/widgets/section_card.dart';
import '../../shared/widgets/timeframe_selector.dart';
import '../../shared/widgets/bar_chart.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/metric_row.dart';
import '../../shared/utils/number_formatter.dart';
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}
class _AnalyticsScreenState extends State<AnalyticsScreen> {
  Timeframe _tf = Timeframe.d30;
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  late List<_Stat> _stats;
  late List<_BarPoint> _bars;
  late List<_Publication> _allPubs;
  @override
  void initState() {
    super.initState();
    _seedData();
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim());
    });
  }
  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
  Future<void> _refresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    setState(() => _seedData());
  }
  void _seedData() {
    final rnd = math.Random(42 + _tf.index);
    List<double> series(int n) =>
        List<double>.generate(n, (_) => 50 + rnd.nextInt(100).toDouble());
    _stats = <_Stat>[
      _Stat(
        icon: Icons.visibility,
        label: 'Vues totales',
        value: 7500 + _tf.index * 1800,
        deltaPct: 12.4 - (_tf.index * 2.1),
        series: series(16),
      ),
      _Stat(
        icon: Icons.article,
        label: 'Publications',
        value: 15 + _tf.index * 3,
        deltaPct: -4.2 + (_tf.index * 1.5),
        series: series(16),
      ),
      _Stat(
        icon: Icons.thumb_up,
        label: 'J\'aime',
        value: 1320 + _tf.index * 240,
        deltaPct: 6.8 + (_tf.index * 0.9),
        series: series(16),
      ),
      _Stat(
        icon: Icons.group,
        label: 'Nouveaux abonnés',
        value: 210 + _tf.index * 60,
        deltaPct: 18.3 - (_tf.index * 3),
        series: series(16),
      ),
    ];
    const months = <String>[
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Juin',
      'Juil',
      'Août',
      'Sep',
      'Oct',
      'Nov',
      'Déc'
    ];
    _bars = List<_BarPoint>.generate(
      8,
      (i) => _BarPoint(
          label: months[(i + 4) % 12],
          value: 800 + rnd.nextInt(2200).toDouble()),
    );
    _allPubs = List<_Publication>.generate(18, (i) {
      final base = 900 + rnd.nextInt(7000);
      final likes = (base * (0.04 + rnd.nextDouble() * 0.06)).round();
      final comments = (likes * (0.12 + rnd.nextDouble() * 0.2)).round();
      return _Publication(
        id: 'pub_$i',
        title: 'Publication ${i + 1}',
        views: base,
        likes: likes,
        comments: comments,
        durationSec: 15 + rnd.nextInt(75),
        date: DateTime.now().subtract(Duration(days: rnd.nextInt(35))),
      );
    });
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: RefreshIndicator.adaptive(
        onRefresh: _refresh,
        edgeOffset: MediaQuery.of(context).padding.top + 56,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: cs.surface,
              surfaceTintColor: cs.surfaceTint,
              title: const Text('Analyse de vos publications'),
              actions: [
                IconButton(
                  tooltip: 'Exporter',
                  onPressed: () {},
                  icon: const Icon(Icons.download),
                ),
                IconButton(
                  tooltip: 'Paramètres',
                  onPressed: () {},
                  icon: const Icon(Icons.tune),
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      TimeframeSelector(
                        value: _tf,
                        onChanged: (v) => setState(() => _tf = v),
                      ),
                      const Spacer(),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 280),
                        child: TextField(
                          controller: _searchCtrl,
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'Rechercher une publication',
                            prefixIcon: Icon(Icons.search),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.crossAxisExtent;
                  final cols = w < 420 ? 2 : (w < 900 ? 3 : 4);
                  return SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      mainAxisExtent: 148,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => StatCard(
                        icon: _stats[i].icon,
                        label: _stats[i].label,
                        value: _stats[i].value,
                        deltaPct: _stats[i].deltaPct,
                        series: _stats[i].series,
                        onTap: () {},
                      ),
                      childCount: _stats.length,
                    ),
                  );
                },
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              sliver: SliverToBoxAdapter(
                child: SectionCard(
                  title: 'Performance sur la période',
                  subtitle: _tf.toDisplayString(),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: BarChart(
                      data: _bars.map((e) => e.value).toList(),
                      labels: _bars.map((e) => e.label).toList(),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  children: [
                    Text('Publications récentes',
                        style: theme.textTheme.titleMedium),
                    const Spacer(),
                    _SortButton(
                      onSelected: (sort) {
                        setState(() {
                          switch (sort) {
                            case _Sort.views:
                              _allPubs
                                  .sort((a, b) => b.views.compareTo(a.views));
                              break;
                            case _Sort.date:
                              _allPubs.sort((a, b) => b.date.compareTo(a.date));
                              break;
                            case _Sort.likes:
                              _allPubs
                                  .sort((a, b) => b.likes.compareTo(a.likes));
                              break;
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: _buildPublicationsSliver(context),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildPublicationsSliver(BuildContext context) {
    final filtered = _query.isEmpty
        ? _allPubs
        : _allPubs
            .where((p) => p.title.toLowerCase().contains(_query.toLowerCase()))
            .toList();
    if (filtered.isEmpty) {
      return SliverToBoxAdapter(
        child: EmptyState(
          title: 'Aucun résultat',
          message: 'Aucune publication ne correspond à "$_query".',
        ),
      );
    }
    return SliverList.separated(
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _PublicationTile(pub: filtered[i]),
    );
  }
}
enum _Sort { views, date, likes }
class _SortButton extends StatelessWidget {
  final ValueChanged<_Sort> onSelected;
  const _SortButton({required this.onSelected});
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_Sort>(
      tooltip: 'Trier',
      onSelected: onSelected,
      itemBuilder: (context) => const [
        PopupMenuItem(value: _Sort.date, child: Text('Plus récent')),
        PopupMenuItem(value: _Sort.views, child: Text('Vues')),
        PopupMenuItem(value: _Sort.likes, child: Text('J\'aime')),
      ],
      child: const Row(
        children: [
          Icon(Icons.compare_arrows),
          SizedBox(width: 6),
          Text('Trier'),
        ],
      ),
    );
  }
}
class _PublicationTile extends StatelessWidget {
  final _Publication pub;
  const _PublicationTile({required this.pub});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Material(
      color: cs.surfaceContainerHighest.withOpacity(0.4),
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 72,
                  height: 72,
                  color: cs.onSurfaceVariant.withOpacity(0.1),
                  child: Icon(Icons.play_arrow, size: 36),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DefaultTextStyle.merge(
                  style: theme.textTheme.bodyMedium!,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pub.title,
                          style: theme.textTheme.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          InlineMetric(
                              icon: Icons.visibility,
                              label: pub.views.toCompactFr()),
                          InlineMetric(
                              icon: Icons.thumb_up,
                              label: pub.likes.toCompactFr()),
                          InlineMetric(
                              icon: Icons.comment,
                              label: pub.comments.toCompactFr()),
                          InlineMetric(
                              icon: Icons.schedule,
                              label: '${pub.durationSec}s'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(pub.date),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Actions',
                onSelected: (_) {},
                itemBuilder: (context) => const [
                  PopupMenuItem(
                      value: 'details', child: Text('Voir les détails')),
                  PopupMenuItem(value: 'share', child: Text('Partager')),
                ],
                icon: Icon(Icons.more_horiz),
              ),
            ],
          ),
        ),
      ),
    );
  }
  String _formatDate(DateTime d) {
    return DateFormatter.formatRelative(d);
  }
}
class _Stat {
  final IconData icon;
  final String label;
  final int value;
  final double deltaPct;
  final List<double> series;
  _Stat({
    required this.icon,
    required this.label,
    required this.value,
    required this.deltaPct,
    required this.series,
  });
}
class _BarPoint {
  final String label;
  final double value;
  _BarPoint({required this.label, required this.value});
}
class _Publication {
  final String id;
  final String title;
  final int views;
  final int likes;
  final int comments;
  final int durationSec;
  final DateTime date;
  _Publication({
    required this.id,
    required this.title,
    required this.views,
    required this.likes,
    required this.comments,
    required this.durationSec,
    required this.date,
  });
}