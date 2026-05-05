import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kuri_app/providers/group_provider.dart';
import 'package:kuri_app/screens/groupadmin/home_screen.dart';
import 'package:kuri_app/screens/groupadmin/groups/totalgroup.dart';

// Import other main screens as needed for the bottom navigation

class GroupAdminMainScreen extends ConsumerWidget {
  const GroupAdminMainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fallback check: if the user is here but has 0 groups, force them back to setup.
    // We listen to the group list provider to detect this state.
    final currentIndex = ref.watch(groupScreenIndexProvider);

    // Default to HomeScreen when index is -1
    final effectiveIndex = currentIndex == -1 ? 0 : currentIndex;

    final List<Widget> screens = [
      const HomeScreen(),
      const TotalGroupScreen(),
      // Add more screens here if you want them in the IndexedStack
    ];

    return PopScope(
      canPop: effectiveIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        ref.read(groupScreenIndexProvider.notifier).goTo(0);
      },
      child: Scaffold(
        body: IndexedStack(index: effectiveIndex, children: screens),
      ),
    );
  }
}
