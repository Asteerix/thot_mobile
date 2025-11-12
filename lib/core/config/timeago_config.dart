import 'package:timeago/timeago.dart' as timeago;
class TimeagoConfig {
  TimeagoConfig._();
  static const String defaultLocale = 'fr';
  static void init() {
    timeago.setLocaleMessages(defaultLocale, timeago.FrMessages());
  }
}
void initTimeagoLocales() => TimeagoConfig.init();