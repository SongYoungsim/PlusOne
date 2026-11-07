import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../models/app_settings.dart';
import '../models/proposal.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/logo_header.dart';

class AddProposalScreen extends ConsumerStatefulWidget {
  const AddProposalScreen({super.key});

  @override
  ConsumerState<AddProposalScreen> createState() => _AddProposalScreenState();
}

class _AddProposalScreenState extends ConsumerState<AddProposalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _problemController = TextEditingController();
  final _ideaController = TextEditingController();
  final _memoController = TextEditingController();

  DateTime _receivedDate = DateTime.now();
  ProposalCategory _category = ProposalCategory.production;
  ExecutionStatus _executionStatus = ExecutionStatus.suggestion;
  String? _image1Path;
  String? _image2Path;

  @override
  void dispose() {
    _titleController.dispose();
    _problemController.dispose();
    _ideaController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(int slot) async {
    final picker = ref.read(imagePickerProvider);
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;
    setState(() {
      if (slot == 1) {
        _image1Path = file.path;
      } else {
        _image2Path = file.path;
      }
    });
  }

  Future<void> _save(AppSettings settings) async {
    if (!_formKey.currentState!.validate()) return;

    final proposal = Proposal(
      id: ref.read(uuidProvider).v4(),
      title: _titleController.text.trim(),
      receivedDate: _receivedDate,
      category: _category,
      problem: _problemController.text.trim(),
      improvementIdea: _ideaController.text.trim(),
      employeeNumber: settings.employeeNumber,
      userName: settings.userName,
      email: settings.email,
      image1LocalPath: _image1Path,
      image2LocalPath: _image2Path,
      executionStatus: _executionStatus,
      adoptionStatus: AdoptionStatus.beforeStart,
      memo: _memoController.text.trim(),
      syncStatus: SyncStatus.pending,
    );

    await ref.read(proposalsProvider.notifier).addProposal(proposal);
    if (!mounted) return;

    _titleController.clear();
    _problemController.clear();
    _ideaController.clear();
    _memoController.clear();
    setState(() {
      _receivedDate = DateTime.now();
      _category = ProposalCategory.production;
      _executionStatus = ExecutionStatus.suggestion;
      _image1Path = null;
      _image2Path = null;
    });

    ref.read(currentTabProvider.notifier).state = 1;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('제안이 저장되었습니다. 내역에서 확인해주세요.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return SafeArea(
      child: settings.when(
        data: (value) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            const LogoHeader(
              title: '제안 등록',
              subtitle: '업무·현장에서 본 문제점과 개선 아이디어를 제안해주세요.',
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('기본 정보', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 6),
                        Text(
                          '필수 입력: 제목, 접수일, 카테고리, 문제점, 개선아이디어, 실행여부',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(labelText: '제목 *'),
                          validator: (value) =>
                              value == null || value.trim().isEmpty ? '제목을 입력해주세요.' : null,
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _receivedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() => _receivedDate = picked);
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: '접수일 *',
                              suffixIcon: Icon(Icons.calendar_today_outlined),
                            ),
                            child: Text(DateFormat('yyyy-MM-dd').format(_receivedDate)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<ProposalCategory>(
                          initialValue: _category,
                          decoration: const InputDecoration(labelText: '카테고리 *'),
                          items: ProposalCategory.values
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item,
                                  child: Text(item.label),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _category = value);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _problemController,
                          minLines: 4,
                          maxLines: 5,
                          decoration: const InputDecoration(labelText: '문제점 *'),
                          validator: (value) => value == null || value.trim().isEmpty
                              ? '문제점을 입력해주세요.'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _ideaController,
                          minLines: 4,
                          maxLines: 5,
                          decoration: const InputDecoration(labelText: '개선아이디어 *'),
                          validator: (value) => value == null || value.trim().isEmpty
                              ? '개선아이디어를 입력해주세요.'
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('첨부 및 처리 정보', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 6),
                        Text(
                          '선택 입력: 이미지, 메모',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 16),
                        _ImagePickerTile(
                          title: '이미지 1',
                          path: _image1Path,
                          onTap: () => _pickImage(1),
                        ),
                        const SizedBox(height: 16),
                        _ImagePickerTile(
                          title: '이미지 2',
                          path: _image2Path,
                          onTap: () => _pickImage(2),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<ExecutionStatus>(
                          initialValue: _executionStatus,
                          decoration: const InputDecoration(labelText: '실행여부'),
                          items: ExecutionStatus.values
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item,
                                  child: Text(item.label),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _executionStatus = value);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F5FB),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '채택여부',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSub,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                '시작전',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _memoController,
                          minLines: 3,
                          maxLines: 4,
                          decoration: const InputDecoration(labelText: '메모'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => _save(value),
                    child: const Text('저장'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value.notionToken.isEmpty || value.notionDatabaseId.isEmpty
                        ? '연동 정보가 없으면 로컬에 저장되고 동기화는 실패 상태로 표시됩니다.'
                        : '저장 후 외부 시스템 동기화를 자동으로 시도합니다.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('설정 정보를 불러오지 못했습니다.\n$error')),
      ),
    );
  }
}

class _ImagePickerTile extends StatelessWidget {
  const _ImagePickerTile({
    required this.title,
    required this.path,
    required this.onTap,
  });

  final String title;
  final String? path;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            height: 140,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F5FB),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.border),
              image: path == null
                  ? null
                  : DecorationImage(
                      image: FileImage(File(path!)),
                      fit: BoxFit.cover,
                    ),
            ),
            child: path == null
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined, color: AppTheme.textSub),
                      SizedBox(height: 8),
                      Text('사진 추가', style: TextStyle(color: AppTheme.textSub)),
                    ],
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
