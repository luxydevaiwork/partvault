import 'package:home_widget/home_widget.dart';
import '../../data/models/item.dart';

/// Updates the Android home screen widget with the latest item data.
abstract final class WidgetService {
  static const _appGroupId = 'com.urban.partvault';
  static const _androidWidgetName = 'PartVaultWidgetProvider';

  static Future<void> initialize() async {
    await HomeWidget.setAppGroupId(_appGroupId);
  }

  static Future<void> updateWidget({
    required List<Item> items,
  }) async {
    final recentItem = items.isNotEmpty ? items.first : null;
    await HomeWidget.saveWidgetData<String>(
      'widget_recent_item',
      recentItem?.name ?? 'Nessun oggetto',
    );
    await HomeWidget.saveWidgetData<String>(
      'widget_recent_code',
      recentItem?.modelCode ?? '',
    );
    await HomeWidget.saveWidgetData<int>(
      'widget_item_count',
      items.length,
    );
    await HomeWidget.updateWidget(
      androidName: _androidWidgetName,
    );
  }
}
