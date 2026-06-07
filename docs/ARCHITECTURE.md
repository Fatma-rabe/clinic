# Architecture & Screen Map

## State management: **Riverpod 2**

- `StreamProvider` for Firestore realtime (live queue, visits, finance)
- `StateNotifierProvider` for auth actions
- `StateProvider` for finance date range and role-based access

## Firestore schema

### `users/{uid}`
```json
{ "uid": "", "name": "", "email": "", "role": "receptionist" | "doctor" }
```

### `patients/{patient_id}`
```json
{ "patient_id": "", "name": "", "phone": "", "age": 0, "general_history": "", "created_at": "Timestamp" }
```

### `patients/{patient_id}/visits/{visit_id}`
```json
{ "visit_id": "", "date": "Timestamp", "diagnosis": "", "prescription_text": "", "x_ray_url": "" }
```

### `live_queue/{queue_entry_id}` (realtime workflow)
```json
{ "queue_entry_id": "", "patient_id": "", "patient_name": "", "phone": "", "status": "waiting|in_consultation|completed", "created_at": "Timestamp", "visit_id": "" }
```

### `invoices/{invoice_id}`
```json
{ "invoice_id": "", "patient_id": "", "amount_paid": 0.0, "service_type": "Examination", "date": "Timestamp" }
```

### `expenses/{expense_id}`
```json
{ "expense_id": "", "title": "", "amount": 0.0, "date": "Timestamp" }
```

### `medical_reps/{rep_id}`
```json
{ "rep_id": "", "rep_name": "", "company_name": "", "visit_date": "Timestamp", "notes": "" }
```

### Storage: `xrays/{patientId}/{visitId}/xray_{timestamp}.jpg`

## Screen structure

```
/login
├── Reception (role: receptionist)  /reception
│   ├── Tab: Register Patient       → PatientRegistrationScreen
│   ├── Tab: Payment & Queue        → PaymentQueueScreen (invoice + visit + queue)
│   ├── Tab: Expenses               → ExpenseLogScreen
│   └── Tab: Live Queue              → LiveQueuePanel (read-only)
│
└── Doctor (role: doctor)           /doctor
    ├── Tab: Live Queue              → LiveQueuePanel (actions + open consult)
    ├── Tab: Consultation            → ConsultationScreen (history, Rx, X-ray, print)
    └── Route: Financial Dashboard   /doctor/finance (doctor-only metrics)
```

## Key files

| Concern | Path |
|---------|------|
| Firebase init + offline | `lib/core/services/firebase_init_service.dart` |
| Image compression | `lib/core/services/image_compress_service.dart` |
| Live queue stream | `lib/data/repositories/queue_repository.dart` |
| Financial aggregation | `lib/data/services/financial_aggregation_service.dart` |
| Security rules | `firebase/firestore.rules`, `firebase/storage.rules` |
| Setup checklist | `docs/FIREBASE_SETUP_CHECKLIST.md` |
