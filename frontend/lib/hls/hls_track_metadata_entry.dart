import 'package:better_player/src/hls/hls_parser/hls_track_metadata_entry.dart';
import 'package:better_player/src/hls/hls_parser/variant_info.dart';

class HlsTrackMetadataEntryPatch extends HlsTrackMetadataEntry {
  final String? groupId;
  final String? name;
  final List<VariantInfo>? variantInfos;

  HlsTrackMetadataEntryPatch({
    this.groupId,
    this.name,
    this.variantInfos,
  });

  @override
  int get hashCode => Object.hash(groupId, name, variantInfos);
} 