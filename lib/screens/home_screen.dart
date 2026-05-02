import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/parse_service.dart';
import 'login_screen.dart';
import 'task_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _parseService = ParseService();
  List<TaskModel> _tasks = [];
  List<TaskModel> _filtered = [];
  bool _isLoading = false;
  String _filterStatus = 'All'; // All | Pending | Completed
  String _username = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadTasks();
  }

  Future<void> _loadUser() async {
    final user = await _parseService.currentUser();
    if (user != null && mounted) {
      setState(() => _username = user.emailAddress ?? user.username ?? '');
    }
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    final result = await _parseService.getTasks();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result['success'] == true) {
        _tasks = List<TaskModel>.from(result['tasks'] ?? []);
        _applyFilter();
      }
    });
  }

  void _applyFilter() {
    setState(() {
      switch (_filterStatus) {
        case 'Pending':
          _filtered = _tasks.where((t) => !t.isCompleted).toList();
          break;
        case 'Completed':
          _filtered = _tasks.where((t) => t.isCompleted).toList();
          break;
        default:
          _filtered = List.from(_tasks);
      }
    });
  }

  Future<void> _deleteTask(TaskModel task) async {
    if (task.objectId == null) return;
    final result = await _parseService.deleteTask(task.objectId!);
    if (!mounted) return;
    if (result['success'] == true) {
      _showSnackBar('Task deleted!');
      _loadTasks();
    } else {
      _showSnackBar(result['message'], isError: true);
    }
  }

  Future<void> _toggleComplete(TaskModel task) async {
    final result = await _parseService.toggleTaskComplete(task);
    if (!mounted) return;
    if (result['success'] == true) {
      _loadTasks();
    } else {
      _showSnackBar(result['message'], isError: true);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Logout')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    await _parseService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _openTaskForm({TaskModel? task}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => TaskFormScreen(existingTask: task)),
    );
    if (result == true) _loadTasks();
  }

  // Stats summary
  int get _completedCount => _tasks.where((t) => t.isCompleted).length;
  int get _pendingCount => _tasks.where((t) => !t.isCompleted).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('My Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadTasks,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTasks,
        color: const Color(0xFF00897B),
        child: Column(
          children: [
            // ── Stats Card ──
            _buildStatsCard(),

            // ── Filter Chips ──
            _buildFilterRow(),

            // ── Task List ──
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF00897B)))
                  : _filtered.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) => _buildTaskCard(_filtered[i]),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openTaskForm(),
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00897B), Color(0xFF4DB6AC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00897B).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Colors.white24,
                child: Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _username,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _statItem('Total', _tasks.length.toString(), Icons.list_alt),
              const SizedBox(width: 16),
              _statItem('Pending', _pendingCount.toString(),
                  Icons.hourglass_empty, color: Colors.orangeAccent),
              const SizedBox(width: 16),
              _statItem('Done', _completedCount.toString(),
                  Icons.check_circle_outline, color: Colors.lightGreenAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon,
      {Color color = Colors.white}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: ['All', 'Pending', 'Completed'].map((f) {
          final isSelected = _filterStatus == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(f),
              selected: isSelected,
              onSelected: (_) {
                setState(() => _filterStatus = f);
                _applyFilter();
              },
              selectedColor: const Color(0xFF00897B),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              checkmarkColor: Colors.white,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTaskCard(TaskModel task) {
    final priorityColor = {
      TaskPriority.high: Colors.red.shade400,
      TaskPriority.medium: Colors.orange.shade400,
      TaskPriority.low: Colors.green.shade400,
    }[task.priority]!;

    return Dismissible(
      key: Key(task.objectId ?? task.title),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 28),
            Text('Delete', style: TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete Task'),
            content: const Text('Are you sure you want to delete this task?'),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => _deleteTask(task),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: GestureDetector(
            onTap: () => _toggleComplete(task),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: task.isCompleted
                    ? const Color(0xFF00897B)
                    : Colors.transparent,
                border: Border.all(
                  color: task.isCompleted
                      ? const Color(0xFF00897B)
                      : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: task.isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ),
          title: Text(
            task.title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              decoration:
                  task.isCompleted ? TextDecoration.lineThrough : null,
              color: task.isCompleted ? Colors.grey : Colors.black87,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (task.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  task.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    decoration:
                        task.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      task.priority.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: priorityColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: task.isCompleted
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      task.isCompleted ? 'Completed' : 'Pending',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: task.isCompleted
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.edit_outlined,
                color: Color(0xFF00897B)),
            onPressed: () => _openTaskForm(task: task),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        const SizedBox(height: 60),
        Center(
          child: Column(
            children: [
              Icon(Icons.inbox_outlined,
                  size: 80, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                _filterStatus == 'All'
                    ? 'No tasks yet!'
                    : 'No $_filterStatus tasks',
                style: TextStyle(
                    fontSize: 18, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap + to create your first task',
                style: TextStyle(
                    fontSize: 14, color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
