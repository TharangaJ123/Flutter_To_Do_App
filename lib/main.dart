import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const ToDoApp());
}

class Task {
  String title;
  bool completed;
  DateTime? dueDate;

  Task({required this.title, this.completed = false, this.dueDate});

  Map<String, dynamic> toJson() => {
        'title': title,
        'completed': completed,
        'dueDate': dueDate?.toIso8601String(),
      };

  static Task fromJson(Map<String, dynamic> json) => Task(
        title: json['title'],
        completed: json['completed'] ?? false,
        dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      );
}

class ToDoApp extends StatelessWidget {
  const ToDoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter To-Do List',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ToDoListScreen(),
    );
  }
}

class ToDoListScreen extends StatefulWidget {
  const ToDoListScreen({super.key});

  @override
  State<ToDoListScreen> createState() => _ToDoListScreenState();
}

class _ToDoListScreenState extends State<ToDoListScreen> {
  List<Task> _tasks = [];
  final TextEditingController _controller = TextEditingController();
  DateTime? _selectedDueDate;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksString = prefs.getString('tasks');
    if (tasksString != null) {
      final List decoded = jsonDecode(tasksString);
      setState(() {
        _tasks = decoded.map((e) => Task.fromJson(e)).toList();
      });
    }
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_tasks.map((e) => e.toJson()).toList());
    await prefs.setString('tasks', encoded);
  }

  void _addTask() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _tasks.add(Task(title: text, dueDate: _selectedDueDate));
        _controller.clear();
        _selectedDueDate = null;
      });
      _saveTasks();
    }
  }

  void _removeTask(int index) {
    setState(() {
      _tasks.removeAt(index);
    });
    _saveTasks();
  }

  void _toggleComplete(int index) {
    setState(() {
      _tasks[index].completed = !_tasks[index].completed;
    });
    _saveTasks();
  }

  void _editTask(int index, String newTitle, DateTime? newDueDate) {
    setState(() {
      _tasks[index].title = newTitle;
      _tasks[index].dueDate = newDueDate;
    });
    _saveTasks();
  }

  void _deleteAllTasks() {
    setState(() {
      _tasks.clear();
    });
    _saveTasks();
  }

  Future<void> _pickDueDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  void _showEditDialog(int index) {
    final editController = TextEditingController(text: _tasks[index].title);
    DateTime? editDueDate = _tasks[index].dueDate;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: editController,
                decoration: const InputDecoration(labelText: 'Task'),
              ),
              Row(
                children: [
                  Text(editDueDate == null
                      ? 'No due date'
                      : 'Due: \\${editDueDate.toLocal().toString().split(' ')[0]}'),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: editDueDate ?? now,
                        firstDate: now,
                        lastDate: DateTime(now.year + 5),
                      );
                      if (picked != null) {
                        setState(() {
                          editDueDate = picked;
                        });
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _editTask(index, editController.text, editDueDate);
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('To-Do List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Delete All Tasks',
            onPressed: _tasks.isNotEmpty
                ? () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete All Tasks?'),
                        content: const Text('Are you sure you want to delete all tasks?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              _deleteAllTasks();
                              Navigator.of(context).pop();
                            },
                            child: const Text('Delete All'),
                          ),
                        ],
                      ),
                    );
                  }
                : null,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'Add a new task',
                    ),
                    onSubmitted: (_) => _addTask(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  tooltip: 'Pick Due Date',
                  onPressed: () => _pickDueDate(context),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addTask,
                ),
              ],
            ),
          ),
          if (_selectedDueDate != null)
            Padding(
              padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
              child: Row(
                children: [
                  Text('Due: \\${_selectedDueDate!.toLocal().toString().split(' ')[0]}'),
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _selectedDueDate = null;
                      });
                    },
                  ),
                ],
              ),
            ),
          Expanded(
            child: _tasks.isEmpty
                ? const Center(child: Text('No tasks yet!'))
                : ListView.builder(
                    itemCount: _tasks.length,
                    itemBuilder: (context, index) {
                      final task = _tasks[index];
                      return Dismissible(
                        key: Key(task.title + index.toString()),
                        onDismissed: (direction) => _removeTask(index),
                        background: Container(color: Colors.red),
                        child: ListTile(
                          leading: Checkbox(
                            value: task.completed,
                            onChanged: (_) => _toggleComplete(index),
                          ),
                          title: Text(
                            task.title,
                            style: TextStyle(
                              decoration: task.completed
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          subtitle: task.dueDate != null
                              ? Text('Due: \\${task.dueDate!.toLocal().toString().split(' ')[0]}')
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showEditDialog(index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _removeTask(index),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
} 