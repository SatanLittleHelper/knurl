import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/auth',
        builder: (context, state) =>
            Scaffold(appBar: AppBar(title: const Text('Auth'))),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) =>
            Scaffold(appBar: AppBar(title: const Text('Home'))),
      ),
      GoRoute(
        path: '/planner',
        builder: (context, state) =>
            Scaffold(appBar: AppBar(title: const Text('Planner'))),
      ),
      GoRoute(
        path: '/workout',
        builder: (context, state) =>
            Scaffold(appBar: AppBar(title: const Text('Active Workout'))),
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) =>
            Scaffold(appBar: AppBar(title: const Text('History'))),
      ),
      GoRoute(
        path: '/exercises',
        builder: (context, state) =>
            Scaffold(appBar: AppBar(title: const Text('Exercise Library'))),
      ),
    ],
  );
});
