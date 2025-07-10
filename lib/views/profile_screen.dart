import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<Map<String, int>> _fetchCounts(String uid) async {
    final itemsSnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('items')
            .get();

    final outfitsSnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('outfits')
            .get();

    return {'items': itemsSnapshot.size, 'outfits': outfitsSnapshot.size};
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body:
          user == null
              ? const Center(child: Text('Not logged in'))
              : FutureBuilder<Map<String, int>>(
                future: _fetchCounts(user.uid),
                builder: (context, countSnapshot) {
                  if (countSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final itemCount = countSnapshot.data?['items'] ?? 0;
                  final outfitCount = countSnapshot.data?['outfits'] ?? 0;

                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage:
                              user.photoURL != null
                                  ? NetworkImage(user.photoURL!)
                                  : null,
                          backgroundColor: Colors.black12,
                          child:
                              user.photoURL == null
                                  ? const Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Colors.black54,
                                  )
                                  : null,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          user.displayName ?? 'Anonymous',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user.email ?? 'No email',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _statTile("Items", itemCount),
                            const SizedBox(width: 32),
                            _statTile("Outfits", outfitCount),
                          ],
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () async {
                            await FirebaseAuth.instance.signOut();
                            if (context.mounted) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                                (route) => false,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 14,
                            ),
                          ),
                          child: const Text('Log out'),
                        ),
                      ],
                    ),
                  );
                },
              ),
    );
  }

  Widget _statTile(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 16, color: Colors.black54),
        ),
      ],
    );
  }
}
