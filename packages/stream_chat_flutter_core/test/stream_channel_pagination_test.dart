import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';
import 'package:stream_chat_flutter_core/stream_chat_flutter_core.dart';

import 'mocks.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(const PaginationParams());
  });

  for (final direction in ['top', 'bottom', 'replies']) {
    testWidgets('$direction pagination retries after failure without reopening',
        (tester) async {
      final channel = MockChannel();
      final message = Message(id: 'existing');
      final failure = Exception('Temporary connection failure');
      final pending = Completer<void>();
      var attempts = 0;
      final pages = <PaginationParams>[];
      when(() => channel.state.messages).thenReturn([message]);
      when(() => channel.state.threads).thenReturn({
        'parent': [message]
      });
      when(() => channel.state.isUpToDate).thenReturn(false);

      Future<List<Message>> fetch(PaginationParams page) async {
        pages.add(page);
        attempts++;
        if (attempts == 1) throw failure;
        await pending.future;
        return [Message(id: 'fetched')];
      }

      when(() => channel.query(
            messagesPagination: any(named: 'messagesPagination'),
            preferOffline: any(named: 'preferOffline'),
          )).thenAnswer((invocation) async {
        final page =
            invocation.namedArguments[#messagesPagination] as PaginationParams;
        final messages = await fetch(page);
        return ChannelState(messages: messages);
      });
      when(() => channel.getReplies(
            'parent',
            options: any(named: 'options'),
            preferOffline: any(named: 'preferOffline'),
          )).thenAnswer((invocation) async {
        final page = invocation.namedArguments[#options] as PaginationParams;
        final messages = await fetch(page);
        return QueryRepliesResponse()..messages = messages;
      });

      await tester.pumpWidget(MaterialApp(
          home: StreamChannel(
        channel: channel,
        child: const SizedBox.shrink(),
      )));
      await tester.pumpAndSettle();
      final state =
          tester.state<StreamChannelState>(find.byType(StreamChannel));
      final stream = (direction == 'bottom'
          ? state.queryBottomMessages
          : state.queryTopMessages) as ValueStream<bool>;

      Future<void> paginate() => direction == 'replies'
          ? state.getReplies('parent', limit: 20)
          : state.queryMessages(
              direction: direction == 'top'
                  ? QueryDirection.top
                  : QueryDirection.bottom,
            );

      await paginate();
      await tester.pump();
      expect(stream.error, failure);
      expect(stream.value, isFalse);

      final retry = paginate();
      await tester.pump();
      expect(attempts, 2);
      expect(stream.value, isTrue);
      await paginate();
      expect(attempts, 2);

      pending.complete();
      await retry;
      await tester.pump();
      expect(stream.value, isFalse);
      expect(pages.last.limit, 20);
      expect(
        direction == 'bottom'
            ? pages.last.greaterThanOrEqual
            : pages.last.lessThan,
        message.id,
      );
      await paginate();
      expect(attempts, 2);
    });
  }
}
