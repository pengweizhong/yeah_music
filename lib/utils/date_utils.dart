import 'package:intl/intl.dart';

class LocalDateUtils {
  static String formatDateTime(DateTime? dateTime, String pattern) {
    if (dateTime == null) {
      return "";
    }
    return DateFormat(pattern).format(dateTime);
  }
}
