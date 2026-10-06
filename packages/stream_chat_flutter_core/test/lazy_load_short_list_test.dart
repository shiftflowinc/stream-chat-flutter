import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_chat_flutter_core/stream_chat_flutter_core.dart';

void main() {
  for (final axis in Axis.values) {
    for (final reverse in [false, true]) {
      testWidgets('wheel paginates a short $axis list with reverse=$reverse',
          (tester) async {
        var starts = 0;
        var ends = 0;
        final pending = Completer<void>();
        await tester.pumpWidget(Directionality(
          textDirection: TextDirection.ltr,
          child: LazyLoadScrollView(
            onStartOfPage: () async => starts++,
            onEndOfPage: () {
              ends++;
              return pending.future;
            },
            child: ListView(
              scrollDirection: axis,
              reverse: reverse,
              children: const [SizedBox(width: 50, height: 50)],
            ),
          ),
        ));
        await tester.pumpAndSettle();
        final delta = reverse ? -100.0 : 100.0;
        final offset =
            axis == Axis.vertical ? Offset(0, delta) : Offset(delta, 0);
        final position = tester.getCenter(find.byType(ListView));
        tester.binding.handlePointerEvent(PointerScrollEvent(
          position: position,
          scrollDelta: offset,
        ));
        await tester.pump();
        expect(ends, 1);
        expect(starts, 0);

        tester.binding.handlePointerEvent(PointerScrollEvent(
          position: position,
          scrollDelta: offset,
        ));
        await tester.pump();
        expect(ends, 1);

        pending.complete();
        await tester.pump();
        tester.binding.handlePointerEvent(PointerScrollEvent(
          position: position,
          scrollDelta: -offset,
        ));
        await tester.pump();
        expect(starts, 1);
        expect(ends, 1);
      });
    }
  }

  testWidgets('wheel keeps normal scroll pagination for a long list',
      (tester) async {
    var ends = 0;
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: LazyLoadScrollView(
        onEndOfPage: () async => ends++,
        child: ListView(
          children: List.generate(30, (_) => const SizedBox(height: 100)),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    final position = tester.getCenter(find.byType(ListView));
    tester.binding.handlePointerEvent(PointerScrollEvent(
      position: position,
      scrollDelta: const Offset(0, 200),
    ));
    await tester.pumpAndSettle();
    expect(ends, 0);
    tester.binding.handlePointerEvent(PointerScrollEvent(
      position: position,
      scrollDelta: const Offset(0, 3000),
    ));
    await tester.pumpAndSettle();
    expect(ends, 1);
  });
}
