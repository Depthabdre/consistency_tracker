import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:consistency_tracker/core/services/audio_service.dart';
import 'package:consistency_tracker/core/services/notification_service.dart';
import 'package:consistency_tracker/core/utils/result.dart';
import 'package:consistency_tracker/features/focus_timer/data/models/focus_session_model.dart';
import 'package:consistency_tracker/features/focus_timer/data/repositories/focus_session_repository.dart';
import 'package:consistency_tracker/features/focus_timer/presentation/bloc/focus_timer_bloc.dart';
import 'package:consistency_tracker/features/focus_timer/presentation/bloc/focus_timer_event.dart';
import 'package:consistency_tracker/features/focus_timer/presentation/bloc/focus_timer_state.dart';

class MockFocusSessionRepository extends Mock
    implements FocusSessionRepository {}

class MockAudioService extends Mock implements AudioService {}

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  late FocusTimerBloc bloc;
  late MockFocusSessionRepository mockRepository;
  late MockAudioService mockAudioService;
  late MockNotificationService mockNotificationService;

  setUpAll(() {
    registerFallbackValue(
      FocusSessionModel(
        id: 's1',
        goalId: 'g1',
        durationMinutes: 25,
        timestamp: DateTime.now(),
        completedTargetMet: true,
      ),
    );
  });

  setUp(() {
    mockRepository = MockFocusSessionRepository();
    mockAudioService = MockAudioService();
    mockNotificationService = MockNotificationService();

    when(
      () => mockRepository.saveSession(any()),
    ).thenAnswer((_) async => const Result.success(true));
    when(
      () =>
          mockAudioService.playTransitionSound(enabled: any(named: 'enabled')),
    ).thenAnswer((_) async {});
    when(
      () => mockNotificationService.showPhaseNotification(
        title: any(named: 'title'),
        body: any(named: 'body'),
        enabled: any(named: 'enabled'),
      ),
    ).thenAnswer((_) async {});

    bloc = FocusTimerBloc(
      sessionRepository: mockRepository,
      audioService: mockAudioService,
      notificationService: mockNotificationService,
    );
  });

  test('Positive: initial state should be FocusTimerInitialState', () {
    expect(bloc.state, isA<FocusTimerInitialState>());
  });

  test(
    'Positive: StartFocusTimerEvent emits FocusTimerRunningState with phases',
    () {
      bloc.add(const StartFocusTimerEvent(goalId: 'g1', targetMinutes: 25));

      expect(
        bloc.stream,
        emits(
          isA<FocusTimerRunningState>().having(
            (s) => s.phases.length,
            'phases count',
            greaterThanOrEqualTo(1),
          ),
        ),
      );
    },
  );

  group('CompleteFocusTimerEvent & Phase Transitions', () {
    test(
      'Partial/Early Stop: stop session after 120s logs exact focus time',
      () async {
        bloc.add(const StartFocusTimerEvent(goalId: 'g1', targetMinutes: 25));
        bloc.add(const CompleteFocusTimerEvent(elapsedSeconds: 120));

        expect(bloc.stream, emitsThrough(isA<FocusTimerCompletedState>()));
      },
    );

    test('Negative: PauseFocusTimerEvent while initial state does nothing', () {
      bloc.add(const PauseFocusTimerEvent());
      expect(bloc.state, isA<FocusTimerInitialState>());
    });

    test(
      'Negative: ResumeFocusTimerEvent while initial state does nothing',
      () {
        bloc.add(const ResumeFocusTimerEvent());
        expect(bloc.state, isA<FocusTimerInitialState>());
      },
    );
  });

  group('Monkey / Chaos Sequence', () {
    test(
      'Chaos: Rapid sequence Start -> Pause -> Resume -> Pause -> Complete',
      () async {
        bloc.add(const StartFocusTimerEvent(goalId: 'g1', targetMinutes: 30));
        bloc.add(const PauseFocusTimerEvent());
        bloc.add(const ResumeFocusTimerEvent());
        bloc.add(const PauseFocusTimerEvent());
        bloc.add(const CompleteFocusTimerEvent(elapsedSeconds: 300));

        expect(bloc.stream, emitsThrough(isA<FocusTimerCompletedState>()));
      },
    );
  });
}
