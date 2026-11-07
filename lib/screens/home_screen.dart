import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/proposal.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/logo_header.dart';
import '../widgets/status_badge.dart';
import 'proposal_detail_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proposals = ref.watch(filteredProposalsProvider);
    final filter = ref.watch(selectedCategoryFilterProvider);
    final now = DateTime.now();
    final monthly = proposals.where((item) {
      return item.receivedDate.year == now.year && item.receivedDate.month == now.month;
    }).toList();
    final failedCount = monthly.where((item) => item.syncStatus == SyncStatus.failed).length;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          try {
            await ref.read(proposalsProvider.notifier).refreshFromRemote();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('내역을 새로고침했습니다. 운영자 변경사항을 반영했어요.')),
              );
            }
          } catch (error) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('새로고침 실패: $error')),
              );
            }
          }
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Row(
              children: [
                const Expanded(
                  child: LogoHeader(
                    title: '제안 내역',
                    subtitle: '최근 날짜순으로 정렬됩니다.',
                  ),
                ),
                IconButton(
                  tooltip: '새로고침',
                  onPressed: () async {
                    try {
                      await ref.read(proposalsProvider.notifier).refreshFromRemote();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('내역을 새로고침했습니다.')),
                        );
                      }
                    } catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('새로고침 실패: $error')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 20),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('조회 조건', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ProposalCategory?>(
                    initialValue: filter,
                    decoration: const InputDecoration(labelText: '카테고리'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('전체')),
                      ...ProposalCategory.values.map(
                        (item) => DropdownMenuItem(value: item, child: Text(item.label)),
                      ),
                    ],
                    onChanged: (value) {
                      ref.read(selectedCategoryFilterProvider.notifier).state = value;
                    },
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    color: AppTheme.primaryBlue,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '이번달 제안 건수',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${monthly.length}건',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$failedCount건의 동기화 실패',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '아래로 당기거나 새로고침 버튼을 누르면 Notion 운영 상태를 다시 가져옵니다.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  if (proposals.isEmpty)
                    const _EmptyState()
                  else
                    ...proposals.map(
                      (proposal) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ProposalListItem(proposal: proposal),
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
}

class _ProposalListItem extends StatelessWidget {
  const _ProposalListItem({required this.proposal});

  final Proposal proposal;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProposalDetailScreen(proposalId: proposal.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(proposal.title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  StatusBadge(
                    label: proposal.category.label,
                    foreground: AppTheme.primaryBlue,
                    background: const Color(0xFFE8EFFF),
                  ),
                  StatusBadge(
                    label: proposal.syncStatus.label,
                    foreground: proposal.syncStatus == SyncStatus.failed
                        ? const Color(0xFFE96B2C)
                        : const Color(0xFF3D9140),
                    background: proposal.syncStatus == SyncStatus.failed
                        ? const Color(0xFFFFEBDC)
                        : const Color(0xFFE8F6E9),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                DateFormat('yyyy-MM-dd').format(proposal.receivedDate),
                style: const TextStyle(color: AppTheme.textSub),
              ),
              const SizedBox(height: 8),
              Text(
                proposal.adoptionStatus.label,
                style: const TextStyle(color: AppTheme.textSub, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Image.asset('GUI/logo.png', width: 88),
          const SizedBox(height: 16),
          Text(
            '등록된 제안이 없습니다.',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            '하단의 제안입력 탭에서 첫 제안을 등록해보세요.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSub),
          ),
        ],
      ),
    );
  }
}
