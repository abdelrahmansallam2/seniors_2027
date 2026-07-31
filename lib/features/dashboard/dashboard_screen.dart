import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:seniors_27/core/api/api_client.dart';
import 'package:seniors_27/core/api/api_exception.dart';
import 'package:seniors_27/core/constants/app_assets.dart';
import 'package:seniors_27/core/constants/app_colors.dart';
import 'package:seniors_27/core/utils/app_log.dart';
import 'package:seniors_27/features/app_shell/widgets/main_page_header.dart';
import 'package:seniors_27/features/dashboard/data/daily_highlights_api_service.dart';
import 'package:seniors_27/features/dashboard/data/dashboard_api_service.dart';
import 'package:seniors_27/features/dashboard/models/announcement.dart';
import 'package:seniors_27/features/dashboard/models/daily_highlight.dart';
import 'package:seniors_27/features/dashboard/models/event.dart';
import 'package:seniors_27/features/dashboard/widgets/announcement_card.dart';

import 'package:seniors_27/features/dashboard/widgets/countdown_board_row.dart';
import 'package:seniors_27/features/dashboard/widgets/event_card.dart';
import 'package:seniors_27/features/dashboard/widgets/events_empty_state.dart';
import 'package:seniors_27/features/dashboard/add_highlight_sheet.dart';
import 'package:seniors_27/features/dashboard/daily_highlights_book_screen.dart';
import 'package:seniors_27/shared/widgets/app_logo.dart';
import 'package:seniors_27/shared/widgets/retro_button.dart';
import 'package:seniors_27/shared/widgets/retro_card.dart';
import 'package:seniors_27/shared/widgets/retro_section_header.dart';
import 'package:seniors_27/shared/widgets/retro_sticker.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    required this.onOpenNotes,
    this.apiService,
    this.highlightsApiService,
    this.registerRefresh,
    this.onRefreshSuccess,
    super.key,
  });

  final VoidCallback onOpenNotes;
  final DashboardApiService? apiService;
  final DailyHighlightsApiService? highlightsApiService;
  final void Function(Future<void> Function({bool force}) refresh)?
  registerRefresh;
  final VoidCallback? onRefreshSuccess;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final DashboardApiService _api =
      widget.apiService ?? DashboardApiService(ApiClient());
  late final DailyHighlightsApiService _highlightsApi =
      widget.highlightsApiService ?? DailyHighlightsApiService(ApiClient());

  List<Announcement> _announcements = [];
  List<Event> _events = [];
  List<DailyHighlight> _highlights = [];
  bool _isLoading = true;
  bool _eventsLoading = true;
  bool _highlightsLoading = true;
  String? _error;
  String? _eventsError;
  String? _highlightsError;
  final Set<String> _votingAnnouncementIds = {};

  bool _dashboardRequestInFlight = false;
  DateTime? _lastSuccessfulLoad;
  int _dashboardRequestId = 0;
  int _announcementsVersion = 0;
  VoidCallback? _notifyRefreshSuccess;

  @override
  void initState() {
    super.initState();
    widget.registerRefresh?.call(refresh);
    _notifyRefreshSuccess = widget.onRefreshSuccess;
    _loadData(trigger: 'initial');
  }

  Future<void> refresh({bool force = true}) {
    return _loadData(forceRefresh: force, trigger: 'refresh');
  }

  Future<void> _loadData({
    bool forceRefresh = false,
    String trigger = 'unknown',
  }) async {
    if (_dashboardRequestInFlight) {
      appDebugLog('[Dashboard] blocked duplicate trigger=$trigger');
      return;
    }

    final isFresh =
        _lastSuccessfulLoad != null &&
        DateTime.now().difference(_lastSuccessfulLoad!) <
            const Duration(minutes: 1);

    if (!forceRefresh && isFresh) {
      appDebugLog('[Dashboard] using fresh state trigger=$trigger');
      return;
    }

    final requestId = ++_dashboardRequestId;
    _dashboardRequestInFlight = true;

    setState(() {
      _isLoading = _announcements.isEmpty;
      _eventsLoading = _events.isEmpty;
      _highlightsLoading = _highlights.isEmpty;
      _error = null;
      _eventsError = null;
      _highlightsError = null;
    });
    final announcementsVersionAtStart = _announcementsVersion;
    try {
      final announcements = await _api.getAnnouncements();
      if (!mounted || requestId != _dashboardRequestId) return;
      if (announcementsVersionAtStart == _announcementsVersion) {
        setState(() {
          _announcements = announcements;
          _isLoading = false;
          _lastSuccessfulLoad = DateTime.now();
        });
        _notifyRefreshSuccess?.call();
      }
    } on ApiException catch (e) {
      if (!mounted || requestId != _dashboardRequestId) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted || requestId != _dashboardRequestId) return;
      setState(() {
        _error = 'Something went wrong. Please try again.';
        _isLoading = false;
      });
    }
    try {
      final eventsResponse = await _api.getEvents();
      if (!mounted || requestId != _dashboardRequestId) return;
      setState(() {
        _events = _parseEvents(eventsResponse.data);
        _eventsLoading = false;
      });
    } catch (_) {
      if (!mounted || requestId != _dashboardRequestId) return;
      setState(() {
        _eventsError = 'Could not load upcoming events.';
        _eventsLoading = false;
      });
    }
    try {
      final highlightsResponse = await _highlightsApi.getActive();
      if (!mounted || requestId != _dashboardRequestId) return;
      setState(() {
        _highlights = _parseHighlights(highlightsResponse.data);
        _highlightsLoading = false;
      });
    } catch (_) {
      if (!mounted || requestId != _dashboardRequestId) return;
      setState(() {
        _highlightsError = 'Could not load highlights.';
        _highlightsLoading = false;
      });
    } finally {
      if (mounted && requestId == _dashboardRequestId) {
        _dashboardRequestInFlight = false;
      }
    }
  }

  List<Event> _parseEvents(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => Event.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }
    return [];
  }

  List<DailyHighlight> _parseHighlights(dynamic data) {
    if (data is List) {
      return data
          .map((item) => DailyHighlight.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<void> _handleAddHighlight({
    required String filePath,
    String? captionText,
    double? captionYPercent,
    List<int> mentionUserIds = const [],
  }) async {
    await _highlightsApi.upload(
      filePath: filePath,
      captionText: captionText,
      captionYPercent: captionYPercent,
      mentionUserIds: mentionUserIds,
    );
    if (!mounted) return;
    Navigator.pop(context);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Daily highlight added successfully.'),
        backgroundColor: AppColors.ink,
      ),
    );
    _loadHighlights();
  }

  void _openHighlightsBook({int initialIndex = 0}) {
    if (_highlights.isEmpty) return;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Daily Highlights Book',
      barrierColor: Colors.transparent,
      pageBuilder: (_, _, _) {
        return DailyHighlightsBookScreen(
          highlights: _highlights,
          onDashboardRefresh: _loadHighlights,
          initialIndex: initialIndex,
        );
      },
    );
  }

  Future<void> _loadHighlights() async {
    setState(() => _highlightsLoading = true);
    try {
      final response = await _highlightsApi.getActive();
      if (!mounted) return;
      setState(() {
        _highlights = _parseHighlights(response.data);
        _highlightsLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _highlightsLoading = false);
    }
  }

  Future<void> _handleVote(String announcementId, String optionLabel) async {
    if (_votingAnnouncementIds.contains(announcementId)) return;
    setState(() => _votingAnnouncementIds.add(announcementId));
    try {
      final updated = await _api.voteInPoll(announcementId, optionLabel);
      if (!mounted) return;
      setState(() {
        _announcementsVersion++;
        final index = _announcements.indexWhere((a) => a.id == announcementId);
        if (index >= 0) {
          _announcements = [
            for (var i = 0; i < _announcements.length; i++)
              if (i == index) updated else _announcements[i],
          ];
        }
        _votingAnnouncementIds.remove(announcementId);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _votingAnnouncementIds.remove(announcementId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: refresh,
      child: SingleChildScrollView(
        key: const PageStorageKey('dashboard_scroll'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(22, 30, 22, 110),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Stack(
                  clipBehavior: Clip.none,
                  children: [
                    MainPageHeader(
                      title: 'Dashboard',
                      subtitle: 'Your senior portal home.',
                    ),
                    Positioned(
                      top: 2,
                      right: 4,
                      child: RetroSticker(
                        color: AppColors.yellow,
                        width: 58,
                        height: 20,
                        angle: 0.12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const _DashboardHeroCard(),
                const SizedBox(height: 26),
                _DailyHighlightsSection(
                  highlights: _highlights,
                  isLoading: _highlightsLoading,
                  error: _highlightsError,
                  onAddToday: () => AddHighlightSheet.show(
                    context,
                    onHighlightSubmitted: _handleAddHighlight,
                  ),
                  onOpenBook: (index) =>
                      _openHighlightsBook(initialIndex: index),
                  onRetry: () =>
                      _loadData(forceRefresh: true, trigger: 'retry'),
                ),
                const SizedBox(height: 26),
                _buildAnnouncementsSection(),
                const SizedBox(height: 26),
                _buildUpcomingEventsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnnouncementsSection() {
    if (_isLoading) {
      return _buildLoadingSection('ANNOUNCEMENTS', AppColors.magenta);
    }
    if (_error != null) {
      return _buildErrorSection('ANNOUNCEMENTS', AppColors.magenta);
    }
    return _AnnouncementsSection(
      announcements: _announcements,
      votingAnnouncementIds: _votingAnnouncementIds,
      onVote: _handleVote,
    );
  }

  Widget _buildUpcomingEventsSection() {
    if (_eventsLoading) {
      return _buildLoadingSection('UPCOMING_EVENTS', AppColors.orange);
    }
    if (_eventsError != null) {
      return _buildErrorSection('UPCOMING_EVENTS', AppColors.orange);
    }
    return _UpcomingEventsSection(events: _events);
  }

  Widget _buildLoadingSection(String title, Color color) {
    return RetroCard(
      padding: EdgeInsets.zero,
      backgroundColor: AppColors.paper,
      child: Column(
        children: [
          RetroSectionHeader(title: title, backgroundColor: color),
          const SizedBox(height: 28),
          const Center(
            child: Text(
              'Loading...',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
              ),
            ),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  Widget _buildErrorSection(String title, Color color) {
    return RetroCard(
      padding: EdgeInsets.zero,
      backgroundColor: AppColors.paper,
      child: Column(
        children: [
          RetroSectionHeader(title: title, backgroundColor: color),
          const SizedBox(height: 14),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18),
            child: Text(
              'Could not load data.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 90,
            child: RetroButton(
              label: 'Retry',
              height: 32,
              onPressed: () => _loadData(forceRefresh: true, trigger: 'retry'),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}

class _DashboardHeroCard extends StatelessWidget {
  const _DashboardHeroCard();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        RetroCard(
          backgroundColor: AppColors.paper,
          padding: const EdgeInsets.fromLTRB(22, 40, 22, 40),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                const AppLogo(size: 170),
                const SizedBox(height: 22),
                const Text(
                  'BUILT TO BE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 16),
                Transform.rotate(
                  angle: -0.025,
                  child: Container(
                    width: 320,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.yellow,
                      border: Border.all(color: AppColors.ink, width: 3),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.ink,
                          offset: Offset(6, 6),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'REMEMBERED',
                        maxLines: 1,
                        softWrap: false,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 34,
                          height: 1,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 15,
          left: 15,
          child: Transform.rotate(
            angle: -0.16,
            child: SvgPicture.asset(
              AppAssets.seniorCardSticker,
              width: 90,
              height: 90,
            ),
          ),
        ),
        const Positioned(
          bottom: -10,
          right: 18,
          child: RetroSticker(
            color: AppColors.pink,
            width: 54,
            height: 18,
            angle: -0.12,
          ),
        ),
      ],
    );
  }
}

class _DailyHighlightsSection extends StatelessWidget {
  const _DailyHighlightsSection({
    required this.highlights,
    required this.isLoading,
    required this.error,
    required this.onAddToday,
    required this.onOpenBook,
    required this.onRetry,
  });

  final List<DailyHighlight> highlights;
  final bool isLoading;
  final String? error;
  final VoidCallback onAddToday;
  final void Function(int index) onOpenBook;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return RetroCard(
      padding: EdgeInsets.zero,
      backgroundColor: AppColors.paper,
      child: Column(
        children: [
          const RetroSectionHeader(
            title: 'DAILY_HIGHLIGHTS',
            backgroundColor: AppColors.green,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 132,
            child: RetroButton(
              label: 'ADD TODAY',
              height: 34,
              onPressed: onAddToday,
              textStyle: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 14),
          _buildBookCard(context),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildBookCard(BuildContext context) {
    final bool canOpen = !isLoading && error == null && highlights.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: canOpen ? () => onOpenBook(0) : null,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.paper,
            border: Border.all(color: AppColors.ink, width: 3),
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: AppColors.ink,
                offset: Offset(6, 7),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      "TODAY'S HIGHLIGHTS",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                        decoration: TextDecoration.none,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: canOpen ? () => onOpenBook(0) : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cyan,
                        border: Border.all(color: AppColors.ink, width: 2),
                      ),
                      child: const Text(
                        'OPEN BOOK',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          color: AppColors.ink,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildBookCenter(context),
              const SizedBox(height: 12),
              _buildBookBottom(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookCenter(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 100,
        child: Center(
          child: Text(
            'Loading highlights...',
            style: TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
              fontSize: 13,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      );
    }

    if (error != null) {
      return SizedBox(
        height: 100,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Could not load highlights.',
                style: TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: onRetry,
                child: const Text(
                  'TAP TO RETRY',
                  style: TextStyle(
                    color: AppColors.orange,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    fontSize: 11,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (highlights.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(
          child: Text(
            'No highlights yet.',
            style: TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
              fontSize: 13,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      );
    }

    final int count = highlights.length.clamp(0, 3);
    return SizedBox(
      height: 110,
      child: Center(
        child: SizedBox(
          width: 140,
          height: 110,
          child: Stack(
            alignment: Alignment.center,
            children: List.generate(count, (i) {
              final h = highlights[i];
              final int behindCount = count - 1 - i;
              final double dx = behindCount * -14.0;
              final double dy = behindCount * -6.0;
              final double rotation = behindCount.isEven ? 0.05 : -0.05;
              final double scale = 1.0 - behindCount * 0.03;

              return Transform.rotate(
                angle: rotation,
                child: Transform.scale(
                  scale: scale.clamp(0.8, 1.0),
                  child: Transform.translate(
                    offset: Offset(dx, dy),
                    child: Container(
                      width: 80,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.paper,
                        border: Border.all(color: AppColors.ink, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.ink,
                            offset: Offset(2, 2),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(3),
                      child: ClipRect(
                        child: Image.network(
                          h.photoUrl ?? '',
                          width: 74,
                          height: 94,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: AppColors.cyan,
                            alignment: Alignment.center,
                            child: const Text(
                              'PHOTO',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                                letterSpacing: 1.2,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildBookBottom() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Expanded(
          child: Text(
            'Tap to open the archive.',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.muted,
              decoration: TextDecoration.none,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (!isLoading && error == null)
          Text(
            'TOTAL: ${highlights.length}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              decoration: TextDecoration.none,
            ),
          ),
      ],
    );
  }
}

class _AnnouncementsSection extends StatelessWidget {
  const _AnnouncementsSection({
    required this.announcements,
    required this.votingAnnouncementIds,
    required this.onVote,
  });

  final List<Announcement> announcements;
  final Set<String> votingAnnouncementIds;
  final void Function(String announcementId, String optionLabel) onVote;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AnnouncementColors.paper,
        border: Border.all(color: AnnouncementColors.ink, width: 3),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: AnnouncementColors.ink,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AnnouncementColors.magenta,
              border: Border.all(color: AnnouncementColors.ink, width: 2),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: AnnouncementColors.ink,
                  offset: Offset(2, 2),
                  blurRadius: 0,
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.notifications_outlined,
                  size: 14,
                  color: AnnouncementColors.ink,
                ),
                SizedBox(width: 5),
                Text(
                  'ANNOUNCEMENTS',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AnnouncementColors.ink,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: _AdminBadge(count: announcements.length),
          ),
          const SizedBox(height: 8),
          announcements.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: const _AnnouncementsEmptyState(),
                )
              : Column(
                  children: announcements.map((announcement) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AnnouncementCard(
                        announcement: announcement,
                        isVoting: votingAnnouncementIds.contains(
                          announcement.id,
                        ),
                        onVote: (label) => onVote(announcement.id, label),
                        onWhoVoted: (option) =>
                            showPollVotersDialog(context, option),
                      ),
                    );
                  }).toList(),
                ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _AnnouncementsEmptyState extends StatelessWidget {
  const _AnnouncementsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.ink, width: 2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        children: [
          Icon(Icons.campaign_outlined, size: 30, color: AppColors.muted),
          SizedBox(height: 10),
          Text(
            'No announcements yet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: AppColors.muted,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Admin posts, events, and polls will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingEventsSection extends StatelessWidget {
  const _UpcomingEventsSection({required this.events});

  final List<Event> events;

  List<Event> get _sortedEvents {
    final sorted = List<Event>.from(events);
    sorted.sort((a, b) {
      if (a.eventDate == null && b.eventDate == null) return 0;
      if (a.eventDate == null) return 1;
      if (b.eventDate == null) return -1;
      return a.eventDate!.compareTo(b.eventDate!);
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final sorted = _sortedEvents;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.ink, width: 3),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: AppColors.ink, offset: Offset(6, 7), blurRadius: 0),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.orange,
              border: Border.all(color: AppColors.ink, width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'UPCOMING_EVENTS',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: CountdownBoardRow(count: sorted.length),
          ),
          const SizedBox(height: 12),
          if (sorted.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: EventsEmptyState(),
            )
          else
            ...sorted.map(
              (event) => Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                child: EventCard(event: event),
              ),
            ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}

class _AdminBadge extends StatelessWidget {
  const _AdminBadge({this.count = 0});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AnnouncementColors.paper,
        border: Border.all(color: AnnouncementColors.ink, width: 3),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: AnnouncementColors.ink,
            offset: Offset(6, 7),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AnnouncementColors.pinkBadge,
              border: Border.all(color: AnnouncementColors.ink, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.campaign_outlined,
                  size: 10,
                  color: AnnouncementColors.ink,
                ),
                SizedBox(width: 3),
                Text(
                  'FRESH FROM ADMIN',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AnnouncementColors.ink,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            '$count active post${count == 1 ? '' : 's'}',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AnnouncementColors.ink,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}
