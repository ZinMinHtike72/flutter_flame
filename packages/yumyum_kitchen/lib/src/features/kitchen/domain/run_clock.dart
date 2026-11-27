/// The restaurant's one clock, in milliseconds.
///
/// Cookers, trays, tickets, tables and the waiter all keep absolute
/// deadlines on this clock, so pausing it freezes every timer at once: while
/// [paused], [advance] does nothing, and on resume every deadline is still
/// exactly as far away as when the pause began.
class RunClock {
  int now = 0;
  bool paused = false;

  /// Moves time on by [ms] unless paused; returns the time.
  int advance(int ms) {
    if (!paused && ms > 0) {
      now += ms;
    }
    return now;
  }
}
