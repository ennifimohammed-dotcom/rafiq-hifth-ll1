enum SessionType { memorization, revision }

enum SessionRating { excellent, good, weak }

extension SessionRatingX on SessionRating {
  String get label => switch (this) {
        SessionRating.excellent => 'ممتاز',
        SessionRating.good => 'جيد',
        SessionRating.weak => 'ضعيف',
      };
  int get score => switch (this) {
        SessionRating.excellent => 3,
        SessionRating.good => 2,
        SessionRating.weak => 1,
      };
}

class SessionEntity {
  final String id;
  final String studentId;
  final SessionType type;
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
