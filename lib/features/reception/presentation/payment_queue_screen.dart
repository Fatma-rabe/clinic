import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/providers.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/models/patient.dart';

/// Workflow: select patient → cash payment → invoice → visit → live queue.
class PaymentQueueScreen extends ConsumerStatefulWidget {
  const PaymentQueueScreen({super.key});

  @override
  ConsumerState<PaymentQueueScreen> createState() => _PaymentQueueScreenState();
}

class _PaymentQueueScreenState extends ConsumerState<PaymentQueueScreen> {
  final _searchController = TextEditingController();
  final _amountController = TextEditingController();
  Patient? _selected;
  String _serviceType = AppConstants.serviceTypes.first;
  bool _processing = false;

  @override
  void dispose() {
    _searchController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _confirmPaymentAndQueue() async {
    final patient = _selected;
    final amount = double.tryParse(_amountController.text);
    if (patient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a patient first')),
      );
      return;
    }
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid cash amount')),
      );
      return;
    }

    setState(() => _processing = true);
    try {
      await ref.read(receptionWorkflowServiceProvider).processPaymentAndEnqueue(
            patient: patient,
            amountPaid: amount,
            serviceType: _serviceType,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Payment logged. ${patient.name} added to live queue.',
            ),
          ),
        );
        _amountController.clear();
        setState(() => _selected = null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Workflow failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = _searchController.text;
    final patientsAsync = ref.watch(
      _patientSearchProvider(searchQuery),
    );
    final isMobile = !Responsive.isDesktop(context);

    if (isMobile) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 350,
              child: _PatientSearchPanel(
                searchController: _searchController,
                patientsAsync: patientsAsync,
                selected: _selected,
                onSelect: (p) => setState(() => _selected = p),
              ),
            ),
            const SizedBox(height: 20),
            _PaymentFormPanel(
              selected: _selected,
              serviceType: _serviceType,
              onServiceTypeChanged: (v) =>
                  setState(() => _serviceType = v),
              amountController: _amountController,
              processing: _processing,
              onConfirm: _confirmPaymentAndQueue,
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate height safely: use available space if finite, 
        // otherwise fallback to screen height to avoid zero-size hit test errors.
        final height = constraints.maxHeight.isFinite 
            ? constraints.maxHeight 
            : MediaQuery.of(context).size.height - 140;
        return SizedBox(
          height: height,
          child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 550,
                child: _PatientSearchPanel(
                  searchController: _searchController,
                  patientsAsync: patientsAsync,
                  selected: _selected,
                  onSelect: (p) => setState(() => _selected = p),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 1,
              child: _PaymentFormPanel(
                selected: _selected,
                serviceType: _serviceType,
                onServiceTypeChanged: (v) =>
                    setState(() => _serviceType = v),
                amountController: _amountController,
                processing: _processing,
                onConfirm: _confirmPaymentAndQueue,
              ),
            ),
          ],
          ),
        );
      },
    );
  }
}

class _PatientSearchPanel extends StatefulWidget {
  const _PatientSearchPanel({
    required this.searchController,
    required this.patientsAsync,
    required this.selected,
    required this.onSelect,
  });

  final TextEditingController searchController;
  final AsyncValue<List<Patient>> patientsAsync;
  final Patient? selected;
  final Function(Patient) onSelect;

  @override
  State<_PatientSearchPanel> createState() => _PatientSearchPanelState();
}

class _PatientSearchPanelState extends State<_PatientSearchPanel> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.person_search, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Select Patient',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: widget.searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or phone...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: widget.patientsAsync.when(
              data: (patients) {
                if (patients.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_outline,
                            size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(
                          'No patients found',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  itemCount: patients.length,
                  itemBuilder: (context, i) {
                    final p = patients[i];
                    final selected = widget.selected?.patientId == p.patientId;
                    return _PatientTile(
                      patient: p,
                      isSelected: selected,
                      onTap: () => widget.onSelect(p),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _PatientTile extends StatelessWidget {
  const _PatientTile({
    required this.patient,
    required this.isSelected,
    required this.onTap,
  });

  final Patient patient;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[300] ?? Colors.grey,
                child: Text(
                  patient.name.isNotEmpty ? patient.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.phone_outlined, size: 12, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            patient.phone,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.cake_outlined, size: 12, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${patient.age}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentFormPanel extends StatelessWidget {
  const _PaymentFormPanel({
    required this.selected,
    required this.serviceType,
    required this.onServiceTypeChanged,
    required this.amountController,
    required this.processing,
    required this.onConfirm,
  });

  final Patient? selected;
  final String serviceType;
  final ValueChanged<String> onServiceTypeChanged;
  final TextEditingController amountController;
  final bool processing;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.payments, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 12),
                  Text(
                    'Payment & Queue',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (selected != null)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D6A4F).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF2D6A4F).withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle,
                              color: Color(0xFF2D6A4F), size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selected!.name,
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF2D6A4F),
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  selected!.phone,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[300] ?? Colors.grey),
                      ),
                      child: Text(
                        'No patient selected',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Text(
                    'Service Type',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: serviceType,
                    items: AppConstants.serviceTypes
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) onServiceTypeChanged(v);
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Cash Amount (\$)',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountController,
                    decoration: InputDecoration(
                      prefixText: '\$ ',
                      prefixStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                      hintText: '0.00',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: processing ? null : onConfirm,
                    icon: processing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(processing ? 'Processing...' : 'Confirm & Queue'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final _patientSearchProvider = StreamProvider.family<List<Patient>, String>((ref, query) {
  return ref.watch(patientRepositoryProvider).searchByName(query);
});
