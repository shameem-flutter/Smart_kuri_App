import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kuri_app/providers/group_provider.dart';
import 'package:kuri_app/utilities/colors.dart';
import 'package:kuri_app/widgets/custom_error_widget.dart';
import 'package:kuri_app/screens/collector-admin/widgets/history_components.dart';

class AllCollectionsScreen extends ConsumerWidget {
  const AllCollectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    final collectionsAsync = ref.watch(collectorCollectionsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        backgroundColor: transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: blackColor,
            size: 20,
          ),
          onPressed: () =>
              ref.read(collectorScreenIndexProvider.notifier).goTo(0),
        ),
        title: Text(
          'All Collections',
          style: GoogleFonts.poppins(
            color: blackColor,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body: collectionsAsync.when(
        data: (data) {
          if (data.groups.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No collections found.',
                    style: GoogleFonts.inter(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(collectorCollectionsProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: data.groups.length,
              itemBuilder: (context, index) {
                return GroupHistoryCard(group: data.groups[index]);
              },
            ),
          );
        },
        loading: () =>
            Center(child: CircularProgressIndicator(color: primaryColor)),
        error: (error, stack) => CustomErrorWidget(
          error: error.toString().replaceAll('Exception: ', ''),
          onRetry: () => ref.invalidate(collectorCollectionsProvider),
        ),
      ),
    );
  }
}
