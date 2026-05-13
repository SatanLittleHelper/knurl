import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/auth',
      builder: (context, state) =>
          const Scaffold(appBar: AppBar(title: Text('Auth'))),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) =>
          const Scaffold(appBar: AppBar(title: Text('Home'))),
    ),
    GoRoute(
      path: '/planner',
      builder: (context, state) =>
          const Scaffold(appBar: AppBar(title: Text('Planner'))),
    ),
    GoRoute(
      path: '/workout',
      builder: (context, state) =>
          const Scaffold(appBar: AppBar(title: Text('Active Workout'))),
    ),
    GoRoute(
      path: '/history',
      builder: (context, state) =>
          const Scaffold(appBar: AppBar(title: Text('History'))),
    ),
    GoRoute(
      path: '/exercises',
      builder: (context, state) =>
          const Scaffold(appBar: AppBar(title: Text('Exercise Library'))),
    ),
  ],
);
