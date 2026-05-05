import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../models/groupadmin/collection_create_model.dart';
import '../../../models/groupadmin/group_model.dart';
import '../../../models/groupadmin/member_details_model.dart';
import '../../../models/groupadmin/member_list.dart';
import '../../../providers/group_provider.dart';

// ── Palette ──────────────────────────────────────────────────────────────────
const _primary = Color(0xFF5A57FF); // Indigo/Blue from mockup
const _bg = Color(0xFFF9FAFF);
const _surface = Color(0xFFFFFFFF);
const _border = Color(0xFFE5E7EB);
const _textMain = Color(0xFF1F2937);
const _textMuted = Color(0xFF6B7280);
const _red = Color(0xFFEF4444);
const _redSoft = Color(0xFFFEF2F2);

class AddCollectionScreen extends ConsumerStatefulWidget {
  const AddCollectionScreen({super.key});

  @override
  ConsumerState<AddCollectionScreen> createState() =>
      _AddCollectionScreenState();
}

class _AddCollectionScreenState extends ConsumerState<AddCollectionScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();

  // State
  bool _isLoading = false;
  bool _isFetchingAmount = false;
  bool _isLoadingData = true;
  String? _error;

  List<Group> _groups = [];
  List<Member> _allMembers = [];
  List<Member> _filteredMembers = [];

  int? _selectedGroupId;
  int? _selectedMemberId;
  DateTime? _selectedDate;
  MemberDetailsResponse? _memberDetails; // Holds the status card data

  // Dropdown options
  final List<String> _paymentMethods = [
    'Razorpay',
    'Cash',
    'UPI',
    'Bank Transfer',
  ];
  String? _selectedPaymentMethod;

  // final List<String> _paymentStatuses = ['Success', 'Failed', 'Pending'];
  String? _selectedPaymentStatus;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final groupsResponse = await apiService.getGroups();
      final membersResponse = await apiService.getMembers();

      if (mounted) {
        setState(() {
          _groups = groupsResponse.groups;
          _allMembers = membersResponse.results;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load data. Please try again.';
          _isLoadingData = false;
        });
      }
    }
  }

  void _onGroupChanged(int? groupId) {
    if (groupId == null) return;

    setState(() {
      _selectedGroupId = groupId;
      _selectedMemberId = null;
      _memberDetails = null;
      _amountController.clear();
      // Filter members belonging to the selected group
      _filteredMembers = _allMembers
          .where((m) => m.groupId == groupId)
          .toList();
    });
  }

  Future<void> _onMemberChanged(int? memberId) async {
    if (memberId == null) return;

    setState(() {
      _selectedMemberId = memberId;
      _memberDetails = null;
      _amountController.clear();
      _isFetchingAmount = true;
    });

    final apiService = ref.read(apiServiceProvider);
    try {
      final details = await apiService.getMemberAdminDetails(memberId);
      if (mounted && _selectedMemberId == memberId) {
        setState(() {
          _memberDetails = details;
          // Pre-fill with the total amount needed to be current (includes arrears + partial remainders)
          final suggestedAmount = details.totalDue > 0
              ? details.totalDue
              : details.monthlyAmount;
          _amountController.text = suggestedAmount.toStringAsFixed(0);
          _isFetchingAmount = false;
        });
      }
    } catch (_) {
      // Fallback: use the selected group's monthly amount and show the card
      if (mounted && _selectedMemberId == memberId) {
        final selectedGroup = _groups.firstWhere(
          (g) => g.id == _selectedGroupId,
          orElse: () => _groups.first,
        );
        final fallbackAmount = selectedGroup.monthlyAmount;
        setState(() {
          if (fallbackAmount > 0) {
            _amountController.text = fallbackAmount.toStringAsFixed(0);
          }
          // Build a minimal summary so the status card is always visible
          _memberDetails = MemberDetailsResponse(
            member: MemberDetailInfo(
              id: memberId,
              name: '',
              phone: '',
              email: '',
              address: '',
              aadhaarNo: '',
              status: '',
              tokenNo: 0,
              group: '',
            ),
            totalCollected: 0.0,
            totalDue: fallbackAmount,
            monthsPaid: 0,
            durationMonths: 0,
            monthlyAmount: fallbackAmount,
            monthWise: const [],
            recentTransactions: const [],
          );
          _isFetchingAmount = false;
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2962FF),
              onPrimary: Colors.white,
              onSurface: Color(0xFF2B3A4A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _submitCollection() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGroupId == null) {
      _showSnackBar('Please select a group');
      return;
    }
    if (_selectedMemberId == null) {
      _showSnackBar('Please select a member');
      return;
    }
    if (_selectedPaymentMethod == null) {
      _showSnackBar('Please select a payment method');
      return;
    }

    // ── Check if member is already finished ──────────────────────────
    if (_memberDetails != null &&
        _memberDetails!.monthsPaid >= _memberDetails!.durationMonths &&
        _memberDetails!.totalDue <= 0) {
      _showCompletionDialog();
      return;
    }
    // if (_selectedPaymentStatus == null) {
    //   _showSnackBar('Please select a payment status');
    //   return;
    // }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final request = CollectionCreateRequest(
        group: _selectedGroupId!,
        member: _selectedMemberId!,
        amount: double.parse(_amountController.text.trim()),
        paidDate: _dateController.text.trim(),
        paymentMethod: _selectedPaymentMethod!.toLowerCase(),
        // paymentStatus: _selectedPaymentStatus!.toLowerCase(),
      );

      await ref.read(apiServiceProvider).createCollection(request);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            icon: const Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 60,
            ),
            title: const Text(
              'Success!',
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            content: const Text(
              'Collection added successfully.',
              textAlign: TextAlign.center,
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context)
                    ..pop() // Close dialog
                    ..pop(); // Go back
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
        });
        _showSnackBar(_error ?? 'An error occurred');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: _primary),
            const SizedBox(width: 10),
            const Text('Fully Paid'),
          ],
        ),
        content: const Text(
          'This member has already completed all scheduled installments for this group.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(
          'Add Collection',
          style: GoogleFonts.poppins(
            color: _textMain,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: _textMain,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: _isLoadingData
            ? const Center(child: CircularProgressIndicator(color: _primary))
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 8,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── 01. CHOOSE CHITTI GROUP ────────────────────────────
                      _SectionHeader(
                        number: '01',
                        title: 'CHOOSE CHITTI GROUP',
                        icon: Icons.layers_outlined,
                        color: _primary,
                      ),
                      const SizedBox(height: 12),
                      _buildDropdown<int>(
                        value: _selectedGroupId,
                        items: _groups.map((g) {
                          return DropdownMenuItem(
                            value: g.id,
                            child: Text(g.name),
                          );
                        }).toList(),
                        hint: 'Select Group',
                        icon: Icons.account_balance_outlined,
                        onChanged: _onGroupChanged,
                      ),
                      const SizedBox(height: 28),

                      // ── 02. SELECT MEMBER ──────────────────────────────────
                      _SectionHeader(
                        number: '02',
                        title: 'SELECT MEMBER',
                        icon: Icons.person_outline_rounded,
                        color: _primary,
                      ),
                      const SizedBox(height: 12),
                      _buildDropdown<int>(
                        value: _selectedMemberId,
                        items: _filteredMembers.map((m) {
                          return DropdownMenuItem(
                            value: m.id,
                            child: Text(m.name),
                          );
                        }).toList(),
                        hint: 'Select Member',
                        icon: Icons.person_search_outlined,
                        onChanged: _selectedGroupId == null
                            ? null
                            : (val) => _onMemberChanged(val),
                      ),

                      // ── Member Status Card (Dynamic) ──────────────────────
                      if (_memberDetails != null) ...[
                        const SizedBox(height: 24),
                        _MemberStatusCard(details: _memberDetails!),
                      ],
                      const SizedBox(height: 32),

                      // ── 03. AMOUNT (INR) ──────────────────────────────────
                      _SectionHeader(
                        number: '03',
                        title: 'AMOUNT (INR)',
                        icon: Icons.payments_outlined,
                        color: _primary,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _amountController,
                        label: _isFetchingAmount ? 'Fetching...' : 'Amount',
                        icon: _isFetchingAmount
                            ? Icons.hourglass_top_rounded
                            : Icons.currency_rupee_rounded,
                        keyboardType: TextInputType.number,
                        readOnly: false, // User might want to adjust
                        validator: (v) {
                          if (v?.isEmpty == true) return 'Amount is required';
                          if (double.tryParse(v!) == null) {
                            return 'Invalid amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),

                      // ── 04. PAYMENT DATE ──────────────────────────────────
                      _SectionHeader(
                        number: '04',
                        title: 'PAYMENT DATE',
                        icon: Icons.calendar_today_outlined,
                        color: _primary,
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => _selectDate(context),
                        child: AbsorbPointer(
                          child: _buildTextField(
                            controller: _dateController,
                            label: 'Paid Date',
                            icon: Icons.calendar_month_outlined,
                            suffixIcon: const Icon(
                              Icons.calendar_today_rounded,
                              size: 18,
                            ),
                            validator: (v) =>
                                v?.isEmpty == true ? 'Date is required' : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ── Secondary Details (Method & Status) ────────────────
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdown<String>(
                              value: _selectedPaymentMethod,
                              items: _paymentMethods.map((m) {
                                return DropdownMenuItem(
                                  value: m,
                                  child: Text(m),
                                );
                              }).toList(),
                              hint: 'Method',
                              icon: Icons.payment_rounded,
                              onChanged: (val) =>
                                  setState(() => _selectedPaymentMethod = val),
                            ),
                          ),
                          // const SizedBox(width: 16),
                          // Expanded(
                          //   child: _buildDropdown<String>(
                          //     value: _selectedPaymentStatus,
                          //     items: _paymentStatuses.map((s) {
                          //       return DropdownMenuItem(
                          //         value: s,
                          //         child: Text(s),
                          //       );
                          //     }).toList(),
                          //     hint: 'Status',
                          //     icon: Icons.info_outline_rounded,
                          //     onChanged: (val) =>
                          //         setState(() => _selectedPaymentStatus = val),
                          //   ),
                          // ),
                        ],
                      ),

                      const SizedBox(height: 48),

                      // ── Submit Button ──────────────────────────────────────
                      SizedBox(
                        height: 60,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitCollection,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Confirm & Record',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF6366F1), // Specific indigo from mockup
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool readOnly = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    const radius = BorderRadius.all(Radius.circular(16));
    final outlineBorder = OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide.none,
    );

    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: radius,
        border: Border.all(color: _border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        // ← clips internal ink/fill
        borderRadius: radius,
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          validator: validator,
          style: GoogleFonts.inter(
            fontSize: 16,
            color: _textMain,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: label,
            hintStyle: GoogleFonts.inter(
              color: _textMuted.withValues(alpha: 0.4),
              fontSize: 14,
            ),
            prefixIcon: Icon(
              icon,
              color: _textMuted.withValues(alpha: 0.5),
              size: 20,
            ),
            suffixIcon: suffixIcon,
            border: outlineBorder, // ← all four states use same border
            enabledBorder: outlineBorder,
            focusedBorder: outlineBorder,
            errorBorder: outlineBorder,
            focusedErrorBorder: outlineBorder,
            filled: true,
            fillColor: _surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required String hint,
    required IconData icon,
    required void Function(T?)? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Row(
            children: [
              Icon(icon, color: _textMuted.withValues(alpha: 0.5), size: 20),
              const SizedBox(width: 12),
              Text(
                hint,
                style: GoogleFonts.inter(
                  color: _textMuted.withValues(alpha: 0.4),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: _textMuted,
            size: 20,
          ),
          isExpanded: true,
          items: items,
          onChanged: onChanged,
          style: GoogleFonts.inter(
            fontSize: 16,
            color: _textMain,
            fontWeight: FontWeight.w600,
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

// ── Redesigned Helper Widgets ────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String number;
  final String title;
  final IconData icon;
  final Color color;

  const _SectionHeader({
    required this.number,
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(
          '$number. $title',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _MemberStatusCard extends StatelessWidget {
  final MemberDetailsResponse details;

  const _MemberStatusCard({required this.details});

  @override
  Widget build(BuildContext context) {
    final _StatusStyle style = _statusStyle(details);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: _primary.withValues(alpha: 0.08)),
      ),
      color: _surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔹 HEADER (STATUS BADGE)
            Row(
              children: [
                _statusBadge(style),
                const Spacer(),
                Icon(
                  Icons.verified_rounded,
                  size: 18,
                  color: _textMuted.withValues(alpha: 0.6),
                ),
              ],
            ),

            const SizedBox(height: 16),

            /// 🔹 DIVIDER
            Divider(color: _primary.withValues(alpha: 0.05)),

            const SizedBox(height: 12),

            /// 🔹 DATA SECTION
            Row(
              children: [
                Expanded(
                  child: _infoTile(
                    'Paid to Date',
                    '₹${details.totalCollected.toStringAsFixed(0)}',
                    color: const Color(0xFF16A34A),
                  ),
                ),
                _verticalDivider(),
                Expanded(
                  child: _infoTile(
                    'Balance (Due)',
                    '₹${details.totalDue.toStringAsFixed(0)}',
                    color: details.totalDue > 0 ? _red : _textMain,
                  ),
                ),
                _verticalDivider(),
                Expanded(
                  child: _infoTile(
                    'Installment',
                    '₹${details.monthlyAmount.toStringAsFixed(0)}',
                    color: _textMain,
                  ),
                ),
              ],
            ),

            if (details.monthWise.isNotEmpty) ...[
              const SizedBox(height: 20),
              Divider(color: _primary.withValues(alpha: 0.05)),
              const SizedBox(height: 16),
              Text(
                'Payment Timeline',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _textMuted,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 70,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: details.monthWise.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final month = details.monthWise[index];
                    return _MonthMetricTile(month: month);
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 🔹 STATUS STYLE LOGIC (unchanged)
  _StatusStyle _statusStyle(MemberDetailsResponse details) {
    // ── Check if fully finished ──────────────────────────────────────
    if (details.monthsPaid >= details.durationMonths && details.totalDue <= 0) {
      return const _StatusStyle(
        label: 'COMPLETED',
        icon: Icons.workspace_premium_rounded,
        fgColor: Color(0xFF0D9488),
        bgColor: Color(0xFFF0FDFA),
      );
    }

    if (details.totalDue <= 0) {
      int nextPayment = details.monthsPaid;
      return _StatusStyle(
        label: 'CLEARED ${_getOrdinal(nextPayment)}',
        icon: Icons.star_rounded,
        fgColor: const Color(0xFF059669),
        bgColor: const Color(0xFFECFDF5),
      );
    } else if (details.totalCollected > 0) {
      return _StatusStyle(
        label: 'PARTIALLY PAID',
        icon: Icons.timelapse_rounded,
        fgColor: const Color(0xFFD97706),
        bgColor: const Color(0xFFFFFBEB),
      );
    } else {
      return _StatusStyle(
        label: 'DUE PENDING',
        icon: Icons.access_time_filled_rounded,
        fgColor: _red,
        bgColor: _redSoft,
      );
    }
  }

  String _getOrdinal(int number) {
    if (number >= 11 && number <= 13) return '${number}TH';
    switch (number % 10) {
      case 1:
        return '${number}ST';
      case 2:
        return '${number}ND';
      case 3:
        return '${number}RD';
      default:
        return '${number}TH';
    }
  }

  /// 🔹 INFO TILE (clean & spaced)
  Widget _infoTile(String label, String value, {required Color color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: _textMuted,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  /// 🔹 VERTICAL DIVIDER
  Widget _verticalDivider() {
    return Container(
      height: 32,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: _primary.withValues(alpha: 0.06),
    );
  }
}

// ── Status badge data class ────────────────────────────────────────────────
class _StatusStyle {
  final String label;
  final IconData? icon;
  final Color fgColor;
  final Color bgColor;

  const _StatusStyle({
    required this.label,
    this.icon,
    required this.fgColor,
    required this.bgColor,
  });
}

Widget _statusBadge(_StatusStyle style) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: style.bgColor,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(style.icon, size: 14, color: style.fgColor),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            style.label,
            overflow: TextOverflow.visible,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: style.fgColor,
            ),
          ),
        ),
      ],
    ),
  );
}

class _MonthMetricTile extends StatelessWidget {
  final MonthWisePayment month;
  const _MonthMetricTile({required this.month});

  @override
  Widget build(BuildContext context) {
    final bool isPaid = month.status.toLowerCase() == 'paid';
    final bool isPartial = month.status.toLowerCase() == 'partial';
    final bool isPending = month.status.toLowerCase() == 'pending';
    final bool isAdvance = month.isAdvance;

    Color color;
    if (isAdvance) {
      color = Colors.indigo;
    } else if (isPaid) {
      color = const Color(0xFF059669);
    } else if (isPartial) {
      color = const Color(0xFFD97706);
    } else {
      color = _red;
    }

    return Container(
      width: 70,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'MO ${month.month}',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: _textMuted,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              month.status.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
