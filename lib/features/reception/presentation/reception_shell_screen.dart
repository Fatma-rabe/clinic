import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_shell.dart';
import '../../shared/presentation/live_queue_panel.dart';
import 'expense_log_screen.dart';
import 'patient_registration_screen.dart';
import 'payment_queue_screen.dart';

class ReceptionShellScreen extends ConsumerStatefulWidget {
  const ReceptionShellScreen({super.key});

  @override
  ConsumerState<ReceptionShellScreen> createState() =>
      _ReceptionShellScreenState();
}

class _ReceptionShellScreenState extends ConsumerState<ReceptionShellScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const PatientRegistrationScreen(),
      const PaymentQueueScreen(),
      const ExpenseLogScreen(),
      SizedBox(
        height: MediaQuery.of(context).size.height - 140,
        child: const LiveQueuePanel(),
      ),
    ];

    return AppShell(
      title: 'Reception & Front Desk',
      selectedIndex: _index,
      onDestinationSelected: (i) => setState(() => _index = i),
      destinations: const [
        AppNavDestination(
          icon: Icons.person_add_outlined,
          label: 'Register',
        ),
        AppNavDestination(
          icon: Icons.payments_outlined,
          label: 'Payment',
        ),
        AppNavDestination(
          icon: Icons.receipt_long_outlined,
          label: 'Expenses',
        ),
        AppNavDestination(
          icon: Icons.queue_outlined,
          label: 'Queue',
        ),
      ],
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: pages[_index],
      ),
    );
  }
}
