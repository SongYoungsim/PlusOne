import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import 'add_proposal_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(currentTabProvider);
    const pages = [
      AddProposalScreen(),
      HomeScreen(),
      StatsScreen(),
      SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentTab,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentTab,
        onDestinationSelected: (index) {
          ref.read(currentTabProvider.notifier).state = index;
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.edit_outlined),
            selectedIcon: Icon(Icons.edit),
            label: '제안입력',
          ),
          NavigationDestination(
            icon: Icon(Icons.view_list_outlined),
            selectedIcon: Icon(Icons.view_list),
            label: '내역',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart),
            label: '통계',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '설정',
          ),
        ],
      ),
    );
  }
}
