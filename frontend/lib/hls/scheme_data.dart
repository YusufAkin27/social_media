import 'dart:typed_data';
import 'package:better_player/src/hls/hls_parser/scheme_data.dart';

class SchemeDataPatch extends SchemeData {
  final String? licenseServerUrl;
  final Uint8List? requestData;
  final String? mimeType;
  final bool allowedSchemeIdUri;

  SchemeDataPatch({
    this.licenseServerUrl,
    this.requestData,
    this.mimeType,
    this.allowedSchemeIdUri = true,
  });

  @override
  int get hashCode => Object.hash(
        licenseServerUrl,
        requestData != null ? Object.hash(requestData![0], requestData!.length) : null,
        mimeType,
        allowedSchemeIdUri,
      );
} 