import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/groupadmin/cashcollector/cashcollector_list.dart';
import '../../../providers/group_provider.dart';
import '../../../widgets/custom_error_widget.dart';

class CashCollectorListScreen extends ConsumerStatefulWidget {
  const CashCollectorListScreen({super.key});

  @override
  ConsumerState<CashCollectorListScreen> createState() =>
      _CashCollectorListScreenState();
}

class _CashCollectorListScreenState extends ConsumerState<CashCollectorListScreen> {
  List<CashCollectorListItem> _collectors = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCollectors();
  }

  Future<void> _loadCollectors() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final response = await ref.read(apiServiceProvider).getCollectors();
      if (mounted) {
        setState(() {
          _collectors = response.results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteCollector(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.error.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.delete_outline_rounded,
            color: Theme.of(context).colorScheme.error,
            size: 32,
          ),
        ),
        title: const Text(
          'Delete Collector?',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        content: const Text(
          'Are you sure you want to remove this collector? This action cannot be undone.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
        actionsPadding: const EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: 20,
          top: 8,
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Delete',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(apiServiceProvider).deleteCollector(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Collector deleted successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadCollectors();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showEditDialog(CashCollectorListItem collector) async {
    final usernameController = TextEditingController(text: collector.username);
    final emailController = TextEditingController(text: collector.email);
    final phoneController = TextEditingController(text: collector.phone);
    final formKey = GlobalKey<FormState>();
    bool isUpdating = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (sbContext, setSbState) {
            return AlertDialog(
              icon: const Icon(Icons.person_search_outlined, size: 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text('Edit Collector'),
              content: SizedBox(
                width: MediaQuery.of(dialogContext).size.width * 0.8,

                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        buildPremiumField(
                          controller: usernameController,
                          label: "Username",
                          icon: Icons.person_rounded,
                          isEnabled: !isUpdating,
                          validator: (v) =>
                              v?.trim().isEmpty ?? true ? 'Required' : null,
                          context: context,
                        ),
                        const SizedBox(height: 16),
                        buildPremiumField(
                          controller: emailController,
                          label: "Email",
                          icon: Icons.alternate_email_outlined,
                          isEnabled: !isUpdating,
                          validator: (v) =>
                              v?.trim().isEmpty ?? true ? 'Required' : null,
                          context: context,
                        ),
                        const SizedBox(height: 16),
                        buildPremiumField(
                          controller: phoneController,
                          label: "Phone",
                          icon: Icons.phone_rounded,
                          isEnabled: !isUpdating,
                          validator: (v) =>
                              v?.trim().isEmpty ?? true ? 'Required' : null,
                          context: context,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                if (isUpdating)
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 8.0,
                    ),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  )
                else ...[
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () async {
                      if (formKey.currentState?.validate() != true) return;

                      setSbState(() => isUpdating = true);

                      try {
                        final data = {
                          "username": usernameController.text.trim(),
                          "email": emailController.text.trim(),
                          "phone": phoneController.text.trim(),
                        };
                        debugPrint('Keeping it simple: Updating $data');

                        await ref.read(apiServiceProvider).updateCollector(collector.id, data);

                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Collector updated successfully'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          // Small delay to ensure server consistency
                          await Future.delayed(
                            const Duration(milliseconds: 500),
                          );
                          _loadCollectors();
                        }
                      } catch (e) {
                        if (sbContext.mounted) {
                          setSbState(() => isUpdating = false);
                        }

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Error: ${e.toString().replaceAll('Exception: ', '')}',
                              ),
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.error,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Save'),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Cash Collectors',
          style: GoogleFonts.poppins(
            color: const Color(0xFF2B3A4A),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: Color(0xFF2B3A4A),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),

        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF2962FF)),
              )
            : _error != null
            ? CustomErrorWidget(
                error: _error!,
                onRetry: _loadCollectors,
              )
            : _collectors.isEmpty
            ? Center(
                child: Text(
                  'No collectors found',
                  style: GoogleFonts.inter(color: Colors.grey),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Padding(
                  //   padding: const EdgeInsets.symmetric(horizontal: 20),
                  //   child:
                  // ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _collectors.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final collector = _collectors[index];
                        return _buildCollectorCard(collector);
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCollectorCard(CashCollectorListItem collector) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2962FF).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      collector.username.isNotEmpty
                          ? collector.username[0].toUpperCase()
                          : 'C',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF2962FF),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        collector.username,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: const Color(0xFF2B3A4A),
                        ),
                      ),
                      Text(
                        'Group: ${collector.groupName}',
                        style: GoogleFonts.inter(
                          color: Colors.grey[500],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: collector.status
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    collector.status ? 'ACTIVE' : 'INACTIVE',
                    style: GoogleFonts.inter(
                      color: collector.status
                          ? Colors.green[700]
                          : Colors.red[700],
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.email_outlined, collector.email),
            const SizedBox(height: 8),
            _buildDetailRow(Icons.phone_outlined, collector.phone),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showEditDialog(collector),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF2962FF),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _deleteCollector(collector.id),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[400]),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.inter(
            color: const Color(0xFF2B3A4A),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// 1. Drop this helper function inside your builder (or make it a separate stateless widget)
Widget buildPremiumField({
  required TextEditingController controller,
  required String label,
  required IconData icon,
  required bool isEnabled,
  required BuildContext context,
  TextInputType keyboardType = TextInputType.text,
  TextInputAction textInputAction = TextInputAction.next,
  String? Function(String?)? validator,
}) {
  final primaryColor = Theme.of(context).primaryColor;

  return TextFormField(
    controller: controller,
    enabled: isEnabled,
    keyboardType: keyboardType,
    textInputAction: textInputAction,
    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: Colors.grey.shade500,
        fontWeight: FontWeight.w500,
      ),
      floatingLabelStyle: TextStyle(
        color: primaryColor,
        fontWeight: FontWeight.w700,
      ),
      // Here is the magic: A custom, tinted container for the icon
      prefixIcon: Padding(
        padding: const EdgeInsets.only(
          left: 8.0,
          right: 12.0,
          top: 8.0,
          bottom: 8.0,
        ),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: primaryColor, size: 20),
        ),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none, // Removes the harsh default line
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: primaryColor.withValues(alpha: 0.6),
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.error,
          width: 2,
        ),
      ),
    ),
    validator: validator,
  );
}


