class Student {
  final String id;
  final String name;
  final int? age;
  final String currentSurah;
  final int currentAyahStart;
  final int currentAyahEnd;
  final double progressPercent;
  final DateTime createdAt;

  const Student({
    required this.id,
    required this.name,
    this.age,
    required this.currentSurah,
    required this.currentAyahStart,
    required this.currentAyahEnd,
    required this.progressPercent,
    required this.createdAt,
  });

  Student copyWith({
    String? name,
    int? age,
    String? currentSurah,
    int? currentAyahStart,
    int? currentAyahEnd,
    double? progressPercent,
  }) =>
      Student(
        id: id,
        name: name ?? this.name,
        age: age ?? this.age,
        currentSurah: currentSurah ?? this.currentSurah,
        currentAyahStart: currentAyahStart ?? this.currentAyahStart,
        currentAyahEnd: currentAyahEnd ?? this.currentAyahEnd,
        progressPercent: progressPercent ?? this.progressPercent,
        createdAt: createdAt,
      );
}
