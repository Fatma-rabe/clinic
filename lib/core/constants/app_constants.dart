/// Application-wide constants.
class AppConstants {
  AppConstants._();

  static const String appName = 'OrthoClinic Pro';

  /// Max compressed X-ray size target (bytes) before upload.
  static const int maxXrayBytes = 2 * 1024 * 1024;

  /// JPEG quality for flutter_image_compress (0–100).
  static const int xrayCompressQuality = 72;

  /// Max dimension (width or height) after resize.
  static const int xrayMaxDimension = 2048;

  static const List<String> serviceTypes = [
    'Examination',
    'Consultation',
    'Splinting',
    'Follow-up',
    'Injection',
  ];

  static const String roleDoctor = 'doctor';
  static const String roleReceptionist = 'receptionist';

  static const String queueStatusWaiting = 'waiting';
  static const String queueStatusInConsultation = 'in_consultation';
  static const String queueStatusCompleted = 'completed';
}
