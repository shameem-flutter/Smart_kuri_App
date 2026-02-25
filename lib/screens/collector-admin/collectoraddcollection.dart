import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kuri_app/providers/group_provider.dart';
import 'package:kuri_app/utilities/colors.dart';
import 'package:kuri_app/models/groupadmin/assigned_member_model.dart';
import 'package:kuri_app/services/api_service.dart';

class Addcollection extends ConsumerStatefulWidget {
  const Addcollection({super.key});

  @override
  ConsumerState<Addcollection> createState() => _AddcollectionState();
}

class _AddcollectionState extends ConsumerState<Addcollection> {
  final _formKey = GlobalKey<FormState>();
  
  AssignedMember? _selectedMember;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  String _paymentMethod = 'UPI'; // Default payment method
  
  final List<String> _paymentMethods = ['UPI', 'Cash', 'Bank Transfer'];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('dd-MM-yyyy').format(DateTime.now());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: const Color(0xFF2B3A4A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('dd-MM-yyyy').format(picked);
      });
    }
  }

  Future<void> _submitForm(ApiService apiService) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMember == null) {
      _showSnackBar('Please select a member', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final requestData = {
        "member": _selectedMember!.id,
        "amount": _amountController.text.trim(),
        "paid_date": _dateController.text,
        "payment_method": _paymentMethod,
      };

      final response = await apiService.addCollectorCollection(requestData);
      
      if (!mounted) return;
      
      _showSnackBar(response['message'] ?? 'Collection added successfully');
      
      // Refresh relevant providers
      ref.invalidate(collectorDashboardProvider);
      ref.invalidate(pendingMembersProvider);
      
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(e.toString().replaceAll('Exception: ', ''), isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(color: Colors.white),
        ),
        backgroundColor: isError ? Colors.red[400] : Colors.green[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(assignedMemberProvider({'page': 1, 'pageSize': 100}));
    final apiService = ref.read(apiServiceProvider);

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    const darkBlue = Color(0xFF2B3A4A);
    const bgGrey = Color(0xFFF2F4F7);

    return Scaffold(
      backgroundColor: bgGrey,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: darkBlue, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Add Collection',
          style: GoogleFonts.poppins(
            color: darkBlue,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: membersAsync.when(
          loading: () => Center(child: CircularProgressIndicator(color: primaryColor)),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (data) => _buildForm(context, data.results, apiService),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, List<AssignedMember> members, ApiService apiService) {
    const darkBlue = Color(0xFF2B3A4A);

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Member Selection
            _buildLabel('Select Member'),
            const SizedBox(height: 8),
            DropdownButtonFormField<AssignedMember>(
              value: _selectedMember,
              hint: Text('Choose a member', style: GoogleFonts.inter(color: Colors.grey[400])),
              isExpanded: true,
              decoration: _inputDecoration(prefixIcon: Icons.person_outline),
              items: members.map((member) {
                return DropdownMenuItem(
                  value: member,
                  child: Text(
                    '${member.name} (${member.groupName})',
                    style: GoogleFonts.inter(color: darkBlue),
                  ),
                );
              }).toList(),
              validator: (value) => value == null ? 'Required field' : null,
              onChanged: (value) {
                setState(() {
                  _selectedMember = value;
                  if (value != null && value.monthlyAmount > 0) {
                    _amountController.text = value.monthlyAmount.toStringAsFixed(0);
                  } else {
                    _amountController.clear();
                  }
                });
              },
            ),

            const SizedBox(height: 24),

            // Amount Field
            _buildLabel('Amount'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountController,
              readOnly: true, // Amount is fixed based on monthly amount to be paid
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.inter(color: darkBlue, fontWeight: FontWeight.w500),
              decoration: _inputDecoration(
                prefixIcon: Icons.currency_rupee_rounded,
                hintText: 'Amount',
              ).copyWith(
                fillColor: Colors.grey[100], // Make it look read-only
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Select a member to view amount';
                if (double.tryParse(value.trim()) == null) return 'Invalid amount';
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Date Field
            _buildLabel('Payment Date'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _dateController,
              readOnly: true,
              onTap: () => _selectDate(context),
              style: GoogleFonts.inter(color: darkBlue, fontWeight: FontWeight.w500),
              decoration: _inputDecoration(
                prefixIcon: Icons.calendar_today_rounded,
              ),
            ),

            const SizedBox(height: 24),

            // Payment Method
            _buildLabel('Payment Method'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _paymentMethod,
              decoration: _inputDecoration(prefixIcon: Icons.payment_rounded),
              items: _paymentMethods.map((method) {
                return DropdownMenuItem(
                  value: method,
                  child: Text(
                    method,
                    style: GoogleFonts.inter(color: darkBlue),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _paymentMethod = value);
                }
              },
            ),

            const SizedBox(height: 48),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : () => _submitForm(apiService),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        'Add Collection',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF2B3A4A),
      ),
    );
  }

  InputDecoration _inputDecoration({required IconData prefixIcon, String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
      prefixIcon: Icon(prefixIcon, color: Colors.grey[400], size: 22),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.red.withOpacity(0.5)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }
}
