import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../models/groupadmin/auction/spin_auction_model.dart';
import '../../../models/groupadmin/auction/auction_group_details_model.dart';
import '../../../providers/auction_provider.dart';
import '../../../providers/group_provider.dart';
import '../../../utilities/colors.dart';
import '../../../widgets/custom_error_widget.dart';

// ──────────────────────────────────────────────────────────────
// Custom Smooth Wheel Painter
// ──────────────────────────────────────────────────────────────

class _WheelPainter extends CustomPainter {
  final List<String> labels;
  final List<Color> colors;
  final double angleDeg; // current rotation in degrees

  _WheelPainter({
    required this.labels,
    required this.colors,
    required this.angleDeg,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;
    final count = labels.length;
    final sweepAngle = 2 * pi / count;
    final startAngle = (angleDeg * pi / 180) - pi / 2;

    final paint = Paint()..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 1.5;

    for (int i = 0; i < count; i++) {
      final sliceStart = startAngle + i * sweepAngle;

      // Slice fill
      paint.color = colors[i % colors.length];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        sliceStart,
        sweepAngle,
        true,
        paint,
      );

      // Slice border
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        sliceStart,
        sweepAngle,
        true,
        borderPaint,
      );

      // Draw text
      final textAngle = sliceStart + sweepAngle / 2;
      final textRadius = radius * 0.62;
      final tx = center.dx + textRadius * cos(textAngle);
      final ty = center.dy + textRadius * sin(textAngle);

      canvas.save();
      canvas.translate(tx, ty);
      canvas.rotate(textAngle + pi / 2);

      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
          ),
        ),
        textDirection: ui.TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: radius * 0.9);

      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }

    // Center circle
    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 22, centerPaint);

    final centerBorder = Paint()
      ..color = const Color(0xFF2E3165)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, 22, centerBorder);
  }

  @override
  bool shouldRepaint(_WheelPainter oldDelegate) =>
      oldDelegate.angleDeg != angleDeg || oldDelegate.labels != labels;
}

// ──────────────────────────────────────────────────────────────
// Spin Screen
// ──────────────────────────────────────────────────────────────

class SpinScreen extends ConsumerStatefulWidget {
  final int auctionId;
  final String groupId;
  final String? auctionDate; // null = no date set → block spin

  const SpinScreen({
    super.key,
    required this.auctionId,
    required this.groupId,
    this.auctionDate,
  });

  @override
  ConsumerState<SpinScreen> createState() => _SpinScreenState();
}

