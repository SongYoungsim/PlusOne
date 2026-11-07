class AppSecrets {
  static const notionToken = String.fromEnvironment('NOTION_TOKEN');
  static const notionDatabaseId = String.fromEnvironment('NOTION_DATABASE_ID');
  static const imgbbApiKey = String.fromEnvironment('IMGBB_API_KEY');

  static bool get hasExternalDefaults {
    return notionToken.isNotEmpty &&
        notionDatabaseId.isNotEmpty &&
        imgbbApiKey.isNotEmpty;
  }
}
