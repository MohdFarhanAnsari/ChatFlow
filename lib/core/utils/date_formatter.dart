import 'package:intl/intl.dart';

/// Formats timestamps for conversation cards and message bubbles.
class DateFormatter {
  DateFormatter._();

  static final DateFormat _timeFormat = DateFormat('h:mm a');
  static final DateFormat _dayFormat = DateFormat('E');
  static final DateFormat _dateFormat = DateFormat('MMM d');
  static final DateFormat _fullDateFormat = DateFormat('MMM d, yyyy');

  /// Formats message timestamp for inside message bubbles (e.g. "10:45 AM")
  static String formatMessageTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    return _timeFormat.format(dateTime.toLocal());
  }

  /// Formats conversation last message timestamp (e.g. "Just now", "10:45 AM", "Yesterday", "Tue", "Oct 12")
  static String formatConversationTimestamp(DateTime? dateTime) {
    if (dateTime == null) return '';
    final local = dateTime.toLocal();
    final now = DateTime.now();
    final difference = now.difference(local);

    if (difference.inMinutes < 1) {
      return 'Just now';
    }

    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(local.year, local.month, local.day);
    final daysDifference = today.difference(messageDate).inDays;

    if (daysDifference == 0) {
      return _timeFormat.format(local);
    } else if (daysDifference == 1) {
      return 'Yesterday';
    } else if (daysDifference < 7) {
      return _dayFormat.format(local);
    } else if (now.year == local.year) {
      return _dateFormat.format(local);
    } else {
      return _fullDateFormat.format(local);
    }
  }

  /// Formats presence last seen string (e.g. "Active 5m ago", "Yesterday at 4:30 PM")
  static String formatLastSeen(DateTime? lastSeen, bool isOnline) {
    if (isOnline) return 'Active now';
    if (lastSeen == null) return 'Offline';
    final local = lastSeen.toLocal();
    final now = DateTime.now();
    final difference = now.difference(local);

    if (difference.inMinutes < 1) {
      return 'Active just now';
    } else if (difference.inMinutes < 60) {
      return 'Active ${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return 'Active ${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Active yesterday at ${_timeFormat.format(local)}';
    } else {
      return 'Active ${_dateFormat.format(local)}';
    }
  }
}
