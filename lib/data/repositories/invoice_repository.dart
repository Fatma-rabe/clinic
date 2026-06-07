import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/firestore_paths.dart';
import '../models/invoice.dart';

class InvoiceRepository {
  InvoiceRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(FirestorePaths.invoices);

  Future<Invoice> createCashInvoice({
    required String patientId,
    required double amountPaid,
    required String serviceType,
  }) async {
    final id = _uuid.v4();
    final invoice = Invoice(
      invoiceId: id,
      patientId: patientId,
      amountPaid: amountPaid,
      serviceType: serviceType,
      date: DateTime.now(),
    );
    await _col.doc(id).set(invoice.toJson());
    return invoice;
  }

  Stream<List<Invoice>> watchInvoicesInRange({
    required DateTime start,
    required DateTime end,
  }) {
    return _col
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('date')
        .snapshots()
        .map((snap) => snap.docs.map(Invoice.fromFirestore).toList());
  }

  Future<List<Invoice>> fetchInvoicesInRange({
    required DateTime start,
    required DateTime end,
  }) async {
    final snap = await _col
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('date')
        .get();
    return snap.docs.map(Invoice.fromFirestore).toList();
  }
}
