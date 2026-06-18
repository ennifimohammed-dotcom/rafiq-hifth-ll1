enum SessionRating { excellent, good, average, poor }

extension SessionRatingX on SessionRating {
  String get label => switch (this) {
        SessionRating.excellent => 'ممتاز',
        SessionRating.good => 'جيد',
        SessionRating.average => 'متوسط',
        SessionRating.poor => 'ضعيف',
      };
}

class SessionEntity {
  final String id;
  final String studentId;
  final String type;
  final String surah;
  final int ayahStart;
  final int ayahEnd;
  final SessionRating rating;
  final List<String> mistakes;
  final String notes;
  final DateTime timestamp;

  const SessionEntity({
    required this.id,
    required this.studentId,
    required this.type,
    required this.surah,
    required this.ayahStart,
    required this.ayahEnd,
    required this.rating,
    required this.mistakes,
    required this.notes,
    required this.timestamp,
  });
}
