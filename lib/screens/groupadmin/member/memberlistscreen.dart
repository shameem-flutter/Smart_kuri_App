import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kuri_app/utilities/gap_func.dart';
import '../../../models/groupadmin/member_list.dart';
import '../../../services/api_service.dart';
import '../../../services/storage_service.dart';
import 'createmember.dart';

class MemberListScreen extends StatefulWidget {
  const MemberListScreen({super.key});

  @override
  State<MemberListScreen> createState() => _MemberListScreenState();
}

class _MemberListScreenState extends State<MemberListScreen> {
  late final ApiService _apiService;

  bool _isLoading = true;
  String? _error;
  List<Member> _members = [];
  List<Member> _filteredMembers = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(storageService: StorageService());
    _loadMembers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredMembers = _members.where((member) {
        return member.name.toLowerCase().contains(query) ||
            member.email.toLowerCase().contains(query) ||
            member.phone.contains(query) ||
            member.groupName.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _loadMembers() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await _apiService.getMembers();
      setState(() {
        _members = response.results;
        _filteredMembers = response.results;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
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
        toolbarHeight: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              vertGap(10),
              _buildHeader(),
              const SizedBox(height: 24),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF2962FF),
                        ),
                      )
                    : _error != null
                    ? _buildErrorView()
                    : _buildMembersList(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateMemberScreen()),
          );
          _loadMembers(); // Refresh list on return
        },
        backgroundColor: const Color(0xFF2962FF),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Members',
                  style: GoogleFonts.poppins(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2B3A4A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage your group network',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF2962FF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_filteredMembers.length} Total',
                style: GoogleFonts.inter(
                  color: const Color(0xFF2962FF),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(100),
            ),
            child: TextField(
              controller: _searchController,
              textAlignVertical: TextAlignVertical.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: const Color(0xFF111827),
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: 'Search members...',
                hintStyle: GoogleFonts.inter(
                  color: const Color(0xFF9CA3AF),
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),

                prefixIconConstraints: const BoxConstraints(
                  minWidth: 46,
                  minHeight: 46,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF9CA3AF),
                  size: 20,
                ),

                suffixIconConstraints: const BoxConstraints(
                  minWidth: 46,
                  minHeight: 46,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          FocusScope.of(context).unfocus();
                        },

                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE5E7EB),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Color(0xFF6B7280),
                              size: 14,
                            ),
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Colors.red[400],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Oops! Something went wrong',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: const Color(0xFF2B3A4A),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _error ?? 'Unable to load members at this time.',
              style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadMembers,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2962FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            icon: const Icon(
              Icons.refresh_rounded,
              color: Colors.white,
              size: 18,
            ),
            label: Text(
              'Try Again',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersList() {
    if (_filteredMembers.isEmpty) {
      final isSearching = _searchController.text.isNotEmpty;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSearching
                    ? Icons.person_search_rounded
                    : Icons.people_outline_rounded,
                size: 48,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isSearching ? 'No match found' : 'No members yet',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2B3A4A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? 'We couldn\'t find anyone matching "${_searchController.text}"'
                  : 'Your member list is currently empty.',
              style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMembers,
      color: const Color(0xFF2962FF),
      child: ListView.separated(
        itemCount: _filteredMembers.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final member = _filteredMembers[index];
          return _buildMemberCard(member);
        },
      ),
    );
  }

  Widget _buildMemberCard(Member member) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2962FF).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      member.name.isNotEmpty
                          ? member.name.substring(0, 1).toUpperCase()
                          : '?',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF2962FF),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2B3A4A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.layers_rounded,
                            size: 12,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              member.groupName.isNotEmpty
                                  ? member.groupName
                                  : 'No Assigned Group',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: member.isActive
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    member.isActive ? 'ACTIVE' : 'INACTIVE',
                    style: GoogleFonts.inter(
                      color: member.isActive
                          ? Colors.green[700]
                          : Colors.red[700],
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1, color: Color(0xFFF0F0F0)),
            ),
            Row(
              children: [
                Expanded(
                  child: _buildContactItem(
                    icon: Icons.phone_rounded,
                    value: member.phone,
                  ),
                ),
                if (member.phone.isNotEmpty && member.email.isNotEmpty)
                  Container(
                    width: 1,
                    height: 24,
                    color: const Color(0xFFE0E0E0),
                  ),
                Expanded(
                  child: _buildContactItem(
                    icon: Icons.email_rounded,
                    value: member.email,
                    isRight: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String value,
    bool isRight = false,
  }) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(left: isRight ? 12 : 0, right: isRight ? 0 : 12),
      child: Row(
        mainAxisAlignment: isRight
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: Colors.grey[400]),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: isRight ? TextAlign.right : TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildEnhancedMemberCard(Member member) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: const Color(0xFFF0F4F8),
        width: 1.5,
      ), // Matches Group Card
      boxShadow: [
        BoxShadow(
          color: const Color(
            0xFF2962FF,
          ).withValues(alpha: 0.04), // Tinted shadow
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          // Tap card to view member full profile
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // --- Header Row ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2962FF).withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        member.name.isNotEmpty
                            ? member.name.substring(0, 1).toUpperCase()
                            : '?',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF2962FF),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Member Name & Group
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.name,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1D1E),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.people_outline_rounded,
                              size: 14,
                              color: const Color(0xFF8A94A6),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                member.groupName.isNotEmpty
                                    ? member.groupName
                                    : 'Unassigned',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: const Color(0xFF8A94A6),
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Clean Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: member.isActive
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: member.isActive
                                ? Colors.green[600]
                                : Colors.red[500],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          member.isActive ? 'Active' : 'Inactive',
                          style: GoogleFonts.inter(
                            color: member.isActive
                                ? Colors.green[700]
                                : Colors.red[700],
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1, color: Color(0xFFF0F4F8)),
              ),

              // --- Interactive Contact Chips ---
              Row(
                children: [
                  if (member.phone.isNotEmpty)
                    Expanded(
                      child: _buildContactChip(
                        icon: Icons.phone_outlined,
                        text: member.phone,
                        color: const Color(
                          0xFF2962FF,
                        ), // Primary blue for calling
                        onTap: () {
                          // Launch url_launcher to dial phone
                        },
                      ),
                    ),

                  if (member.phone.isNotEmpty && member.email.isNotEmpty)
                    const SizedBox(width: 12),

                  if (member.email.isNotEmpty)
                    Expanded(
                      child: _buildContactChip(
                        icon: Icons.email_outlined,
                        text:
                            'Email', // Simplified label to prevent layout breaks from long emails
                        color: const Color(
                          0xFF4A5568,
                        ), // Neutral grey for secondary action
                        onTap: () {
                          // Launch url_launcher to open email app
                        },
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _buildContactChip({
  required IconData icon,
  required String text,
  required Color color,
  required VoidCallback onTap,
}) {
  return Material(
    color: color.withValues(alpha: 0.08),
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                text,
                style: GoogleFonts.inter(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
