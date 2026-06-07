import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/appointment_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/expense_repository.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../data/repositories/medical_rep_repository.dart';
import '../../data/repositories/patient_repository.dart';
import '../../data/repositories/queue_repository.dart';
import '../../data/repositories/visit_repository.dart';
import '../../data/services/financial_aggregation_service.dart';
import '../../data/services/reception_workflow_service.dart';
import '../services/image_compress_service.dart';

// Repositories
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final patientRepositoryProvider = Provider<PatientRepository>((ref) {
  return PatientRepository();
});

final queueRepositoryProvider = Provider<QueueRepository>((ref) {
  return QueueRepository();
});

final visitRepositoryProvider = Provider<VisitRepository>((ref) {
  return VisitRepository();
});

final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  return InvoiceRepository();
});

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository();
});

final medicalRepRepositoryProvider = Provider<MedicalRepRepository>((ref) {
  return MedicalRepRepository();
});

final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  return AppointmentRepository();
});

final receptionWorkflowServiceProvider = Provider<ReceptionWorkflowService>((ref) {
  return ReceptionWorkflowService();
});

final imageCompressServiceProvider = Provider<ImageCompressService>((ref) {
  return ImageCompressService();
});

final financialAggregationServiceProvider =
    Provider<FinancialAggregationService>((ref) {
  return FinancialAggregationService();
});

// Realtime live queue stream
final liveQueueStreamProvider = StreamProvider((ref) {
  return ref.watch(queueRepositoryProvider).watchLiveQueue();
});
