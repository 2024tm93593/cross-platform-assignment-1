import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

enum TaskPriority { low, medium, high }

class TaskModel {
  final String? objectId;
  final String title;
  final String description;
  final bool isCompleted;
  final TaskPriority priority;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TaskModel({
    this.objectId,
    required this.title,
    required this.description,
    this.isCompleted = false,
    this.priority = TaskPriority.medium,
    this.createdAt,
    this.updatedAt,
  });

  // Convert a ParseObject → TaskModel
  factory TaskModel.fromParse(ParseObject obj) {
    final priorityStr = obj.get<String>('priority') ?? 'medium';
    return TaskModel(
      objectId: obj.objectId,
      title: obj.get<String>('title') ?? '',
      description: obj.get<String>('description') ?? '',
      isCompleted: obj.get<bool>('isCompleted') ?? false,
      priority: TaskPriority.values.firstWhere(
        (e) => e.name == priorityStr,
        orElse: () => TaskPriority.medium,
      ),
      createdAt: obj.createdAt,
      updatedAt: obj.updatedAt,
    );
  }

  // Convert TaskModel → ParseObject
ParseObject toParseObject(ParseUser currentUser) {
  final obj = ParseObject('Task')
    ..set('title', title)
    ..set('description', description)
    ..set('isCompleted', isCompleted)
    ..set('priority', priority.name)
    ..set('user', currentUser);

  if (objectId != null) {
    obj.objectId = objectId;
  }

  final acl = ParseACL(owner: currentUser);
  obj.setACL(acl);

  return obj;
}

  TaskModel copyWith({
    String? objectId,
    String? title,
    String? description,
    bool? isCompleted,
    TaskPriority? priority,
  }) {
    return TaskModel(
      objectId: objectId ?? this.objectId,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
