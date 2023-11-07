class Chapter {
  const Chapter(this.id, this.name, this.position, this.isCompleted);

  // the file name
  final String id;
  final String name;
  final int position;
  final bool isCompleted;

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      json['id'] as String,
      json['name'] as String,
      json['position'] as int,
      json['isCompleted'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'position': position,
      'isCompleted': isCompleted,
    };
  }

  Chapter copyWith({String? name, int? position, bool? isCompleted}) {
    return Chapter(
      id,
      name ?? this.name,
      position ?? this.position,
      isCompleted ?? this.isCompleted,
    );
  }
}
