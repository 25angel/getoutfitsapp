import 'package:flutter/material.dart';
import '/views/closet_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentIndex = 0;

  final List<Map<String, String>> _pages = [
    {
      'image': 'assets/onboarding1.png',
      'text': 'Build a closet by importing photos you took or screenshotted.',
    },
    {
      'image': 'assets/onboarding2.png',
      'text':
          'Check possible looks based on items you have. Save favorite ones.',
    },
    {
      'image': 'assets/onboarding3.png',
      'text': 'Shop smarter by checking possible outfits before you buy.',
    },
  ];

  String? _selectedType;
  final List<String> _goals = [
    'Organize wardrobe easily',
    'Pick outfits quickly',
    'Find fresh outfit ideas',
    'Shop smart, buy less',
    'Plan outfits for special occasion',
    'Other',
    "Don't want to answer",
  ];
  final Set<String> _selectedGoals = {};

  Future<void> _finishOnboarding() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'seenOnboarding': true},
      );
    }

    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ClosetScreen()),
      );
    }
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        5,
        (i) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i == _currentIndex ? Colors.orange : Colors.grey.shade400,
          ),
        ),
      ),
    );
  }

  Widget _buildPageContent() {
    if (_currentIndex < 3) {
      final item = _pages[_currentIndex];
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(item['image']!, height: 220),
          const SizedBox(height: 32),
          Text(
            item['text']!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18),
          ),
        ],
      );
    } else if (_currentIndex == 3) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Optimize experience for...",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text("Select type of items that you want to see"),
          const SizedBox(height: 24),
          RadioListTile(
            title: const Text("Womenswear"),
            value: "Womenswear",
            groupValue: _selectedType,
            onChanged: (val) => setState(() => _selectedType = val),
          ),
          RadioListTile(
            title: const Text("Menswear"),
            value: "Menswear",
            groupValue: _selectedType,
            onChanged: (val) => setState(() => _selectedType = val),
          ),
          RadioListTile(
            title: const Text("Everything"),
            value: "Everything",
            groupValue: _selectedType,
            onChanged: (val) => setState(() => _selectedType = val),
          ),
        ],
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "What are your goals?",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text("Select as many as you need"),
          const SizedBox(height: 24),
          ..._goals.map(
            (goal) => CheckboxListTile(
              title: Text(goal),
              value: _selectedGoals.contains(goal),
              onChanged: (val) {
                setState(() {
                  if (val == true) {
                    _selectedGoals.add(goal);
                  } else {
                    _selectedGoals.remove(goal);
                  }
                });
              },
            ),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: _buildPageContent(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentIndex > 0)
                  TextButton(
                    onPressed: () => setState(() => _currentIndex--),
                    child: const Text('Back'),
                  )
                else
                  const SizedBox(width: 64),
                _buildDots(),
                TextButton(
                  onPressed: () {
                    if (_currentIndex == 4) {
                      _finishOnboarding();
                    } else {
                      setState(() => _currentIndex++);
                    }
                  },
                  child: Text(
                    _currentIndex == 4 ? 'Continue' : 'Next',
                    style: const TextStyle(color: Colors.orange),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
