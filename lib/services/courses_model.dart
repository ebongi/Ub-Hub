import 'course_model.dart';

class Courses {
  final List<Course> courses;
  final int? total;
  final int? pageSize;
  final int? page;

  Courses({
    required this.courses,
    this.total,
    this.pageSize,
    this.page,
  });
}