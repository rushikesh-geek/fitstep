import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/profile_viewmodel.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late ProfileViewModel _profileViewModel;

  @override
  void initState() {
    super.initState();
    _profileViewModel = context.read<ProfileViewModel>();
    _loadUserProfile();
  }

  void _loadUserProfile() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _profileViewModel.loadUserProfile(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.purple,
      ),
      body: Consumer2<ProfileViewModel, AuthViewModel>(
        builder: (context, profileVM, authVM, _) {
          if (profileVM.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () async {
              _loadUserProfile();
            },
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Profile Header
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.purple,
                          child: Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          authVM.userEmail ?? 'User',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // User Information or Edit Section
                if (!profileVM.isEditing)
                  _buildViewMode(context, profileVM, authVM, uid)
                else
                  _buildEditMode(context, profileVM, uid),

                const SizedBox(height: 24),

                // Error Message
                if (profileVM.errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Text(
                      profileVM.errorMessage ?? '',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildViewMode(BuildContext context, ProfileViewModel profileVM,
      AuthViewModel authVM, String? uid) {
    return Column(
      children: [
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'User Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (profileVM.userModel != null) ...[
                  _buildInfoRow('Username', profileVM.userModel!.username),
                  _buildInfoRow('Age', '${profileVM.userModel!.age}'),
                  _buildInfoRow('Height', '${profileVM.userModel!.height} cm'),
                  _buildInfoRow('Weight', '${profileVM.userModel!.weight} kg'),
                  _buildInfoRow(
                    'BMI',
                    profileVM.bmi > 0
                        ? profileVM.bmi.toStringAsFixed(1)
                        : 'Not set',
                  ),
                  _buildInfoRow('Step Goal', '${profileVM.userModel!.stepGoal}'),
                ] else ...[
                  _buildInfoRow('Username', 'Not set'),
                  _buildInfoRow('Age', 'Not set'),
                  _buildInfoRow('Height', 'Not set'),
                  _buildInfoRow('Weight', 'Not set'),
                  _buildInfoRow('BMI', 'Not set'),
                  _buildInfoRow('Step Goal', '8000'),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: profileVM.enableEdit,
                icon: const Icon(Icons.edit),
                label: const Text('Edit Profile'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  authVM.logout();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Logged out')),
                  );
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEditMode(BuildContext context, ProfileViewModel profileVM, String? uid) {
    return Column(
      children: [
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Edit User Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildEditField('Username', profileVM.usernameController),
                _buildEditField('Age', profileVM.ageController, isNumeric: true),
                _buildEditField('Height (cm)', profileVM.heightController,
                    isNumeric: true),
                _buildEditField('Weight (kg)', profileVM.weightController,
                    isNumeric: true, isDecimal: true),
                _buildEditField('Step Goal', profileVM.stepGoalController,
                    isNumeric: true),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  if (uid != null) {
                    profileVM.saveUserProfile(uid);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile saved')),
                    );
                  }
                },
                icon: const Icon(Icons.save),
                label: const Text('Save'),
                style:
                    ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: profileVM.cancelEdit,
                icon: const Icon(Icons.cancel),
                label: const Text('Cancel'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditField(String label, TextEditingController controller,
      {bool isNumeric = false, bool isDecimal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: TextField(
        controller: controller,
        keyboardType: isNumeric
            ? (isDecimal ? TextInputType.number : TextInputType.number)
            : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }
}
