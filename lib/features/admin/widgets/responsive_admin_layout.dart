import 'package:flutter/material.dart';

class ResponsiveAdminLayout extends StatelessWidget {
  final Widget child;
  final String title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final EdgeInsetsGeometry? padding;
  const ResponsiveAdminLayout({
    super.key,
    required this.child,
    required this.title,
    this.actions,
    this.floatingActionButton,
    this.padding,
  });
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        elevation: 0,
        actions: actions,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth > 600;
          final isDesktop = constraints.maxWidth > 900;
          EdgeInsetsGeometry effectivePadding;
          if (isDesktop) {
            effectivePadding = EdgeInsets.symmetric(
              horizontal: (constraints.maxWidth - 1200) / 2 > 0
                  ? (constraints.maxWidth - 1200) / 2
                  : 24,
              vertical: 24,
            );
          } else if (isTablet) {
            effectivePadding = const EdgeInsets.all(24);
          } else {
            effectivePadding = padding ?? const EdgeInsets.all(16);
          }
          return Container(
            padding: effectivePadding,
            child: child,
          );
        },
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}

class ResponsiveGridView extends StatelessWidget {
  final List<Widget> children;
  final double childAspectRatio;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  const ResponsiveGridView({
    super.key,
    required this.children,
    this.childAspectRatio = 1.0,
    this.mainAxisSpacing = 8.0,
    this.crossAxisSpacing = 8.0,
    this.shrinkWrap = true,
    this.physics,
  });
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount;
        if (width > 1200) {
          crossAxisCount = 4;
        } else if (width > 900) {
          crossAxisCount = 3;
        } else if (width > 600) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 1;
        }
        return GridView.count(
          shrinkWrap: shrinkWrap,
          physics: physics,
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: mainAxisSpacing,
          crossAxisSpacing: crossAxisSpacing,
          childAspectRatio: childAspectRatio,
          children: children,
        );
      },
    );
  }
}

class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final double? elevation;
  final Color? color;
  final VoidCallback? onTap;
  const ResponsiveCard({
    super.key,
    required this.child,
    this.margin,
    this.elevation,
    this.color,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 400;
        return Card(
          margin: margin ??
              EdgeInsets.symmetric(
                horizontal: isCompact ? 8 : 16,
                vertical: isCompact ? 4 : 8,
              ),
          elevation: elevation ?? 2,
          color: color,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.all(isCompact ? 12 : 16),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;
  final bool isTitle;
  final bool isSubtitle;
  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.isTitle = false,
    this.isSubtitle = false,
  });
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 360;
        final theme = Theme.of(context);
        TextStyle effectiveStyle = style ?? const TextStyle();
        if (isTitle) {
          effectiveStyle = theme.textTheme.titleLarge!.merge(effectiveStyle);
          if (isCompact) {
            effectiveStyle = effectiveStyle.copyWith(
              fontSize: (effectiveStyle.fontSize ?? 20) * 0.85,
            );
          }
        } else if (isSubtitle) {
          effectiveStyle = theme.textTheme.bodyMedium!.merge(effectiveStyle);
          if (isCompact) {
            effectiveStyle = effectiveStyle.copyWith(
              fontSize: (effectiveStyle.fontSize ?? 14) * 0.9,
            );
          }
        }
        return Text(
          text,
          style: effectiveStyle,
          maxLines: maxLines,
          overflow: overflow,
          textAlign: textAlign,
        );
      },
    );
  }
}

class ResponsiveBottomSheet extends StatelessWidget {
  final Widget child;
  final double initialChildSize;
  final double minChildSize;
  final double maxChildSize;
  const ResponsiveBottomSheet({
    super.key,
    required this.child,
    this.initialChildSize = 0.7,
    this.minChildSize = 0.4,
    this.maxChildSize = 0.95,
  });
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    double initialChildSize = 0.7,
    double minChildSize = 0.4,
    double maxChildSize = 0.95,
  }) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width > 600;
    if (isTablet) {
      return showDialog<T>(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 600,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: child,
            ),
          ),
        ),
      );
    } else {
      return showModalBottomSheet<T>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: initialChildSize,
          minChildSize: minChildSize,
          maxChildSize: maxChildSize,
          expand: false,
          builder: (context, scrollController) => SingleChildScrollView(
            controller: scrollController,
            child: child,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
