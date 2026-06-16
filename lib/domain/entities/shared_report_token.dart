class SharedReportToken {
  final String token;
  final String studentId;
  final DateTime createdAt;
  final DateTime? expiresAt;

  const SharedReportToken({
    required this.token,
    required this.studentId,
    required this.createdAt,
    this.expiresAt,
  });
}
