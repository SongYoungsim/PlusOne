import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../config/app_secrets.dart';
import '../models/app_settings.dart';
import '../providers/app_providers.dart';
import '../widgets/app_card.dart';
import '../widgets/logo_header.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _userFormKey = GlobalKey<FormState>();
  final _syncFormKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _employeeController;
  late final TextEditingController _emailController;
  late final TextEditingController _notionTokenController;
  late final TextEditingController _databaseController;
  late final TextEditingController _imgbbController;

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _employeeController = TextEditingController();
    _emailController = TextEditingController();
    _notionTokenController = TextEditingController();
    _databaseController = TextEditingController();
    _imgbbController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _employeeController.dispose();
    _emailController.dispose();
    _notionTokenController.dispose();
    _databaseController.dispose();
    _imgbbController.dispose();
    super.dispose();
  }

  void _bind(AppSettings settings) {
    if (_initialized) return;
    _initialized = true;
    _nameController.text = settings.userName;
    _employeeController.text = settings.employeeNumber;
    _emailController.text = settings.email;
    _notionTokenController.text = settings.notionToken;
    _databaseController.text = settings.notionDatabaseId;
    _imgbbController.text = settings.imgbbApiKey;
  }

  Future<void> _saveUser(AppSettings current) async {
    if (!_userFormKey.currentState!.validate()) return;
    final next = current.copyWith(
      userName: _nameController.text.trim(),
      employeeNumber: _employeeController.text.trim(),
      email: _emailController.text.trim(),
    );
    await ref.read(settingsProvider.notifier).save(next);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사용자 정보를 저장했습니다.')),
      );
    }
  }

  Future<void> _saveSync(AppSettings current) async {
    if (AppSecrets.hasExternalDefaults) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('외부 연동 설정은 앱에 고정되어 있어 수정할 수 없습니다.')),
        );
      }
      return;
    }

    if (!_syncFormKey.currentState!.validate()) return;
    final next = current.copyWith(
      notionToken: _notionTokenController.text.trim(),
      notionDatabaseId: _databaseController.text.trim(),
      imgbbApiKey: _imgbbController.text.trim(),
    );
    await ref.read(settingsProvider.notifier).save(next);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('연동 정보를 저장했습니다.')),
      );
    }
  }

  Future<void> _checkConnection(AppSettings current) async {
    final probe = current.copyWith(
      notionToken: _notionTokenController.text.trim(),
      notionDatabaseId: _databaseController.text.trim(),
      imgbbApiKey: _imgbbController.text.trim(),
    );

    String result;
    if (probe.notionToken.isEmpty || probe.notionDatabaseId.isEmpty) {
      result = '실패: Notion Token 또는 Database ID가 비어 있습니다.';
    } else {
      try {
        await ref.read(notionServiceProvider).checkDatabaseSchema(probe);
        result = '확인 완료: Notion 데이터베이스 스키마가 연결 기준과 일치합니다.';
      } catch (error) {
        result = '실패: $error';
      }
    }

    final next = probe.copyWith(
      lastSyncCheckAt: DateTime.now().toIso8601String(),
      lastSyncCheckResult: result,
    );
    await ref.read(settingsProvider.notifier).save(next);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);

    return SafeArea(
      child: settingsAsync.when(
        data: (settings) {
          _bind(settings);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              const LogoHeader(
                title: '설정',
                subtitle: '앱 설정 및 개인 정보를 관리합니다.',
              ),
              const SizedBox(height: 20),
              AppCard(
                child: Form(
                  key: _userFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('사용자 정보', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: '이름'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _employeeController,
                        decoration: const InputDecoration(labelText: '사번'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: '이메일'),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => _saveUser(settings),
                        child: const Text('사용자 정보 저장'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Form(
                  key: _syncFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('외부 연동 설정', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notionTokenController,
                        obscureText: true,
                        readOnly: AppSecrets.hasExternalDefaults,
                        decoration: const InputDecoration(labelText: 'Notion Token'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _databaseController,
                        readOnly: AppSecrets.hasExternalDefaults,
                        decoration: const InputDecoration(labelText: 'Notion Database ID'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _imgbbController,
                        obscureText: true,
                        readOnly: AppSecrets.hasExternalDefaults,
                        decoration: const InputDecoration(labelText: '이미지 API Key'),
                      ),
                      if (AppSecrets.hasExternalDefaults) ...[
                        const SizedBox(height: 12),
                        Text(
                          '외부 연동 설정은 빌드 시 고정값으로 주입되어 사용자 수정이 제한됩니다.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        settings.lastSyncCheckAt == null
                            ? '마지막 확인: 아직 확인하지 않음'
                            : '마지막 확인: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(settings.lastSyncCheckAt!))}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        settings.lastSyncCheckResult.isEmpty
                            ? '연동 상태를 아직 확인하지 않았습니다.'
                            : settings.lastSyncCheckResult,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: AppSecrets.hasExternalDefaults
                            ? null
                            : () => _saveSync(settings),
                        child: Text(
                          AppSecrets.hasExternalDefaults ? '고정 설정 사용 중' : '연동 정보 저장',
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: () => _checkConnection(settings),
                        child: const Text('연동 상태 확인'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('설정 화면을 불러오지 못했습니다.\n$error')),
      ),
    );
  }
}
