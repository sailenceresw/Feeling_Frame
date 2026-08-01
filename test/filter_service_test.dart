import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_mobile_app/src/services/filter_service.dart';

void main() {
  group('FilterService.cinematicFilters', () {
    test('starts with an untouched Original (empty chain)', () {
      expect(FilterService.cinematicFilters.first.name, 'Original');
      expect(FilterService.cinematicFilters.first.vf, '');
    });

    test('offers a rich catalogue', () {
      expect(FilterService.cinematicFilters.length, greaterThanOrEqualTo(10));
    });

    test('filter names are unique', () {
      final names = FilterService.cinematicFilters.map((f) => f.name).toList();
      expect(names.toSet().length, names.length);
    });

    test('every non-Original look has a filter chain', () {
      for (final f in FilterService.cinematicFilters) {
        if (f.name == 'Original') continue;
        expect(f.vf.isNotEmpty, isTrue, reason: '${f.name} has no chain');
      }
    });

    test('no chain contains spaces (keeps -vf quoting robust)', () {
      for (final f in FilterService.cinematicFilters) {
        expect(f.vf.contains(' '), isFalse, reason: '${f.name} has a space');
      }
    });

    test('signature looks use the expected filters', () {
      CinematicFilter byName(String n) =>
          FilterService.cinematicFilters.firstWhere((f) => f.name == n);
      expect(byName('Noir').vf.contains('hue=s=0'), isTrue);
      expect(byName('Vintage').vf.contains('curves=preset=vintage'), isTrue);
      expect(byName('Invert').vf, 'negate');
    });
  });

  group('FilterService.filterCommand', () {
    test('wraps the chain in -vf and copies audio', () {
      final cmd = FilterService.filterCommand('in.mp4', 'out.mp4', 'negate');
      expect(cmd.contains('-i in.mp4'), isTrue);
      expect(cmd.contains('-vf "negate"'), isTrue);
      expect(cmd.contains('-c:v libx264'), isTrue);
      expect(cmd.contains('-c:a copy'), isTrue);
      expect(cmd.trim().endsWith('out.mp4'), isTrue);
    });
  });
}
