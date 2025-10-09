import 'package:flutter/material.dart';
import 'package:neo/services/database.dart';
import 'package:neo/services/department.dart';
import 'package:neo/services/course_model.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/streams.dart' show CombineLatestStream;
import 'package:intl/intl.dart';

class Notifications extends StatefulWidget {
  const Notifications({super.key});


  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  @override
  Widget build(BuildContext context) {
    final departments = Provider.of<List<Department>?>(context);

    final theme = Theme.of(context);
    final department = DatabaseService();
    return Scaffold(
      // backgroundColor: ,
      appBar: AppBar(title: const Text("Notifications"), centerTitle: true),
      body: StreamBuilder<List<dynamic>>(
        stream: _getCombinedStream(department),
        builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No notifications found"));
          }

          final notifications = snapshot.data!;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final item = notifications[index];
              IconData icon;
              String title;
              String subtitle = '';
              DateTime? creationDate;

              if (item is Department) {
                icon = Icons.store;
                title = "New Department Added: ${item.name}";
                subtitle = item.description ?? 'No description';
                creationDate = item.createdAt;
              } else if (item is Course) {
                icon = Icons.book;
                title = "New Course Added: ${item.name}";
                subtitle = 'Course Code: ${item.code}';
                creationDate = item.createdAt;
              } else {
                icon = Icons.info_outline;
                title = "Unknown Notification";
              }

              return Card(
                elevation: 4,
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  leading: Icon(icon, size: 32),
                  title: Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(subtitle),
                      if (creationDate != null) Text(DateFormat.yMMMd().add_jm().format(creationDate), style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  // Customize the appearance here
                ),
              );
            }
            );
          }
      ),
      );
    
  }

  // Helper function to combine department and course streams
  Stream<List<dynamic>> _getCombinedStream(DatabaseService dbService) {
    return CombineLatestStream.list<dynamic>([
      dbService.departments,
      dbService.courseData, // Make sure this stream returns a List<Course>
    ]).map((results) {
      final List<Department> departments = results[0] as List<Department>;
      final List<Course> courses = results[1] as List<Course>;

      return [...departments, ...courses];
    });
  }
}
