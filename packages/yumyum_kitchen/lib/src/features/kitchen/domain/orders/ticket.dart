import "package:yumyum_kitchen/src/features/kitchen/domain/orders/bowl.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/orders/recipe.dart";

/// An order on the ticket rail: a guest's [recipe] and their patience,
/// from [arrivedAt] until [expiresAt] (run clock, ms).
class Ticket {
  const Ticket(this.id, this.recipe, this.arrivedAt, this.expiresAt);

  final int id;
  final Recipe recipe;
  final int arrivedAt;
  final int expiresAt;

  /// Patience left in thousandths: 1000 on arrival, 0 when it runs out.
  /// The speed part of the tip and the patience bar both read it.
  int patiencePermille(int now) {
    final permille = (expiresAt - now) * 1000 ~/ (expiresAt - arrivedAt);
    return permille < 0
        ? 0
        : permille > 1000
        ? 1000
        : permille;
  }
}

/// Index of the ticket with the least patience left (earliest [Ticket.expiresAt],
/// then the lowest index), skipping indexes set in the [skip] bit mask; -1
/// when none is left. The rail is sorted by this order.
int mostUrgent(List<Ticket?> tickets, {int skip = 0}) {
  var urgent = -1;
  for (var i = 0; i < tickets.length; i++) {
    final ticket = tickets[i];
    if (ticket == null || skip & (1 << i) != 0) {
      continue;
    }
    if (urgent < 0 || ticket.expiresAt < tickets[urgent]!.expiresAt) {
      urgent = i;
    }
  }
  return urgent;
}

/// The ticket a finished [bowl] is served to: the most urgent one whose
/// recipe it matches exactly, or -1 (the bowl shakes and stays).
int ticketFor(Bowl bowl, List<Ticket?> tickets) {
  var skip = 0;
  for (var round = 0; round < tickets.length; round++) {
    final urgent = mostUrgent(tickets, skip: skip);
    if (urgent < 0) {
      return -1;
    }
    if (bowl.matches(tickets[urgent]!.recipe)) {
      return urgent;
    }
    skip |= 1 << urgent;
  }
  return -1;
}
