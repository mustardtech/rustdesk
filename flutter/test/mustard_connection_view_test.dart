import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/desktop/widgets/mustard_cm.dart';
import 'package:flutter_hbb/desktop/widgets/mustard_theme.dart';
import 'package:flutter_hbb/models/server_model.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpView(WidgetTester tester, Widget view) async {
  tester.view.physicalSize = const Size(360, 552);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: mustardTheme(MyTheme.lightTheme, MustardColors.light),
    home: Scaffold(body: view),
  ));
}

void main() {
  testWidgets('a request offers Decline and Accept at the same size',
      (tester) async {
    var accepted = 0;
    var declined = 0;
    await pumpView(
      tester,
      MustardConnectionView(
        name: 'Technician',
        peerId: '300118442',
        state: MustardCmState.request,
        abilities: const ['See your screen'],
        onAccept: () => accepted++,
        onDecline: () => declined++,
      ),
    );

    final decline = find.widgetWithText(OutlinedButton, 'Decline');
    final accept = find.widgetWithText(ElevatedButton, 'Accept');
    expect(tester.getSize(decline), tester.getSize(accept));
    expect(find.text('ID 300 118 442'), findsOneWidget);

    await tester.tap(accept);
    await tester.tap(decline);
    expect((accepted, declined), (1, 1));
  });

  testWidgets('a session shows what the technician can do and how to end it',
      (tester) async {
    var ended = 0;
    final client = Client(1, true, false, false, 'Technician', '300118442',
        true, false, false);
    await pumpView(
      tester,
      MustardConnectionView(
        name: client.name,
        peerId: client.peerId,
        state: MustardCmState.active,
        abilities: mustardAbilities(client),
        elapsedSeconds: 252,
        onEnd: () => ended++,
      ),
    );

    expect(find.text('Support session in progress'), findsOneWidget);
    expect(find.text('04:12'), findsOneWidget);
    expect(find.text('Use your keyboard and mouse'), findsOneWidget);
    expect(find.text('Copy and paste text'), findsNothing);
    expect(find.textContaining('chat', findRichText: true), findsNothing);
    expect(find.text('Accept'), findsNothing);

    await tester.tap(find.widgetWithText(ElevatedButton, 'End session'));
    expect(ended, 1);
  });

  testWidgets('password-only approval offers no Accept button', (tester) async {
    await pumpView(
      tester,
      MustardConnectionView(
        name: 'Technician',
        peerId: '300118442',
        state: MustardCmState.request,
        canAccept: false,
        onDecline: () {},
      ),
    );

    expect(find.text('Accept'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, 'Decline'), findsOneWidget);
  });
}
