import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class TodoTask {
  String id;
  String title;
  String description;
  DateTime? deadline;
  DateTime? reminder;
  double progress; // 0.0 to 1.0
  String priority; // Low, Medium, High
  String category;
  bool isDone;

  TodoTask({
    required this.id,
    required this.title,
    this.description = "",
    this.deadline,
    this.reminder,
    this.progress = 0.0,
    this.priority = "Medium",
    this.category = "Personal",
    this.isDone = false,
  });
}

class TaskManagerScreen extends StatefulWidget {
  const TaskManagerScreen({super.key});

  @override
  State<TaskManagerScreen> createState() => _TaskManagerScreenState();
}

class _TaskManagerScreenState extends State<TaskManagerScreen> {
  final List<TodoTask> _tasks = [
    TodoTask(
      id: "1",
      title: "Complete Assignment 1",
      description: "Submit the math report before 5 PM",
      deadline: DateTime.now().add(const Duration(days: 1)),
      priority: "High",
      category: "Academic",
      progress: 0.34,
    ),
    TodoTask(
      id: "2",
      title: "Read Chapter 4",
      isDone: true,
      category: "Academic",
      progress: 1.0,
    ),
  ];

  String _searchQuery = "";
  String _selectedCategory = "All";
  final List<String> _categories = [
    "All",
    "Academic",
    "Personal",
    "Research",
    "Side projects",
  ];

  List<TodoTask> get _filteredTasks {
    return _tasks.where((task) {
      final matchesSearch = task.title.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final matchesCategory =
          _selectedCategory == "All" || task.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  Map<String, List<TodoTask>> get _groupedTasks {
    final Map<String, List<TodoTask>> grouped = {
      "Overdue": [],
      "Today": [],
      "Upcoming": [],
      "Completed": [],
    };

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (var task in _filteredTasks) {
      if (task.isDone) {
        grouped["Completed"]!.add(task);
      } else if (task.deadline == null) {
        grouped["Upcoming"]!.add(task);
      } else {
        final taskDate = DateTime(
          task.deadline!.year,
          task.deadline!.month,
          task.deadline!.day,
        );
        if (taskDate.isBefore(today)) {
          grouped["Overdue"]!.add(task);
        } else if (taskDate.isAtSameMomentAs(today)) {
          grouped["Today"]!.add(task);
        } else {
          grouped["Upcoming"]!.add(task);
        }
      }
    }
    return grouped;
  }

  void _showAddTaskDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    DateTime? selectedDeadline;
    DateTime? selectedReminder;
    double progress = 0.0;
    String priority = "Medium";
    String category = _categories[1]; // Default to first non-All category

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            "New To-Do task",
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Task name",
                    hintText: "Example Task",
                  ),
                ),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: "Description"),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (date != null) {
                            setDialogState(() => selectedDeadline = date);
                          }
                        },
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(
                          selectedDeadline == null
                              ? "Deadline"
                              : DateFormat('MMM d').format(selectedDeadline!),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (time != null) {
                            final now = DateTime.now();
                            setDialogState(
                              () => selectedReminder = DateTime(
                                now.year,
                                now.month,
                                now.day,
                                time.hour,
                                time.minute,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.alarm, size: 18),
                        label: Text(
                          selectedReminder == null
                              ? "Reminder"
                              : DateFormat('HH:mm').format(selectedReminder!),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text("Progress: ", style: GoogleFonts.outfit(fontSize: 12)),
                    Expanded(
                      child: Slider(
                        value: progress,
                        onChanged: (val) =>
                            setDialogState(() => progress = val),
                      ),
                    ),
                    Text(
                      "${(progress * 100).toInt()}%",
                      style: GoogleFonts.outfit(fontSize: 12),
                    ),
                  ],
                ),
                DropdownButtonFormField<String>(
                  value: priority,
                  decoration: const InputDecoration(labelText: "Priority"),
                  items: ["Low", "Medium", "High"]
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (val) => setDialogState(() => priority = val!),
                ),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: "Category"),
                  items: _categories
                      .where((c) => c != "All")
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) => setDialogState(() => category = val!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCEL"),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  setState(() {
                    _tasks.add(
                      TodoTask(
                        id: DateTime.now().toString(),
                        title: nameController.text,
                        description: descController.text,
                        deadline: selectedDeadline,
                        reminder: selectedReminder,
                        progress: progress,
                        priority: priority,
                        category: category,
                      ),
                    );
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text("OKAY"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groupedTasks;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "To-Do List",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [IconButton(icon: const Icon(Icons.search), onPressed: () {})],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search tasks...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                filled: true,
                fillColor: theme.cardColor,
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: _categories
                  .map(
                    (cat) => Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: _selectedCategory == cat,
                        onSelected: (selected) =>
                            setState(() => _selectedCategory = cat),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: groups.entries.where((e) => e.value.isNotEmpty).expand((
                entry,
              ) {
                return [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: GoogleFonts.outfit(
                            color: entry.key == "Overdue"
                                ? Colors.red
                                : Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          "${entry.value.length}",
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const Divider(thickness: 1.5),
                  ...entry.value.map((task) => _buildTaskTile(task)),
                  const SizedBox(height: 16),
                ];
              }).toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTaskTile(TodoTask task) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Checkbox(
          value: task.isDone,
          onChanged: (val) => setState(() => task.isDone = val ?? false),
        ),
        title: Text(
          task.title,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            decoration: task.isDone ? TextDecoration.lineThrough : null,
            color: task.isDone ? Colors.grey : null,
          ),
        ),
        subtitle: task.deadline != null
            ? Text(
                "Deadline: ${DateFormat('MMM d, y').format(task.deadline!)}",
                style: TextStyle(
                  fontSize: 12,
                  color: task.deadline!.isBefore(DateTime.now()) && !task.isDone
                      ? Colors.red
                      : Colors.grey,
                ),
              )
            : const Text(
                "No Deadline",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (task.description.isNotEmpty) ...[
                  Text(task.description, style: GoogleFonts.outfit()),
                  const SizedBox(height: 10),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoTag(task.category, Colors.teal),
                    _buildInfoTag(
                      task.priority,
                      _getPriorityColor(task.priority),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: task.progress,
                  backgroundColor: Colors.grey[200],
                ),
                const SizedBox(height: 5),
                Text(
                  "Progress: ${(task.progress * 100).toInt()}%",
                  style: const TextStyle(fontSize: 12),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.grey),
                    onPressed: () => setState(() => _tasks.remove(task)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case "High":
        return Colors.red;
      case "Medium":
        return Colors.orange;
      default:
        return Colors.green;
    }
  }
}
