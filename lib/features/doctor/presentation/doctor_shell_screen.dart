import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';

import '../../../core/widgets/app_shell.dart';
import '../../shared/presentation/live_queue_panel.dart';
import 'consultation_screen.dart';

class DoctorShellScreen extends ConsumerStatefulWidget {
  const DoctorShellScreen({super.key});

  @override
  ConsumerState<DoctorShellScreen> createState() => _DoctorShellScreenState();
}

class _DoctorShellScreenState extends ConsumerState<DoctorShellScreen> {
  int _index = 0;
  String? _consultPatientId;
  String? _consultPatientName;
  String? _consultVisitId;

  void _openConsultation(String patientId, String patientName, String? visitId) {
    setState(() {
      _consultPatientId = patientId;
      _consultPatientName = patientName;
      _consultVisitId = visitId;
      _index = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      SizedBox(
        height: max(0.0, MediaQuery.of(context).size.height - 140),
        child: LiveQueuePanel(
          showActions: true,
          onPatientTap: (entry) => _openConsultation(
            entry.patientId,
            entry.patientName,
            entry.visitId,
          ),
        ),
      ),
      _consultPatientId != null
          ? ConsultationScreen(
              key: ValueKey(_consultPatientId),
              patientId: _consultPatientId!,
              patientName: _consultPatientName ?? '',
              initialVisitId: _consultVisitId,
            )
          : const Center(
              child: Text('Select a patient from the live queue'),
            ),
    ];

    return AppShell(
      title: _index == 0 ? 'Live Patient Queue' : 'Patient Consultation',
      profileName: _index == 0 ? 'د/ محمد ربيع\nDr. Mohamed Rabie' : null,
      selectedIndex: _index,
      onDestinationSelected: (i) => setState(() => _index = i),
      destinations: const [
        AppNavDestination(
          icon: Icons.queue_outlined,
          label: 'Queue',
        ),
        AppNavDestination(
          icon: Icons.medical_services_outlined,
          label: 'Consult',
        ),
      ],
      actions: [
        IconButton(
          tooltip: 'Financial Dashboard',
          onPressed: () => context.push('/doctor/finance'),
          icon: const Icon(Icons.lock_outline, color: Colors.white),
        ),
      ],
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: pages[_index],
      ),
    );
  }
}