class _SpinScreenState extends ConsumerState<SpinScreen>
    with SingleTickerProviderStateMixin {
  // ── Animation ──────────────────────────────────────────
  late final AnimationController _controller;
  late Animation<double> _animation;

  double _currentAngle = 0; // in degrees
  double _targetAngle = 0;

  // ── State ──────────────────────────────────────────────
  bool _isSpinning = false;
  String? _winnerName;
  bool _autoAssigned = false;

  bool _isAutoDraw = true;
  bool _isSequential = false;
  int? _selectedManualMemberId;
  int _selectedSequentialMonth = 1;
  final Map<int, int> _sequentialAssignments = {}; // month -> memberId

  // ── Audio ──────────────────────────────────────────────
  final AudioPlayer _tickPlayer = AudioPlayer();
  Timer? _tickTimer;

  // ── Colours ─────────────────────────────────────────────
  static const List<Color> _sliceColors = [
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFFF43F5E),
    Color(0xFFF97316),
    Color(0xFF14B8A6),
    Color(0xFF06B6D4),
    Color(0xFF3B82F6),
    Color(0xFF10B981),
    Color(0xFFEAB308),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5500),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _tickPlayer.dispose();
    _tickTimer?.cancel();
    super.dispose();
  }

  void _spin(List<EligibleMember> members) {
    if (_isSpinning || members.isEmpty) return;

    // Pick a random winner
    final rng = Random();
    final winnerIdx = rng.nextInt(members.length);

    final sliceSize = 360.0 / members.length;

    // Spin at least 5 full rotations, then land on the winner slice center
    final winnerSliceCenter = winnerIdx * sliceSize + sliceSize / 2;
    final landingAngle = (270.0 - winnerSliceCenter) % 360;
    final extraSpins = 5 + rng.nextInt(3);
    _targetAngle =
        _currentAngle +
        extraSpins * 360 +
        ((landingAngle - _currentAngle) % 360);

    _animation = Tween<double>(
      begin: _currentAngle,
      end: _targetAngle,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart));

    setState(() {
      _isSpinning = true;
      _winnerName = null;
    });

    _startTickSound();
    _controller.reset();
    _controller.forward().then((_) {
      _stopTickSound();
      _currentAngle = _targetAngle % 360;
      if (!mounted) return;
      _assignWinnerAPI(members[winnerIdx]);
    });
  }

  Future<void> _assignWinnerAPI(EligibleMember member) async {
    if (!mounted) return;
    setState(() => _isSpinning = true);

    try {
      final apiService = ref.read(apiServiceProvider);
      final result = await apiService.assignAuctionWinner(
        widget.auctionId,
        member.id,
      );

      if (mounted) {
        final winnerData = result['winner'] as Map<String, dynamic>?;
        setState(() {
          _isSpinning = false;
          _winnerName = winnerData?['name'] ?? member.name;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Winner assigned successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSpinning = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to assign winner: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitManualAssignment(List<EligibleMember> members) async {
    if (_isSequential) {
      if (_sequentialAssignments.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please assign at least one member.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() => _isSpinning = true);
      try {
        final apiService = ref.read(apiServiceProvider);
        List<Map<String, int>> winners = [];
        _sequentialAssignments.forEach((month, memberId) {
          winners.add({'month': month, 'id': memberId});
        });

        await apiService.assignAllWinners(widget.auctionId, winners);

        if (mounted) {
          setState(() {
            _isSpinning = false;
            // Get the first assigned member name for display purposes if needed
            if (winners.isNotEmpty) {
              _winnerName = 'Sequential Assignment Complete';
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sequential assignment successful!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isSpinning = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to assign sequentially: $e'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      if (_selectedManualMemberId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a member first.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final member = members.firstWhere(
        (m) => m.id == _selectedManualMemberId!,
      );
      await _assignWinnerAPI(member);
    }
  }

  void _startTickSound() {
    _tickTimer = Timer.periodic(const Duration(milliseconds: 130), (_) async {
      try {
        await _tickPlayer.stop();
        await _tickPlayer.play(AssetSource('sounds/tick.wav'), volume: 0.3);
      } catch (_) {}
    });
  }

  void _stopTickSound() {
    _tickTimer?.cancel();
    _tickTimer = null;
    _tickPlayer.stop();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.auctionDate == null || widget.auctionDate!.isEmpty) {
      return _NoDateScreen();
    }

    final spinAsync = ref.watch(spinAuctionProvider(widget.auctionId));
    final groupDetailsAsync = ref.watch(
      auctionGroupDetailsProvider(widget.groupId),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1F2937),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Assign Winner',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1F2937),
          ),
        ),
        centerTitle: true,
      ),
      body: spinAsync.when(
        data: (data) {
          return groupDetailsAsync.when(
            data: (groupData) {
              // Date validation check
              final now = DateTime.now();
              final auctionDate = DateTime.tryParse(widget.auctionDate ?? '');
              bool isFuture = false;
              if (auctionDate != null) {
                final today = DateTime(now.year, now.month, now.day);
                final target = DateTime(
                  auctionDate.year,
                  auctionDate.month,
                  auctionDate.day,
                );
                if (target.isAfter(today)) isFuture = true;
              }

              if (data.eligibleMembers.length == 1 &&
                  _winnerName == null &&
                  !_isSpinning &&
                  !_autoAssigned &&
                  !isFuture) {
                _autoAssigned = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _assignWinnerAPI(data.eligibleMembers[0]);
                });
              }
              return _buildContent(data, groupData, isFuture);
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: Color(0xFF333385)),
            ),
            error: (err, _) => CustomErrorWidget(
              error: err.toString().replaceAll('Exception: ', ''),
              onRetry: () =>
                  ref.invalidate(auctionGroupDetailsProvider(widget.groupId)),
            ),
          );
        },
        loading: () =>
            Center(child: CircularProgressIndicator(color: primaryColor)),
        error: (err, _) => CustomErrorWidget(
          error: err.toString().replaceAll('Exception: ', ''),
          onRetry: () => ref.invalidate(spinAuctionProvider(widget.auctionId)),
        ),
      ),
    );
  }

  Widget _buildContent(
    SpinAuctionResponse data,
    AuctionGroupDetailsResponse groupData,
    bool isFuture,
  ) {
    final members = data.eligibleMembers;

    if (members.isEmpty) {
      return _EmptyMembersView();
    }

    if (members.length == 1 && !_isSequential) {
      return _SingleMemberView(
        groupName: data.group,
        memberName: _winnerName ?? members[0].name,
        isLoading: _isSpinning,
        winnerAssigned: _winnerName != null,
        isFuture: isFuture,
        onBack: () => Navigator.pop(context),
      );
    }

    List<int> unassignedMonths = [];
    for (var month in groupData.months) {
      if (month.auction == null || month.auction!.winner == null) {
        unassignedMonths.add(month.monthNo);
      }
    }

    if (!_isSequential && _winnerName != null) {
      return Center(
        child: SingleChildScrollView(
          child: AnimatedOpacity(
            opacity: 1.0,
            duration: const Duration(milliseconds: 600),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🎉', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  Text(
                    'Winner Assigned!',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _winnerName!,
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF6366F1),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Back to Auctions',
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
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

    return Column(
      children: [
        const SizedBox(height: 16),
        // Toggle Buttons
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (!_isSpinning) {
                      setState(() {
                        _isAutoDraw = true;
                        _isSequential = false;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _isAutoDraw
                          ? const Color(0xFF2E63F6)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      'Auto Draw',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _isAutoDraw ? Colors.white : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (!_isSpinning) {
                      setState(() {
                        _isAutoDraw = false;
                        if (unassignedMonths.isNotEmpty) {
                          _selectedSequentialMonth = unassignedMonths.first;
                        }
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: !_isAutoDraw
                          ? const Color(0xFF2E63F6)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      'Manual Pick',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: !_isAutoDraw ? Colors.white : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        if (_isAutoDraw) ...[
          // Auto Draw View
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (_, __) {
                  final angle = _controller.isAnimating
                      ? _animation.value
                      : _currentAngle;
                  return Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Center(
                        child: Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                const Color(0xFF6366F1).withValues(alpha: 0.08),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: CustomPaint(
                            painter: _WheelPainter(
                              labels: members.map((m) => m.name).toList(),
                              colors: _sliceColors,
                              angleDeg: angle,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        child: CustomPaint(
                          painter: _TrianglePainter(),
                          size: const Size(28, 32),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (isFuture)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Auction date is yet to come',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange[800],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_isSpinning || isFuture)
                    ? null
                    : () => _spin(members),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF333385),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 6,
                  shadowColor: const Color(0xFF333385).withValues(alpha: 0.4),
                ),
                child: _isSpinning
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🎯', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Text(
                            _winnerName != null ? 'Spin Again' : 'Spin',
                            style: GoogleFonts.dmSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ] else ...[
          // Manual Pick View
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Sequential Toggle
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isSequential = !_isSequential;
                        _selectedManualMemberId = null;
                        _sequentialAssignments.clear();
                        if (_isSequential && unassignedMonths.isNotEmpty) {
                          _selectedSequentialMonth = unassignedMonths.first;
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: _isSequential
                                  ? const Color(0xFFEA4335)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _isSequential
                                    ? const Color(0xFFEA4335)
                                    : Colors.grey[400]!,
                                width: 2,
                              ),
                            ),
                            child: _isSequential
                                ? const Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              'SEQUENTIAL ASSIGNMENT (FULL ROSTER)',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1F2937),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (_isSequential) ...[
                    // Sequential Month Selector
                    if (unassignedMonths.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'All months have winners assigned.',
                          style: GoogleFonts.dmSans(
                            color: Colors.green[800],
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else ...[
                      SizedBox(
                        height: 50,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: unassignedMonths.length,
                          itemBuilder: (context, index) {
                            final m = unassignedMonths[index];
                            final isSelected = m == _selectedSequentialMonth;
                            final hasAssignment = _sequentialAssignments
                                .containsKey(m);

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedSequentialMonth = m;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF6366F1)
                                      : hasAssignment
                                      ? const Color(0xFF10B981)
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '$m',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: (isSelected || hasAssignment)
                                        ? Colors.white
                                        : Colors.grey[600],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Select winner for Month $_selectedSequentialMonth',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6366F1),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ] else ...[
                    Text(
                      'Click a member to assign for current month',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6366F1),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Members Grid
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: members.map((member) {
                      bool isSelected = false;
                      bool isAssignedElsewhere = false;

                      if (_isSequential) {
                        isSelected =
                            _sequentialAssignments[_selectedSequentialMonth] ==
                            member.id;
                        isAssignedElsewhere =
                            _sequentialAssignments.containsValue(member.id) &&
                            !isSelected;
                      } else {
                        isSelected = _selectedManualMemberId == member.id;
                      }

                      return GestureDetector(
                        onTap: isAssignedElsewhere
                            ? null
                            : () {
                                setState(() {
                                  if (_isSequential) {
                                    if (isSelected) {
                                      _sequentialAssignments.remove(
                                        _selectedSequentialMonth,
                                      );
                                    } else {
                                      _sequentialAssignments[_selectedSequentialMonth] =
                                          member.id;
                                      // Auto-advance to next empty month
                                      int nextMonthIndex =
                                          unassignedMonths.indexOf(
                                            _selectedSequentialMonth,
                                          ) +
                                          1;
                                      if (nextMonthIndex <
                                          unassignedMonths.length) {
                                        int next =
                                            unassignedMonths[nextMonthIndex];
                                        if (!_sequentialAssignments.containsKey(
                                          next,
                                        )) {
                                          _selectedSequentialMonth = next;
                                        }
                                      }
                                    }
                                  } else {
                                    _selectedManualMemberId = isSelected
                                        ? null
                                        : member.id;
                                  }
                                });
                              },
                        child: Container(
                          width: (MediaQuery.of(context).size.width - 72) / 2,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF6366F1).withValues(alpha: 0.1)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF6366F1)
                                  : Colors.grey[200]!,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: [
                              if (!isSelected)
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                            ],
                          ),
                          child: Opacity(
                            opacity: isAssignedElsewhere ? 0.4 : 1.0,
                            child: Text(
                              member.name,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? const Color(0xFF6366F1)
                                    : const Color(0xFF1F2937),
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Submit Button
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSpinning
                    ? null
                    : () => _submitManualAssignment(members),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF333385),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSpinning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _isSequential
                            ? 'Confirm Assignment'
                            : 'Assign Selected',
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2E3165)
      ..style = PaintingStyle.fill;
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, shadow);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrianglePainter old) => false;
}

class _NoDateScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1F2937),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Assign Winner',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1F2937),
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.event_busy_rounded,
                  size: 56,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Auction Date Set',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Please set an auction date before assigning a winner.',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFF333385)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Go Back',
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF333385),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyMembersView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.people_outline_rounded,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No eligible members',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'There are no members eligible for this auction spin.',
              style: GoogleFonts.dmSans(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SingleMemberView extends StatelessWidget {
  final String groupName;
  final String memberName;
  final bool isLoading;
  final bool winnerAssigned;
  final bool isFuture;
  final VoidCallback onBack;
  const _SingleMemberView({
    required this.groupName,
    required this.memberName,
    required this.isLoading,
    required this.winnerAssigned,
    required this.isFuture,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF2E3165).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                groupName,
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2E3165),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            if (isLoading)
              const CircularProgressIndicator(color: Color(0xFF333385))
            else
              Text(isFuture ? '⏳' : '🎉', style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              isFuture
                  ? 'Waiting for Auction Date'
                  : (winnerAssigned ? 'Auction Closed' : 'Assigning winner...'),
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937),
              ),
              textAlign: TextAlign.center,
            ),
            if (isFuture) ...[
              const SizedBox(height: 8),
              Text(
                'You can only assign on or after the auction date.',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isFuture
                      ? [Colors.grey, Colors.blueGrey]
                      : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: (isFuture ? Colors.grey : const Color(0xFF6366F1))
                        .withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                isFuture
                    ? 'Eligible Member: $memberName'
                    : 'Winner: $memberName',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onBack,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Color(0xFF333385)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Back to Auctions',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333385),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
