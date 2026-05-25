import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:overlay_support/overlay_support.dart';
import 'presentation/routes/app_router.dart';  // ← Importación necesaria

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return OverlaySupport(
      child: MaterialApp.router(
        title: 'DriverAI',
        theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
        routerConfig: appRouter,  // ← ahora definido
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}