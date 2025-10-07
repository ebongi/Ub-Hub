import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neo/services/auth.dart' show Authentication;
import 'package:neo/services/database.dart';
import 'package:neo/theme_provider.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final Authentication authentication = Authentication();
    // final DatabaseService _database =   DatabaseService();
    return Scaffold(
      appBar: AppBar(title: Text('Settings', style: GoogleFonts.poppins())),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [

          Card(
            child: ListTile(
              onTap: () async {
                
              },
              title:  Text("Edit  Data",style: GoogleFonts.poppins(fontWeight: FontWeight.w500),),
            ),
          ),
          Divider(),
          Card(
            child: ListTile(
              leading: const Icon(Icons.dark_mode_outlined),
              title: Text(
                'Dark Mode',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              trailing: Switch(
                value: themeProvider.themeMode == ThemeMode.dark,
                onChanged: (value) {
                  final provider = Provider.of<ThemeProvider>(
                    context,
                    listen: false,
                  );
                  provider.toggleTheme(value);
                },
              ),
            ),
          ),
          Divider(),
           Card(
             
             child: ListTile(
              title: Text(
                'Logout',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              onTap: () async {
                await authentication.signUserOut();
              }
             ),
           )
        ],
      ),
    );
  }
}
