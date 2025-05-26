import 'package:flutter/foundation.dart';

// This file defines global functions to replace ones that were removed from Flutter
// These are needed by some packages that have not been updated

/// Global hashValues function that can be called from any package.
/// This function replaces the deprecated one originally in Flutter.
int hashValues(Object? a, [Object? b, Object? c, Object? d, Object? e,
                          Object? f, Object? g, Object? h, Object? i,
                          Object? j, Object? k, Object? l, Object? m]) {
  return Object.hash(
    a,
    b,
    c,
    d,
    e,
    f,
    g,
    h,
    i,
    j,
    k,
    l,
    m,
  );
} 