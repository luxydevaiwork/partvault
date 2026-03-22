import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/services/database_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/widget_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DatabaseService.initialize();
  await NotificationService.initialize();
  await NotificationService.requestPermissions();
  await WidgetService.initialize();

  // Allow all orientations; on phones portrait is natural, tablets use landscape too.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(
    const ProviderScope(
      child: PartVaultApp(),
    ),
  );
}
