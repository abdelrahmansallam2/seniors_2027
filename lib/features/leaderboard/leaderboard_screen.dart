import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:seniors_27/core/api/api_client.dart';
import 'package:seniors_27/core/api/api_exception.dart';
import 'package:seniors_27/core/constants/app_assets.dart';
import 'package:seniors_27/core/constants/app_colors.dart';
import 'package:seniors_27/features/app_shell/widgets/main_page_header.dart';
import 'package:seniors_27/features/seniors_directory/data/seniors_api_service.dart';
import 'package:seniors_27/features/seniors_directory/models/senior_student.dart';
import 'package:seniors_27/shared/widgets/retro_button.dart';
import 'package:seniors_27/shared/widgets/retro_card.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final _api = SeniorsApiService(ApiClient());
  List<SeniorStudent> _rankedSeniors = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await _api.getUsers(pageNumber: 1, pageSize: 100);
      final data = response.data;
      if (!mounted) return;
      final seniors = _parseSeniors(data);
      seniors.sort((a, b) => b.points.compareTo(a.points));
      setState(() {
        _rankedSeniors = seniors;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Something went wrong. Please try again.';
        _isLoading = false;
      });
    }
  }

  List<SeniorStudent> _parseSeniors(dynamic data) {
    if (data is List) {
      return data
          .map((item) => SeniorStudent.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    if (data is Map && data['items'] is List) {
      return (data['items'] as List)
          .map((item) => SeniorStudent.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const PageStorageKey('leaderboard_scroll'),
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 20),
      child: Column(
        children: [
          const MainPageHeader(
            title: 'Leaderboard',
            subtitle: 'All seniors ranked by points.',
          ),
          const SizedBox(height: 25),
          _buildBody(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 80),
          child: Text(
            'Loading...',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.muted,
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Column(
            children: [
              const Text(
                'Could not load leaderboard.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 100,
                child: RetroButton(
                  label: 'Retry',
                  height: 36,
                  onPressed: _loadData,
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_rankedSeniors.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 80),
          child: Column(
            children: [
              Icon(
                Icons.leaderboard_outlined,
                size: 48,
                color: AppColors.muted,
              ),
              SizedBox(height: 16),
              Text(
                'No seniors yet.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 8),
              Text(
                'The leaderboard will populate once users are added.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RetroCard(
      padding: EdgeInsets.zero,
      borderRadius: 4,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                SvgPicture.asset(AppAssets.trophyWinner, width: 72, height: 72),
                const SizedBox(height: 8),
                const Text(
                  'TOP SENIORS',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                ),
                const Text(
                  'CLASS OF 2027',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          for (var index = 0; index < _rankedSeniors.length; index++)
            _RankRow(rank: index + 1, senior: _rankedSeniors[index]),
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.rank, required this.senior});

  final int rank;
  final SeniorStudent senior;

  Widget _buildRankIcon() {
    if (rank <= 3) {
      final asset = switch (rank) {
        1 => AppAssets.icRank1,
        2 => AppAssets.icRank2,
        _ => AppAssets.icRank3,
      };
      return SvgPicture.asset(asset, width: 24, height: 24);
    }
    return Text(
      '$rank',
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w900,
        fontFamily: 'monospace',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTopThree = rank <= 3;
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.ink, width: 2)),
      ),
      child: Row(
        children: [
          SizedBox(width: 30, child: Center(child: _buildRankIcon())),
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: senior.photoUrl != null && senior.photoUrl!.isNotEmpty
                ? Image.network(
                    senior.photoUrl!,
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: rank.isEven ? AppColors.pink : AppColors.cyan,
                      ),
                    ),
                  )
                : Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: rank.isEven ? AppColors.pink : AppColors.cyan,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              senior.name.isNotEmpty ? senior.name : '—',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isTopThree ? FontWeight.w900 : FontWeight.w800,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isTopThree ? AppColors.yellow : AppColors.paper,
              border: Border.all(color: AppColors.ink, width: 1.5),
            ),
            child: Text(
              '${senior.points} PTS',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
