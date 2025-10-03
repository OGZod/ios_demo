// Example of using the UserProvider in a widget
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/user_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Use Consumer to prevent unnecessary rebuilds
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final User? user = userProvider.user;
        final studentId = userProvider.userData?['identificationNumber'];
        if (user == null) {
          return Center(
            child: Text('Not logged in'),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Profile'),
            actions: [
              IconButton(
                icon: Icon(Icons.logout),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 20),
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                  child: user.photoURL == null
                      ? Icon(Icons.person, size: 60, color: Colors.grey[600])
                      : null,
                ),
                SizedBox(height: 20),
                Text(
                  user.displayName ?? (userProvider.isAdmin?'Lecturer':'Student'),
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  user.email ?? 'No email',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                SizedBox(height: 30),
                if(!userProvider.isAdmin)_buildProfileCard(
                  title: 'Account Information',
                  children: [
                    _buildProfileItem(
                      icon: Icons.badge,
                      title: ''
                          'Student ID Number',
                      subtitle: studentId.toString(),
                    ),
                    _buildProfileItem(
                      icon: Icons.verified_user,
                      title: 'Email Verified',
                      subtitle: user.emailVerified ? 'Yes' : 'No',
                    ),
                    // if (user.phoneNumber != null)
                    //   _buildProfileItem(
                    //     icon: Icons.phone,
                    //     title: 'Phone',
                    //     subtitle: user.phoneNumber??'',
                    //   ),
                  ],
                ),
                SizedBox(height: 16),
                _buildProfileCard(
                  title: 'Account Settings',
                  children: [
                    _buildActionItem(
                      icon: Icons.edit,
                      title: 'Edit Profile',
                      onTap: () {
                        // Navigate to edit profile screen
                      },
                    ),
                    _buildActionItem(
                      icon: Icons.password,
                      title: 'Change Password',
                      onTap: () {
                        // Navigate to change password screen
                      },
                    ),
                    _buildActionItem(
                      icon: Icons.delete,
                      title: 'Delete Account',
                      onTap: () {
                        // Show delete account confirmation
                      },
                      isDestructive: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileCard({required String title, required List<Widget> children}) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? Colors.red : Colors.blue,
            ),
            SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: isDestructive ? Colors.red : null,
              ),
            ),
            Spacer(),
            Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}