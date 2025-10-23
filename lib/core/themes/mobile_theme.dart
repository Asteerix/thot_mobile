library;
@Deprecated(
  'MobileTheme est totalement inutilisé (0 références). '
  'Utiliser SpacingConstants pour les espacements, '
  'AppSpacing pour les valeurs sémantiques, '
  'ou WebTheme.isMobile() pour le responsive design. '
  'Considérer la suppression de ce fichier.',
)
class MobileTheme {
  static const double unit = 8.0;
  static const double xs = unit * 0.5;
  static const double sm = unit;
  static const double md = unit * 2;
  static const double lg = unit * 3;
  static const double xl = unit * 4;
  static const double xxl = unit * 6;
  static const double screenPaddingHorizontal = md;
  static const double screenPaddingVertical = md;
  static const double buttonHeight = 48.0;
  @Deprecated('Viole les guidelines Material Design (minimum 48x48)')
  static const double buttonHeightSmall = 36.0;
  static const double inputHeight = 48.0;
  static const double iconButtonSize = 48.0;
  static const double buttonPaddingHorizontal = lg;
  static const double buttonPaddingVertical = md;
  static const double cardPadding = md;
  static const double listItemPadding = md;
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double avatarSizeSmall = 32.0;
  static const double avatarSizeMedium = 48.0;
  static const double avatarSizeLarge = 64.0;
  static const double avatarSizeXLarge = 96.0;
  static const double bottomNavHeight = 60.0;
  static const double bottomNavIconSize = 24.0;
  static const double appBarHeight = 56.0;
  static const double feedItemSpacing = md;
  static const double postImageMaxHeight = 400.0;
  static const double minTouchTarget = 48.0;
}