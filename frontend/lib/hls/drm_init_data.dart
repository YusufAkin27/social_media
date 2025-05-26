import 'package:better_player/src/hls/hls_parser/drm_init_data.dart';
import 'package:better_player/src/hls/hls_parser/scheme_data.dart';

class DrmInitDataPatch extends DrmInitData {
  final String schemeType;
  final List<SchemeData> schemeData;

  DrmInitDataPatch({required this.schemeType, required this.schemeData});

  @override
  int get hashCode => Object.hash(schemeType, schemeData);
} 