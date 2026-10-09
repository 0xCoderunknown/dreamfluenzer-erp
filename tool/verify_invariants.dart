import 'dart:io';

/// Automated Invariant Verification Gate for AI Maintainers.
/// Checks repository Dart formatting, presentation file sizes, secrets, analysis, and tests.
void main() async {
  stdout.writeln('======================================================');
  stdout.writeln('🤖 DreamFluenzer ERP — AI Maintainer Invariant Gate');
  stdout.writeln('======================================================\n');

  int exitCode = 0;

  stdout.writeln('🧹 [1/5] Checking repository Dart formatting...');
  final repositoryFilesResult = await Process.run('git', [
    'ls-files',
    '-co',
    '--exclude-standard',
    '-z',
  ], runInShell: true);
  if (repositoryFilesResult.exitCode != 0) {
    stdout.writeln(
      '❌ Could not list repository files:\n'
      '${repositoryFilesResult.stdout}${repositoryFilesResult.stderr}',
    );
    exitCode = 1;
  } else {
    final dartPaths = (repositoryFilesResult.stdout as String)
        .split('\x00')
        .where((path) => path.endsWith('.dart'))
        .toList();
    final formatResult = await Process.run('dart', [
      'format',
      '--output=none',
      '--set-exit-if-changed',
      ...dartPaths,
    ], runInShell: true);
    if (formatResult.exitCode != 0) {
      stdout.writeln(
        '❌ Dart formatting check failed:\n'
        '${formatResult.stdout}${formatResult.stderr}',
      );
      exitCode = 1;
    } else {
      stdout.writeln('✅ All repository Dart files are formatted.');
    }
  }

  stdout.writeln(
    '\n🔍 [2/5] Checking presentation file line limits (< 500)...',
  );
  final presentationFiles = [
    ...Directory('lib/screens')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart')),
    ...Directory('lib/widgets')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart')),
  ];
  final oversizedFiles = <Map<String, Object>>[];
  for (final file in presentationFiles) {
    final lineCount = file.readAsLinesSync().length;
    if (lineCount >= 500) {
      oversizedFiles.add({'path': file.path, 'lines': lineCount});
    }
  }

  if (oversizedFiles.isNotEmpty) {
    stdout.writeln(
      '❌ ${oversizedFiles.length} presentation file(s) exceed 500 lines:',
    );
    for (final f in oversizedFiles) {
      stdout.writeln('   - ${f['path']}: ${f['lines']} lines');
    }
    exitCode = 1;
  } else {
    stdout.writeln('✅ All presentation files are within the 500-line limit.');
  }

  stdout.writeln(
    '\n🔒 [3/5] Scanning repository source/config files for secrets...',
  );
  final secretPatterns = [
    RegExp(r'AIzaSy[A-Za-z0-9_-]{33}'), // Firebase Web API key
    RegExp(r'sk-[A-Za-z0-9]{32,}'), // OpenAI / API key
    RegExp(
      r'''(?:password|secret|private[_-]?key|client[_-]?secret)\s*["']?\s*[:=]\s*["'][^'"\r\n]{6,}["']''',
      caseSensitive: false,
    ),
  ];

  final secretHits = <String>[];
  if (repositoryFilesResult.exitCode == 0) {
    final repositoryPaths = (repositoryFilesResult.stdout as String)
        .split('\x00')
        .where(
          (path) => [
            '.dart',
            '.json',
            '.yaml',
            '.yml',
            '.html',
            '.md',
            '.txt',
          ].any(path.endsWith),
        );
    for (final path in repositoryPaths) {
      if (path.contains('.example')) {
        continue;
      }
      final file = File(path);
      if (!file.existsSync()) {
        continue;
      }
      final content = file.readAsStringSync();
      for (final pattern in secretPatterns) {
        if (pattern.hasMatch(content)) {
          secretHits.add('$path: matched pattern ${pattern.pattern}');
        }
      }
    }
  }

  if (secretHits.isNotEmpty) {
    stdout.writeln('❌ Potential hardcoded secret detected:');
    for (final hit in secretHits) {
      stdout.writeln('   - $hit');
    }
    exitCode = 1;
  } else if (repositoryFilesResult.exitCode == 0) {
    stdout.writeln('✅ No repository source/config secrets detected.');
  }

  stdout.writeln('\n🩺 [4/5] Running flutter analyze...');
  final analyzeResult = await Process.run('flutter', [
    'analyze',
  ], runInShell: true);
  if (analyzeResult.exitCode != 0) {
    stdout.writeln(
      '❌ Analyzer reported issues:\n'
      '${analyzeResult.stdout}${analyzeResult.stderr}',
    );
    exitCode = 1;
  } else {
    stdout.writeln('✅ Analyzer passed with zero issues!');
  }

  stdout.writeln('\n🧪 [5/5] Running all unit & contract tests...');
  final testResult = await Process.run('flutter', ['test'], runInShell: true);
  if (testResult.exitCode != 0) {
    stdout.writeln('❌ Tests failed:\n${testResult.stdout}${testResult.stderr}');
    exitCode = 1;
  } else {
    stdout.writeln('✅ All unit, engine, and serialization tests passed!');
  }

  stdout.writeln('\n======================================================');
  if (exitCode == 0) {
    stdout.writeln('🎉 ALL INVARIANT GATES PASSED! Safe to commit & conclude.');
  } else {
    stdout.writeln(
      '❌ INVARIANT VIOLATIONS DETECTED. Resolve before finishing.',
    );
  }
  stdout.writeln('======================================================');

  exit(exitCode);
}
