import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/groupadmin/group_model.dart';
import '../../../models/groupadmin/cashcollector/cashcollector.dart';
import '../../../services/api_service.dart';
import '../../../services/storage_service.dart';

class Createcashcollectorscreen extends StatefulWidget {
  const Createcashcollectorscreen({super.key});

  @override
  State<Createcashcollectorscreen> createState() => _CashCollectorScreenState();
}

class _CashCollectorScreenState extends State<Createcashcollectorscreen> {
  final _formKey = GlobalKey<FormState>();
  late final ApiService _apiService;

  // Controllers
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
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
    _apiService = ApiService(storageService: StorageService());
    _loadGroups();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    try {
      final response = await _apiService.getGroups();
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

  Future<void> _submitCollector() async {
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
      final collector = CashCollectorModel(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        group: _selectedGroupId!,
      );

      final response = await _apiService.createCollector(collector);

      if (mounted) {
        // showDialog(
        //   context: context,
        //   barrierDismissible: false,
        //   builder: (context) => AlertDialog(
        //     title: const Text('Success'),
        //     content: Text(
        //       response['message'] ?? 'Cash Collector created successfully',
        //     ),
        //     actions: [
        //       TextButton(
        //         onPressed: () {
        //           Navigator.pop(context);
        //           _usernameController.clear();
        //           _emailController.clear();
        //           _phoneController.clear();
        //           _passwordController.clear();
        //           setState(() {
        //             _selectedGroupId = null;
        //           });
        //         },
        //         child: const Text('OK'),
        //       ),
        //     ],
        //   ),
        // );
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
        title: Text(
          'Create Cash Collector',
          style: GoogleFonts.poppins(
            color: const Color(0xFF2B3A4A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
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
                      _buildSectionTitle('Personal Information'),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _usernameController,
                        label: 'Username',
                        icon: Icons.person_outline_rounded,
                        validator: (v) =>
                            v?.isEmpty == true ? 'Username is required' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email Address',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) =>
                            v?.isEmpty == true ? 'Email is required' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (v) =>
                            v?.isEmpty == true ? 'Phone is required' : null,
                      ),

                      const SizedBox(height: 32),
                      _buildSectionTitle('Group Assignment'),
                      const SizedBox(height: 16),
                      _buildGroupDropdown(),

                      const SizedBox(height: 32),
                      _buildSectionTitle('Security'),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _passwordController,
                        label: 'Password',
                        icon: Icons.lock_outline_rounded,
                        obscureText: _obscurePassword,
                        isPassword: true,
                        validator: (v) => v != null && v.length < 6
                            ? 'Password must be at least 6 chars'
                            : null,
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

                      const SizedBox(height: 40),
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitCollector,
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
                                  'Create Cash Collector',
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
        fontSize: 10,
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
          labelStyle: GoogleFonts.inter(color: Colors.grey[400], fontSize: 14),
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
        ),
      ),
    );
  }

  Widget _buildGroupDropdown() {
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
                'Select Group',
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
          onChanged: (int? newValue) {
            setState(() {
              _selectedGroupId = newValue!;
            });
          },
        ),
      ),
    );
  }
}
