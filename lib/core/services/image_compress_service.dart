import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;

import '../constants/app_constants.dart';

/// Compresses X-ray images before Firebase Storage upload.
/// Uses [flutter_image_compress] on IO platforms and [image] package on Web.
class ImageCompressService {
  /// Returns JPEG bytes under [AppConstants.maxXrayBytes] when possible.
  Future<Uint8List> compressXray(Uint8List sourceBytes) async {
    if (kIsWeb) {
      return _compressWeb(sourceBytes);
    }
    return _compressNative(sourceBytes);
  }

  Future<Uint8List> _compressNative(Uint8List sourceBytes) async {
    var result = await FlutterImageCompress.compressWithList(
      sourceBytes,
      quality: AppConstants.xrayCompressQuality,
      minWidth: AppConstants.xrayMaxDimension,
      minHeight: AppConstants.xrayMaxDimension,
      format: CompressFormat.jpeg,
    );

    if (result.length <= AppConstants.maxXrayBytes) {
      return Uint8List.fromList(result);
    }

    var quality = AppConstants.xrayCompressQuality - 15;
    while (quality >= 40 && result.length > AppConstants.maxXrayBytes) {
      result = await FlutterImageCompress.compressWithList(
        sourceBytes,
        quality: quality,
        minWidth: 1600,
        minHeight: 1600,
        format: CompressFormat.jpeg,
      );
      quality -= 10;
    }

    return Uint8List.fromList(result);
  }

  Future<Uint8List> _compressWeb(Uint8List sourceBytes) async {
    final decoded = img.decodeImage(sourceBytes);
    if (decoded == null) {
      throw StateError('Unable to decode image for compression.');
    }

    var resized = decoded;
    final maxDim = AppConstants.xrayMaxDimension;
    if (decoded.width > maxDim || decoded.height > maxDim) {
      resized = img.copyResize(
        decoded,
        width: decoded.width >= decoded.height ? maxDim : null,
        height: decoded.height > decoded.width ? maxDim : null,
      );
    }

    var quality = AppConstants.xrayCompressQuality;
    var encoded = Uint8List.fromList(img.encodeJpg(resized, quality: quality));

    while (encoded.length > AppConstants.maxXrayBytes && quality > 35) {
      quality -= 8;
      encoded = Uint8List.fromList(img.encodeJpg(resized, quality: quality));
    }

    return encoded;
  }
}
