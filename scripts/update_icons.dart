// https://github.com/flutter/flutter/blob/3.27.3/dev/tools/update_icons.dart

import 'dart:convert';
import 'dart:io';

const List<String> _defaultPossibleStyleSuffixes = <String>[
  '_outlined',
  '_rounded',
  '_sharp',
];

// Rewrite certain Flutter IDs (numbers) using prefix matching.
const Map<String, String> _identifierPrefixRewrites = <String, String>{
  '1': 'one_',
  '2': 'two_',
  '3': 'three_',
  '4': 'four_',
  '5': 'five_',
  '6': 'six_',
  '7': 'seven_',
  '8': 'eight_',
  '9': 'nine_',
  '10': 'ten_',
  '11': 'eleven_',
  '12': 'twelve_',
  '13': 'thirteen_',
  '14': 'fourteen_',
  '15': 'fifteen_',
  '16': 'sixteen_',
  '17': 'seventeen_',
  '18': 'eighteen_',
  '19': 'nineteen_',
  '20': 'twenty_',
  '21': 'twenty_one_',
  '22': 'twenty_two_',
  '23': 'twenty_three_',
  '24': 'twenty_four_',
  '30': 'thirty_',
  '60': 'sixty_',
  '123': 'onetwothree',
  '360': 'threesixty',
  '2d': 'twod',
  '3d': 'threed',
  '3d_rotation': 'threed_rotation',
};

// Rewrite certain Flutter IDs (reserved keywords) using exact matching.
const Map<String, String> _identifierExactRewrites = <String, String>{
  'class': 'class_',
  'new': 'new_',
  'switch': 'switch_',
  'try': 'try_sms_star',
  'door_back': 'door_back_door',
  'door_front': 'door_front_door',
};

const Set<String> _iconsMirroredWhenRTL = <String>{
  // This list is obtained from:
  // https://developers.google.com/fonts/docs/material_icons#which_icons_should_be_mirrored_for_rtl
  'arrow_back',
  'arrow_back_ios',
  'arrow_forward',
  'arrow_forward_ios',
  'arrow_left',
  'arrow_right',
  'assignment',
  'assignment_return',
  'backspace',
  'battery_unknown',
  'call_made',
  'call_merge',
  'call_missed',
  'call_missed_outgoing',
  'call_received',
  'call_split',
  'chevron_left',
  'chevron_right',
  'chrome_reader_mode',
  'device_unknown',
  'dvr',
  'event_note',
  'featured_play_list',
  'featured_video',
  'first_page',
  'flight_land',
  'flight_takeoff',
  'format_indent_decrease',
  'format_indent_increase',
  'format_list_bulleted',
  'forward',
  'functions',
  'help',
  'help_outline',
  'input',
  'keyboard_backspace',
  'keyboard_tab',
  'label',
  'label_important',
  'label_outline',
  'last_page',
  'launch',
  'list',
  'live_help',
  'mobile_screen_share',
  'multiline_chart',
  'navigate_before',
  'navigate_next',
  'next_week',
  'note',
  'open_in',
  'playlist_add',
  'queue_music',
  'redo',
  'reply',
  'reply_all',
  'screen_share',
  'send',
  'short_text',
  'show_chart',
  'sort',
  'star_half',
  'subject',
  'trending_flat',
  'toc',
  'trending_down',
  'trending_up',
  'undo',
  'view_list',
  'view_quilt',
  'wrap_text',
};

Map<String, String> stringToTokenPairMap(String codepointData) {
  final Iterable<String> cleanData = LineSplitter.split(codepointData)
      .map((String line) => line.trim())
      .where((String line) => line.isNotEmpty);

  final Map<String, String> pairs = <String, String>{};

  for (final String line in cleanData) {
    final List<String> tokens = line.split(' ');
    if (tokens.length != 2) {
      throw FormatException('Unexpected codepoint data: $line');
    }
    pairs.putIfAbsent(tokens[0], () => tokens[1]);
  }

  return pairs;
}

class Icon {
  Icon({
    required this.id,
    required this.hexCodepoint,
    required this.fontFamily,
  }) {
    _generateShortId();
    _generateFlutterId();
  }

  final String id; // e.g. 5g, 5g_outlined, 5g_rounded, 5g_sharp
  late String shortId; // e.g. 5g
  late String flutterId; // e.g. five_g, five_g_outlined, five_g_rounded
  final String hexCodepoint; // e.g. e547
  final String fontFamily; // The IconData font family.

  bool get isMirroredInRTL {
    // Remove common suffixes (e.g. "_new" or "_alt") from the shortId.
    final String normalizedShortId =
        shortId.replaceAll(RegExp(r'_(new|alt|off|on)$'), '');
    return _iconsMirroredWhenRTL.any((String shortIdMirroredWhenRTL) =>
        normalizedShortId == shortIdMirroredWhenRTL);
  }

