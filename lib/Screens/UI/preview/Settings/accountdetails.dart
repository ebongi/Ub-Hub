import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:neo/Screens/Shared/constanst.dart';
import 'package:neo/services/database.dart';
import 'package:provider/provider.dart';

class Accountdetails extends StatefulWidget {
  const Accountdetails({super.key});

  @override
  State<Accountdetails> createState() => _AccountdetailsState();
}

class _AccountdetailsState extends State<Accountdetails> {
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  bool _isLoading = false;

  late TextEditingController _nameController;
  late TextEditingController _matriculeController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<User?>(context, listen: false);
    final userModel = Provider.of<UserModel>(context, listen: false);

    _nameController = TextEditingController(
      text: user?.displayName ?? userModel.name,
    );
    _matriculeController = TextEditingController(
      text: userModel.matricule ?? 'N/A',
    );
    _phoneController = TextEditingController(
      text: user?.phoneNumber ?? userModel.phoneNumber ?? 'N/A',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _matriculeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final user = Provider.of<User?>(context, listen: false);
      final userModel = Provider.of<UserModel>(context, listen: false);
      final dbService = DatabaseService(uid: user!.uid);

      try {
        // Update display name in Firebase Auth
        if (user.displayName != _nameController.text) {
          await user.updateDisplayName(_nameController.text);
        }

        // Update custom data in Firestore
        await dbService.updateUserData(
          name: _nameController.text,
          matricule: _matriculeController.text,
          phoneNumber: _phoneController.text,
        );

        // Update local UserModel
        userModel.update(
          name: _nameController.text,
          matricule: _matriculeController.text,
          phoneNumber: _phoneController.text,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() => _isEditing = false);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update profile: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(
            () => _isLoading = false,
          ); // This is already correct, but good to confirm.
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = Provider.of<User?>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final userModel = Provider.of<UserModel>(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Account Info"),
        centerTitle: true,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: Icon(
                _isEditing ? Icons.save : Icons.edit,
                color: theme.scaffoldBackgroundColor == const Color(0xFF121212)
                    ? Colors.white
                    : Colors.black,
              ),
              onPressed: () {
                if (_isEditing) {
                  _saveProfile();
                } else {
                  setState(() => _isEditing = true);
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: theme.primaryColor.withOpacity(0.8),
                radius: screenWidth * 0.2, // Radius is 20% of screen width
                child: Icon(
                  Icons.person,
                  size: screenWidth * 0.25,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              if (_isEditing) ...[
                _buildEditItem(
                  controller: _nameController,
                  label: "Name",
                  icon: Icons.account_circle_rounded,
                ),
                _buildEditItem(
                  controller: _matriculeController,
                  label: "Matricule",
                  icon: Iconsax.archive4,
                ),
                _buildEditItem(
                  controller: _phoneController,
                  label: "Phone Number",
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                ),
                _buildDetailItem(
                  icon: Icons.email,
                  label: "Email",
                  value: user?.email ?? 'N/A',
                  isEditable: false,
                ),
              ] else ...[
                _buildDetailItem(
                  icon: Icons.account_circle_rounded,
                  label: "Name",
                  value: userModel.name!.isNotEmpty
                      ? userModel.name.toString()
                      : 'N/A',
                ),
                _buildDetailItem(
                  icon: Iconsax.archive4,
                  label: "Matricule",
                  value: userModel.matricule ?? 'N/A',
                ),
                _buildDetailItem(
                  icon: Icons.email,
                  label: "Email",
                  value: userModel.email.toString(),
                ),
                _buildDetailItem(
                  icon: Icons.phone,
                  label: "Phone Number",
                  value: userModel.phoneNumber ?? 'N/A',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditItem({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    bool isEditable = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          ListTile(
            leading: Icon(icon),
            title: Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              value,
              style: GoogleFonts.poppins(fontSize: 18, letterSpacing: 1.2),
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }
}
