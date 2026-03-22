import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/add_item/add_item_sheet.dart';
import '../../features/categories/categories_screen.dart';
import '../../features/categories/category_detail_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/item_detail/edit_item_screen.dart';
import '../../features/item_detail/item_detail_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/statistics/statistics_screen.dart';
import '../../providers/items_provider.dart';
import '../services/nfc_handler.dart';
import '../services/notification_service.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HomeScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/categories',
              builder: (context, state) => const CategoriesScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (context, state) => CategoryDetailScreen(
                    categoryId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/statistics',
              builder: (context, state) => const StatisticsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ]),
        ],
      ),
      GoRoute(
        path: '/item/:id',
        builder: (context, state) =>
            ItemDetailScreen(itemId: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (context, state) =>
                EditItemScreen(itemId: state.pathParameters['id']!),
          ),
        ],
      ),
    ],
  );
});

class MainShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell shell;
  const MainShell({super.key, required this.shell});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkPendingNfcPayload(context, ref);
      _checkExpiryNotifications();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      checkPendingNfcPayload(context, ref);
    }
  }

  Future<void> _checkExpiryNotifications() async {
    final items = await ref.read(itemsProvider.future);
    await NotificationService.checkExpiryNotifications(items);
  }

  void _onTab(int index) {
    widget.shell.goBranch(index,
        initialLocation: index == widget.shell.currentIndex);
  }

  static const _destinations = [
    (icon: Icons.search_outlined, selected: Icons.search, label: 'Cerca'),
    (icon: Icons.grid_view_outlined, selected: Icons.grid_view, label: 'Categorie'),
    (icon: Icons.bar_chart_outlined, selected: Icons.bar_chart, label: 'Statistiche'),
    (icon: Icons.settings_outlined, selected: Icons.settings, label: 'Impostazioni'),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 600;
    final cs = Theme.of(context).colorScheme;

    final fab = FloatingActionButton(
      heroTag: 'main_fab',
      onPressed: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => const AddItemSheet(),
      ),
      child: const Icon(Icons.add),
    );

    if (isWide) {
      // Tablet: NavigationRail on the left
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: widget.shell.currentIndex,
              onDestinationSelected: _onTab,
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FloatingActionButton.small(
                  heroTag: 'rail_fab',
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => const AddItemSheet(),
                  ),
                  child: const Icon(Icons.add),
                ),
              ),
              destinations: [
                for (final d in _destinations)
                  NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selected),
                    label: Text(d.label),
                  ),
              ],
            ),
            VerticalDivider(
                width: 1, thickness: 1, color: cs.outlineVariant.withAlpha(80)),
            Expanded(child: widget.shell),
          ],
        ),
      );
    }

    // Phone: bottom NavigationBar
    return Scaffold(
      body: widget.shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.shell.currentIndex,
        onDestinationSelected: _onTab,
        destinations: [
          for (final d in _destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selected),
              label: d.label,
            ),
        ],
      ),
      floatingActionButton: fab,
    );
  }
}
