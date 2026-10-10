import 'dart:ffi' show Abi;

import 'errors.dart';

/// The `os` / `arch` values the release server understands.
final class PlatformInfo {
  const PlatformInfo({required this.os, required this.arch});

  /// `macos`, `windows` or `linux`.
  final String os;

  /// `x64` or `arm64`.
  final String arch;

  /// The platform this process is running on. For a macOS universal binary
  /// this is the architecture it is actually executing as (a Rosetta run is
  /// `x64`); the server still picks the `universal` file for either.
  factory PlatformInfo.current() {
    final abi = Abi.current();
    final os = switch (abi.toString().split('_').first) {
      'macos' => 'macos',
      'windows' => 'windows',
      'linux' => 'linux',
      final other => throw UpdateException(
          UpdateErrorKind.unsupportedPlatform, 'Unsupported OS: $other'),
    };
    final arch = switch (abi.toString().split('_').last) {
      'x64' => 'x64',
      'arm64' => 'arm64',
      final other => throw UpdateException(
          UpdateErrorKind.unsupportedPlatform, 'Unsupported CPU: $other'),
    };
    return PlatformInfo(os: os, arch: arch);
  }
}
