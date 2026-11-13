import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

const _res = 'android/app/src/main/res';

String _read(String path) => File(path).readAsStringSync();

void main() {
  final manifest = _read('android/app/src/main/AndroidManifest.xml');
  final strings = _read('$_res/values/strings.xml');

  for (final widget in [
    (
      provider: 'MaratonaWidgetProvider',
      resource: 'maratona',
      label: 'watching',
      title: 'Da Vedere',
      width: 480,
      height: 480
    ),
    (
      provider: 'ProssimamenteWidgetProvider',
      resource: 'prossimamente',
      label: 'upcoming',
      title: 'In Uscita',
      width: 840,
      height: 420
    ),
  ]) {
    test('${widget.title}: nome e descrizione specifici nel selettore', () {
      final receiver =
          RegExp('<receiver\\s[^>]*android:name="\\.${widget.provider}"[^>]*>')
              .firstMatch(manifest)
              ?.group(0);
      expect(receiver, isNotNull);
      expect(receiver,
          contains('android:label="@string/widget_${widget.label}_name"'));
      expect(
          strings,
          contains(
              '<string name="widget_${widget.label}_name">${widget.title}</string>'));
      expect(strings, contains('name="widget_${widget.label}_description"'));
    });

    test('${widget.title}: preview dedicata senza cambiare layout attivo', () {
      final name = 'widget_${widget.resource}';
      final info = _read('$_res/xml/${name}_info.xml');
      expect(
          info, contains('android:previewImage="@drawable/${name}_preview"'));
      expect(info, contains('android:previewLayout="@layout/${name}_preview"'));
      expect(
          info,
          contains(
              'android:description="@string/widget_${widget.label}_description"'));
      expect(info, contains('android:initialLayout="@layout/$name"'));
      expect(info, isNot(contains('ic_launcher')));
      final preview = _read('$_res/layout/${name}_preview.xml');
      expect(preview, contains('@string/widget_${widget.label}_name'));
      expect(preview, contains('@string/widget_preview_first_title'));
      expect(preview, contains('@drawable/widget_preview_scene'));
      expect(RegExp('android:src="https?://').hasMatch(preview), isFalse);
    });

    test('${widget.title}: fallback PNG trasparente con proporzioni corrette',
        () {
      final bytes =
          File('$_res/drawable-nodpi/widget_${widget.resource}_preview.png')
              .readAsBytesSync();
      expect(bytes.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
      final header = ByteData.sublistView(bytes);
      expect(header.getUint32(16), widget.width);
      expect(header.getUint32(20), widget.height);
      expect(bytes.length, greaterThan(1000));
      // PNG RGBA: mantiene trasparenti gli angoli arrotondati nel launcher.
      expect(bytes[25], 6);
    });
  }
}
