// Mengimpor pustaka antarmuka Material Design utama dari framework Flutter 
import 'package:flutter/material.dart'; 
// [PERUBAHAN TAHAP 7.5]: Tambahkan impor halaman Splash Screen 
import 'pages/splash_screen_page.dart'; 
 
// Fungsi utama (entry point) aplikasi 
void main() { 
  runApp(const SmartKasirApp()); 
} 
 
// Deklarasi kelas root aplikasi turunan StatelessWidget 
class SmartKasirApp extends StatelessWidget { 
  const SmartKasirApp({super.key}); 
 
  @override 
  Widget build(BuildContext context) { 
    return MaterialApp( 
      title: 'SmartKasir', 
      debugShowCheckedModeBanner: false, 
      theme: ThemeData( 
        useMaterial3: true, 
        colorScheme: ColorScheme.fromSeed( 
          seedColor: Color(0xFFFFB6C1), // Warna Baby Pink / Light Pink yang lembut
          brightness: Brightness.light, 
        ), 
        appBarTheme: const AppBarTheme( 
          centerTitle: true, 
          elevation: 2, 
          backgroundColor: Color(0xFFFF91A4), // Warna AppBar Baby Pink yang serasi dan elegan
          foregroundColor: Colors.white, 
        ), 
      ), 
      // [PERUBAHAN TAHAP 7.5]: Titik awal aplikasi dibuka pertama kali melalui SplashScreenPage() 
      home: const SplashScreenPage(), 
    ); 
  } 
}