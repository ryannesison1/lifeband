// screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/models.dart';

class ProfileScreen extends StatefulWidget {
  final UserProfile? userProfile;
  final DatabaseReference userRef;

  const ProfileScreen({
    super.key,
    required this.userProfile,
    required this.userRef,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;

  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _bloodTypeController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _ageController = TextEditingController();
    _bloodTypeController = TextEditingController();
    _updateControllers(widget.userProfile);
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userProfile != oldWidget.userProfile && !_isEditing) {
      _updateControllers(widget.userProfile);
    }
  }

  void _updateControllers(UserProfile? profile) {
    _nameController.text = profile?.name ?? '';
    _ageController.text = profile?.age.toString() ?? '0';
    _bloodTypeController.text = profile?.bloodType ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _bloodTypeController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        await widget.userRef.child('profile').update({
          'name': _nameController.text,
          'age': int.parse(_ageController.text),
          'bloodType': _bloodTypeController.text,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
          );
        }
        setState(() => _isEditing = false);
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update profile: $error'), backgroundColor: Theme.of(context).colorScheme.error),
          );
        }
      }
    }
  }

  void _showContactDialog({EmergencyContact? contact}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: contact?.name);
    // MODIFICATION: Initialize with '+63' for new contacts
    final phoneController = TextEditingController(text: contact?.phone ?? '+63');
    final emailController = TextEditingController(text: contact?.email);
    final isEditing = contact != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Contact' : 'Add New Contact'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: nameController, decoration: const InputDecoration(labelText: 'Name'), validator: (v) => v!.isEmpty ? 'Required' : null),
              // MODIFICATION: Added maxLength and a new validator for the phone number
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  counterText: "", // Hides the default maxLength counter
                ),
                keyboardType: TextInputType.phone,
                maxLength: 13, // 1. Limit input to 13 characters
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Phone number is required.';
                  }
                  // 2. Enforce the '+63' format and length
                  if (!value.startsWith('+63')) {
                    return 'Number must start with +63.';
                  }
                  if (value.length != 13) {
                    return 'Number must be 13 characters long.';
                  }
                  return null; // Return null if valid
                },
              ),
              TextFormField(controller: emailController, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress, validator: (v) => v!.isEmpty || !v.contains('@') ? 'Invalid Email' : null),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            child: const Text('Save'),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final newContactData = {
                  'name': nameController.text,
                  'phone': phoneController.text,
                  'email': emailController.text,
                };

                final contactsRef = widget.userRef.child('profile/emergencyContacts');

                try {
                  if (isEditing) {
                    await contactsRef.child(contact.id).update(newContactData);
                  } else {
                    await contactsRef.push().set(newContactData);
                  }
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Contact ${isEditing ? 'updated' : 'added'}!'), backgroundColor: Colors.green),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Operation failed: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  // NEW: Function to delete a contact
  Future<void> _deleteContact(String contactId) async {
    try {
      await widget.userRef.child('profile/emergencyContacts/$contactId').remove();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contact deleted.'), backgroundColor: Colors.orange),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: $e'), backgroundColor: Colors.red),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    if (widget.userProfile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Elder's Personal Info Section
          Form(
            key: _formKey,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Elder Personal Information', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    _buildProfileField(label: 'Name', controller: _nameController, icon: Icons.person_outline, validator: (v) => v!.isEmpty ? 'Please enter a name.' : null),
                    const SizedBox(height: 16),
                    _buildProfileField(label: 'Age', controller: _ageController, icon: Icons.cake_outlined, keyboardType: TextInputType.number, validator: (v) => v == null || int.tryParse(v) == null ? 'Please enter a valid age.' : null),
                    const SizedBox(height: 16),
                    _buildProfileField(label: 'Blood Type', controller: _bloodTypeController, icon: Icons.bloodtype_outlined, validator: (v) => v!.isEmpty ? 'Please enter a blood type.' : null),
                    const SizedBox(height: 16),
                    if (_isEditing)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(child: const Text('Cancel'), onPressed: () => setState(() { _isEditing = false; _updateControllers(widget.userProfile); })),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(icon: const Icon(Icons.save), label: const Text('Save'), onPressed: _saveProfile),
                        ],
                      )
                    else
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(icon: const Icon(Icons.edit, size: 20), label: const Text('Edit Profile'), onPressed: () => setState(() => _isEditing = true)),
                      )
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Emergency Contacts Section
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Emergency Contacts', style: Theme.of(context).textTheme.titleLarge),
                      IconButton(icon: const Icon(Icons.add_circle, color: Colors.green), onPressed: () => _showContactDialog(), tooltip: 'Add new contact'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (widget.userProfile!.emergencyContacts.isEmpty)
                    const Text('No emergency contacts added.')
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.userProfile!.emergencyContacts.length,
                      itemBuilder: (context, index) {
                        final contact = widget.userProfile!.emergencyContacts[index];
                        return ListTile(
                          leading: CircleAvatar(child: Text(contact.name[0])),
                          title: Text(contact.name),
                          subtitle: Text('${contact.phone}\n${contact.email}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showContactDialog(contact: contact), tooltip: 'Edit'),
                              IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteContact(contact.id), tooltip: 'Delete'),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildProfileField({required String label, required TextEditingController controller, required IconData icon, TextInputType keyboardType = TextInputType.text, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      enabled: _isEditing,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        filled: !_isEditing,
        fillColor: Colors.grey[200],
      ),
      validator: validator,
    );
  }
}