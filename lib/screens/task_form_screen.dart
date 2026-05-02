import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/parse_service.dart';

class TaskFormScreen extends StatefulWidget {
  final TaskModel? existingTask;

  const TaskFormScreen({super.key, this.existingTask});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _parseService = ParseService();

  TaskPriority _priority = TaskPriority.medium;
  bool _isCompleted = false;
  bool _isLoading = false;

  bool get _isEditing => widget.existingTask != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _titleCtrl.text = widget.existingTask!.title;
      _descCtrl.text = widget.existingTask!.description;
      _priority = widget.existingTask!.priority;
      _isCompleted = widget.existingTask!.isCompleted;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final task = TaskModel(
      objectId: widget.existingTask?.objectId,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      priority: _priority,
      isCompleted: _isCompleted,
    );

    final result = _isEditing
        ? await _parseService.updateTask(task)
        : await _parseService.createTask(task);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      _showSnackBar(result['message']);
      Navigator.pop(context, true);
    } else {
      _showSnackBar(result['message'], isError: true);
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Task' : 'New Task'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child:
                      CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton.icon(
              onPressed: _saveTask,
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text('Save',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Title ──
              _sectionLabel('Task Title *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleCtrl,
                maxLength: 100,
                decoration: const InputDecoration(
                  hintText: 'Enter task title...',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Title is required';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // ── Description ──
              _sectionLabel('Description'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                maxLength: 500,
                decoration: const InputDecoration(
                  hintText: 'Add more details about this task...',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 64),
                    child: Icon(Icons.description_outlined),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Priority ──
              _sectionLabel('Priority'),
              const SizedBox(height: 12),
              Row(
                children: TaskPriority.values.map((p) {
                  final colors = {
                    TaskPriority.low: Colors.green,
                    TaskPriority.medium: Colors.orange,
                    TaskPriority.high: Colors.red,
                  };
                  final icons = {
                    TaskPriority.low: Icons.arrow_downward,
                    TaskPriority.medium: Icons.remove,
                    TaskPriority.high: Icons.arrow_upward,
                  };
                  final isSelected = _priority == p;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () => setState(() => _priority = p),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colors[p]!.withOpacity(0.15)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? colors[p]!
                                  : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(icons[p]!,
                                  color: isSelected
                                      ? colors[p]!
                                      : Colors.grey.shade500),
                              const SizedBox(height: 4),
                              Text(
                                p.name.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? colors[p]!
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // ── Completion toggle (only for edit) ──
              if (_isEditing) ...[
                _sectionLabel('Status'),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SwitchListTile(
                    title: const Text('Mark as Completed',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Text(
                      _isCompleted ? 'Task is completed ✓' : 'Task is pending',
                      style: TextStyle(
                          color: _isCompleted
                              ? Colors.green.shade700
                              : Colors.orange.shade700,
                          fontSize: 12),
                    ),
                    value: _isCompleted,
                    onChanged: (v) => setState(() => _isCompleted = v),
                    activeColor: const Color(0xFF00897B),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // ── Save Button ──
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveTask,
                  icon: Icon(_isEditing ? Icons.save : Icons.add_task),
                  label: Text(
                    _isEditing ? 'Update Task' : 'Create Task',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF2D2D2D),
      ),
    );
  }
}
