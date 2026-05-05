import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kuri_app/models/collector/collections_model.dart';
import 'package:kuri_app/providers/group_provider.dart';
import 'package:kuri_app/utilities/colors.dart'; // Assumes primaryColor is here
import 'package:kuri_app/models/groupadmin/assigned_member_model.dart';
import 'package:kuri_app/models/collector/handover_pending_model.dart';
import 'package:kuri_app/services/api_service.dart';
import 'package:kuri_app/widgets/custom_error_widget.dart';

// ─────────────────────────────────────────────
// Constants - Refined for Minimalism
// ─────────────────────────────────────────────

class _AppColors {
  static const bgWhite = Colors.white;
  static const surfaceGrey = Color(0xFFF9FAFB);
  static const borderGrey = Color(0xFFE5E7EB);
  static const textMain = Color(0xFF111827);
  static const textMuted = Color(0xFF6B7280);

  static const emerald = Color(0xFF10B981);
  static const amber = Color(0xFFF59E0B);
  static const indigo = Color(0xFF6366F1);
}

class _AppTextStyles {
  static TextStyle label() => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: _AppColors.textMuted,
    letterSpacing: 0.5,
  );

  static TextStyle heading() => GoogleFonts.poppins(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: _AppColors.textMain,
    letterSpacing: -0.5,
  );

  static TextStyle appBar() => GoogleFonts.poppins(
    color: _AppColors.textMain,
    fontWeight: FontWeight.w600,
    fontSize: 18,
  );

  static TextStyle body() => GoogleFonts.inter(
    color: _AppColors.textMain,
    fontWeight: FontWeight.w500,
    fontSize: 15,
  );

  static TextStyle hint() =>
      GoogleFonts.inter(color: _AppColors.textMuted, fontSize: 15);

  static TextStyle snackBar() =>
      GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500);

  static TextStyle submitButton() => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static TextStyle statTitle() => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: _AppColors.textMuted,
    letterSpacing: 0.5,
  );

  static TextStyle statAmount(Color color) => GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: color,
  );
}

// ─────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────

class _StatCardData {
  final String title;
  final String amount;
  final Color textColor;
  final Color accentColor;

  const _StatCardData({
    required this.title,
    required this.amount,
    required this.textColor,
    required this.accentColor,
  });
}

// ─────────────────────────────────────────────
// Main Screen
// ─────────────────────────────────────────────

class Addcollection extends ConsumerStatefulWidget {
  const Addcollection({super.key});

  @override
  ConsumerState<Addcollection> createState() => _AddcollectionState();
}

