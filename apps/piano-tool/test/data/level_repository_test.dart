import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/data/level_repository.dart';

void main() {
  test('ships three built-in stages, in order', () {
    final stages = LevelRepository().getAllStages();
    expect(stages.map((s) => s.id).toList(), ['stage_1', 'stage_2', 'stage_3']);
    expect(stages.map((s) => s.order).toList(), [1, 2, 3]);
  });

  test('every stage has a level with measures and notes', () {
    for (final stage in LevelRepository().getAllStages()) {
      expect(stage.level.measures, isNotEmpty, reason: stage.id);
      expect(
        stage.level.measures.expand((m) => m.notes),
        isNotEmpty,
        reason: stage.id,
      );
    }
  });

  test('note beats are ordered within each level', () {
    for (final stage in LevelRepository().getAllStages()) {
      final beats = stage.level.measures.expand((m) => m.notes).map((n) => n.startBeat).toList();
      final sorted = [...beats]..sort();
      expect(beats, sorted, reason: stage.id);
    }
  });
}
