import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/firestore_paths.dart';
import '../models/invoice.dart';
import '../models/patient.dart';
import '../models/queue_entry.dart';
import '../models/visit.dart';

/// Handles multi-document reception workflows as an atomic batch.
class ReceptionWorkflowService {
  ReceptionWorkflowService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  Future<void> processPaymentAndEnqueue({
    required Patient patient,
    required double amountPaid,
    required String serviceType,
  }) async {
    final invoiceId = _uuid.v4();
    final visitId = _uuid.v4();
    final queueEntryId = patient.patientId;

    final invoice = Invoice(
      invoiceId: invoiceId,
      patientId: patient.patientId,
      amountPaid: amountPaid,
      serviceType: serviceType,
      date: DateTime.now(),
    );

    final visit = Visit(
      visitId: visitId,
      date: DateTime.now(),
      diagnosis: '',
      prescriptionText: '',
      xRayUrl: '',
    );

    final queueEntry = QueueEntry(
      queueEntryId: queueEntryId,
      patientId: patient.patientId,
      patientName: patient.name,
      phone: patient.phone,
      status: AppConstants.queueStatusWaiting,
      createdAt: DateTime.now(),
      visitId: visitId,
    );

    final queueDoc = _firestore.collection(FirestorePaths.liveQueue).doc(queueEntryId);
    final invoiceDoc = _firestore.collection(FirestorePaths.invoices).doc(invoiceId);
    final visitDoc = _firestore
        .collection(FirestorePaths.patients)
        .doc(patient.patientId)
        .collection(FirestorePaths.visits)
        .doc(visitId);

    final batch = _firestore.batch();
    batch.set(invoiceDoc, invoice.toJson());
    batch.set(visitDoc, visit.toJson()); 
    
    final queueData = queueEntry.toJson();
    queueData['created_at'] = FieldValue.serverTimestamp();
    
    batch.set(queueDoc, queueData, SetOptions(merge: true));

    await batch.commit();
  }
}
