enum AttendanceStatus { present, absent, late }

extension AttendanceStatusX on AttendanceStatus {
  String get label => switch (this) {
        AttendanceStatus.present => 'حاضر',
        AttendanceStatus.absent => 'غائب',
        AttendanceStatus.late => 'متأخر',
      };
}

class AttendanceRecord {
  final String id;
  final String studentId;
  final DateTime date;
  final AttendanceStatus status;

  const AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.date,
    required this.status,
  });
}
