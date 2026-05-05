import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kuri_app/models/groupadmin/group_create_model.dart';
import 'package:kuri_app/providers/group_provider.dart';
import 'package:kuri_app/screens/groupadmin/groups/groupdetails.dart';
import '../../../models/groupadmin/dashboard_model.dart';

class GroupcreateScreen extends ConsumerStatefulWidget {
  final DashboardGroup? group;
  const GroupcreateScreen({super.key, this.group});

  @override
  ConsumerState<GroupcreateScreen> createState() => _GroupcreateScreenState();
}

class _GroupcreateScreenState extends ConsumerState<GroupcreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _amountController = TextEditingController();
  final _durationController = TextEditingController();
  final _auctionsPerMonthController = TextEditingController(text: '1');
  final _startDateController = TextEditingController();
  final _intervalMonthsController = TextEditingController();
  final List<TextEditingController> _auctionDateCtrls = [];

  bool get _isInterval => _auctionType == 'interval';

  String _formatIsoDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _formatDisplayDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';

  String _auctionType = 'monthly';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _auctionsPerMonthController.addListener(_onAuctionsCountChanged);
    // Initialize with 1 auction date controller
    _auctionDateCtrls.add(TextEditingController());

    if (widget.group != null) {
      _nameController.text = widget.group!.name;
      _amountController.text = widget.group!.monthlyAmount.toString();
      _durationController.text = widget.group!.durationMonths.toString();
      _startDateController.text = widget.group!.startDate;
    }
  }

  void _onAuctionsCountChanged() {
    final text = _auctionsPerMonthController.text.trim();
    if (text.isEmpty) return;
    final count = int.tryParse(text) ?? 1;
    if (count < 1 || count > 20) return;

    if (_auctionDateCtrls.length != count) {
      setState(() {
        while (_auctionDateCtrls.length < count) {
          _auctionDateCtrls.add(TextEditingController());
        }
        while (_auctionDateCtrls.length > count) {
          _auctionDateCtrls.last.dispose();
          _auctionDateCtrls.removeLast();
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _amountController.dispose();
    _durationController.dispose();
    _auctionsPerMonthController.removeListener(_onAuctionsCountChanged);
    _auctionsPerMonthController.dispose();
    _intervalMonthsController.dispose();
    _startDateController.dispose();
    for (var ctrl in _auctionDateCtrls) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller, {
    bool isStartDate = false,
  }) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2962FF),
              onPrimary: Colors.white,
              onSurface: Color(0xFF2B3A4A),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2962FF),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          controller.text = _formatDisplayDate(picked);
        } else {
          controller.text = _formatIsoDate(picked);
        }
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final apiService = ref.read(apiServiceProvider);

        if (widget.group != null) {
          // Editing
          final Map<String, dynamic> updateData = {
            "name": _nameController.text,
            "monthly_amount": double.parse(_amountController.text),
            "duration_months": int.parse(_durationController.text),
            "start_date": _startDateController.text,
          };

          await apiService.updateGroup(widget.group!.id, updateData);

          if (mounted) {
            ref.invalidate(dashboardDataProvider); // Refresh dashboard
            ref.invalidate(groupListProvider);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Group updated successfully'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.pop(context); // Go back to dashboard/list
            // If we want to view details after edit, we could replace pop with pushReplacement
            // But usually backing out to the list or previous screen is expected after 'Save'
          }
        } else {
          // Creating
          // Construct request with modern field names
          final request = GroupCreateRequest(
            name: _nameController.text,
            monthlyAmount: int.tryParse(_amountController.text) ?? 0,
            durationMonths: int.parse(_durationController.text),
            startDate: _startDateController.text,
            auctionType: _auctionType,
            auctionsPerMonth:
                int.tryParse(_auctionsPerMonthController.text) ?? 1,
            auctionIntervalMonths: _isInterval
                ? int.tryParse(_intervalMonthsController.text)
                : null,
            auctionDate1:
                _auctionDateCtrls.isNotEmpty &&
                    _auctionDateCtrls[0].text.isNotEmpty
                ? _auctionDateCtrls[0].text
                : null,
            otherAuctionDates: _auctionDateCtrls.length > 1
                ? _auctionDateCtrls
                      .sublist(1)
                      .map((c) => c.text.trim())
                      .where((t) => t.isNotEmpty)
                      .toList()
                : [],
          );

          final response = await apiService.createGroup(request);

          if (mounted) {
            ref.invalidate(groupListProvider);
            ref.invalidate(profileProvider);
            ref.invalidate(dashboardDataProvider);

            setState(() {
              _nameController.clear();
              _phoneController.clear();
              _emailController.clear();
              _amountController.clear();
              _durationController.clear();
              _auctionsPerMonthController.text = '1';
              _intervalMonthsController.clear();
              _startDateController.clear();
              for (var ctrl in _auctionDateCtrls) {
                ctrl.clear();
              }
            });
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => GroupDetailsScreen(groupId: response.id),
              ),
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Group created: ${response.message}'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: Colors.red,
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF2B3A4A),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.group != null ? 'Edit Group' : 'Add Group',
          style: GoogleFonts.poppins(
            // color: const Color(0xFF2962FF),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.group != null
                        ? 'Edit Group Details'
                        : 'Group Information',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Name Field
                  _buildTextField(
                    controller: _nameController,
                    label: 'Group Name',
                    hint: 'Enter group name',
                    icon: Icons.group_outlined,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a group name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Contact Info
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _phoneController,
                          label: 'Phone Number',
                          hint: '90000 00000',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _emailController,
                          label: 'Email Address',
                          hint: 'test@gmail.com',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            if (!value.contains('@')) return 'Invalid email';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  Text(
                    'Chitty Settings',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _amountController,
                          label: 'Monthly Amount',
                          hint: '0.00',
                          icon: Icons.attach_money_rounded,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Invalid';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _durationController,
                          label: 'Duration (Months)',
                          hint: '10',
                          icon: Icons.timer_outlined,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            if (int.tryParse(value) == null) return 'Invalid';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown(
                          label: 'Auction Type',
                          value: _auctionType,
                          items: const ['monthly', 'interval'],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _auctionType = val;
                                if (val == 'interval') {
                                  _auctionsPerMonthController.text = '1';
                                } else {
                                  _intervalMonthsController.clear();
                                }
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _auctionsPerMonthController,
                          label: 'Auctions / Month',
                          hint: '1',
                          icon: Icons.repeat_rounded,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  if (_isInterval) ...[
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _intervalMonthsController,
                      label: 'Auction Interval (Months)',
                      hint: '2',
                      icon: Icons.calendar_view_day_rounded,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required for interval';
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 32),

                  Text(
                    'Timeline',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildDateField(
                    controller: _startDateController,
                    label: 'Start Date',
                    hint: 'DD-MM-YYYY',
                    onTap: () => _selectDate(
                      context,
                      _startDateController,
                      isStartDate: true,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Auction Dates',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._auctionDateCtrls.asMap().entries.map((entry) {
                    final index = entry.key;
                    final ctrl = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildDateField(
                        controller: ctrl,
                        label: 'Auction Date ${index + 1}',
                        hint: 'YYYY-MM-DD',
                        onTap: () => _selectDate(context, ctrl),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          return null;
                        },
                      ),
                    );
                  }),

                  const SizedBox(height: 40),

                  // Submit Button
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2962FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 5,
                        shadowColor: const Color(
                          0xFF2962FF,
                        ).withValues(alpha: 0.4),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              widget.group != null
                                  ? 'Save Changes'
                                  : 'Create Group',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF2B3A4A),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.inter(
            color: const Color(0xFF2B3A4A),
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: Colors.grey[400], fontSize: 14),
            prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF2962FF),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required VoidCallback onTap,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF2B3A4A),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: AbsorbPointer(
            child: TextFormField(
              controller: controller,
              validator: validator,
              style: GoogleFonts.inter(
                color: const Color(0xFF2B3A4A),
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.inter(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.calendar_today_rounded,
                  color: Colors.grey[400],
                  size: 20,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF2962FF),
                    width: 1.5,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red, width: 1),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF2B3A4A),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.grey[400],
              ),
              style: GoogleFonts.inter(
                color: const Color(0xFF2B3A4A),
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
              items: items.map((String item) {
                return DropdownMenuItem<String>(value: item, child: Text(item));
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
