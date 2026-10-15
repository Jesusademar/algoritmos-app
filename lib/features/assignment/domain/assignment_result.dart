import 'package:app_grafos/shared/domain/mathematical_procedure.dart';
import 'package:app_grafos/features/assignment/domain/assignment_problem.dart';

class AssignmentMatch {
  const AssignmentMatch({
    required this.origin,
    required this.destination,
    required this.value,
  });

  final AssignmentItem origin;
  final AssignmentItem destination;
  final num value;
}

class AssignmentResult {
  AssignmentResult({required List<AssignmentMatch> matches, this.procedure})
    : matches = List.unmodifiable(matches),
      total = matches.fold<num>(0, (sum, match) => sum + match.value);

  final List<AssignmentMatch> matches;
  final num total;
  final MathematicalProcedure? procedure;
}
