class MonthlyStats {
  const MonthlyStats({
    required this.totalCount,
    required this.adoptedCount,
    required this.completedCount,
    required this.failedCount,
    required this.categoryCounts,
  });

  final int totalCount;
  final int adoptedCount;
  final int completedCount;
  final int failedCount;
  final Map<String, int> categoryCounts;
}
