import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../models/app_settings.dart';
import '../models/monthly_stats.dart';
import '../models/proposal.dart';
import '../services/image_upload_service.dart';
import '../services/notion_service.dart';
import '../services/proposal_storage_service.dart';
import '../services/settings_service.dart';
import '../services/sync_service.dart';

final currentTabProvider = StateProvider<int>((ref) => 1);
final selectedCategoryFilterProvider = StateProvider<ProposalCategory?>((ref) => null);

final dioProvider = Provider<Dio>((ref) => Dio());
final uuidProvider = Provider<Uuid>((ref) => const Uuid());
final imagePickerProvider = Provider<ImagePicker>((ref) => ImagePicker());
final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

final proposalStorageProvider = Provider<ProposalStorageService>(
  (ref) => ProposalStorageService(),
);
final settingsServiceProvider = Provider<SettingsService>(
  (ref) => SettingsService(ref.watch(secureStorageProvider)),
);
final imageUploadServiceProvider = Provider<ImageUploadService>(
  (ref) => ImageUploadService(ref.watch(dioProvider)),
);
final notionServiceProvider = Provider<NotionService>(
  (ref) => NotionService(ref.watch(dioProvider)),
);
final syncServiceProvider = Provider<SyncService>(
  (ref) => SyncService(
    storageService: ref.watch(proposalStorageProvider),
    imageUploadService: ref.watch(imageUploadServiceProvider),
    notionService: ref.watch(notionServiceProvider),
  ),
);

final proposalsProvider = StateNotifierProvider<ProposalNotifier, List<Proposal>>((ref) {
  final notifier = ProposalNotifier(
    ref.watch(proposalStorageProvider),
    ref.watch(syncServiceProvider),
    ref.watch(settingsServiceProvider),
  );
  notifier.load();
  return notifier;
});

final settingsProvider = StateNotifierProvider<SettingsNotifier, AsyncValue<AppSettings>>((ref) {
  final notifier = SettingsNotifier(ref.watch(settingsServiceProvider));
  notifier.load();
  return notifier;
});

final filteredProposalsProvider = Provider<List<Proposal>>((ref) {
  final proposals = ref.watch(proposalsProvider);
  final filter = ref.watch(selectedCategoryFilterProvider);
  if (filter == null) return proposals;
  return proposals.where((item) => item.category == filter).toList();
});

final monthlyStatsProvider = Provider.family<MonthlyStats, DateTime>((ref, month) {
  final items = ref.watch(proposalsProvider).where((proposal) {
    return proposal.receivedDate.year == month.year &&
        proposal.receivedDate.month == month.month;
  }).toList();

  final categoryCounts = {
    for (final category in ProposalCategory.values) category.label: 0,
  };
  for (final item in items) {
    categoryCounts[item.category.label] = (categoryCounts[item.category.label] ?? 0) + 1;
  }

  return MonthlyStats(
    totalCount: items.length,
    adoptedCount:
        items.where((item) => item.adoptionStatus == AdoptionStatus.adopted).length,
    completedCount:
        items.where((item) => item.executionStatus == ExecutionStatus.completed).length,
    failedCount: items.where((item) => item.syncStatus == SyncStatus.failed).length,
    categoryCounts: categoryCounts,
  );
});

class ProposalNotifier extends StateNotifier<List<Proposal>> {
  ProposalNotifier(
    this._storageService,
    this._syncService,
    this._settingsService,
  ) : super(const []);

  final ProposalStorageService _storageService;
  final SyncService _syncService;
  final SettingsService _settingsService;

  void load() {
    state = _storageService.getAllProposals();
  }

  Future<void> addProposal(Proposal proposal) async {
    await _storageService.saveProposal(proposal);
    load();
    final settings = await _settingsService.load();
    final synced = await _syncService.syncProposal(proposal: proposal, settings: settings);
    state = [
      for (final item in state) if (item.id == synced.id) synced else item,
    ]..sort((a, b) => b.receivedDate.compareTo(a.receivedDate));
  }

  Proposal? getById(String id) {
    for (final item in state) {
      if (item.id == id) return item;
    }
    return _storageService.getProposal(id);
  }

  Future<void> retrySync(String id) async {
    final proposal = getById(id);
    if (proposal == null) return;
    final settings = await _settingsService.load();
    await _syncService.syncProposal(
      proposal: proposal.copyWith(syncStatus: SyncStatus.pending),
      settings: settings,
    );
    load();
  }

  Future<void> deleteProposal(String id) async {
    final proposal = getById(id);
    if (proposal == null) return;
    final settings = await _settingsService.load();
    await _syncService.deleteProposal(
      proposal: proposal,
      settings: settings,
    );
    load();
  }

  Future<void> refreshFromRemote() async {
    final settings = await _settingsService.load();
    if (settings.notionToken.isEmpty || settings.notionDatabaseId.isEmpty) {
      throw Exception('연동 정보를 먼저 설정해주세요.');
    }

    final remoteUpdated = await _syncService.notionService.fetchRemoteUpdates(
      settings: settings,
      localProposals: state,
    );
    await _storageService.saveProposals(remoteUpdated);
    load();
  }
}

class SettingsNotifier extends StateNotifier<AsyncValue<AppSettings>> {
  SettingsNotifier(this._settingsService) : super(const AsyncLoading());

  final SettingsService _settingsService;

  Future<void> load() async {
    state = AsyncData(await _settingsService.load());
  }

  Future<void> save(AppSettings settings) async {
    await _settingsService.save(settings);
    state = AsyncData(settings);
  }
}
