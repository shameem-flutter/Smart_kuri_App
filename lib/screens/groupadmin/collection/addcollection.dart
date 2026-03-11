import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../models/groupadmin/collection_create_model.dart';
import '../../../models/groupadmin/group_model.dart';
import '../../../models/groupadmin/member_list.dart';
import '../../../providers/group_provider.dart';

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

  // Dropdown options
  final List<String> _paymentMethods = [
    'Razorpay',
    'Cash',
    'UPI',
    'Bank Transfer',
  ];
  String? _selectedPaymentMethod;

  final List<String> _paymentStatuses = ['Success', 'Failed', 'Pending'];
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
      _amountController.clear();
      _isFetchingAmount = true;
    });

    final apiService = ref.read(apiServiceProvider);
    try {
      final history = await apiService.getMemberHistory(memberId);
      if (mounted && _selectedMemberId == memberId) {
        setState(() {
          _amountController.text = history.summary.monthlyAmount
              .toStringAsFixed(0);
          _isFetchingAmount = false;
        });
      }
    } catch (_) {
      // Fallback: use the selected group's monthly amount
      if (mounted && _selectedMemberId == memberId) {
        final selectedGroup = _groups.firstWhere(
          (g) => g.id == _selectedGroupId,
          orElse: () => _groups.first,
        );
        setState(() {
          if (selectedGroup.monthlyAmount > 0) {
            _amountController.text = selectedGroup.monthlyAmount
                .toStringAsFixed(0);
          }
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
    if (_selectedPaymentStatus == null) {
      _showSnackBar('Please select a payment status');
      return;
    }

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
        paymentStatus: _selectedPaymentStatus!.toLowerCase(),
      );

      await ref.read(apiServiceProvider).createCollection(request);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Success'),
            content: const Text('Collection added successfully'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text(
          'Add Collection',
          style: GoogleFonts.poppins(
            color: const Color(0xFF2B3A4A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: Color(0xFF2B3A4A),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: _isLoadingData
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF2962FF)),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSectionTitle('Transaction Details'),
                      const SizedBox(height: 16),

                      // Group Dropdown
                      _buildDropdown<int>(
                        value: _selectedGroupId,
                        items: _groups
                            .map(
                              (g) => DropdownMenuItem(
                                value: g.id,
                                child: Text(g.name),
                              ),
                            )
                            .toList(),
                        hint: 'Select Group',
                        icon: Icons.group_work_outlined,
                        onChanged: _onGroupChanged,
                      ),
                      const SizedBox(height: 16),

                      // Member Dropdown
                      _buildDropdown<int>(
                        value: _selectedMemberId,
                        items: _filteredMembers
                            .map(
                              (m) => DropdownMenuItem(
                                value: m.id,
                                child: Text(m.name),
                              ),
                            )
                            .toList(),
                        hint: 'Select Member',
                        icon: Icons.person_outline_rounded,
                        onChanged: _selectedGroupId == null
                            ? null
                            : (val) => _onMemberChanged(val),
                      ),
                      const SizedBox(height: 16),

                      // Amount Field
                      _buildTextField(
                        controller: _amountController,
                        label: _isFetchingAmount
                            ? 'Fetching amount…'
                            : 'Amount',
                        icon: _isFetchingAmount
                            ? Icons.hourglass_top_rounded
                            : Icons.currency_rupee_rounded,
                        keyboardType: TextInputType.number,
                        readOnly: true,
                        validator: (v) {
                          if (v?.isEmpty == true) return 'Amount is required';
                          if (double.tryParse(v!) == null) {
                            return 'Invalid amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Date Picker
                      GestureDetector(
                        onTap: () => _selectDate(context),
                        child: AbsorbPointer(
                          child: _buildTextField(
                            controller: _dateController,
                            label: 'Paid Date',
                            icon: Icons.calendar_today_rounded,
                            validator: (v) =>
                                v?.isEmpty == true ? 'Date is required' : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Payment Method Dropdown
                      _buildDropdown<String>(
                        value: _selectedPaymentMethod,
                        items: _paymentMethods
                            .map(
                              (m) => DropdownMenuItem(value: m, child: Text(m)),
                            )
                            .toList(),
                        hint: 'Payment Method',
                        icon: Icons.payment_rounded,
                        onChanged: (val) =>
                            setState(() => _selectedPaymentMethod = val),
                      ),
                      const SizedBox(height: 16),

                      // Payment Status Dropdown
                      _buildDropdown<String>(
                        value: _selectedPaymentStatus,
                        items: _paymentStatuses
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                        hint: 'Payment Status',
                        icon: Icons.info_outline_rounded,
                        onChanged: (val) =>
                            setState(() => _selectedPaymentStatus = val),
                      ),

                      const SizedBox(height: 40),
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitCollection,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2962FF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                            shadowColor: const Color(
                              0xFF2962FF,
                            ).withValues(alpha: 0.4),
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
                                  'Add Collection',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
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
        fontWeight: FontWeight.w600,
        color: Colors.grey[500],
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: readOnly ? const Color(0xFFF0F0F0) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        validator: validator,
        style: GoogleFonts.inter(
          fontSize: 15,
          color: const Color(0xFF2B3A4A),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.never,

          labelStyle: GoogleFonts.inter(color: Colors.grey[400], fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFF2962FF), size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF2962FF), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.red[300]!, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.red[300]!, width: 1.5),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
              Icon(icon, color: const Color(0xFF2962FF), size: 22),
              const SizedBox(width: 12),
              Text(
                hint,
                style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 14),
              ),
            ],
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.grey,
          ),
          isExpanded: true,
          items: items,
          onChanged: onChanged,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: const Color(0xFF2B3A4A),
            fontWeight: FontWeight.w500,
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
