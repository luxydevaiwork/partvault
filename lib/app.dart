import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'core/services/lock_service.dart';
import 'core/theme/app_theme.dart';
import 'features/lock/lock_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'providers/theme_provider.dart';

class PartVaultApp extends ConsumerWidget {
  const PartVaultApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider);

    final brightness = themeMode == ThemeMode.dark
        ? Brightness.dark
        : themeMode == ThemeMode.light
            ? Brightness.light
            : WidgetsBinding.instance.platformDispatcher.platformBrightness;
    SystemChrome.setSystemUIOverlayStyle(
      brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
              .copyWith(statusBarColor: Colors.transparent)
          : SystemUiOverlayStyle.dark
              .copyWith(statusBarColor: Colors.transparent),
    );

    return MaterialApp(
      title: 'PartVault',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: _AppEntry(router: router),
    );
  }
}

/// Entry widget: shows onboarding → lock → main app.
class _AppEntry extends ConsumerStatefulWidget {
  final GoRouter router;
  const _AppEntry({required this.router});

  @override
  ConsumerState<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends ConsumerState<_AppEntry>
    with WidgetsBindingObserver {
  bool? _onboardingDone;
  bool _isLocked = false;
  bool _initDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      LockService.isEnabled().then((enabled) {
        if (enabled && mounted) setState(() => _isLocked = true);
      });
    }
  }

  Future<void> _init() async {
    final done = await isOnboardingDone();
    final lockEnabled = await LockService.isEnabled();
    if (mounted) {
      setState(() {
        _onboardingDone = done;
        _isLocked = lockEnabled;
        _initDone = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initDone) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_onboardingDone == false) {
      return OnboardingScreen(
        onDone: () => setState(() => _onboardingDone = true),
      );
    }

    if (_isLocked) {
      return LockScreen(
        onUnlocked: () => setState(() => _isLocked = false),
      );
    }

    return Router(
      routerDelegate: widget.router.routerDelegate,
      routeInformationParser: widget.router.routeInformationParser,
      routeInformationProvider: widget.router.routeInformationProvider,
      backButtonDispatcher: widget.router.backButtonDispatcher,
    );
  }
}
