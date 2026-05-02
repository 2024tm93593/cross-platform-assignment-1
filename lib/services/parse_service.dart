import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import '../models/task_model.dart';

/// Handles all Back4App / Parse Server interactions.
class ParseService {
  // ──────────────────────────────────────────
  //  AUTH
  // ──────────────────────────────────────────

  /// Register a new user with email + password.
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final user = ParseUser(username, password, email);
    final response = await user.signUp();

    if (response.success) {
      return {'success': true, 'message': 'Registration successful!'};
    } else {
      return {
        'success': false,
        'message': response.error?.message ?? 'Registration failed.',
      };
    }
  }

  /// Login with email (used as username) + password.
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final user = ParseUser(email, password, email);
    final response = await user.login();

    if (response.success) {
      return {'success': true, 'message': 'Login successful!'};
    } else {
      return {
        'success': false,
        'message': response.error?.message ?? 'Login failed.',
      };
    }
  }

  /// Logout the current user and invalidate session.
  Future<Map<String, dynamic>> logout() async {
    final user = await ParseUser.currentUser() as ParseUser?;
    if (user == null) return {'success': true};

    final response = await user.logout();
    if (response.success) {
      return {'success': true, 'message': 'Logged out successfully.'};
    } else {
      return {
        'success': false,
        'message': response.error?.message ?? 'Logout failed.',
      };
    }
  }

  /// Returns the currently logged-in user, or null.
  Future<ParseUser?> currentUser() async {
    return await ParseUser.currentUser() as ParseUser?;
  }

  // ──────────────────────────────────────────
  //  CRUD – TASKS
  // ──────────────────────────────────────────

  /// CREATE – Save a new task to Back4App.
  Future<Map<String, dynamic>> createTask(TaskModel task) async {
  final user = await ParseUser.currentUser() as ParseUser?;
  if (user == null) return {'success': false, 'message': 'Not logged in.'};

  final parseObj = task.toParseObject(user);
  final response = await parseObj.save();

  if (response.success) {
    final saved = (response.results != null && response.results!.isNotEmpty)
        ? response.results!.first as ParseObject
        : parseObj;
    return {
      'success': true,
      'task': TaskModel.fromParse(saved),
      'message': 'Task created!',
    };
  } else {
    return {
      'success': false,
      'message': response.error?.message ?? 'Failed to create task.',
    };
  }
}

  /// READ – Fetch all tasks for the current user.
  Future<Map<String, dynamic>> getTasks() async {
    final user = await ParseUser.currentUser() as ParseUser?;
    if (user == null) return {'success': false, 'message': 'Not logged in.'};

    final query = QueryBuilder<ParseObject>(ParseObject('Task'))
  ..whereEqualTo('user', user.toPointer())  
  ..orderByDescending('createdAt');

    final response = await query.query();

    if (response.success) {
      final tasks = (response.results ?? [])
          .map((e) => TaskModel.fromParse(e as ParseObject))
          .toList();
      return {'success': true, 'tasks': tasks};
    } else {
      return {
        'success': false,
        'message': response.error?.message ?? 'Failed to fetch tasks.',
      };
    }
  }

  /// UPDATE – Update an existing task.
  Future<Map<String, dynamic>> updateTask(TaskModel task) async {
  if (task.objectId == null) {
    return {'success': false, 'message': 'Task has no ID.'};
  }

  final user = await ParseUser.currentUser() as ParseUser?;
  if (user == null) return {'success': false, 'message': 'Not logged in.'};

  final parseObj = task.toParseObject(user);
  final response = await parseObj.save();

  if (response.success) {
    return {'success': true, 'message': 'Task updated!'};
  } else {
    return {
      'success': false,
      'message': response.error?.message ?? 'Failed to update task.',
    };
  }
}

  /// DELETE – Remove a task from Back4App.
  Future<Map<String, dynamic>> deleteTask(String objectId) async {
    final parseObj = ParseObject('Task')..objectId = objectId;
    final response = await parseObj.delete();

    if (response.success) {
      return {'success': true, 'message': 'Task deleted!'};
    } else {
      return {
        'success': false,
        'message': response.error?.message ?? 'Failed to delete task.',
      };
    }
  }

  /// TOGGLE – Flip isCompleted without changing other fields.
  Future<Map<String, dynamic>> toggleTaskComplete(TaskModel task) async {
    return updateTask(task.copyWith(isCompleted: !task.isCompleted));
  }
}
