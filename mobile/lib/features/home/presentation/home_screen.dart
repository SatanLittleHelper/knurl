// mobile/lib/features/home/presentation/home_screen.dart
import 'package:flutter/material.dart';
import 'package:knurl/shared/widgets/knurl_app_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: KnurlAppBar(),
      body: Center(child: Text('Home')),
    );
  }
}
