import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../data/models/item.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  static Future<void> requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
  }

  /// Schedules a daily check at 09:00 for maintenance reminders.
  /// Shows a notification if [item] is due for maintenance.
  static Future<void> scheduleMaintenanceReminder(Item item) async {
    if (item.maintenanceIntervalDays == null) return;
    final nextDate = item.nextMaintenanceDate;
    if (nextDate == null) return;

    const androidDetails = AndroidNotificationDetails(
      'maintenance_reminders',
      'Promemoria Manutenzione',
      channelDescription: 'Notifiche per la manutenzione periodica degli oggetti',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const details = NotificationDetails(android: androidDetails);

    // Use item id hash as notification id (must be int)
    final notifId = item.id.hashCode.abs() % 100000;

    await _plugin.show(
      notifId,
      'Manutenzione: ${item.name}',
      'Prevista per ${_formatDate(nextDate)}',
      details,
      payload: item.id,
    );
  }

  static Future<void> cancelReminder(String itemId) async {
    final notifId = itemId.hashCode.abs() % 100000;
    await _plugin.cancel(notifId);
  }

  /// Shows immediate notification when an item with expiry ≤30 days is saved.
  static Future<void> scheduleExpiryReminder(Item item) async {
    if (item.expiryDate == null) return;
    final days = item.daysUntilExpiry ?? 0;
    if (days > 30) return;

    const androidDetails = AndroidNotificationDetails(
      'expiry_reminders',
      'Promemoria Scadenza',
      channelDescription: 'Avvisi per oggetti in scadenza o scaduti',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    final notifId = ('exp_${item.id}').hashCode.abs() % 100000;
    final label = item.isExpired
        ? 'Scaduto!'
        : 'Scade tra ${days}gg (${_formatDate(item.expiryDate!)})';

    await _plugin.show(notifId, 'Scadenza: ${item.name}', label, details,
        payload: item.id);
  }

  /// Called on app startup — groups expiring items (≤7 days) into one notification.
  static Future<void> checkExpiryNotifications(List<Item> items) async {
    final expiring = items
        .where((i) => i.expiryDate != null && (i.daysUntilExpiry ?? 999) <= 7)
        .toList();
    if (expiring.isEmpty) return;

    const androidDetails = AndroidNotificationDetails(
      'expiry_reminders',
      'Promemoria Scadenza',
      channelDescription: 'Avvisi per oggetti in scadenza o scaduti',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);

    if (expiring.length == 1) {
      final item = expiring.first;
      final days = item.daysUntilExpiry ?? 0;
      await _plugin.show(
        99998,
        'Scadenza: ${item.name}',
        item.isExpired ? 'Scaduto!' : 'Scade tra ${days}gg',
        details,
        payload: item.id,
      );
    } else {
      final expired = expiring.where((i) => i.isExpired).length;
      final soon = expiring.length - expired;
      final body = [
        if (expired > 0) '$expired scaduti',
        if (soon > 0) '$soon in scadenza (≤7gg)',
      ].join(', ');
      await _plugin.show(99998, '${expiring.length} oggetti', body, details);
    }
  }

  static Future<void> showMaintenanceDueNotification(Item item) async {
    const androidDetails = AndroidNotificationDetails(
      'maintenance_due',
      'Manutenzione Scaduta',
      channelDescription: 'Avvisi per manutenzione in ritardo',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    final notifId = item.id.hashCode.abs() % 100000;

    await _plugin.show(
      notifId,
      'Manutenzione in ritardo!',
      '${item.name} richiede manutenzione',
      details,
      payload: item.id,
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
