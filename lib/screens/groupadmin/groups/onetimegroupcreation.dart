import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kuri_app/models/auth/plan_model.dart';
import 'package:kuri_app/providers/group_provider.dart';
import 'package:kuri_app/providers/auth_provider_riverpod.dart';
import 'package:kuri_app/models/groupadmin/group_create_model.dart';
import 'package:kuri_app/utilities/colors.dart';

// ── Design Tokens ─────────────────────────────────────────────────────────────
abstract class _T {
  static const pageBg = Color(0xFFFBFBFD);
  static const surface = Color(0xFFFFFFFF);

  static const brandLight = Color(0xFFF5F3FF);
  static const ink = Color(0xFF19191D);
  static const inkMid = Color(0xFF787880);
  static const inkLight = Color(0xFF9CA3AF);
  static const border = Color(0xFFE5E7EB);
  static const error = Color(0xFFFF5F6D);
}

// ── Screen ────────────────────────────────────────────────────────────────────
class Onetimegroupcreation extends ConsumerStatefulWidget {
  const Onetimegroupcreation({super.key});

  @override
  ConsumerState<Onetimegroupcreation> createState() =>
      _OnetimegroupcreationState();
}

class _OnetimegroupcreationState extends ConsumerState<Onetimegroupcreation> {
  final _formKey = GlobalKey<FormState>();

  // Group info controllers
  final _nameController = TextEditingController();
  // Phone & email are read-only, pre-filled from the signed-in profile
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  // Chitti settings controllers
  final _amountController = TextEditingController();
  final _durationController = TextEditingController();
  final _auctionsController = TextEditingController(text: '1');
  final _intervalMonthsController = TextEditingController();

  // Date controllers
  final _startDateCtrl = TextEditingController();
  final List<TextEditingController> _auctionDateCtrls = [];

  // Plan selection (UI only – not sent to the new API)
  int? _selectedPlanId;

  // Auction type
  String _selectedAuctionType = 'Monthly';

  bool _isLoading = false;
  bool _profilePrefilled = false; // guard so we only pre-fill once

  /// UI label  →  API value
  static const Map<String, String> _auctionTypeApiValues = {
    'Monthly': 'monthly',
    'Interval': 'interval',
  };

  // ── Helpers ────────────────────────────────────────────────────────────────

  bool get _isInterval => _selectedAuctionType == 'Interval';

