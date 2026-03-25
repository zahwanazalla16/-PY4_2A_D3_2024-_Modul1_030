import 'package:mongo_dart/mongo_dart.dart';
import 'package:hive/hive.dart';

part 'log_model.g.dart';

@HiveType(typeId: 0)
class LogModel {
  @HiveField(0)
  final String? id;
  
  @HiveField(1)
  final String title;
  
  @HiveField(2)
  final String description;
  
  @HiveField(3)
  final DateTime date;
  
  @HiveField(4)
  final String category;
  
  @HiveField(5)
  final String username;
  
  @HiveField(6)
  final String authorId;
  
  @HiveField(7)
  final String teamId;

  @HiveField(8)
  final bool isPublic;

  @HiveField(9)
  final bool isSynced;

  @HiveField(10)
  final bool pendingDelete;

  LogModel({
    this.id,
    required this.title,
    required this.description,
    required this.date,
    this.category = 'mechanical',
    required this.username,
    required this.authorId,
    required this.teamId,
    this.isPublic = false,
    this.isSynced = true,
    this.pendingDelete = false,
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
      'authorId': authorId,
      'teamId': teamId,
      'isPublic': isPublic,
    };

    // Jika id sudah ada (update), masukkan ke map
    if (id != null) {
      map['_id'] = ObjectId.fromHexString(id!);
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
      id: objectId?.oid,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      date: map['date'] != null
          ? DateTime.parse(map['date'] as String)
          : DateTime.now(),
      category: map['category'] as String? ?? 'mechanical',
      username: map['username'] as String? ?? 'unknown',
      authorId: map['authorId'] as String? ?? 'unknown_author',
      teamId: map['teamId'] as String? ?? 'unknown_team',
      isPublic: map['isPublic'] == true, // Cara aman konversi ke bool
      isSynced: map['isSynced'] == true || map['isSynced'] == null, // Default true jika dari cloud
    );
  }

  /// Copy with untuk update field tertentu
  LogModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    String? category,
    String? username,
    String? authorId,
    String? teamId,
    bool? isPublic,
    bool? isSynced,
    bool? pendingDelete,
  }) {
    return LogModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      category: category ?? this.category,
      username: username ?? this.username,
      authorId: authorId ?? this.authorId,
      teamId: teamId ?? this.teamId,
      isPublic: isPublic ?? this.isPublic,
      isSynced: isSynced ?? this.isSynced,
      pendingDelete: pendingDelete ?? this.pendingDelete,
    );
  }

  @override
  String toString() =>
      'LogModel(id: $id, title: $title, description: $description, date: $date, category: $category, username: $username, authorId: $authorId, teamId: $teamId, isPublic: $isPublic, isSynced: $isSynced, pendingDelete: $pendingDelete)';
}