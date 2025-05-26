import 'dart:io';

void main() async {
  // Find the better_player package in the Flutter cache
  final flutterCache = Platform.environment['PUB_CACHE'] ?? 
      (Platform.isWindows 
       ? '${Platform.environment['LOCALAPPDATA']}\\Pub\\Cache'
       : '${Platform.environment['HOME']}/.pub-cache');
  
  print('Looking for better_player package in: $flutterCache');
  
  final betterPlayerDir = Directory('$flutterCache/hosted/pub.dev/better_player-0.0.84');
  if (!await betterPlayerDir.exists()) {
    print('Error: better_player package not found in the cache.');
    exit(1);
  }
  
  print('Found better_player package at: ${betterPlayerDir.path}');
  
  // Add namespace to android/build.gradle
  final androidBuildGradle = File('${betterPlayerDir.path}/android/build.gradle');
  if (!await androidBuildGradle.exists()) {
    print('Error: android/build.gradle not found in better_player package.');
    exit(1);
  }
  
  print('Patching ${androidBuildGradle.path}');
  String content = await androidBuildGradle.readAsString();
  
  // Add the namespace to the android block if not already present
  if (!content.contains('namespace')) {
    content = content.replaceFirst(
      'android {',
      'android {\n    namespace "com.jhomlala.better_player"',
    );
    
    await androidBuildGradle.writeAsString(content);
    print('Added namespace to android/build.gradle');
  } else {
    print('Namespace already exists in android/build.gradle');
  }
  
  print('Patch completed successfully!');
} 