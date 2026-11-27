import "dart:developer";
import "dart:isolate" as iso;

import "package:vm_service/vm_service.dart"
    show ClassRef, CpuSample, FuncRef, VmService;
import "package:vm_service/vm_service_io.dart";

/// Allocation classes worth guarding in a hot loop: geometry, closures,
/// records, lists, sets, iterators and boxed doubles.
const guardedClasses = {
  "Rect",
  "RRect",
  "Offset",
  "Size",
  "Color",
  "Vector2",
  "_Closure",
  "_Record",
  "_Float32List",
  "Path",
  "_GrowableList",
  "_List",
  "ListIterator",
  "_CompactIterator",
  "_Set",
};

/// The VM service address, or null when tests run without
/// `--enable-vmservice` (`make test` passes it).
Future<Uri?> vmServiceUri() async =>
    (await Service.getInfo()).serverWebSocketUri;

/// Runs [warmUp] (to compile every path and build caches), then traces
/// allocations of the [traced] classes while [measure] runs, twice, in two
/// separate time windows.
///
/// Returns the allocations whose stack passes through one of the [ours]
/// classes or top-level functions and none of the [allowed]
/// `Owner.function` frames, counted by `"Class at a < b < c < d"` (the four
/// innermost frames), summed over both windows. Only sites seen in **both**
/// windows count: a real per-frame allocation repeats in every window, while
/// a one-off from the JIT compiling a branch late (a stray `_List` under an
/// arithmetic operator) does not, so the guard is not flaky. Must run
/// outside fake async (inside `tester.runAsync` in widget tests).
Future<Map<String, int>> traceAllocations(
  Uri uri, {
  required Set<String> ours,
  required void Function() warmUp,
  required void Function() measure,
  Set<String> traced = guardedClasses,
  Set<String> allowed = const {},
}) async {
  final VmService vm = await vmServiceConnectUri(uri.toString());
  final id = Service.getIsolateId(iso.Isolate.current)!;
  warmUp();
  final profile = await vm.getAllocationProfile(id);
  final classes = {
    for (final m in profile.members!)
      if (traced.contains(m.classRef!.name)) m.classRef!.name!: m.classRef!.id!,
  };

  String? owner(Object? fn) {
    if (fn is! FuncRef) {
      return null;
    }
    final o = fn.owner;
    return o is ClassRef
        ? o.name
        : o is FuncRef
        ? owner(o)
        : null;
  }

  Future<Map<String, int>> window() async {
    final origin = (await vm.getVMTimelineMicros()).timestamp!;
    for (final cid in classes.values) {
      await vm.setTraceClassAllocation(id, cid, true);
    }
    measure();
    for (final cid in classes.values) {
      await vm.setTraceClassAllocation(id, cid, false);
    }
    final end = (await vm.getVMTimelineMicros()).timestamp!;
    final found = <String, int>{};
    for (final MapEntry(key: name, value: cid) in classes.entries) {
      final traces = await vm.getAllocationTraces(
        id,
        classId: cid,
        timeOriginMicros: origin,
        timeExtentMicros: end - origin,
      );
      for (final sample in traces.samples ?? const <CpuSample>[]) {
        final stack = [
          for (final i in sample.stack ?? const <int>[])
            traces.functions![i].function,
        ];
        final qualified = [
          for (final fn in stack)
            if (fn is FuncRef) "${owner(fn)}.${fn.name}",
        ];
        final inOurs = stack.any(
          (fn) =>
              fn is FuncRef &&
              (ours.contains(owner(fn)) ||
                  (fn.owner is! ClassRef && ours.contains(fn.name))),
        );
        if (qualified.any(allowed.contains) || !inOurs) {
          continue;
        }
        final where = qualified.take(4).join(" < ");
        found["$name at $where"] = (found["$name at $where"] ?? 0) + 1;
      }
    }
    return found;
  }

  final first = await window();
  final second = await window();
  await vm.dispose();
  return {
    for (final MapEntry(:key, :value) in first.entries)
      if (second[key] case final again?) key: value + again,
  };
}
