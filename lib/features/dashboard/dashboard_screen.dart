import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:seniors_27/core/api/api_client.dart';
import 'package:seniors_27/core/api/api_exception.dart';
import 'package:seniors_27/core/constants/app_assets.dart';
import 'package:seniors_27/core/constants/app_colors.dart';
import 'package:seniors_27/features/app_shell/widgets/main_page_header.dart';
import 'package:seniors_27/features/dashboard/data/daily_highlights_api_service.dart';
import 'package:seniors_27/features/dashboard/data/dashboard_api_service.dart';
import 'package:seniors_27/features/dashboard/models/announcement.dart';
import 'package:seniors_27/features/dashboard/models/daily_highlight.dart';
import 'package:seniors_27/features/dashboard/models/event.dart';
import 'package:seniors_27/features/dashboard/widgets/announcement_card.dart';
import 'package:seniors_27/features/dashboard/widgets/challenge_poll_announcement_card.dart';
import 'package:seniors_27/features/dashboard/widgets/challenge_preview_card.dart';
import 'package:seniors_27/features/dashboard/widgets/challenges_empty_state.dart';
import 'package:seniors_27/features/dashboard/widgets/countdown_board_row.dart';
import 'package:seniors_27/features/dashboard/widgets/dashboard_upload_placeholder.dart';
import 'package:seniors_27/features/dashboard/widgets/event_card.dart';
import 'package:seniors_27/features/dashboard/widgets/events_empty_state.dart';
import 'package:seniors_27/shared/widgets/add_memory_sheet.dart';
import 'package:seniors_27/shared/widgets/app_logo.dart';
import 'package:seniors_27/shared/widgets/retro_button.dart';
import 'package:seniors_27/shared/widgets/retro_card.dart';
import 'package:seniors_27/shared/widgets/retro_section_header.dart';
import 'package:seniors_27/shared/widgets/retro_sticker.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    required this.onOpenNotes,
    this.apiService,
    super.key,
  });

  final VoidCallback onOpenNotes;
  final DashboardApiService? apiService;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final DashboardApiService _api =
      widget.apiService ?? DashboardApiService(ApiClient());
  late final DailyHighlightsApiService _highlightsApi =
      DailyHighlightsApiService(ApiClient());

  List<Announcement> _announcements = [];
  List<Event> _events = [];
  List<DailyHighlight> _highlights = [];
  bool _isLoading = true;
  bool _highlightsLoading = true;
  String? _error;
  String? _highlightsError;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _highlightsLoading = true;
      _error = null;
      _highlightsError = null;
    });
    try {
      final results = await Future.wait([
        _api.getAnnouncements(),
        _api.getEvents(),
        _highlightsApi.getActive(),
      ]);
      final announcementsData = results[0].data;
      final eventsData = results[1].data;
      final highlightsData = results[2].data;
      if (!mounted) return;
      setState(() {
        _announcements = _parseAnnouncements(announcementsData);
        _events = _parseEvents(eventsData);
        _highlights = _parseHighlights(highlightsData);
        _isLoading = false;
        _highlightsLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _highlightsError = e.message;
        _isLoading = false;
        _highlightsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Something went wrong. Please try again.';
        _highlightsError = 'Something went wrong. Please try again.';
        _isLoading = false;
        _highlightsLoading = false;
      });
    }
  }

  List<Announcement> _parseAnnouncements(dynamic data) {
    if (data is List) {
      return data
          .map((item) => Announcement.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  List<Event> _parseEvents(dynamic data) {
    if (data is List) {
      return data
          .map((item) => Event.fromJson(item as Map<String, dynamic>))
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

  Future<void> _handleAddHighlight(String filePath, String? description) async {
    await _highlightsApi.upload(filePath: filePath, description: description);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Highlight submitted.')));
      _loadHighlights();
    }
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const PageStorageKey('dashboard_scroll'),
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
                onAddToday: () => AddMemorySheet.show(
                  context,
                  onMemorySubmitted: _handleAddHighlight,
                ),
                onRetry: _loadData,
              ),
              const SizedBox(height: 26),
              _buildAnnouncementsSection(),
              const SizedBox(height: 26),
              _buildUpcomingEventsSection(),
              const SizedBox(height: 26),
              const _ChallengesPreviewSection(),
            ],
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
    return _AnnouncementsSection(announcements: _announcements);
  }

  Widget _buildUpcomingEventsSection() {
    if (_isLoading) {
      return _buildLoadingSection('UPCOMING_EVENTS', AppColors.orange);
    }
    if (_error != null) {
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
              onPressed: _loadData,
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
                    child: const Text(
                      'REMEMBERED',
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
    required this.onRetry,
  });

  final List<DailyHighlight> highlights;
  final bool isLoading;
  final String? error;
  final VoidCallback onAddToday;
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
          _buildContent(context),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: DashboardUploadPlaceholder(),
      );
    }

    if (error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const Text(
              'Could not load highlights.',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 80,
              child: RetroButton(
                label: 'Retry',
                height: 28,
                onPressed: onRetry,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 9,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (highlights.isEmpty) {
      return Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: DashboardUploadPlaceholder(),
          ),
          const SizedBox(height: 10),
          const Text(
            'click to open memories',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 0, 18, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Latest by admin',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: AppColors.muted,
                  ),
                ),
                Text(
                  'Today',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        height: 170,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: highlights.length,
          separatorBuilder: (context, index) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final h = highlights[index];
            return _HighlightPolaroid(highlight: h);
          },
        ),
      ),
    );
  }
}

