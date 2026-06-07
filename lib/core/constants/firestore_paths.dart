/// Centralized Firestore collection and field path constants.
class FirestorePaths {
  FirestorePaths._();

  static const String users = 'users';
  static const String patients = 'patients';
  static const String visits = 'visits';
  static const String liveQueue = 'live_queue';
  static const String invoices = 'invoices';
  static const String expenses = 'expenses';
  static const String medicalReps = 'medical_reps';
  static const String appointments = 'appointments';

  static String patientDoc(String patientId) => '$patients/$patientId';
  static String visitsCollection(String patientId) =>
      '$patients/$patientId/$visits';

  static String xrayStoragePath(
    String patientId,
    String visitId,
    String fileName,
  ) =>
      'xrays/$patientId/$visitId/$fileName';
}
