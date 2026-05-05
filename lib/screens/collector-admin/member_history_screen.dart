import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kuri_app/providers/group_provider.dart';
import 'package:kuri_app/utilities/colors.dart';
import 'package:kuri_app/widgets/custom_error_widget.dart';
import 'package:kuri_app/screens/collector-admin/widgets/history_components.dart';

class MemberHistoryScreen extends ConsumerWidget {
  final int? memberId;
  final String? memberName;
  final String? memberPhone;

  const MemberHistoryScreen({
    super.key,
    this.memberId,
    this.memberName,
    this.memberPhone,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int selectedMemberId =
        memberId ?? ref.watch(paymentHistoryMemberIdProvider);

    final historyAsync = ref.watch(memberHistoryProvider(selectedMemberId));

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        ref.read(paymentHistoryMemberIdProvider.notifier).setId(0);
        ref.read(collectorScreenIndexProvider.notifier).goTo(1);
      },
      child: Scaffold(
        backgroundColor: bgGrey,
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
            onPressed: () {
              ref.read(paymentHistoryMemberIdProvider.notifier).setId(0);
              ref.read(collectorScreenIndexProvider.notifier).goTo(1);
              Navigator.of(context).pop();
            },
          ),
          title: Text(
            'Member History',
            style: GoogleFonts.poppins(
              color: blackColor,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh_rounded, color: blackColor),
              onPressed: () =>
                  ref.invalidate(memberHistoryProvider(selectedMemberId)),
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: Column(
          children: [
            // Show Member Info Header immediately if we have the data
            if (memberName != null || memberPhone != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: MemberHistoryInfoCard(
                  name: memberName ?? '',
                  phone: memberPhone ?? '',
                  id: selectedMemberId,
                ),
              ),
            Expanded(
              child: historyAsync.when(
                data: (data) {
                  return RefreshIndicator(
                    onRefresh: () => ref.refresh(
                      memberHistoryProvider(selectedMemberId).future,
                    ),
                    color: primaryColor,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      child: MemberHistoryDetailCard(
                        history: data,
                        showHeader: false,
                      ),
                    ),
                  );
                },
                loading: () => Center(
                  child: CircularProgressIndicator(color: primaryColor),
                ),
                error: (error, stack) => CustomErrorWidget(
                  error: error.toString().replaceAll('Exception: ', ''),
                  onRetry: () =>
                      ref.invalidate(memberHistoryProvider(selectedMemberId)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
