/// What keeps a form from being sent, worded for the [field] whose label turns red.
class FieldProblem<F extends Enum> {
  const FieldProblem(this.field, this.message);

  final F field;
  final String message;
}
