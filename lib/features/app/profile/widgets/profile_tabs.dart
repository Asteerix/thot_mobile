// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';

// class ProfileTabs extends StatelessWidget implements PreferredSizeWidget {
//   final TabController tabController;
//   final bool isJournalist;
//   const ProfileTabs({
//     super.key,
//     required this.tabController,
//     this.isJournalist = false,
//   });
//   @override
//   Size get preferredSize => const Size.fromHeight(52);
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final cs = theme.colorScheme;
//     final showText = MediaQuery.of(context).size.width >= 360;
//     return Material(
//       color: theme.colorScheme.surface,
//       elevation: 0,
//       child: SafeArea(
//         bottom: false,
//         child: TabBar(
//           controller: tabController,
//           isScrollable: true,
//           dividerColor: cs.outlineVariant,
//           indicatorSize: TabBarIndicatorSize.tab,
//           indicatorPadding:
//               const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
//           indicator: ShapeDecoration(
//             color: cs.secondaryContainer,
//             shape: const StadiumBorder(),
//           ),
//           labelColor: cs.onSecondaryContainer,
//           unselectedLabelColor: cs.onSurfaceVariant,
//           labelStyle: const TextStyle(
//               fontWeight: FontWeight.w600, fontSize: 13, letterSpacing: 0.2),
//           unselectedLabelStyle: const TextStyle(
//               fontWeight: FontWeight.w500, fontSize: 13, letterSpacing: 0.2),
//           overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
//             if (states.contains(WidgetState.pressed)) {
//               return cs.primary.withOpacity(0.10);
//             }
//             if (states.contains(WidgetState.hovered) ||
//                 states.contains(WidgetState.focused)) {
//               return cs.primary.withOpacity(0.06);
//             }
//             return cs.primary.withOpacity(0.02);
//           }),
//           labelPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
//           onTap: (_) => HapticFeedback.selectionClick(),
//           tabs: [
//             _tab(
//                 icon: Icons.dashboard,
//                 text: showText ? 'Publications' : null,
//                 tooltip: 'Publications'),
//             if (isJournalist) ...[
//               _tab(
//                   icon: Icons.play_circle_filled,
//                   text: showText ? 'Shorts' : null,
//                   tooltip: 'Courts formats'),
//               _tab(
//                   icon: Icons.help_outline,
//                   text: showText ? 'Questions' : null,
//                   tooltip: 'Questions'),
//             ] else
//               _tab(
//                   icon: Icons.bookmark,
//                   text: showText ? 'Enregistrés' : null,
//                   tooltip: 'Enregistrés'),
//           ],
//         ),
//       ),
//     );
//   }

//   Tab _tab({required IconData icon, String? text, required String tooltip}) {
//     return Tab(
//       icon: Tooltip(message: tooltip, child: Icon(icon, size: 22)),
//       text: text,
//     );
//   }
// }
