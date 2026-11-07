import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/proposal.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/status_badge.dart';

class ProposalDetailScreen extends ConsumerWidget {
  const ProposalDetailScreen({
    super.key,
    required this.proposalId,
  });

  final String proposalId;

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('제안을 삭제할까요?'),
          content: const Text(
            '삭제하면 앱에서 제거되고, 동기화된 제안은 Notion DB에도 반영됩니다.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFC63D2F),
              ),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Color _syncForeground(SyncStatus status) {
    switch (status) {
      case SyncStatus.failed:
        return const Color(0xFFE96B2C);
      case SyncStatus.pending:
        return const Color(0xFF8A6D1F);
      case SyncStatus.synced:
        return const Color(0xFF3D9140);
    }
  }

  Color _syncBackground(SyncStatus status) {
    switch (status) {
      case SyncStatus.failed:
        return const Color(0xFFFFEBDC);
      case SyncStatus.pending:
        return const Color(0xFFFFF4D6);
      case SyncStatus.synced:
        return const Color(0xFFE8F6E9);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(proposalsProvider);
    Proposal? proposal;
    for (final item in items) {
      if (item.id == proposalId) proposal = item;
    }
    proposal ??= ref.read(proposalsProvider.notifier).getById(proposalId);

    if (proposal == null) {
      return const Scaffold(
        body: SafeArea(
          child: Center(
            child: Text('제안 정보를 찾을 수 없습니다.'),
          ),
        ),
      );
    }
    final currentProposal = proposal;

    return Scaffold(
      appBar: AppBar(title: const Text('제안 상세')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          AppCard(
            color: AppTheme.primaryBlue,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentProposal.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  DateFormat('yyyy-MM-dd').format(currentProposal.receivedDate),
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '상세 정보',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    StatusBadge(
                      label: currentProposal.syncStatus.label,
                      foreground: _syncForeground(currentProposal.syncStatus),
                      background: _syncBackground(currentProposal.syncStatus),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _InfoRow(label: '제목', value: currentProposal.title),
                _InfoRow(
                  label: '접수일',
                  value: DateFormat('yyyy-MM-dd').format(currentProposal.receivedDate),
                ),
                _InfoRow(label: '카테고리', value: currentProposal.category.label),
                _InfoRow(label: '문제점', value: currentProposal.problem),
                _InfoRow(label: '개선 내용', value: currentProposal.improvementIdea),
                _InfoRow(label: '실행 여부', value: currentProposal.executionStatus.label),
                _InfoRow(label: '채택 여부', value: currentProposal.adoptionStatus.label),
                if (currentProposal.syncErrorMessage?.isNotEmpty == true)
                  _InfoRow(label: '오류', value: currentProposal.syncErrorMessage!),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _DetailImageCard(title: '이미지 1', path: currentProposal.image1LocalPath),
          const SizedBox(height: 16),
          _DetailImageCard(title: '이미지 2', path: currentProposal.image2LocalPath),
          const SizedBox(height: 16),
          if (currentProposal.syncStatus == SyncStatus.failed)
            OutlinedButton.icon(
              onPressed: () async {
                await ref.read(proposalsProvider.notifier).retrySync(currentProposal.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('동기화 재시도를 요청했습니다.')),
                  );
                }
              },
              icon: const Icon(Icons.sync),
              label: const Text('동기화 재시도'),
            ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () async {
              final confirmed = await _confirmDelete(context);
              if (!confirmed) return;

              try {
                await ref.read(proposalsProvider.notifier).deleteProposal(currentProposal.id);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('제안을 삭제했습니다.')),
                  );
                }
              } catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('삭제 실패: $error')),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC63D2F),
            ),
            icon: const Icon(Icons.delete),
            label: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 74,
            child: Text(label, style: const TextStyle(color: AppTheme.textSub)),
          ),
          Expanded(
            child: Text(value.isEmpty ? '-' : value),
          ),
        ],
      ),
    );
  }
}

class _DetailImageCard extends StatelessWidget {
  const _DetailImageCard({
    required this.title,
    required this.path,
  });

  final String title;
  final String? path;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F5FB),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.border),
              image: path == null || path!.isEmpty
                  ? null
                  : DecorationImage(
                      image: FileImage(File(path!)),
                      fit: BoxFit.cover,
                    ),
            ),
            child: path == null || path!.isEmpty
                ? const Center(child: Text('첨부된 이미지가 없습니다.'))
                : null,
          ),
        ],
      ),
    );
  }
}
