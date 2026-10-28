@Tags(['ai'])
import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/ai/experiments/variant_assigner.dart';
import 'package:the_scheduler/data/models/experiment.dart';

void main() {
  group('VariantAssigner', () {
    late VariantAssigner assigner;

    setUp(() {
      assigner = VariantAssigner(salt: 'test_salt');
    });

    Experiment createTestExperiment({
      ExperimentStatus status = ExperimentStatus.active,
      List<ExperimentVariant>? variants,
    }) {
      return Experiment(
        id: 'exp_123',
        businessId: 'biz_123',
        name: 'Test Experiment',
        type: ExperimentType.modelComparison,
        status: status,
        variants: variants ??
            [
              ExperimentVariant.control(trafficPercentage: 50),
              ExperimentVariant.treatment(
                id: 'treatment_a',
                name: 'Treatment A',
                trafficPercentage: 50,
                config: {'model_version': 'v2.0'},
              ),
            ],
        createdAt: DateTime.now(),
        createdBy: 'user_123',
      );
    }

    group('assignVariant', () {
      test('returns variant for active experiment', () {
        final experiment = createTestExperiment();
        final variant = assigner.assignVariant(
          experiment: experiment,
          userId: 'user_456',
        );

        expect(variant, isNotNull);
        expect(variant!.id, isIn(['control', 'treatment_a']));
      });

      test('returns null for draft experiment', () {
        final experiment = createTestExperiment(status: ExperimentStatus.draft);
        final variant = assigner.assignVariant(
          experiment: experiment,
          userId: 'user_456',
        );

        expect(variant, isNull);
      });

      test('returns null for paused experiment', () {
        final experiment = createTestExperiment(status: ExperimentStatus.paused);
        final variant = assigner.assignVariant(
          experiment: experiment,
          userId: 'user_456',
        );

        expect(variant, isNull);
      });

      test('returns null for completed experiment', () {
        final experiment = createTestExperiment(status: ExperimentStatus.completed);
        final variant = assigner.assignVariant(
          experiment: experiment,
          userId: 'user_456',
        );

        expect(variant, isNull);
      });

      test('returns null for invalid traffic allocation', () {
        final experiment = createTestExperiment(
          variants: [
            ExperimentVariant.control(trafficPercentage: 50),
            ExperimentVariant.treatment(
              id: 'treatment_a',
              name: 'Treatment A',
              trafficPercentage: 40, // Only 90% total
            ),
          ],
        );

        final variant = assigner.assignVariant(
          experiment: experiment,
          userId: 'user_456',
        );

        expect(variant, isNull);
      });

      test('returns consistent variant for same user', () {
        final experiment = createTestExperiment();

        final variant1 = assigner.assignVariant(
          experiment: experiment,
          userId: 'user_789',
        );

        final variant2 = assigner.assignVariant(
          experiment: experiment,
          userId: 'user_789',
        );

        expect(variant1?.id, equals(variant2?.id));
      });

      test('returns different variants for different users (in aggregate)', () {
        final experiment = createTestExperiment();
        final assignments = <String, int>{'control': 0, 'treatment_a': 0};

        // Assign 1000 different users
        for (var i = 0; i < 1000; i++) {
          final variant = assigner.assignVariant(
            experiment: experiment,
            userId: 'user_$i',
          );
          if (variant != null) {
            assignments[variant.id] = (assignments[variant.id] ?? 0) + 1;
          }
        }

        // Should have assignments in both variants
        expect(assignments['control'], greaterThan(0));
        expect(assignments['treatment_a'], greaterThan(0));
      });

      test('respects traffic allocation percentages approximately', () {
        final experiment = createTestExperiment(
          variants: [
            ExperimentVariant.control(trafficPercentage: 80),
            ExperimentVariant.treatment(
              id: 'treatment_a',
              name: 'Treatment A',
              trafficPercentage: 20,
            ),
          ],
        );

        final assignments = <String, int>{'control': 0, 'treatment_a': 0};

        // Assign 10000 different users
        for (var i = 0; i < 10000; i++) {
          final variant = assigner.assignVariant(
            experiment: experiment,
            userId: 'user_$i',
          );
          if (variant != null) {
            assignments[variant.id] = (assignments[variant.id] ?? 0) + 1;
          }
        }

        // Control should get ~80% (within 5% tolerance)
        final controlPercent = assignments['control']! / 10000 * 100;
        expect(controlPercent, closeTo(80, 5));

        // Treatment should get ~20% (within 5% tolerance)
        final treatmentPercent = assignments['treatment_a']! / 10000 * 100;
        expect(treatmentPercent, closeTo(20, 5));
      });

      test('includes entityId in hash when provided', () {
        final experiment = createTestExperiment();

        // Verify basic assignment works
        final variantWithoutEntity = assigner.assignVariant(
          experiment: experiment,
          userId: 'user_123',
        );
        expect(variantWithoutEntity, isNotNull);

        final variantWithEntity = assigner.assignVariant(
          experiment: experiment,
          userId: 'user_123',
          entityId: 'appointment_456',
        );

        // May or may not be different, but should be deterministic
        final variantWithSameEntity = assigner.assignVariant(
          experiment: experiment,
          userId: 'user_123',
          entityId: 'appointment_456',
        );

        expect(variantWithEntity?.id, equals(variantWithSameEntity?.id));
      });
    });

    group('isInTreatment', () {
      test('returns true for treatment variant', () {
        final experiment = createTestExperiment();

        // Find a user that's in treatment
        String? treatmentUserId;
        for (var i = 0; i < 100; i++) {
          final variant = assigner.assignVariant(
            experiment: experiment,
            userId: 'user_$i',
          );
          if (variant != null && !variant.isControl) {
            treatmentUserId = 'user_$i';
            break;
          }
        }

        expect(treatmentUserId, isNotNull);
        expect(
          assigner.isInTreatment(
            experiment: experiment,
            userId: treatmentUserId!,
          ),
          isTrue,
        );
      });

      test('returns false for control variant', () {
        final experiment = createTestExperiment();

        // Find a user that's in control
        String? controlUserId;
        for (var i = 0; i < 100; i++) {
          final variant = assigner.assignVariant(
            experiment: experiment,
            userId: 'user_$i',
          );
          if (variant != null && variant.isControl) {
            controlUserId = 'user_$i';
            break;
          }
        }

        expect(controlUserId, isNotNull);
        expect(
          assigner.isInTreatment(
            experiment: experiment,
            userId: controlUserId!,
          ),
          isFalse,
        );
      });
    });

    group('getVariantConfig', () {
      test('returns config for assigned variant', () {
        final experiment = createTestExperiment();

        // Find a user that's in treatment (which has config)
        String? treatmentUserId;
        for (var i = 0; i < 100; i++) {
          final variant = assigner.assignVariant(
            experiment: experiment,
            userId: 'user_$i',
          );
          if (variant != null && !variant.isControl) {
            treatmentUserId = 'user_$i';
            break;
          }
        }

        expect(treatmentUserId, isNotNull);
        final config = assigner.getVariantConfig(
          experiment: experiment,
          userId: treatmentUserId!,
        );

        expect(config, isNotNull);
        expect(config!['model_version'], equals('v2.0'));
      });

      test('returns empty config for control variant', () {
        final experiment = createTestExperiment();

        // Find a user that's in control
        String? controlUserId;
        for (var i = 0; i < 100; i++) {
          final variant = assigner.assignVariant(
            experiment: experiment,
            userId: 'user_$i',
          );
          if (variant != null && variant.isControl) {
            controlUserId = 'user_$i';
            break;
          }
        }

        expect(controlUserId, isNotNull);
        final config = assigner.getVariantConfig(
          experiment: experiment,
          userId: controlUserId!,
        );

        expect(config, isNotNull);
        expect(config, isEmpty);
      });
    });

    group('simulateDistribution', () {
      test('returns distribution counts for all variants', () {
        final experiment = createTestExperiment();

        final distribution = assigner.simulateDistribution(
          experiment: experiment,
          sampleSize: 1000,
        );

        expect(distribution, isNotEmpty);
        expect(distribution.containsKey('control'), isTrue);
        expect(distribution.containsKey('treatment_a'), isTrue);

        final total = distribution.values.reduce((a, b) => a + b);
        expect(total, equals(1000));
      });
    });

    group('validateDistribution', () {
      test('validates distribution within tolerance', () {
        final experiment = createTestExperiment();

        final result = assigner.validateDistribution(
          experiment: experiment,
          actualCounts: {'control': 510, 'treatment_a': 490},
          tolerancePercent: 5.0,
        );

        expect(result.isValid, isTrue);
      });

      test('fails validation outside tolerance', () {
        final experiment = createTestExperiment();

        final result = assigner.validateDistribution(
          experiment: experiment,
          actualCounts: {'control': 700, 'treatment_a': 300},
          tolerancePercent: 5.0,
        );

        expect(result.isValid, isFalse);
        expect(result.message, contains('deviation'));
      });

      test('fails validation with no assignments', () {
        final experiment = createTestExperiment();

        final result = assigner.validateDistribution(
          experiment: experiment,
          actualCounts: {},
          tolerancePercent: 5.0,
        );

        expect(result.isValid, isFalse);
        expect(result.message, contains('No assignments'));
      });
    });

    group('multiple variants', () {
      test('distributes traffic across three variants', () {
        final experiment = createTestExperiment(
          variants: [
            ExperimentVariant.control(trafficPercentage: 34),
            ExperimentVariant.treatment(
              id: 'treatment_a',
              name: 'Treatment A',
              trafficPercentage: 33,
            ),
            ExperimentVariant.treatment(
              id: 'treatment_b',
              name: 'Treatment B',
              trafficPercentage: 33,
            ),
          ],
        );

        final distribution = assigner.simulateDistribution(
          experiment: experiment,
          sampleSize: 10000,
        );

        expect(distribution.containsKey('control'), isTrue);
        expect(distribution.containsKey('treatment_a'), isTrue);
        expect(distribution.containsKey('treatment_b'), isTrue);

        // Each should be roughly 33%
        for (final count in distribution.values) {
          final percent = count / 10000 * 100;
          expect(percent, closeTo(33, 5));
        }
      });
    });
  });
}
