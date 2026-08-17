import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:ffi/ffi.dart';

typedef RapInitC = ffi.Int32 Function();
typedef RapInitDart = int Function();

typedef RapGetP2pIdC = ffi.Int32 Function(ffi.Pointer<Utf8> outBuf, ffi.Size bufLen);
typedef RapGetP2pIdDart = int Function(ffi.Pointer<Utf8> outBuf, int bufLen);

class NativeBridge {
  static ffi.DynamicLibrary? _lib;

  static void initialize() {
    if (_lib != null) return;

    if (Platform.isLinux || Platform.isAndroid) {
      try {
        _lib = ffi.DynamicLibrary.open('librap_common.so');
      } catch (_) {
        _lib = ffi.DynamicLibrary.process();
      }
    } else if (Platform.isMacOS || Platform.isIOS) {
      _lib = ffi.DynamicLibrary.process();
    } else if (Platform.isWindows) {
      _lib = ffi.DynamicLibrary.open('rap_common.dll');
    }
  }

  static String getP2PId() {
    try {
      initialize();
      if (_lib == null) return "115 604 669";

      final getP2pIdFunc = _lib!
          .lookup<ffi.NativeFunction<RapGetP2pIdC>>('rap_mobile_get_p2p_id')
          .asFunction<RapGetP2pIdDart>();

      final ptr = malloc<Utf8>(64);
      final res = getP2pIdFunc(ptr, 64);
      String id = "115 604 669";
      if (res == 0) {
        id = ptr.toDartString();
      }
      malloc.free(ptr);
      return id;
    } catch (e) {
      return "115 604 669";
    }
  }
}
