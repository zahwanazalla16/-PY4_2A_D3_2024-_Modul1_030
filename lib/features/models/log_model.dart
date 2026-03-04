import 'package:mongo_dart/mongo_dart.dart';

class LogModel {
  final ObjectId? id;
  final String title;
  final String description;
  final DateTime date;
  final String category;
  final String username;

  LogModel({
    this.id,
    required this.title,
    required this.description,
    required this.date,
    this.category = 'perkuliahan',
    required this.username,
  });

  /// Konversi ke Map untuk disimpan ke MongoDB
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'category': category,
      'createdAt': DateTime.now().toIso8601String(),
      'username': username,
    };
    
    // Jika id sudah ada (update), masukkan ke map
    if (id != null) {
      map['_id'] = id;
    }
    
    return map;
  }

  /// Konversi dari Map MongoDB ke Object
  factory LogModel.fromMap(Map<String, dynamic> map) {
    ObjectId? objectId;
    
    // Handle berbagai format ObjectId dari database
    if (map['_id'] != null) {
      if (map['_id'] is ObjectId) {
        objectId = map['_id'] as ObjectId;
      } else if (map['_id'] is String) {
        try {
          objectId = ObjectId.fromHexString(map['_id']);
        } catch (e) {
          objectId = null;
        }
      }
    }

    return LogModel(
      id: objectId,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      date: map['date'] != null
          ? DateTime.parse(map['date'] as String)
          : DateTime.now(),
      category: map['category'] as String? ?? 'perkuliahan',
      username: map['username'] as String? ?? 'unknown',
    );
  }

  /// Copy with untuk update field tertentu
  LogModel copyWith({
    ObjectId? id,
    String? title,
    String? description,
    DateTime? date,
    String? category,
    String? username,
  }) {
    return LogModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      category: category ?? this.category,
      username: username ?? this.username,
    );
  }

  @override
  String toString() =>
      'LogModel(id: $id, title: $title, description: $description, date: $date, category: $category, username: $username)';
}
