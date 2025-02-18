import 'package:flutter/widgets.dart' hide Interval;

import '../utils.dart';
import 'event.dart';

/// Provides [Event]s to Timetable widgets.
///
/// [EventProvider]s may only return events that intersect the given
/// [visibleRange].
///
/// See also:
///
/// * [eventProviderFromFixedList], which creates an [EventProvider] from a
///   fixed list of events.
/// * [mergeEventProviders], which merges multiple [EventProvider]s.
/// * [DefaultEventProvider], which provides [EventProvider]s to Timetable
///   widgets below it.
typedef EventProvider<E extends Event> = List<E> Function(
  Interval visibleRange,
);

EventProvider<E> eventProviderFromFixedList<E extends Event>(final List<E> events) {
  return (final visibleRange) =>
      events.where((final it) => it.interval.intersects(visibleRange)).toList();
}

EventProvider<E> mergeEventProviders<E extends Event>(
  final List<EventProvider<E>> eventProviders,
) {
  return (final visibleRange) =>
      eventProviders.expand((final it) => it(visibleRange)).toList();
}

extension EventProviderTimetable<E extends Event> on EventProvider<E> {
  EventProvider<E> get debugChecked {
    return (final visibleRange) {
      final events = this(visibleRange);
      assert(() {
        final invalidEvents = events
            .where((final it) => !it.interval.intersects(visibleRange))
            .toList();
        if (invalidEvents.isNotEmpty) {
          throw FlutterError.fromParts([
            ErrorSummary(
              'EventProvider returned events not intersecting the provided '
              'visible range.',
            ),
            ErrorDescription(
              'For the visible range ${visibleRange.start} – ${visibleRange.end}, '
              "${invalidEvents.length} out of ${events.length} events don't "
              'intersect this range: $invalidEvents',
            ),
            ErrorDescription(
              "This property is enforced so that you don't accidentally, e.g., "
              'load thousands of events spread over multiple years when only a '
              'single week is visible.',
            ),
            ErrorHint(
              'If you only have a fixed list of events, use '
              '`eventProviderFromFixedList(myListOfEvents)`.',
            ),
          ]);
        }
        return true;
      }());

      assert(
        events.toSet().length == events.length,
        'Events may not contain duplicates.',
      );

      return events;
    };
  }
}

class DefaultEventProvider<E extends Event> extends InheritedWidget {
  DefaultEventProvider({
    required final EventProvider<E> eventProvider,
    required final Widget child,
  })  : eventProvider = eventProvider.debugChecked,
        super(child: child);

  final EventProvider<E> eventProvider;

  @override
  bool updateShouldNotify(final DefaultEventProvider oldWidget) =>
      eventProvider != oldWidget.eventProvider;

  static EventProvider<E>? of<E extends Event>(final BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<DefaultEventProvider<E>>()
        ?.eventProvider;
  }
}
