import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:consistency_tracker/core/errors/failures.dart';
import 'package:consistency_tracker/core/utils/result.dart';
import 'package:consistency_tracker/features/settings/data/repositories/settings_repository.dart';
import 'package:consistency_tracker/features/settings/domain/entities/app_settings.dart';
import 'package:consistency_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:consistency_tracker/features/settings/presentation/bloc/settings_event.dart';
import 'package:consistency_tracker/features/settings/presentation/bloc/settings_state.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late SettingsBloc bloc;
  late MockSettingsRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(AppSettings.defaults);
  });

  setUp(() {
    mockRepository = MockSettingsRepository();
    bloc = SettingsBloc(repository: mockRepository);
  });

  test('initial state should be SettingsInitial', () {
    expect(bloc.state, equals(const SettingsInitial()));
  });

  blocTest<SettingsBloc, SettingsState>(
    'Positive: LoadSettingsEvent emits [SettingsLoading, SettingsLoaded]',
    build: () {
      when(() => mockRepository.getSettings())
          .thenAnswer((_) async => const Result.success(AppSettings.defaults));
      return bloc;
    },
    act: (b) => b.add(const LoadSettingsEvent()),
    expect: () => [
      const SettingsLoading(),
      const SettingsLoaded(AppSettings.defaults),
    ],
  );

  blocTest<SettingsBloc, SettingsState>(
    'Negative: LoadSettingsEvent emits [SettingsLoading, SettingsError] on failure',
    build: () {
      when(() => mockRepository.getSettings()).thenAnswer(
        (_) async => const Result.failure(CacheFailure('Failed to load settings')),
      );
      return bloc;
    },
    act: (b) => b.add(const LoadSettingsEvent()),
    expect: () => [
      const SettingsLoading(),
      const SettingsError('Failed to load settings'),
    ],
  );

  blocTest<SettingsBloc, SettingsState>(
    'Positive: SettingsUpdated saves settings and emits updated SettingsLoaded state',
    build: () {
      when(() => mockRepository.saveSettings(any()))
          .thenAnswer((_) async => const Result.success(true));
      return bloc;
    },
    act: (b) => b.add(const SettingsUpdated(
      AppSettings(
        focusDurationMinutes: 30,
        breakDurationMinutes: 10,
        soundEnabled: false,
        notificationsEnabled: true,
      ),
    )),
    expect: () => [
      const SettingsLoading(),
      const SettingsLoaded(
        AppSettings(
          focusDurationMinutes: 30,
          breakDurationMinutes: 10,
          soundEnabled: false,
          notificationsEnabled: true,
        ),
      ),
    ],
  );
}
