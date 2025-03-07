// ignore_for_file: avoid_print

import 'dart:io';

import 'package:change_case/change_case.dart';
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

  final designIndexAppendStr = arguments.elementAtOrNull(1) ?? '';

  // Read the contents of the file
  final contents = file.readAsStringSync();

  var modifiedContents = contents;

  // Replace all numbers with zeros
  modifiedContents = modifiedContents.replaceAllMapped(
    RegExp(r'(?:top|bottom|height|vertical):\s*(-?[0-9]*\.?[0-9]+)'),
    (match) => '${match.group(0)!}.h$designIndexAppendStr',
  );
  modifiedContents = modifiedContents.replaceAllMapped(
    RegExp(r'(?:left|right|width|horizontal):\s*(-?[0-9]*\.?[0-9]+)'),
    (match) => '${match.group(0)!}.w$designIndexAppendStr',
  );
  modifiedContents = modifiedContents.replaceAllMapped(
    RegExp(r'(?:radius):\s*(-?[0-9]*\.?[0-9]+)'),
    (match) => '${match.group(0)!}.r$designIndexAppendStr',
  );
  modifiedContents = modifiedContents.replaceAllMapped(
    RegExp(r'(?:fontSize):\s*(-?[0-9]*\.?[0-9]+)'),
    (match) => '${match.group(0)!}.sp$designIndexAppendStr',
  );

  modifiedContents = modifiedContents.replaceAll('const ', '');

  // fontFamily:\s*['"]?([^'"]*)['"]?
  modifiedContents = modifiedContents.replaceAllMapped(
    RegExp('fontFamily:\\s*[\'"]?([^\'"]*)[\'"]?'),
    (match) {
      final fontCamel = match.group(1)?.toCamelCase();
      return 'fontFamily: AppFonts.$fontCamel';
    },
  );
  // fontWeight: FontWeight.w100,
  // fontVariations: [FontVariation('wght', 100)],
  // modifiedContents = modifiedContents.replaceAllMapped(
  //   RegExp(r"fontWeight:\s*FontWeight\.w(\d+),"),
  //   (match) {
  //     return "fontVariations: [FontVariation('wght', ${match.group(1)})],";
  //   },
  // );
  modifiedContents = modifiedContents.replaceAll('height: 0.h$designIndexAppendStr', 'height: 1');

  modifiedContents = processColors(modifiedContents);
  // Write the modified contents back to the file
  file.writeAsStringSync(modifiedContents);
}

String processColors(String content) {
  final colorRegex = RegExp(r'Color\(0x[A-Fa-f0-9]{8}\)');
  final matches = colorRegex.allMatches(content);

  // to set of colors
  final colorsToName = Map.fromEntries(
    matches.map((match) => match.group(0)!).toSet().map(
      (e) {
        final name = e.substring_(8, -1).toUpperCase();
        return MapEntry(e, 'color$name');
      },
    ),
  );

  for (final match in matches) {
    final color = match.group(0)!;
    final name = colorsToName[color]!; // Replace getColorName with your logic to get the name for the color
    content = content.replaceAll(color, 'context.appColors.$name');
  }

  final defs = colorsToName.keys.map(
    (e) {
      final name = colorsToName[e]!;
      return 'final $name = $e;';
    },
  ).join('\n');

  return '$content\n\n$defs';
}
