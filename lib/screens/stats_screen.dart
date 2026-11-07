import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/logo_header.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(monthlyStatsProvider(_month));

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const LogoHeader(
            title: '월별 통계',
            subtitle: '최근 날짜순으로 정리됩니다.',
          ),
          const SizedBox(height: 20),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F5FB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _month = DateTime(_month.year, _month.month - 1);
                          });
                        },
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            DateFormat('yyyy년 M월').format(_month),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _month = DateTime(_month.year, _month.month + 1);
                          });
                        },
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _StatsTile(title: '총 등록', value: stats.totalCount),
                    _StatsTile(title: '채택', value: stats.adoptedCount),
                    _StatsTile(title: '실행 완료', value: stats.completedCount),
                    _StatsTile(title: '동기화 실패', value: stats.failedCount),
                  ],
                ),
                const SizedBox(height: 16),
                AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('카테고리 분포', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      ...stats.categoryCounts.entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              SizedBox(width: 42, child: Text(entry.key)),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: LinearProgressIndicator(
                                    minHeight: 8,
                                    value: stats.totalCount == 0
                                        ? 0
                                        : entry.value / stats.totalCount,
                                    backgroundColor: const Color(0xFFF0F3F8),
                                    color: AppTheme.primaryBlue,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text('${entry.value}건'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsTile extends StatelessWidget {
  const _StatsTile({
    required this.title,
    required this.value,
  });

  final String title;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const Spacer(),
          Text(
            '$value건',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
