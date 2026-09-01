import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

import 'mocks.dart';

void main() {
  late MockClient client;

  setUpAll(initializeDateFormatting);

  setUp(() {
    client = MockClient();
    final clientState = MockClientState();
    when(() => client.state).thenReturn(clientState);
    when(() => clientState.currentUser).thenReturn(OwnUser(id: 'user-id'));
  });

  tearDown(() => Intl.defaultLocale = null);

  Widget buildApp([Locale locale = const Locale('en')]) => MaterialApp(
        home: Builder(
          builder: (context) => Localizations.override(
            context: context,
            locale: locale,
            child: StreamChat(client: client, child: const Scaffold()),
          ),
        ),
      );

  testWidgets(
    'syncs Jiffy with the widget locale when Intl.defaultLocale is unset',
    (tester) async {
      Intl.defaultLocale = null;

      await tester.pumpWidget(buildApp());

      expect(Intl.defaultLocale, 'en');
    },
  );

  testWidgets(
    'leaves a host-configured Intl.defaultLocale alone',
    (tester) async {
      Intl.defaultLocale = 'en_GB';

      await tester.pumpWidget(buildApp());

      expect(Intl.defaultLocale, 'en_GB');
    },
  );

  testWidgets(
    'keeps syncing when Stream Chat initialized Intl.defaultLocale',
    (tester) async {
      Intl.defaultLocale = null;

      await tester.pumpWidget(buildApp());
      expect(Intl.defaultLocale, 'en');

      await tester.pumpWidget(buildApp(const Locale('fr')));
      expect(Intl.defaultLocale, 'fr');
    },
  );
}
