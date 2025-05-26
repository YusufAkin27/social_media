import 'package:better_player/src/hls/hls_parser/variant_info.dart';

class VariantInfoPatch extends VariantInfo {
  final int? bitrate;
  final String? url;
  final String? codecs;
  final String? resolution;
  final double? frameRate;
  final String? videoGroupId;
  final String? audioGroupId;
  final String? subtitleGroupId;
  final String? captionGroupId;

  VariantInfoPatch({
    this.bitrate,
    this.url,
    this.codecs,
    this.resolution,
    this.frameRate,
    this.videoGroupId,
    this.audioGroupId,
    this.subtitleGroupId,
    this.captionGroupId,
  });

  @override
  int get hashCode => Object.hash(
        bitrate,
        url,
        codecs,
        resolution,
        frameRate,
        videoGroupId,
        audioGroupId,
        subtitleGroupId,
        captionGroupId,
      );
} 