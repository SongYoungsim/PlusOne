class AppSettings {
  const AppSettings({
    this.employeeNumber = '',
    this.userName = '',
    this.email = '',
    this.notionToken = '',
    this.notionDatabaseId = '',
    this.imgbbApiKey = '',
    this.lastSyncCheckAt,
    this.lastSyncCheckResult = '',
  });

  final String employeeNumber;
  final String userName;
  final String email;
  final String notionToken;
  final String notionDatabaseId;
  final String imgbbApiKey;
  final String? lastSyncCheckAt;
  final String lastSyncCheckResult;

  AppSettings copyWith({
    String? employeeNumber,
    String? userName,
    String? email,
    String? notionToken,
    String? notionDatabaseId,
    String? imgbbApiKey,
    String? lastSyncCheckAt,
    String? lastSyncCheckResult,
  }) {
    return AppSettings(
      employeeNumber: employeeNumber ?? this.employeeNumber,
      userName: userName ?? this.userName,
      email: email ?? this.email,
      notionToken: notionToken ?? this.notionToken,
      notionDatabaseId: notionDatabaseId ?? this.notionDatabaseId,
      imgbbApiKey: imgbbApiKey ?? this.imgbbApiKey,
      lastSyncCheckAt: lastSyncCheckAt ?? this.lastSyncCheckAt,
      lastSyncCheckResult: lastSyncCheckResult ?? this.lastSyncCheckResult,
    );
  }
}
