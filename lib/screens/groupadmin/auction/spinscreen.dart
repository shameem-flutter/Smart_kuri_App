import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../models/groupadmin/auction/spin_auction_model.dart';
import '../../../providers/auction_provider.dart';
import '../../../providers/group_provider.dart';
import '../../../utilities/colors.dart';
import '../../../widgets/custom_error_widget.dart';

class SpinScreen extends ConsumerStatefulWidget {
  final int auctionId;
  const SpinScreen({super.key, required this.auctionId});

  @override
  ConsumerState<SpinScreen> createState() => _SpinScreenState();
}

class _SpinScreenState extends ConsumerState<SpinScreen> {
  final StreamController<int> _selectedController = StreamController<int>();
  bool _isSpinning = false;
  int? _winnerIndex;
  String? _winnerName;
  final AudioPlayer _tickPlayer = AudioPlayer();
  Timer? _tickTimer;

  // Vibrant color palette for the wheel slices
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
  void dispose() {
    _selectedController.close();
    _tickPlayer.dispose();
    _tickTimer?.cancel();
    super.dispose();
  }

  void _spin(List<EligibleMember> members) {
    if (_isSpinning || members.isEmpty) return;
    setState(() {
      _isSpinning = true;
      _winnerIndex = null;
      _winnerName = null;
    });

    final selected = Random().nextInt(members.length);
    _selectedController.add(selected);

    // Start tick sound during spin
    _startTickSound();

    // Approximate spin duration from FortuneWheel default (~5s)
    Future.delayed(const Duration(seconds: 5), () async {
      _stopTickSound();
      if (!mounted) return;

      // Call the assign-winner API
      try {
        final apiService = ref.read(apiServiceProvider);
        final result = await apiService.assignAuctionWinner(
          widget.auctionId,
          members[selected].id,
        );

        if (mounted) {
          final winnerData = result['winner'] as Map<String, dynamic>?;
          setState(() {
            _isSpinning = false;
            _winnerIndex = selected;
            _winnerName = winnerData?['name'] ?? members[selected].name;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isSpinning = false;
            _winnerIndex = selected;
            _winnerName = members[selected].name;
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
    });
  }

  void _startTickSound() {
    // Play a short tick sound repeatedly while the wheel is spinning
    _tickTimer = Timer.periodic(const Duration(milliseconds: 120), (_) async {
      try {
        await _tickPlayer.stop();
        // Use a system-like tick via a very short tone
        await _tickPlayer.play(AssetSource('sounds/tick.wav'), volume: 0.4);
      } catch (_) {
        // Silently ignore if audio fails (e.g., no asset)
      }
    });
  }

  void _stopTickSound() {
    _tickTimer?.cancel();
    _tickTimer = null;
    _tickPlayer.stop();
  }

  @override
  Widget build(BuildContext context) {
    final spinAsync = ref.watch(spinAuctionProvider(widget.auctionId));

    return Scaffold(
      backgroundColor: whiteColor,
      appBar: AppBar(
        backgroundColor: whiteColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1F2937),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Spin Auction',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1F2937),
          ),
        ),
        centerTitle: true,
      ),
      body: spinAsync.when(
        data: (data) => _buildSpinContent(data),
        loading: () =>
            Center(child: CircularProgressIndicator(color: primaryColor)),
        error: (err, _) => CustomErrorWidget(
          error: err.toString().replaceAll('Exception: ', ''),
          onRetry: () => ref.invalidate(spinAuctionProvider(widget.auctionId)),
        ),
      ),
    );
  }

  Widget _buildSpinContent(SpinAuctionResponse data) {
    final members = data.eligibleMembers;

    if (members.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
      );
    }

    // FortuneWheel requires at least 2 items
    if (members.length == 1) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E3165).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  data.group,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2E3165),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text('🎉', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text(
                'Only 1 eligible member',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Winner: ${members[0].name}',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Safety: FortuneWheel needs at least 2 items
    final wheelMembers = members.length < 2
        ? [...members, EligibleMember(id: -1, name: members.first.name)]
        : members;

    return Column(
      children: [
        const SizedBox(height: 16),
        // Group name badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF2E3165).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            data.group,
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2E3165),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${members.length} eligible members',
          style: GoogleFonts.dmSans(fontSize: 13, color: Colors.grey[600]),
        ),

        // Fortune Wheel
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: FortuneWheel(
              selected: _selectedController.stream,
              animateFirst: false,
              physics: CircularPanPhysics(
                duration: const Duration(seconds: 4),
                curve: Curves.decelerate,
              ),
              indicators: const [
                FortuneIndicator(
                  alignment: Alignment.topCenter,
                  child: TriangleIndicator(
                    color: Color(0xFF2E3165),
                    width: 30,
                    height: 30,
                  ),
                ),
              ],
              items: List.generate(wheelMembers.length, (i) {
                final color = _sliceColors[i % _sliceColors.length];
                return FortuneItem(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 24),
                    child: Text(
                      wheelMembers[i].name,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  style: FortuneItemStyle(
                    color: color,
                    borderColor: color.withValues(alpha: 0.7),
                    borderWidth: 2,
                  ),
                );
              }),
            ),
          ),
        ),

        // Winner announcement
        if (_winnerIndex != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🎉', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    'Winner: ${_winnerName ?? members[_winnerIndex!].name}',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('🎉', style: TextStyle(fontSize: 24)),
              ],
            ),
          ),

        const SizedBox(height: 24),

        // Spin button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSpinning ? null : () => _spin(wheelMembers),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF333385),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[400],
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: const Color(0xFF333385).withValues(alpha: 0.4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isSpinning)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  else ...[
                    const Text('🎯', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(
                      _winnerIndex != null ? 'Spin Again' : 'Spin',
                      style: GoogleFonts.dmSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}


