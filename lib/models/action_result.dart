/// Outcome of a repository action that can be refused, e.g. approving a
/// reservation when no copies are left. Screens show [message] on failure.
class ActionResult {
  const ActionResult.success({
    this.reservationId,
  })  : success = true,
        message = null;

  const ActionResult.failure(String this.message)
      : success = false,
        reservationId = null;

  final bool success;

  /// User-friendly reason, only set when [success] is false.
  final String? message;

  /// ID of the reservation created by the action.
  /// Null for actions that do not create a reservation.
  final String? reservationId;
}