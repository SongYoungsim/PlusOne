import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../models/app_settings.dart';
import '../models/proposal.dart';

class NotionService {
  const NotionService(this._dio);

  final Dio _dio;

  static const _baseUrl = 'https://api.notion.com/v1';
  static const _notionVersion = '2022-06-28';

  static const _titleKey = '제목';
  static const _receivedDateKey = '접수일';
  static const _categoryKey = '카테고리';
  static const _problemKey = '문제점';
  static const _improvementIdeaKey = '개선아이디어';
  static const _image1Key = '이미지1';
  static const _image2Key = '이미지2';
  static const _executionStatusKey = '실행여부';
  static const _adoptionStatusKey = '채택여부';
  static const _completedDateKey = '완료일';
  static const _memoKey = '메모';
  static const _employeeNumberKey = '사번';
  static const _userNameKey = '이름';
  static const _emailKey = '이메일';

  List<Map<String, dynamic>> _richText(String value) {
    if (value.trim().isEmpty) {
      return [];
    }

    return [
      {
        'text': {'content': value}
      }
    ];
  }

  Map<String, dynamic> _choiceValue({
    required Map<String, dynamic> properties,
    required String propertyName,
    required String value,
  }) {
    final property = properties[propertyName] as Map<String, dynamic>?;
    final type = property?['type'] as String?;

    if (type == 'select') {
      return {
        'select': {'name': value}
      };
    }

    return {
      'status': {'name': value}
    };
  }

  Map<String, dynamic> buildProperties(
    Proposal proposal,
    Map<String, dynamic> databaseProperties,
  ) {
    return {
      _titleKey: {
        'title': [
          {
            'text': {'content': proposal.title}
          }
        ]
      },
      _receivedDateKey: {
        'date': {'start': DateFormat('yyyy-MM-dd').format(proposal.receivedDate)}
      },
      _categoryKey: {
        'select': {'name': proposal.category.label}
      },
      _problemKey: {
        'rich_text': _richText(proposal.problem)
      },
      _improvementIdeaKey: {
        'rich_text': _richText(proposal.improvementIdea)
      },
      _image1Key: proposal.image1RemoteUrl == null
          ? {'files': []}
          : {
              'files': [
                {
                  'name': 'image1',
                  'external': {'url': proposal.image1RemoteUrl}
                }
              ]
            },
      _image2Key: proposal.image2RemoteUrl == null
          ? {'files': []}
          : {
              'files': [
                {
                  'name': 'image2',
                  'external': {'url': proposal.image2RemoteUrl}
                }
              ]
            },
      _executionStatusKey: _choiceValue(
        properties: databaseProperties,
        propertyName: _executionStatusKey,
        value: proposal.executionStatus.label,
      ),
      _adoptionStatusKey: _choiceValue(
        properties: databaseProperties,
        propertyName: _adoptionStatusKey,
        value: proposal.adoptionStatus.label,
      ),
      _completedDateKey: proposal.completedDate == null
          ? {'date': null}
          : {
              'date': {
                'start': DateFormat('yyyy-MM-dd').format(proposal.completedDate!)
              }
            },
      _memoKey: {
        'rich_text': _richText(proposal.memo)
      },
      _employeeNumberKey: {
        'rich_text': _richText(proposal.employeeNumber)
      },
      _userNameKey: {
        'rich_text': _richText(proposal.userName)
      },
      _emailKey: {
        'rich_text': _richText(proposal.email)
      },
    };
  }

