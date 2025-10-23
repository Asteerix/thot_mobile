#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';

void main() async {
  final libDir = Directory('lib');
  final files = await _getAllDartFiles(libDir);

  print('Total Dart files: ${files.length}');

  // Map of file -> list of imports
  final Map<String, Set<String>> importMap = {};

  // Get all imports from all files
  for (final file in files) {
    final content = await File(file).readAsString();
    final imports = _extractImports(content, file);
    importMap[file] = imports;
  }

  // Find files that are never imported
  final allFiles = files.map((f) => f.replaceAll('lib/', 'package:thot/')).toSet();
  final importedFiles = <String>{};

  for (final imports in importMap.values) {
    importedFiles.addAll(imports);
  }

  final neverImported = allFiles.difference(importedFiles);

  print('\n=== FILES NEVER IMPORTED (${neverImported.length}) ===');
  for (final file in neverImported.toList()..sort()) {
    if (!file.endsWith('.g.dart') &&
        !file.endsWith('.freezed.dart') &&
        !file.contains('/main.dart')) {
      print(file);
    }
  }

  // Find barrel files
  print('\n=== BARREL FILES ===');
  for (final file in files) {
    if (file.endsWith('providers.dart') ||
        file.endsWith('entities.dart') ||
        file.endsWith('failures.dart') ||
        file.endsWith('repositories.dart') ||
        file.endsWith('models.dart') ||
        file.endsWith('services.dart')) {
      print(file);
    }
  }
}

Future<List<String>> _getAllDartFiles(Directory dir) async {
  final files = <String>[];
  await for (final entity in dir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      files.add(entity.path);
    }
  }
  return files;
}

Set<String> _extractImports(String content, String currentFile) {
  final imports = <String>{};
  final lines = content.split('\n');

  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.startsWith('import ') || trimmed.startsWith('export ')) {
      final match = RegExp(r'''['"](.+?)['"]''').firstMatch(trimmed);
      if (match != null) {
        var importPath = match.group(1)!;

        // Convert relative imports to package imports
        if (importPath.startsWith('package:')) {
          imports.add(importPath.split(' ').first.replaceAll("'", '').replaceAll('"', '').replaceAll(';', ''));
        }
      }
    }
  }

  return imports;
}
