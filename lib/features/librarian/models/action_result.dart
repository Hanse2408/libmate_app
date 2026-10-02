/// Outcome of a repository action that can be refused, e.g. approving a
/// reservation when no copies are left. Screens show [message] on failure.
class ActionResult {
  const ActionResult.success() : success = true, message = null;
  const ActionResult.failure(String this.message) : success = false;

  final bool success;

  /// User-friendly reason, only set when [success] is false.
  final String? message;
}