  Future<Map<String, dynamic>> _getDatabaseProperties(AppSettings settings) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_baseUrl/databases/${settings.notionDatabaseId}',
      options: Options(headers: _headers(settings.notionToken)),
    );
    return response.data?['properties'] as Map<String, dynamic>? ?? {};
  }

  Future<void> checkDatabaseSchema(AppSettings settings) async {
    final properties = await _getDatabaseProperties(settings);
    const requiredKeys = [
      _titleKey,
      _receivedDateKey,
      _categoryKey,
      _problemKey,
      _improvementIdeaKey,
      _image1Key,
      _image2Key,
      _executionStatusKey,
      _adoptionStatusKey,
      _completedDateKey,
      _memoKey,
      _employeeNumberKey,
      _userNameKey,
      _emailKey,
    ];

    for (final key in requiredKeys) {
      if (!properties.containsKey(key)) {
        throw Exception('Notion 데이터베이스 스키마 불일치: $key 속성이 없습니다.');
      }
    }
  }

  Future<String?> createPage({
    required AppSettings settings,
    required Proposal proposal,
  }) async {
    final databaseProperties = await _getDatabaseProperties(settings);
    final response = await _dio.post<Map<String, dynamic>>(
      '$_baseUrl/pages',
      options: Options(headers: _headers(settings.notionToken)),
      data: {
        'parent': {'database_id': settings.notionDatabaseId},
        'properties': buildProperties(proposal, databaseProperties),
      },
    );
    return response.data?['id'] as String?;
  }

  Future<List<Proposal>> fetchRemoteUpdates({
    required AppSettings settings,
    required List<Proposal> localProposals,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_baseUrl/databases/${settings.notionDatabaseId}/query',
      options: Options(headers: _headers(settings.notionToken)),
      data: {
        'page_size': 100,
      },
    );

    final results = (response.data?['results'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .where((item) => item['in_trash'] != true && item['archived'] != true)
        .toList();
    final updated = <Proposal>[];

    for (final local in localProposals) {
      final match = results.cast<Map<String, dynamic>?>().firstWhere(
        (item) => _isMatchingPage(item, local),
        orElse: () => null,
      );

      if (match == null) {
        continue;
      }

      final properties = match['properties'] as Map<String, dynamic>? ?? {};
      updated.add(
        local.copyWith(
          notionPageId: match['id'] as String?,
          executionStatus: _readExecutionStatus(properties[_executionStatusKey]),
          adoptionStatus: _readAdoptionStatus(properties[_adoptionStatusKey]),
          completedDate: _readDate(properties[_completedDateKey]),
          memo: _readRichText(properties[_memoKey]) ?? local.memo,
          syncStatus: SyncStatus.synced,
          syncErrorMessage: null,
        ),
      );
    }

    return updated;
  }

  Future<void> archiveMatchingPage({
    required AppSettings settings,
    required Proposal proposal,
  }) async {
    if (proposal.notionPageId != null && proposal.notionPageId!.isNotEmpty) {
      await _dio.patch<Map<String, dynamic>>(
        '$_baseUrl/pages/${proposal.notionPageId}',
        options: Options(headers: _headers(settings.notionToken)),
        data: {
          'archived': true,
        },
      );
      return;
    }

    final response = await _dio.post<Map<String, dynamic>>(
      '$_baseUrl/databases/${settings.notionDatabaseId}/query',
      options: Options(headers: _headers(settings.notionToken)),
      data: {
        'page_size': 100,
      },
    );

    final results = (response.data?['results'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .where((item) => item['in_trash'] != true && item['archived'] != true)
        .toList();

    final match = results.cast<Map<String, dynamic>?>().firstWhere(
      (item) => _isMatchingPage(item, proposal),
      orElse: () => null,
    );

    if (match == null) {
      throw Exception('삭제할 Notion 페이지를 찾지 못했습니다.');
    }

    final pageId = match['id'] as String?;
    if (pageId == null || pageId.isEmpty) {
      throw Exception('삭제할 Notion 페이지 ID가 없습니다.');
    }

    await _dio.patch<Map<String, dynamic>>(
      '$_baseUrl/pages/$pageId',
      options: Options(headers: _headers(settings.notionToken)),
      data: {
        'archived': true,
      },
    );
  }

  bool _isMatchingPage(Map<String, dynamic>? page, Proposal local) {
    if (page == null) return false;
    final properties = page['properties'] as Map<String, dynamic>? ?? {};
    final title = _readTitle(properties[_titleKey]);
    final receivedDate = _readDate(properties[_receivedDateKey]);
    final employeeNumber = _readRichText(properties[_employeeNumberKey]);

    final sameTitle = title?.trim() == local.title.trim();
    final sameDate = receivedDate != null &&
        receivedDate.year == local.receivedDate.year &&
        receivedDate.month == local.receivedDate.month &&
        receivedDate.day == local.receivedDate.day;
    final sameEmployee = employeeNumber == null ||
        employeeNumber.isEmpty ||
        employeeNumber == local.employeeNumber;

    return sameTitle && sameDate && sameEmployee;
  }

  String? _readTitle(dynamic property) {
    final items = (property as Map<String, dynamic>?)?['title'] as List<dynamic>?;
    if (items == null || items.isEmpty) return null;
    return items
        .map((item) => (item as Map<String, dynamic>)['plain_text'] as String? ?? '')
        .join();
  }

  String? _readRichText(dynamic property) {
    final items = (property as Map<String, dynamic>?)?['rich_text'] as List<dynamic>?;
    if (items == null) return null;
    return items
        .map((item) => (item as Map<String, dynamic>)['plain_text'] as String? ?? '')
        .join();
  }

  DateTime? _readDate(dynamic property) {
    final date = (property as Map<String, dynamic>?)?['date'] as Map<String, dynamic>?;
    final start = date?['start'] as String?;
    if (start == null || start.isEmpty) return null;
    return DateTime.tryParse(start);
  }

  ExecutionStatus _readExecutionStatus(dynamic property) {
    final value = _readChoiceName(property);
    switch (value) {
      case '실행완료':
        return ExecutionStatus.completed;
      case '미실행':
        return ExecutionStatus.notExecuted;
      case '건의':
      default:
        return ExecutionStatus.suggestion;
    }
  }

  AdoptionStatus _readAdoptionStatus(dynamic property) {
    final value = _readChoiceName(property);
    switch (value) {
      case '검토중':
        return AdoptionStatus.reviewing;
      case '채택':
        return AdoptionStatus.adopted;
      case '미채택':
        return AdoptionStatus.rejected;
      case '시작전':
      default:
        return AdoptionStatus.beforeStart;
    }
  }

  String? _readChoiceName(dynamic property) {
    final map = property as Map<String, dynamic>?;
    final status = map?['status'] as Map<String, dynamic>?;
    final select = map?['select'] as Map<String, dynamic>?;
    return (status?['name'] ?? select?['name']) as String?;
  }

  Map<String, String> _headers(String token) {
    return {
      'Authorization': 'Bearer $token',
      'Notion-Version': _notionVersion,
      'Content-Type': 'application/json',
    };
  }
}
