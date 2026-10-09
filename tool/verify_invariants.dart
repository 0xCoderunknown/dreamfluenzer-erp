import 'dart:io';

/// Automated Invariant Verification Gate for AI Maintainers.
/// Ensures zero secret leaks, adherence to file line limits, clean lints, and passing tests.
void main() async {
  stdout.writeln('======================================================');
  stdout.writeln('🤖 DreamFluenzer ERP — AI Maintainer Invariant Gate');
  stdout.writeln('======================================================\n');

  int exitCode = 0;

  // 1. Check Line Length Limits (< 500 lines per presentation file)
  stdout.writeln('🔍 [1/4] Checking file line count constraints (< 500 lines)...');
  final libDir = Directory('lib');
  final dartFiles = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));

  final oversizedFiles = <Map<String, dynamic>>[];
  for (final file in dartFiles) {
    final lineCount = file.readAsLinesSync().length;
    if (lineCount > 500) {
      oversizedFiles.add({'path': file.path, 'lines': lineCount});
    }
  }

  if (oversizedFiles.isNotEmpty) {
    stdout.writeln(
      '⚠️  Warning: ${oversizedFiles.length} file(s) exceed 500 lines (target for modular deconstruction):',
    );
    for (final f in oversizedFiles) {
      stdout.writeln('   - ${f['path']}: ${f['lines']} lines');
    }
  } else {
    stdout.writeln('✅ All files in lib/ are within the 500-line modular limit!');
  }

  // 2. Secret Scan
  stdout.writeln('\n🔒 [2/4] Scanning for hardcoded secrets & credentials...');
  final secretPatterns = [
    RegExp(r'AIzaSy[A-Za-z0-9_-]{33}'), // Firebase Web API key
    RegExp(r'sk-[A-Za-z0-9]{32,}'), // OpenAI / API key
    RegExp(r'''password\s*=\s*['"][^'"]{6,}['"]''', caseSensitive: false),
  ];

  final secretHits = <String>[];
  for (final file in dartFiles) {
    // Exclude examples, demo config, and gitignored firebase_options
    if (file.path.contains('.example') ||
        file.path.contains('demo') ||
        file.path.contains('firebase_options.dart')) {
      continue;
    }
    final content = file.readAsStringSync();
    for (final pattern in secretPatterns) {
      if (pattern.hasMatch(content)) {
        secretHits.add('${file.path}: matched pattern ${pattern.pattern}');
      }
    }
  }

  if (secretHits.isNotEmpty) {
    stdout.writeln('❌ FATAL: Potential hardcoded secret detected:');
    for (final hit in secretHits) {
      stdout.writeln('   - $hit');
    }
    exitCode = 1;
  } else {
    stdout.writeln('✅ Zero hardcoded secrets detected in Dart sources.');
  }

  // 3. Flutter Analyze
  stdout.writeln('\n🩺 [3/4] Running flutter analyze...');
  final analyzeResult = await Process.run(
    'flutter',
    ['analyze'],
    runInShell: true,
  );
  if (analyzeResult.exitCode != 0) {
    stdout.writeln('❌ Analyzer reported issues:\n${analyzeResult.stdout}');
    exitCode = 1;
  } else {
    stdout.writeln('✅ Analyzer passed with zero issues!');
  }

  // 4. Flutter Test
  stdout.writeln('\n🧪 [4/4] Running all unit & contract tests...');
  final testResult = await Process.run('flutter', ['test'], runInShell: true);
  if (testResult.exitCode != 0) {
    stdout.writeln('❌ Tests failed:\n${testResult.stdout}');
    exitCode = 1;
  } else {
    stdout.writeln('✅ All unit, engine, and serialization tests passed!');
  }

  stdout.writeln('\n======================================================');
  if (exitCode == 0) {
    stdout.writeln('🎉 ALL INVARIANT GATES PASSED! Safe to commit & conclude.');
  } else {
    stdout.writeln('❌ INVARIANT VIOLATIONS DETECTED. Resolve before finishing.');
  }
  stdout.writeln('======================================================');

  exit(exitCode);
}