class _HighlightPolaroid extends StatelessWidget {
  const _HighlightPolaroid({required this.highlight});

  final DailyHighlight highlight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 30),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: AppColors.ink, width: 2.5),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.ink,
                    offset: Offset(4, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFEEEEEE),
                  border: Border.all(color: AppColors.ink, width: 1.2),
                ),
                child: Center(
                  child: Text(
                    _formatAuthor(highlight.authorName),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 7,
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            highlight.date,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 7,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAuthor(String name) {
    if (name.isEmpty) return 'Today\'s memory';
    return name;
  }
}

class _AnnouncementsSection extends StatelessWidget {
  const _AnnouncementsSection({required this.announcements});

  final List<Announcement> announcements;

  @override
  Widget build(BuildContext context) {
    return RetroCard(
      padding: EdgeInsets.zero,
      backgroundColor: AppColors.paper,
      child: Column(
        children: [
          const RetroSectionHeader(
            title: 'ANNOUNCEMENTS',
            backgroundColor: AppColors.magenta,
          ),
          const SizedBox(height: 12),
          const _AdminBadge(color: AppColors.pink),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: announcements.isEmpty
                ? const _AnnouncementsEmptyState()
                : Column(
                    children: announcements.map((announcement) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildAnnouncementCard(announcement),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard(Announcement announcement) {
    switch (announcement.type) {
      case AnnouncementType.challengePoll:
      case AnnouncementType.poll:
        return ChallengePollAnnouncementCard(
          announcement: announcement,
          onOptionTap: (id) {
            debugPrint('Tapped poll option: $id');
          },
          onWhoVotedTap: (id) {
            debugPrint('Who voted for option: $id');
          },
        );

      case AnnouncementType.normalAnnouncement:
      case AnnouncementType.event:
      case AnnouncementType.memoryHighlight:
        return AnnouncementCard(announcement: announcement);
    }
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

  @override
  Widget build(BuildContext context) {
    return RetroCard(
      padding: EdgeInsets.zero,
      backgroundColor: AppColors.paper,
      child: Column(
        children: [
          const RetroSectionHeader(
            title: 'UPCOMING_EVENTS',
            backgroundColor: AppColors.orange,
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: CountdownBoardRow(count: events.length),
          ),
          const SizedBox(height: 12),
          if (events.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: EventsEmptyState(),
            )
          else
            ...events.map(
              (event) => Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                child: EventCard(
                  title: event.title,
                  description: event.description,
                  date: event.date,
                ),
              ),
            ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}

class _ChallengesPreviewSection extends StatelessWidget {
  const _ChallengesPreviewSection();

  @override
  Widget build(BuildContext context) {
    // Backend-ready placeholder list
    final challenges = [];

    return RetroCard(
      padding: EdgeInsets.zero,
      backgroundColor: AppColors.paper,
      child: Column(
        children: [
          const RetroSectionHeader(
            title: 'TOP_CHALLENGES',
            backgroundColor: AppColors.yellow,
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: challenges.isEmpty
                ? const ChallengesEmptyState()
                : Column(
                    children: [
                      ...challenges.asMap().entries.map((entry) {
                        final i = entry.key;
                        final challenge = entry.value;
                        return ChallengePreviewCard(
                          index: i + 1,
                          title: challenge['title'] ?? '',
                          votes: challenge['votes'] ?? 0,
                        );
                      }),
                    ],
                  ),
          ),
          const SizedBox(height: 10),
          if (challenges.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              child: RetroButton(
                label: 'VIEW ALL CHALLENGES',
                height: 40,
                onPressed: () {},
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          if (challenges.isEmpty) const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _AdminBadge extends StatelessWidget {
  const _AdminBadge({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.ink, width: 2),
        boxShadow: const [
          BoxShadow(color: AppColors.ink, offset: Offset(4, 4), blurRadius: 0),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.campaign_outlined, size: 16, color: AppColors.ink),
          SizedBox(width: 8),
          Text(
            'Fresh from admin',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