class _AddcollectionState extends ConsumerState<Addcollection> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();

  AssignedMember? _selectedMember;
  String _paymentMethod = 'UPI';
  bool _isLoading = false;

  static const _paymentMethods = ['UPI', 'Cash', 'Bank Transfer'];

  @override
  void initState() {
    super.initState();
    _dateCtrl.text = DateFormat('dd-MM-yyyy').format(DateTime.now());
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: primaryColor,
            onPrimary: Colors.white,
            onSurface: _AppColors.textMain,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _dateCtrl.text = DateFormat('dd-MM-yyyy').format(picked));
    }
  }

  Future<void> _onMemberChanged(AssignedMember? value, ApiService api) async {
    setState(() {
      _selectedMember = value;
      _amountCtrl.clear();
    });

    if (value == null) return;

    try {
      final history = await api.getMemberHistory(value.id);
      if (mounted && _selectedMember?.id == value.id) {
        setState(
          () => _amountCtrl.text = history.summary.monthlyAmount
              .toStringAsFixed(0),
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Failed to fetch amount: $e', isError: true);
      if (value.monthlyAmount > 0) {
        setState(
          () => _amountCtrl.text = value.monthlyAmount.toStringAsFixed(0),
        );
      }
    }
  }

  Future<void> _submitForm(ApiService api) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMember == null) {
      _showSnackBar('Please select a member', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await api.addCollectorCollection({
        'member': _selectedMember!.id,
        'amount': _amountCtrl.text.trim(),
        'paid_date': _dateCtrl.text,
        'payment_method': _paymentMethod,
      });

      if (!mounted) return;

      _showSnackBar(response['message'] ?? 'Collection added successfully');
      ref
        ..invalidate(collectorDashboardProvider)
        ..invalidate(pendingMembersProvider)
        ..invalidate(todayCollectionsProvider)
        ..read(collectorScreenIndexProvider.notifier).goTo(0);
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          e.toString().replaceAll('Exception: ', ''),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<_StatCardData> _buildDynamicStats(
    AsyncValue<CollectorCollectionsResponse> collectionsAsync,
  ) {
    return collectionsAsync.maybeWhen(
      data: (data) {
        double total = 0, received = 0, sent = 0, draft = 0;

        for (final group in data.groups) {
          total += group.totalCollector;
          received += group.totalAdmin;
          sent += group.pending;
          draft += group.notSent;
        }

        return [
          _StatCardData(
            title: 'TOTAL',
            amount: '₹${total.toStringAsFixed(0)}',
            textColor: _AppColors.textMain,
            accentColor: Colors.transparent,
          ),
          _StatCardData(
            title: 'RECEIVED',
            amount: '₹${received.toStringAsFixed(0)}',
            textColor: _AppColors.emerald,
            accentColor: _AppColors.emerald,
          ),
          _StatCardData(
            title: 'SENT',
            amount: '₹${sent.toStringAsFixed(0)}',
            textColor: _AppColors.amber,
            accentColor: _AppColors.amber,
          ),
          _StatCardData(
            title: 'DRAFT',
            amount: '₹${draft.toStringAsFixed(0)}',
            textColor: _AppColors.indigo,
            accentColor: _AppColors.indigo,
          ),
        ];
      },
      orElse: () => [
        const _StatCardData(
          title: 'TOTAL',
          amount: '₹0',
          textColor: _AppColors.textMain,
          accentColor: Colors.transparent,
        ),
        const _StatCardData(
          title: 'RECEIVED',
          amount: '₹0',
          textColor: _AppColors.emerald,
          accentColor: _AppColors.emerald,
        ),
        const _StatCardData(
          title: 'SENT',
          amount: '₹0',
          textColor: _AppColors.amber,
          accentColor: _AppColors.amber,
        ),
        const _StatCardData(
          title: 'DRAFT',
          amount: '₹0',
          textColor: _AppColors.indigo,
          accentColor: _AppColors.indigo,
        ),
      ],
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: _AppTextStyles.snackBar()),
        backgroundColor: isError ? Colors.red[500] : _AppColors.textMain,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Make status bar icons dark for the clean white background
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    final membersAsync = ref.watch(
      assignedMemberProvider(const {'page': 1, 'pageSize': 100}),
    );
    final collectionsAsync = ref.watch(collectorCollectionsProvider);
    final handoverPendingAsync = ref.watch(handoverPendingProvider);
    final api = ref.read(apiServiceProvider);

    final dynamicStatCards = _buildDynamicStats(collectionsAsync);

    return Scaffold(
      backgroundColor: _AppColors.bgWhite, // True flat white background
      appBar: _CollectionAppBar(
        onBack: () => ref.read(collectorScreenIndexProvider.notifier).goTo(0),
      ),
      body: SafeArea(
        child: membersAsync.when(
          loading: () => Center(
            child: CircularProgressIndicator(
              color: primaryColor,
              strokeWidth: 2,
            ),
          ),
          error: (err, _) => CustomErrorWidget(
            error: err.toString().replaceAll('Exception: ', ''),
            onRetry: () => ref.invalidate(
              assignedMemberProvider(const {'page': 1, 'pageSize': 100}),
            ),
          ),
          data: (data) => _CollectionFormBody(
            members: data.results,
            apiService: api,
            formKey: _formKey,
            amountCtrl: _amountCtrl,
            dateCtrl: _dateCtrl,
            selectedMember: _selectedMember,
            paymentMethod: _paymentMethod,
            paymentMethods: _paymentMethods,
            isLoading: _isLoading,
            statCards: dynamicStatCards,
            handoverPendingAsync: handoverPendingAsync,
            onMemberChanged: (v) => _onMemberChanged(v, api),
            onPaymentMethodChanged: (v) => setState(() => _paymentMethod = v!),
            onDateTap: _selectDate,
            onSubmit: () => _submitForm(api),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Minimal AppBar
// ─────────────────────────────────────────────

class _CollectionAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _CollectionAppBar({required this.onBack});
  final VoidCallback onBack;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: _AppColors.bgWhite,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: _AppColors.textMain,
          size: 20,
        ),
        onPressed: onBack,
      ),
      title: Text('New Collection', style: _AppTextStyles.appBar()),
    );
  }
}

// ─────────────────────────────────────────────
// Form Body
// ─────────────────────────────────────────────

class _CollectionFormBody extends StatelessWidget {
  const _CollectionFormBody({
    required this.members,
    required this.apiService,
    required this.formKey,
    required this.amountCtrl,
    required this.dateCtrl,
    required this.selectedMember,
    required this.paymentMethod,
    required this.paymentMethods,
    required this.isLoading,
    required this.statCards,
    required this.handoverPendingAsync,
    required this.onMemberChanged,
    required this.onPaymentMethodChanged,
    required this.onDateTap,
    required this.onSubmit,
  });

  final List<AssignedMember> members;
  final ApiService apiService;
  final GlobalKey<FormState> formKey;
  final TextEditingController amountCtrl;
  final TextEditingController dateCtrl;
  final AssignedMember? selectedMember;
  final String paymentMethod;
  final List<String> paymentMethods;
  final bool isLoading;
  final List<_StatCardData> statCards;
  final AsyncValue<HandoverPendingModel> handoverPendingAsync;
  final ValueChanged<AssignedMember?> onMemberChanged;
  final ValueChanged<String?> onPaymentMethodChanged;
  final VoidCallback onDateTap;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final bool showHandover = handoverPendingAsync.value?.showCard == true;

    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          _StatCardRow(cards: statCards),
          const SizedBox(height: 24),

          // ── Handover Pending Card ──────────────────────────────────────
          if (showHandover) ...[
            handoverPendingAsync.maybeWhen(
              data: (hp) => _HandoverPendingCard(hp: hp),
              orElse: () => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
          ],

          Text('Transaction Details', style: _AppTextStyles.heading()),
          const SizedBox(height: 24),

          _FieldLabel('MEMBER'),
          const SizedBox(height: 8),
          _MemberDropdown(
            members: members,
            selectedMember: selectedMember,
            onChanged: onMemberChanged,
          ),
          const SizedBox(height: 20),

          _FieldLabel('AMOUNT'),
          const SizedBox(height: 8),
          _AmountDropdown(amountCtrl: amountCtrl),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel('DATE'),
                    const SizedBox(height: 8),
                    _DateField(controller: dateCtrl, onTap: onDateTap),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel('METHOD'),
                    const SizedBox(height: 8),
                    _PaymentMethodDropdown(
                      value: paymentMethod,
                      methods: paymentMethods,
                      onChanged: onPaymentMethodChanged,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 48),
          _SubmitButton(isLoading: isLoading, onPressed: onSubmit),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Minimal Flat Stat Cards
// ─────────────────────────────────────────────

class _StatCardRow extends StatelessWidget {
  const _StatCardRow({required this.cards});
  final List<_StatCardData> cards;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.8,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) => _StatCard(data: cards[index]),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data});
  final _StatCardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: _AppColors.surfaceGrey,
        border: Border.all(color: _AppColors.borderGrey, width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: data.accentColor == Colors.transparent
                      ? _AppColors.textMuted
                      : data.accentColor,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  data.title,
                  style: _AppTextStyles.statTitle(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              data.amount,
              style: _AppTextStyles.statAmount(data.textColor),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Form Components & Inputs
// ─────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: _AppTextStyles.label());
  }
}

class _MemberDropdown extends StatelessWidget {
  const _MemberDropdown({
    required this.members,
    required this.selectedMember,
    required this.onChanged,
  });
  final List<AssignedMember> members;
  final AssignedMember? selectedMember;
  final ValueChanged<AssignedMember?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<AssignedMember>(
      initialValue: selectedMember,
      hint: Text('Select member...', style: _AppTextStyles.hint()),
      isExpanded: true,
      icon: const Icon(Icons.expand_more_rounded, color: _AppColors.textMuted),
      decoration: _buildInputDecoration(),
      items: members
          .map(
            (m) => DropdownMenuItem(
              value: m,
              child: Text(
                '${m.name} (${m.groupName})',
                style: _AppTextStyles.body(),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      validator: (v) => v == null ? 'Required' : null,
      onChanged: onChanged,
    );
  }
}

class _AmountDropdown extends StatelessWidget {
  const _AmountDropdown({required this.amountCtrl});
  final TextEditingController amountCtrl;

  @override
  Widget build(BuildContext context) {
    final hasAmount = amountCtrl.text.isNotEmpty;

    return DropdownButtonFormField<String>(
      initialValue: hasAmount ? amountCtrl.text : null,
      hint: Text('0.00', style: _AppTextStyles.hint()),
      isExpanded: true,
      icon: const Icon(Icons.expand_more_rounded, color: _AppColors.textMuted),
      decoration: _buildInputDecoration(
        prefixIcon: Icons.currency_rupee_rounded,
      ),
      items: hasAmount
          ? [
              DropdownMenuItem(
                value: amountCtrl.text,
                child: Text(
                  amountCtrl.text,
                  style: _AppTextStyles.body(),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]
          : [],
      onChanged: (_) {},
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Required';
        return null;
      },
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.controller, required this.onTap});
  final TextEditingController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      style: _AppTextStyles.body(),
      decoration: _buildInputDecoration(),
    );
  }
}

class _PaymentMethodDropdown extends StatelessWidget {
  const _PaymentMethodDropdown({
    required this.value,
    required this.methods,
    required this.onChanged,
  });
  final String value;
  final List<String> methods;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      icon: const Icon(Icons.expand_more_rounded, color: _AppColors.textMuted),
      decoration: _buildInputDecoration(),
      items: methods
          .map(
            (m) => DropdownMenuItem(
              value: m,
              child: Text(
                m,
                style: _AppTextStyles.body(),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

// ─────────────────────────────────────────────
// Submit Button
// ─────────────────────────────────────────────

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.isLoading, required this.onPressed});
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor, // Utilizes your brand color
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0, // Flat button
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text('Confirm Collection', style: _AppTextStyles.submitButton()),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Shared Input Decoration Factory
// ─────────────────────────────────────────────

InputDecoration _buildInputDecoration({IconData? prefixIcon}) {
  return InputDecoration(
    prefixIcon: prefixIcon != null
        ? Icon(prefixIcon, color: _AppColors.textMuted, size: 20)
        : null,
    filled: true,
    fillColor: _AppColors.surfaceGrey,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _AppColors.borderGrey, width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _AppColors.borderGrey, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: primaryColor, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.red.shade300, width: 1),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );
}

// ─────────────────────────────────────────────
// Handover Pending Card Widget
// ─────────────────────────────────────────────

class _HandoverPendingCard extends StatelessWidget {
  final HandoverPendingModel hp;
  const _HandoverPendingCard({required this.hp});

  String _currencyFmt(double v) => '₹${v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4776E6), Color(0xFF8E54E9)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4776E6).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.savings_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Handover Pending',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _currencyFmt(hp.handoverPending),
            style: GoogleFonts.poppins(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Amount to be sent to admin',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _HandoverStat(
                  label: 'Collected',
                  value: _currencyFmt(hp.totalCollected),
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                _HandoverStat(
                  label: 'Sent',
                  value: _currencyFmt(hp.totalSent),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HandoverStat extends StatelessWidget {
  final String label;
  final String value;
  const _HandoverStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
