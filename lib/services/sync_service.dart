import 'dart:convert';

import 'package:dio/dio.dart';

import '../models/app_settings.dart';
import '../models/proposal.dart';
import 'image_upload_service.dart';
import 'notion_service.dart';
import 'proposal_storage_service.dart';

class SyncService {
  SyncService({
    required this.storageService,
    required this.imageUploadService,
    required this.notionService,
  });

  final ProposalStorageService storageService;
  final ImageUploadService imageUploadService;
  final NotionService notionService;

  Future<Proposal> syncProposal({
    required Proposal proposal,
    required AppSettings settings,
  }) async {
    if (settings.notionToken.isEmpty || settings.notionDatabaseId.isEmpty) {
      final failed = proposal.copyWith(
        syncStatus: SyncStatus.failed,
        syncErrorMessage: '연동 설정을 먼저 입력해주세요.',
      );
      await storageService.saveProposal(failed);
      return failed;
    }

    try {
      await notionService.checkDatabaseSchema(settings);

      final image1RemoteUrl = proposal.image1LocalPath == null ||
              proposal.image1LocalPath!.isEmpty ||
              settings.imgbbApiKey.isEmpty
          ? proposal.image1RemoteUrl
          : await imageUploadService.uploadImage(
              localPath: proposal.image1LocalPath!,
              apiKey: settings.imgbbApiKey,
            );

      final image2RemoteUrl = proposal.image2LocalPath == null ||
              proposal.image2LocalPath!.isEmpty ||
              settings.imgbbApiKey.isEmpty
          ? proposal.image2RemoteUrl
          : await imageUploadService.uploadImage(
              localPath: proposal.image2LocalPath!,
              apiKey: settings.imgbbApiKey,
            );

      final prepared = proposal.copyWith(
        image1RemoteUrl: image1RemoteUrl,
        image2RemoteUrl: image2RemoteUrl,
      );

      final notionPageId = await notionService.createPage(
        settings: settings,
        proposal: prepared,
      );

      final synced = prepared.copyWith(
        notionPageId: notionPageId,
        syncStatus: SyncStatus.synced,
        syncErrorMessage: null,
      );
      await storageService.saveProposal(synced);
      return synced;
    } catch (error) {
      final failed = proposal.copyWith(
        syncStatus: SyncStatus.failed,
        syncErrorMessage: _extractErrorMessage(error),
      );
      await storageService.saveProposal(failed);
      return failed;
    }
  }

  Future<void> deleteProposal({
    required Proposal proposal,
    required AppSettings settings,
  }) async {
    if (proposal.syncStatus == SyncStatus.synced) {
      if (settings.notionToken.isEmpty || settings.notionDatabaseId.isEmpty) {
        throw Exception('Notion 연동 정보가 없어 원격 삭제를 진행할 수 없습니다.');
      }

      await notionService.archiveMatchingPage(
        settings: settings,
        proposal: proposal,
      );
    }

    await storageService.deleteProposal(proposal.id);
  }

  String _extractErrorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        final code = data['code'];
        if (message is String && code is String) {
          return 'Notion 오류($code): $message';
        }
        if (message is String) {
          return message;
        }
        return jsonEncode(data);
      }
      if (data is String && data.trim().isNotEmpty) {
        return data;
      }
      return error.message ?? error.toString();
    }
    return error.toString();
  }
}
