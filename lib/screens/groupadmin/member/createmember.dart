import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/groupadmin/group_model.dart';
import '../../../providers/group_provider.dart';

class CreateMemberScreen extends ConsumerStatefulWidget {
  const CreateMemberScreen({super.key});

  @override
  ConsumerState<CreateMemberScreen> createState() => _CreateMemberScreenState();
}

class _CreateMemberScreenState extends ConsumerState<CreateMemberScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _aadhaarController = TextEditingController();
  final _passwordController = TextEditingController();

  // State
  bool _isLoading = false;
  bool _isLoadingGroups = true;
  String? _error;
  List<Group> _groups = [];
  int? _selectedGroupId;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _aadhaarController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    try {
      final response = await ref.read(apiServiceProvider).getGroups();
      if (mounted) {
        setState(() {
          _groups = response.groups;
          _isLoadingGroups = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load groups. Please try again.';
          _isLoadingGroups = false;
        });
      }
    }
  }

  Future<void> _submitMembers() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGroupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a group'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = {
        "name": _nameController.text.trim(),
        "email": _emailController.text.trim(),
        "phone": _phoneController.text.trim(),
        "address": _addressController.text.trim(),
        "aadhaar_no": _aadhaarController.text.trim(),
        "assigned_chitti_group": _selectedGroupId,
        "password": _passwordController.text,
      };

      final response = await ref.read(apiServiceProvider).createMember(data);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            // 1. Modern rounded corners
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            // 2. Clear visual indicator of success
            icon: const Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 60,
            ),
            // 3. Centered, bold title
            title: const Text(
              'Success!',
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            // 4. Centered content
            content: Text(
              response['message'] ?? 'Member created successfully.',
              textAlign: TextAlign.center,
            ),
            // 5. Center the button
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
                  // 6. Cleaner double-pop syntax using the cascade operator
                  Navigator.of(context)
                    ..pop() // Close dialog
                    ..pop(); // Go back to member list
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_error ?? 'An error occurred'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
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
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),
      body: SafeArea(
        child: _isLoadingGroups
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF2962FF)),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Page Title ──────────────────────────────────────
                      Text(
                        'Create New Member',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF2B3A4A),
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),

                      // ── Personal Information ─────────────────────────────
                      const SizedBox(height: 24), // FIX: added top spacing
                      _buildSectionTitle('Personal Information'),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _nameController,
                        label: 'Full Name',
                        icon: Icons.person_outline_rounded,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Name is required'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email Address',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Email is required'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Phone is required'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _addressController,
                        label: 'Address',
                        icon: Icons.location_on_outlined,
                        maxLines: 2,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Address is required'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _aadhaarController,
                        label: 'Aadhaar Number',
                        icon: Icons.badge_outlined,
                        keyboardType: TextInputType.number,
                        // FIX: null-safe Aadhaar validator
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Aadhaar number is required';
                          }
                          if (v.trim().length != 12) {
                            return 'Enter a valid 12-digit Aadhaar';
                          }
                          return null;
                        },
                      ),

                      // ── Group Assignment ─────────────────────────────────
                      const SizedBox(height: 32), // FIX: added top spacing
                      _buildSectionTitle('Group Assignment'),
                      const SizedBox(height: 16),
                      _buildGroupDropdown(),

                      // ── Security ─────────────────────────────────────────
                      const SizedBox(height: 32), // FIX: added top spacing
                      _buildSectionTitle('Security'),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _passwordController,
                        label: 'Password',
                        icon: Icons.lock_outline_rounded,
                        obscureText: _obscurePassword,
                        isPassword: true,
                        // FIX: separate empty vs too-short messages
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Password is required';
                          }
                          if (v.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: Colors.grey[400],
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),

                      // ── Submit Button ────────────────────────────────────
                      const SizedBox(height: 40),
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitMembers,
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
                                  'Create Member',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.poppins(
        fontSize: 11, // FIX: bumped from 10 → 11 for better readability
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
    bool obscureText = false,
    bool isPassword = false,
    String? Function(String?)? validator,
    int maxLines = 1,
    Widget? suffixIcon,
  }) {
    return Container(
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
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
        style: GoogleFonts.inter(
          fontSize: 15,
          color: const Color(0xFF2B3A4A),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(
            color: Colors.grey[500],
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF2962FF), size: 22),
          suffixIcon: suffixIcon,
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
          // FIX: added focusedErrorBorder so border stays visible on focus
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.red[300]!, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupDropdown() {
    final bool isSelected = _selectedGroupId != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        // FIX: show blue border when a group is selected, matching text fields
        border: Border.all(
          color: isSelected ? const Color(0xFF2962FF) : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedGroupId,
          hint: Row(
            children: [
              const Icon(
                Icons.group_work_outlined,
                color: Color(0xFF2962FF),
                size: 22,
              ),
              const SizedBox(width: 12),
              Text(
                'Assigned Chitti Group',
                style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 14),
              ),
            ],
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.grey,
          ),
          isExpanded: true,
          items: _groups.map((Group group) {
            return DropdownMenuItem<int>(
              value: group.id,
              child: Row(
                children: [
                  const Icon(
                    Icons.group_work_outlined,
                    color: Color(0xFF2962FF),
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    group.name,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: const Color(0xFF2B3A4A),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          // FIX: null-safe onChanged — no force-unwrap
          onChanged: (int? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedGroupId = newValue;
              });
            }
          },
        ),
      ),
    );
  }
}