  /// Format a DateTime to "yyyy-MM-dd" for all API date fields.
  String _formatIsoDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Format a DateTime to "DD-MM-YYYY" for the start_date field.
  String _formatDisplayDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime(2101),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: ColorScheme.light(primary: primaryColor),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _startDateCtrl.text = _formatDisplayDate(picked));
    }
  }

  Future<void> _pickAuctionDate(int index) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime(2101),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: ColorScheme.light(primary: primaryColor),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _auctionDateCtrls[index].text = _formatIsoDate(picked));
    }
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final apiService = ref.read(apiServiceProvider);

      final apiAuctionType =
          _auctionTypeApiValues[_selectedAuctionType] ?? _selectedAuctionType;

      // Construct request with modern field names
      final request = GroupCreateRequest(
        planId: _selectedPlanId,
        name: _nameController.text.trim(),
        monthlyAmount: int.tryParse(_amountController.text) ?? 0,
        durationMonths: int.tryParse(_durationController.text) ?? 12,
        startDate: _startDateCtrl.text.trim(),
        auctionsPerMonth: int.tryParse(_auctionsController.text) ?? 1,
        auctionType: apiAuctionType,
        auctionIntervalMonths: _isInterval
            ? int.tryParse(_intervalMonthsController.text)
            : null,
        auctionDate1:
            _auctionDateCtrls.isNotEmpty &&
                _auctionDateCtrls[0].text.trim().isNotEmpty
            ? _auctionDateCtrls[0].text.trim()
            : null,
        otherAuctionDates: _auctionDateCtrls.length > 1
            ? _auctionDateCtrls
                  .sublist(1)
                  .map((c) => c.text.trim())
                  .where((t) => t.isNotEmpty)
                  .toList()
            : [],
      );

      await apiService.createGroup(request);

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Group created successfully! Welcome aboard.',
            key: ValueKey('group_success_msg'),
          ),
          backgroundColor: Colors.green,
        ),
      );

      await ref.read(authProvider.notifier).completeOnetimeSetup();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: _T.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _auctionsController.addListener(_onAuctionsCountChanged);
    // Initialize with 1 auction date controller
    _auctionDateCtrls.add(TextEditingController());
  }

  void _onAuctionsCountChanged() {
    final text = _auctionsController.text.trim();
    if (text.isEmpty) return;

    final count = int.tryParse(text) ?? 1;
    if (count < 1) return;
    if (count > 20) return; // safety limit

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
    _auctionsController.removeListener(_onAuctionsCountChanged);
    _auctionsController.dispose();
    _intervalMonthsController.dispose();
    _startDateCtrl.dispose();
    for (var ctrl in _auctionDateCtrls) {
      ctrl.dispose();
    }
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Pre-fill phone & email from profile (once, when data arrives)
    final profileAsync = ref.watch(profileProvider);
    profileAsync.whenData((profile) {
      if (!_profilePrefilled) {
        _profilePrefilled = true;
        _phoneController.text = profile.profile.phone;
        _emailController.text = profile.profile.email;
      }
    });

    // Auto-select first plan for UI badge only
    final plansAsync = ref.watch(plansProvider);
    ref.listen(plansProvider, (_, next) {
      final plans = next.value;
      if (plans != null && _selectedPlanId == null && plans.isNotEmpty) {
        setState(() => _selectedPlanId = plans.first.id);
      }
    });

    return Scaffold(
      backgroundColor: _T.pageBg,
      appBar: AppBar(
        backgroundColor: _T.pageBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _T.ink,
            size: 20,
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Create Group',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _T.ink,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Show plans for selection (UI only — subscription plan selection)
            plansAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) =>
                  _RetryCard(onRetry: () => ref.invalidate(plansProvider)),
              data: (plans) => _buildPlanSection(plans),
            ),
            const SizedBox(height: 48),
            _buildGroupInfoSection(),
            const SizedBox(height: 32),
            _buildChittiSettingsSection(),
            const SizedBox(height: 32),
            _buildTimelineSection(),
            const SizedBox(height: 48),
            _ModernSubmitButton(
              isLoading: _isLoading,
              onPressed: _handleSubmit,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── Section Builders ───────────────────────────────────────────────────────

  Widget _buildPlanSection(List<PlanModel> plans) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TIER SELECTION',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: primaryColor,
              letterSpacing: 1,
            ),
          ),
          Text(
            'Subscription Plan',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: _T.ink,
            ),
          ),
          const SizedBox(height: 24),
          ...plans.asMap().entries.map((entry) {
            final plan = entry.value;
            final isSelected = _selectedPlanId == plan.id;
            final metadata = _PlanMetadata.get(plan.name, entry.key);
            return Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: _PlanRadioTile(
                plan: plan,
                metadata: metadata,
                isSelected: isSelected,
                onTap: () => setState(() => _selectedPlanId = plan.id),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildGroupInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FormSectionHeader(title: 'Group Information'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _T.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _T.border.withValues(alpha: 0.5)),
          ),
          child: Column(
            children: [
              _ModernField(
                controller: _nameController,
                label: 'GROUP NAME',
                hint: 'Enter circle name',
                prefixIcon: Icons.badge_outlined,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 8),
              _ModernField(
                controller: _phoneController,
                label: 'PHONE',
                hint: 'Loading…',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                readOnly: true,
              ),
              const SizedBox(width: 8),
              _ModernField(
                controller: _emailController,
                label: 'EMAIL',
                hint: 'Loading…',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                readOnly: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChittiSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chitti Settings',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _T.ink,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _T.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _T.border.withValues(alpha: 0.5)),
          ),
          child: Column(
            children: [
              // Amount + Duration
              Row(
                children: [
                  Expanded(
                    child: _ModernField(
                      controller: _amountController,
                      label: 'MONTHLY AMOUNT',
                      hint: '10000',
                      prefixIcon: Icons.currency_rupee_rounded,
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _ModernField(
                      controller: _durationController,
                      label: 'DURATION (MO.)',
                      hint: '12',
                      prefixIcon: Icons.timer_outlined,
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Auction type + auctions per month
              Row(
                children: [
                  Expanded(
                    child: _ModernDropdown(
                      label: 'AUCTION TYPE',
                      value: _selectedAuctionType,
                      items: const ['Monthly', 'Interval'],
                      onChanged: (v) {
                        if (v != null) {
                          setState(() {
                            _selectedAuctionType = v;
                            // Reset interval-specific fields
                            if (v != 'Interval') {
                              _intervalMonthsController.clear();
                            } else {
                              // Per JSON example, Interval usually has 1 auction / month
                              _auctionsController.text = '1';
                            }
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _ModernField(
                      controller: _auctionsController,
                      label: 'AUCTIONS / MONTH',
                      hint: '1',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              // Interval-specific field – only shown for "Interval" type
              if (_isInterval) ...[
                const SizedBox(height: 8),
                _ModernField(
                  controller: _intervalMonthsController,
                  label: 'AUCTION INTERVAL (MO.)',
                  hint: '2',
                  prefixIcon: Icons.swap_horiz_rounded,
                  keyboardType: TextInputType.number,
                  validator: (v) => _isInterval && (v == null || v.isEmpty)
                      ? 'Required for interval type'
                      : null,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Timeline',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _T.ink,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _T.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _T.border.withValues(alpha: 0.5)),
          ),
          child: Column(
            children: [
              // Start date (yyyy-MM-dd)
              _DatePickerField(
                controller: _startDateCtrl,
                label: 'REGISTRATION START DATE',
                placeholder: 'YYYY-MM-DD',
                onTap: _pickStartDate,
              ),
              const SizedBox(height: 8),
              // Dynamic auction dates
              ...List.generate(_auctionDateCtrls.length, (index) {
                final label = index == 0
                    ? 'FIRST AUCTION DATE'
                    : 'AUCTION DATE ${index + 1}';
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: _DatePickerField(
                    controller: _auctionDateCtrls[index],
                    label: label,
                    placeholder: 'YYYY-MM-DD',
                    onTap: () => _pickAuctionDate(index),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Modern UI Components ──────────────────────────────────────────────────────

class _PlanMetadata {
  final IconData icon;
  final String description;
  final bool isMostPopular;

  _PlanMetadata({
    required this.icon,
    required this.description,
    this.isMostPopular = false,
  });

  static _PlanMetadata get(String name, int index) {
    if (name.toLowerCase().contains('plus') || index == 1) {
      return _PlanMetadata(
        icon: Icons.diamond_outlined,
        description: 'Priority support & advanced tools',
        isMostPopular: true,
      );
    } else if (name.toLowerCase().contains('growth') || index == 2) {
      return _PlanMetadata(
        icon: Icons.trending_up_rounded,
        description: 'Enterprise features for large scales',
      );
    } else {
      return _PlanMetadata(
        icon: Icons.bolt_rounded,
        description: 'Basic features for personal circles',
      );
    }
  }
}

class _FormSectionHeader extends StatelessWidget {
  final String title;
  const _FormSectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _T.ink,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _PlanRadioTile extends StatelessWidget {
  final PlanModel plan;
  final _PlanMetadata metadata;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlanRadioTile({
    required this.plan,
    required this.metadata,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isSelected ? _T.brandLight : _T.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? primaryColor : _T.border,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(
                    0xff121212,
                  ).withValues(alpha: isSelected ? 0.08 : 0.02),
                  blurRadius: isSelected ? 20 : 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isSelected ? primaryColor : const Color(0xFFF3F4F6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    metadata.icon,
                    color: isSelected ? Colors.white : _T.inkMid,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.name,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _T.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        metadata.description,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: _T.inkMid,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '₹',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? primaryColor : _T.ink,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              plan.price,
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? primaryColor : _T.ink,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'PER\nMONTH',
                        textAlign: TextAlign.right,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: _T.inkLight,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (metadata.isMostPopular)
            Positioned(
              top: -14,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryColor, width: 1.5),
                  ),
                  child: Text(
                    'MOST POPULAR',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: primaryColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ModernField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool readOnly;

  const _ModernField({
    required this.controller,
    required this.label,
    required this.hint,
    this.prefixIcon,
    this.keyboardType,
    this.validator,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: _T.inkLight,
                letterSpacing: 0,
              ),
            ),
          ),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            readOnly: readOnly,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: readOnly ? _T.inkMid : _T.ink,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(
                fontSize: 15,
                color: _T.inkMid.withValues(alpha: 0.5),
              ),
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon, color: _T.inkLight, size: 20)
                  : null,
              suffixIcon: readOnly
                  ? Icon(
                      Icons.lock_outline_rounded,
                      color: _T.inkLight.withValues(alpha: 0.5),
                      size: 16,
                    )
                  : null,
              filled: true,
              fillColor: readOnly
                  ? const Color(0xFFF3F4F6).withValues(alpha: 0.4)
                  : const Color(0xFFF3F4F6).withValues(alpha: 0.7),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: readOnly
                    ? BorderSide.none
                    : BorderSide(color: primaryColor, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: _T.error, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? placeholder;
  final IconData? suffixIcon;
  final VoidCallback onTap;

  // Constructor with required initializers
  const _DatePickerField({
    required this.controller,
    required this.label,
    this.placeholder,
    this.suffixIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: _T.inkLight,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6).withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      controller.text.isEmpty
                          ? (placeholder ?? 'Select Date')
                          : controller.text,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: controller.text.isEmpty
                            ? _T.inkMid.withValues(alpha: 0.5)
                            : _T.ink,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    suffixIcon ?? Icons.calendar_month_outlined,
                    color: primaryColor,
                    size: 20,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModernDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final Function(String?) onChanged;

  const _ModernDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: _T.inkLight,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6).withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(24),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: _T.inkLight,
                ),
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: _T.ink,
                ),
                onChanged: onChanged,
                items: items
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernSubmitButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;
  const _ModernSubmitButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 64),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                'Create Group',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}

class _RetryCard extends StatelessWidget {
  final VoidCallback onRetry;
  const _RetryCard({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: TextButton(onPressed: onRetry, child: const Text('Retry')),
    );
  }
}
