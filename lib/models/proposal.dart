enum ProposalCategory { production, quality, safety, development, work, cs, etc }

enum ExecutionStatus { completed, notExecuted, suggestion }

enum AdoptionStatus { beforeStart, reviewing, adopted, rejected }

enum SyncStatus { pending, synced, failed }

class Proposal {
  Proposal({
    required this.id,
    required this.title,
    required this.receivedDate,
    required this.category,
    required this.problem,
    required this.improvementIdea,
    required this.employeeNumber,
    required this.userName,
    required this.email,
    this.image1LocalPath,
    this.image2LocalPath,
    this.image1RemoteUrl,
    this.image2RemoteUrl,
    this.notionPageId,
    this.executionStatus = ExecutionStatus.suggestion,
    this.adoptionStatus = AdoptionStatus.beforeStart,
    this.syncStatus = SyncStatus.pending,
    this.completedDate,
    this.memo = '',
    this.syncErrorMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String title;
  final DateTime receivedDate;
  final ProposalCategory category;
  final String problem;
  final String improvementIdea;
  final String employeeNumber;
  final String userName;
  final String email;
  final String? image1LocalPath;
  final String? image2LocalPath;
  final String? image1RemoteUrl;
  final String? image2RemoteUrl;
  final String? notionPageId;
  final ExecutionStatus executionStatus;
  final AdoptionStatus adoptionStatus;
  final SyncStatus syncStatus;
  final DateTime? completedDate;
  final String memo;
  final String? syncErrorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  Proposal copyWith({
    String? id,
    String? title,
    DateTime? receivedDate,
    ProposalCategory? category,
    String? problem,
    String? improvementIdea,
    String? employeeNumber,
    String? userName,
    String? email,
    String? image1LocalPath,
    String? image2LocalPath,
    String? image1RemoteUrl,
    String? image2RemoteUrl,
    String? notionPageId,
    ExecutionStatus? executionStatus,
    AdoptionStatus? adoptionStatus,
    SyncStatus? syncStatus,
    DateTime? completedDate,
    String? memo,
    String? syncErrorMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Proposal(
      id: id ?? this.id,
      title: title ?? this.title,
      receivedDate: receivedDate ?? this.receivedDate,
      category: category ?? this.category,
      problem: problem ?? this.problem,
      improvementIdea: improvementIdea ?? this.improvementIdea,
      employeeNumber: employeeNumber ?? this.employeeNumber,
      userName: userName ?? this.userName,
      email: email ?? this.email,
      image1LocalPath: image1LocalPath ?? this.image1LocalPath,
      image2LocalPath: image2LocalPath ?? this.image2LocalPath,
      image1RemoteUrl: image1RemoteUrl ?? this.image1RemoteUrl,
      image2RemoteUrl: image2RemoteUrl ?? this.image2RemoteUrl,
      notionPageId: notionPageId ?? this.notionPageId,
      executionStatus: executionStatus ?? this.executionStatus,
      adoptionStatus: adoptionStatus ?? this.adoptionStatus,
      syncStatus: syncStatus ?? this.syncStatus,
      completedDate: completedDate ?? this.completedDate,
      memo: memo ?? this.memo,
      syncErrorMessage: syncErrorMessage ?? this.syncErrorMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'receivedDate': receivedDate.toIso8601String(),
      'category': category.name,
      'problem': problem,
      'improvementIdea': improvementIdea,
      'employeeNumber': employeeNumber,
      'userName': userName,
      'email': email,
      'image1LocalPath': image1LocalPath,
      'image2LocalPath': image2LocalPath,
      'image1RemoteUrl': image1RemoteUrl,
      'image2RemoteUrl': image2RemoteUrl,
      'notionPageId': notionPageId,
      'executionStatus': executionStatus.name,
      'adoptionStatus': adoptionStatus.name,
      'syncStatus': syncStatus.name,
      'completedDate': completedDate?.toIso8601String(),
      'memo': memo,
      'syncErrorMessage': syncErrorMessage,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Proposal.fromMap(Map<dynamic, dynamic> map) {
    return Proposal(
      id: map['id'] as String,
      title: map['title'] as String? ?? '',
      receivedDate: DateTime.parse(map['receivedDate'] as String),
      category: ProposalCategory.values.byName(map['category'] as String),
      problem: map['problem'] as String? ?? '',
      improvementIdea: map['improvementIdea'] as String? ?? '',
      employeeNumber: map['employeeNumber'] as String? ?? '',
      userName: map['userName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      image1LocalPath: map['image1LocalPath'] as String?,
      image2LocalPath: map['image2LocalPath'] as String?,
      image1RemoteUrl: map['image1RemoteUrl'] as String?,
      image2RemoteUrl: map['image2RemoteUrl'] as String?,
      notionPageId: map['notionPageId'] as String?,
      executionStatus: ExecutionStatus.values.byName(
        map['executionStatus'] as String? ?? ExecutionStatus.suggestion.name,
      ),
      adoptionStatus: AdoptionStatus.values.byName(
        map['adoptionStatus'] as String? ?? AdoptionStatus.beforeStart.name,
      ),
      syncStatus: SyncStatus.values.byName(
        map['syncStatus'] as String? ?? SyncStatus.pending.name,
      ),
      completedDate: map['completedDate'] == null
          ? null
          : DateTime.parse(map['completedDate'] as String),
      memo: map['memo'] as String? ?? '',
      syncErrorMessage: map['syncErrorMessage'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}

extension ProposalCategoryX on ProposalCategory {
  String get label {
    switch (this) {
      case ProposalCategory.production:
        return '생산';
      case ProposalCategory.quality:
        return '품질';
      case ProposalCategory.safety:
        return '재고부족';
      case ProposalCategory.development:
        return '개발';
      case ProposalCategory.work:
        return '업무';
      case ProposalCategory.cs:
        return '비품요청';
      case ProposalCategory.etc:
        return '기타';
    }
  }
}

extension ExecutionStatusX on ExecutionStatus {
  String get label {
    switch (this) {
      case ExecutionStatus.completed:
        return '실행완료';
      case ExecutionStatus.notExecuted:
        return '미실행';
      case ExecutionStatus.suggestion:
        return '건의';
    }
  }
}

extension AdoptionStatusX on AdoptionStatus {
  String get label {
    switch (this) {
      case AdoptionStatus.beforeStart:
        return '시작전';
      case AdoptionStatus.reviewing:
        return '검토중';
      case AdoptionStatus.adopted:
        return '채택';
      case AdoptionStatus.rejected:
        return '미채택';
    }
  }
}

extension SyncStatusX on SyncStatus {
  String get label {
    switch (this) {
      case SyncStatus.pending:
        return '동기화 대기';
      case SyncStatus.synced:
        return '동기화 완료';
      case SyncStatus.failed:
        return '동기화 실패';
    }
  }
}
