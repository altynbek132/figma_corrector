// ignore_for_file: avoid_print

import 'dart:io';

import 'package:utils/utils_dart/string_extension.dart';

void main(List<String> arguments) {
  if (arguments.isEmpty) {
    print('Usage: figma_correct <filename>');
    exit(1);
  }

  final filename = arguments[0];
  final file = File(filename);

  if (!file.existsSync()) {
    print('Error: File not found.');
    exit(1);
  }

  // Read the contents of the file
  final contents = file.readAsStringSync();

  var modifiedContents = contents;

  // Replace all numbers with zeros
  modifiedContents = modifiedContents.replaceAllMapped(
    RegExp(r'(?:top|bottom|height|vertical):\s*(-?[0-9]*\.?[0-9]+)'),
    (match) => '${match.group(0)!}.h',
  );
  modifiedContents = modifiedContents.replaceAllMapped(
    RegExp(r'(?:left|right|width|horizontal):\s*(-?[0-9]*\.?[0-9]+)'),
    (match) => '${match.group(0)!}.w',
  );
  modifiedContents = modifiedContents.replaceAllMapped(
    RegExp(r'(?:radius):\s*(-?[0-9]*\.?[0-9]+)'),
    (match) => '${match.group(0)!}.r',
  );
  modifiedContents = modifiedContents.replaceAllMapped(
    RegExp(r'(?:fontSize):\s*(-?[0-9]*\.?[0-9]+)'),
    (match) => '${match.group(0)!}.sp',
  );

  modifiedContents = modifiedContents.replaceAll('const ', '');
  modifiedContents =
      modifiedContents.replaceAll("'Muller'", 'FontFamily.muller');
  modifiedContents =
      modifiedContents.replaceAll('fontFamily: FontFamily.muller,', '');
  modifiedContents = modifiedContents.replaceAll('height: 0.h', 'height: 1');

  modifiedContents = processColors(modifiedContents);
  // Write the modified contents back to the file
  file.writeAsStringSync(modifiedContents);
}

String processColors(String content) {
  final colorRegex = RegExp(r'Color\(0x[A-Fa-f0-9]{8}\)');
  final matches = colorRegex.allMatches(content);

  // to set of colors
  final colors_to_name = Map.fromEntries(
    matches.map((match) => match.group(0)!).toSet().map(
      (e) {
        final name = e.substring_(8, -1).toUpperCase();
        return MapEntry(e, 'color$name');
      },
    ),
  );

  for (final match in matches) {
    final color = match.group(0)!;
    final name = colors_to_name[
        color]!; // Replace getColorName with your logic to get the name for the color
    content = content.replaceAll(color, 'context.appColors.$name');
  }

  final defs = colors_to_name.keys.map(
    (e) {
      final name = colors_to_name[e]!;
      return 'static const $name = $e;';
    },
  ).join('\n');

  return '$content\n\n$defs';
}
