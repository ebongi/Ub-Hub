import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:neo/services/database.dart';
import 'package:neo/services/exam_event.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateExamScreen extends StatefulWidget {
  final ExamEvent? exam;
  const CreateExamScreen({super.key, this.exam});

  @override
  State<CreateExamScreen> createState() => _CreateExamScreenState();
}

class _CreateExamScreenState extends State<CreateExamScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _venueController;
  late TextEditingController _descriptionController;

  String _category = 'Midterm';
  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  DateTime _endDate = DateTime.now();
  TimeOfDay _endTime = const TimeOfDay(hour: 11, minute: 0);

  bool _isLoading = false;

  final List<String> _categories = [
    'Midterm',
    'Final',
    'Quiz',
    'Assignment',
    'Practical',
    'Presentation',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.exam?.name ?? '');
    _venueController = TextEditingController(text: widget.exam?.venue ?? '');
    _descriptionController = TextEditingController(
      text: widget.exam?.description ?? '',
    );

    if (widget.exam != null) {
      _category = widget.exam!.category;
      _startDate = widget.exam!.startTime;
      _startTime = TimeOfDay.fromDateTime(widget.exam!.startTime);
      _endDate = widget.exam!.endTime;
      _endTime = TimeOfDay.fromDateTime(widget.exam!.endTime);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _venueController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) _endDate = _startDate;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _saveExam() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final start = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        _startTime.hour,
        _startTime.minute,
      );
      final end = DateTime(
        _endDate.year,
        _endDate.month,
        _endDate.day,
        _endTime.hour,
        _endTime.minute,
      );

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final dbService = DatabaseService(uid: user.id);

      final examEvent = ExamEvent(
        id: widget.exam?.id ?? '',
        userId: user.id,
        name: _nameController.text,
        category: _category,
        venue: _venueController.text,
        startTime: start,
        endTime: end,
        description: _descriptionController.text,
      );

      try {
        if (widget.exam == null) {
          await dbService.addExam(examEvent);
        } else {
          await dbService.updateExam(examEvent);
        }
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error saving exam: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.exam == null ? "Create New Event" : "Edit Event",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDropdownField(
                label: "Event Category",
                value: _category,
                items: _categories,
                onChanged: (val) => setState(() => _category = val!),
              ),
              const SizedBox(height: 20),
              _buildTextField(
                label: "Event Name",
                controller: _nameController,
                hint: "e.g. Computer Science Final",
                required: true,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                label: "Venue",
                controller: _venueController,
                hint: "e.g. Amphi 700",
                required: true,
              ),
              const SizedBox(height: 20),
              _buildDateTimePicker(
                label: "Event Start Time",
                date: _startDate,
                time: _startTime,
                onDateTap: () => _selectDate(context, true),
                onTimeTap: () => _selectTime(context, true),
              ),
              const SizedBox(height: 20),
              _buildDateTimePicker(
                label: "Event End Time",
                date: _endDate,
                time: _endTime,
                onDateTap: () => _selectDate(context, false),
                onTimeTap: () => _selectTime(context, false),
              ),
              const SizedBox(height: 20),
              _buildTextField(
                label: "Event Description",
                controller: _descriptionController,
                hint: "Add any additional details...",
                maxLines: 3,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveExam,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          "Submit",
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    bool required = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
            if (required) const Text(" *", style: TextStyle(color: Colors.red)),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.outfit(),
          decoration: InputDecoration(
            hintText: hint,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          validator: required
              ? (value) => value == null || value.isEmpty ? "Required" : null
              : null,
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e, style: GoogleFonts.outfit()),
                ),
              )
              .toList(),
          onChanged: onChanged,
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimePicker({
    required String label,
    required DateTime date,
    required TimeOfDay time,
    required VoidCallback onDateTap,
    required VoidCallback onTimeTap,
  }) {
    final dateStr = DateFormat('dd-MMM-yyyy').format(date);
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
            const Text(" *", style: TextStyle(color: Colors.red)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: InkWell(
                    onTap: onDateTap,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 20,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Text(dateStr, style: GoogleFonts.outfit()),
                        ],
                      ),
                    ),
                  ),
                ),
                VerticalDivider(
                  width: 1,
                  color: Colors.white.withOpacity(0.1),
                  indent: 12,
                  endIndent: 12,
                ),
                Expanded(
                  flex: 2,
                  child: InkWell(
                    onTap: onTimeTap,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 20,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            timeStr.substring(0, 5),
                            style: GoogleFonts.outfit(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