  String get declaration => 'static const IconData $flutterId = IconData('
      '0x$hexCodepoint,'
      "fontFamily: '$fontFamily',"
      "fontPackage: 'material_off_icons',"
      '${isMirroredInRTL ? 'matchTextDirection: true,' : ''}'
      ');';

  /// Analogous to [String.compareTo]
  int _compareTo(Icon b) {
    if (shortId == b.shortId) {
      // Sort a regular icon before its variants.
      return id.length - b.id.length;
    }
    return shortId.compareTo(b.shortId);
  }

  static String _removeLast(String string, String toReplace) {
    return string.replaceAll(RegExp('$toReplace\$'), '');
  }

  /// See [shortId].
  void _generateShortId() {
    shortId = id;
    for (final String styleSuffix in _defaultPossibleStyleSuffixes) {
      shortId = _removeLast(shortId, styleSuffix);
      if (shortId != id) {
        break;
      }
    }
  }

  /// See [flutterId].
  void _generateFlutterId() {
    flutterId = id;
    // Exact identifier rewrites.
    for (final MapEntry<String, String> rewritePair
        in _identifierExactRewrites.entries) {
      if (shortId == rewritePair.key) {
        flutterId = id.replaceFirst(
          rewritePair.key,
          _identifierExactRewrites[rewritePair.key]!,
        );
      }
    }
    // Prefix identifier rewrites.
    for (final MapEntry<String, String> rewritePair
        in _identifierPrefixRewrites.entries) {
      if (id.startsWith(rewritePair.key)) {
        flutterId = id.replaceFirst(
          rewritePair.key,
          _identifierPrefixRewrites[rewritePair.key]!,
        );
      }
    }

    // Prevent double underscores.
    flutterId = flutterId.replaceAll('__', '_');
  }
}

void main() {
  final styles = [
    (
      fontFamily: 'MaterialOffIcons',
      codepointsFileName: 'MaterialIcons-Regular.codepoints',
      suffix: '',
    ),
    (
      fontFamily: 'MaterialOffIconsOutlined',
      codepointsFileName: 'MaterialIconsOutlined-Regular.codepoints',
      suffix: '_outlined',
    ),
    (
      fontFamily: 'MaterialOffIconsRound',
      codepointsFileName: 'MaterialIconsRound-Regular.codepoints',
      suffix: '_rounded',
    ),
    (
      fontFamily: 'MaterialOffIconsSharp',
      codepointsFileName: 'MaterialIconsSharp-Regular.codepoints',
      suffix: '_sharp',
    ),
  ];

  final iconsMap = <String, Icon>{};
  for (final style in styles) {
    final codepointsFile =
        File('material-design-icons/font/${style.codepointsFileName}');
    final tokenPairMap =
        stringToTokenPairMap(codepointsFile.readAsStringSync());
    for (final e in tokenPairMap.entries) {
      if (iconsMap[e.key] == null && style.suffix.isNotEmpty) {
        iconsMap[e.key] = Icon(
          id: e.key,
          hexCodepoint: e.value,
          fontFamily: style.fontFamily,
        );
      }
      final id = '${e.key}${style.suffix}';
      iconsMap[id] = Icon(
        id: id,
        hexCodepoint: e.value,
        fontFamily: style.fontFamily,
      );
    }
  }
  final icons = iconsMap.values.toList();
  icons.sort((a, b) => a._compareTo(b));

  final buffer = StringBuffer("""
// Generated file. Do not edit.
//
// Source: material-design-icons/font
// To regenerate, run: `dart run scripts/update_icons.dart && dart format lib/material_off_icons.dart`

import 'package:flutter/widgets.dart';

// ignore_for_file: constant_identifier_names

// https://github.com/timmaffett/material_symbols_icons/blob/4.2791.0/lib/material_symbols_icons.dart#L107-L137
@pragma('vm:entry-point')
void forceCompileTimeTreeShaking() {
  // ignore: unused_local_variable
  var forceTreeShake = const IconData(
    0x0030,
    fontFamily: 'MaterialOffIcons',
    fontPackage: 'material_off_icons',
  );
  // ignore: unused_local_variable
  var forceOutlinedTreeShake = const IconData(
    0x0030,
    fontFamily: 'MaterialOffIconsOutlined',
    fontPackage: 'material_off_icons',
  );
  // ignore: unused_local_variable
  var forceRoundedTreeShake = const IconData(
    0x0030,
    fontFamily: 'MaterialOffIconsRound',
    fontPackage: 'material_off_icons',
  );
  // ignore: unused_local_variable
  var forceSharpTreeShake = const IconData(
    0x0030,
    fontFamily: 'MaterialOffIconsSharp',
    fontPackage: 'material_off_icons',
  );
}

@staticIconProvider
abstract final class OffIcons {
""");
  for (final icon in icons) {
    buffer.write('  ${icon.declaration}\n\n');
  }
  buffer.write('}');

  final iconsFile = File('lib/material_off_icons.dart');
  iconsFile.writeAsStringSync(buffer.toString());
}
