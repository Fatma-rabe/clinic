import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

import 'dart:async';
import '../../../core/providers/providers.dart';
import '../../../data/models/patient.dart';
import '../../../data/models/visit.dart';
import '../../../data/models/drug_model.dart';
import '../providers/drug_search_provider.dart';
import '../services/prescription_print_service.dart';
import 'xray_viewer_screen.dart';

class ConsultationScreen extends ConsumerStatefulWidget {
  const ConsultationScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    this.initialVisitId,
  });

  final String patientId;
  final String patientName;
  final String? initialVisitId;

  @override
  ConsumerState<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends ConsumerState<ConsultationScreen> {
  final _diagnosisController = TextEditingController();
  final _prescriptionController = TextEditingController();
  List<String> _selectedDrugs = [];
  Visit? _selectedVisit;
  bool _saving = false;
  bool _uploading = false;

  @override
  void dispose() {
    _diagnosisController.dispose();
    _prescriptionController.dispose();
    super.dispose();
  }

  void _selectVisit(Visit visit) {
    setState(() {
      _selectedVisit = visit;
      _diagnosisController.text = visit.diagnosis;
      _prescriptionController.text = visit.prescriptionText;
      _selectedDrugs = List.from(visit.selectedDrugs);
    });
  }

  Future<void> _saveConsultation() async {
    var visit = _selectedVisit;
    if (visit == null) {
      visit = await ref.read(visitRepositoryProvider).createVisit(
            patientId: widget.patientId,
          );
      setState(() => _selectedVisit = visit);
    }
    setState(() => _saving = true);
    try {
      await ref.read(visitRepositoryProvider).updateVisit(
            patientId: widget.patientId,
            visitId: visit.visitId,
            diagnosis: _diagnosisController.text.trim(),
            prescriptionText: _prescriptionController.text.trim(),
            selectedDrugs: _selectedDrugs,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Consultation saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickAndUploadXray() async {
    Uint8List? bytes;
    if (kIsWeb) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      bytes = result?.files.single.bytes;
    } else {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery);
      if (file != null) {
        bytes = await file.readAsBytes();
      }
    }

    if (bytes == null || bytes.isEmpty) return;

    Visit activeVisit = _selectedVisit ??
        await ref.read(visitRepositoryProvider).createVisit(
              patientId: widget.patientId,
            );
    if (_selectedVisit == null) {
      setState(() => _selectedVisit = activeVisit);
    }

    setState(() => _uploading = true);
    try {
      final url = await ref.read(visitRepositoryProvider).uploadXray(
            patientId: widget.patientId,
            visitId: activeVisit.visitId,
            imageBytes: bytes,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('X-ray uploaded (compressed)')),
        );
        setState(() {
          _selectedVisit = Visit(
            visitId: activeVisit.visitId,
            date: activeVisit.date,
            diagnosis: activeVisit.diagnosis,
            prescriptionText: activeVisit.prescriptionText,
            xRayUrl: url,
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _printPrescription() async {
    final patient = await ref
        .read(patientRepositoryProvider)
        .getPatient(widget.patientId);
    if (patient == null || !mounted) return;

    await PrescriptionPrintService.print(
      patient: patient,
      diagnosis: _diagnosisController.text,
      prescription: _prescriptionController.text,
      selectedDrugs: _selectedDrugs,
      doctorName: 'Orthopedic Surgeon',
    );
  }

  @override
  Widget build(BuildContext context) {
    final patientAsync = ref.watch(_patientProvider(widget.patientId));
    final visitsAsync = ref.watch(_visitsProvider(widget.patientId));
    final isMobile = MediaQuery.of(context).size.width < 900;

    visitsAsync.whenData((visits) {
      if (_selectedVisit == null && visits.isNotEmpty) {
        final Visit match;
        if (widget.initialVisitId != null) {
          match = visits.firstWhere(
            (v) => v.visitId == widget.initialVisitId,
            orElse: () => visits.first,
          );
        } else {
          match = visits.first;
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _selectedVisit == null) _selectVisit(match);
        });
      }
    });

    if (isMobile) {
      // Mobile layout - stacked vertically
      return SizedBox(
        height: max(0.0, MediaQuery.of(context).size.height - 160),
        child: DefaultTabController(
          length: 3,
          child: Column(
          children: [
            TabBar(
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: Theme.of(context).colorScheme.primary,
              tabs: const [
                Tab(text: 'Patient Info'),
                Tab(text: 'Diagnosis'),
                Tab(text: 'X-Ray'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Patient Info Tab
                  _PatientInfoPanel(
                    patientAsync: patientAsync,
                    patientName: widget.patientName,
                    visitsAsync: visitsAsync,
                    selectedVisit: _selectedVisit,
                    onSelectVisit: _selectVisit,
                  ),
                  // Diagnosis Tab
                  _DiagnosisPanel(
                    diagnosisController: _diagnosisController,
                    prescriptionController: _prescriptionController,
                    selectedDrugs: _selectedDrugs,
                    onAddDrug: (d) => setState(() {
                      if (!_selectedDrugs.contains(d)) _selectedDrugs.add(d);
                    }),
                    onRemoveDrug: (d) => setState(() => _selectedDrugs.remove(d)),
                    saving: _saving,
                    onSave: _saveConsultation,
                    onPrint: _printPrescription,
                    onUploadXray: _pickAndUploadXray,
                    uploading: _uploading,
                  ),
                  // X-Ray Tab
                  _selectedVisit?.hasXray == true
                      ? XrayViewerPanel(imageUrl: _selectedVisit!.xRayUrl)
                      : Center(
                          child: Text(
                            _uploading
                                ? 'Uploading X-Ray...'
                                : 'No X-ray for this visit',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
       ),
      );
    }

    // Desktop layout - side by side
    return SizedBox(
      height: max(0.0, MediaQuery.of(context).size.height - 160),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left: Patient Info & Visit History
          Expanded(
            flex: 1,
            child: _PatientInfoPanel(
              patientAsync: patientAsync,
              patientName: widget.patientName,
              visitsAsync: visitsAsync,
              selectedVisit: _selectedVisit,
              onSelectVisit: _selectVisit,
            ),
          ),
          const SizedBox(width: 16),
          // Center: Diagnosis & Prescription
          Expanded(
            flex: 2,
            child: _DiagnosisPanel(
              diagnosisController: _diagnosisController,
              prescriptionController: _prescriptionController,
              selectedDrugs: _selectedDrugs,
              onAddDrug: (d) => setState(() {
                if (!_selectedDrugs.contains(d)) _selectedDrugs.add(d);
              }),
              onRemoveDrug: (d) => setState(() => _selectedDrugs.remove(d)),
              saving: _saving,
              onSave: _saveConsultation,
              onPrint: _printPrescription,
              onUploadXray: _pickAndUploadXray,
              uploading: _uploading,
            ),
          ),
          const SizedBox(width: 16),
          // Right: X-Ray Viewer
          Expanded(
            flex: 1,
            child: _selectedVisit?.hasXray == true
                ? XrayViewerPanel(imageUrl: _selectedVisit!.xRayUrl)
                : Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                        width: 1,
                      ),
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_not_supported_outlined,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _uploading ? 'Uploading...' : 'No X-ray Available',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// Helper Widget: Patient Info Panel
class _PatientInfoPanel extends StatelessWidget {
  const _PatientInfoPanel({
    required this.patientAsync,
    required this.patientName,
    required this.visitsAsync,
    required this.selectedVisit,
    required this.onSelectVisit,
  });

  final AsyncValue<Patient?> patientAsync;
  final String patientName;
  final AsyncValue<List<Visit>> visitsAsync;
  final Visit? selectedVisit;
  final Function(Visit) onSelectVisit;

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
            // Patient Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          patientName,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  patientAsync.when(
                    data: (p) => p == null
                        ? const SizedBox.shrink()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _InfoRow(
                                icon: Icons.cake_outlined,
                                label: 'Age',
                                value: '${p.age} years',
                              ),
                              const SizedBox(height: 8),
                              _InfoRow(
                                icon: Icons.phone_outlined,
                                label: 'Phone',
                                value: p.phone,
                              ),
                              const SizedBox(height: 8),
                              _InfoRow(
                                icon: Icons.description_outlined,
                                label: 'History',
                                value: p.generalHistory.isEmpty
                                    ? 'No history'
                                    : p.generalHistory,
                              ),
                            ],
                          ),
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('Error: $e'),
                  ),
                ],
              ),
            ),
            // Visit History
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Visit History',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            SizedBox(
              height: 300,
              child: visitsAsync.when(
                data: (visits) => visits.isEmpty
                    ? Center(
                        child: Text(
                          'No visits',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: visits.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 8,
                          color: Theme.of(context).dividerColor,
                        ),
                        itemBuilder: (context, i) {
                          final v = visits[i];
                          final selected = selectedVisit?.visitId == v.visitId;
                          return _VisitTile(
                            visit: v,
                            isSelected: selected,
                            onTap: () => onSelectVisit(v),
                          );
                        },
                      ),
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text('Error: $e'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VisitTile extends StatelessWidget {
  const _VisitTile({
    required this.visit,
    required this.isSelected,
    required this.onTap,
  });

  final Visit visit;
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat.yMMMd().format(visit.date),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                  ),
                  const Spacer(),
                  if (visit.hasXray)
                    Icon(
                      Icons.image_outlined,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                visit.diagnosis.isEmpty ? 'No diagnosis' : visit.diagnosis,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Helper Widget: Diagnosis Panel
class _DiagnosisPanel extends StatelessWidget {
  const _DiagnosisPanel({
    required this.diagnosisController,
    required this.prescriptionController,
    required this.selectedDrugs,
    required this.onAddDrug,
    required this.onRemoveDrug,
    required this.saving,
    required this.uploading,
    required this.onSave,
    required this.onPrint,
    required this.onUploadXray,
  });

  final TextEditingController diagnosisController;
  final TextEditingController prescriptionController;
  final List<String> selectedDrugs;
  final ValueChanged<String> onAddDrug;
  final ValueChanged<String> onRemoveDrug;
  final bool saving;
  final bool uploading;
  final VoidCallback onSave;
  final VoidCallback onPrint;
  final VoidCallback onUploadXray;

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
          // Header
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
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.assignment_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Diagnosis & Prescription',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Clinical Diagnosis',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: diagnosisController,
                    decoration: InputDecoration(
                      hintText: 'Enter diagnosis details...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Drugs Search',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  _DrugSearchField(onAddDrug: onAddDrug),
                  const SizedBox(height: 8),
                  if (selectedDrugs.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: selectedDrugs.map((d) {
                        return Chip(
                          label: Text(d),
                          onDeleted: () => onRemoveDrug(d),
                          backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          side: BorderSide.none,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    'Prescription Details',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: prescriptionController,
                    decoration: InputDecoration(
                      hintText: 'Enter prescription details...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 6,
                  ),
                ],
              ),
            ),
          ),
          // Actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: saving ? null : onSave,
                    icon: saving
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
                        : const Icon(Icons.save_outlined),
                    label: Text(saving ? 'Saving...' : 'Save Consultation'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: onPrint,
                    icon: const Icon(Icons.print_outlined),
                    label: const Text('Print'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: uploading ? null : onUploadXray,
                    icon: uploading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_upload_outlined),
                    label: Text(uploading ? 'Uploading...' : 'Upload X-Ray'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final _patientProvider = FutureProvider.family<Patient?, String>((ref, id) {
  return ref.watch(patientRepositoryProvider).getPatient(id);
});

final _visitsProvider = StreamProvider.family<List<Visit>, String>((ref, id) {
  return ref.watch(visitRepositoryProvider).watchVisits(id);
});

class _DrugSearchField extends ConsumerStatefulWidget {
  const _DrugSearchField({required this.onAddDrug});
  final ValueChanged<String> onAddDrug;

  @override
  ConsumerState<_DrugSearchField> createState() => _DrugSearchFieldState();
}

class _DrugSearchFieldState extends ConsumerState<_DrugSearchField> {
  Timer? _debounce;
  TextEditingController? _textController;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<DrugModel>(
      displayStringForOption: (drug) => drug.commercialNameEn,
      optionsBuilder: (TextEditingValue textEditingValue) {
        final query = textEditingValue.text;
        if (query.isEmpty) return const Iterable<DrugModel>.empty();

        final completer = Completer<Iterable<DrugModel>>();
        if (_debounce?.isActive ?? false) _debounce!.cancel();
        
        _debounce = Timer(const Duration(milliseconds: 300), () {
          ref.read(drugSearchQueryProvider.notifier).state = query;
          Future.microtask(() {
            completer.complete(ref.read(filteredDrugsProvider));
          });
        });
        
        return completer.future;
      },
      onSelected: (DrugModel selection) {
        widget.onAddDrug(selection.commercialNameEn);
        _textController?.clear();
      },
      fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
        _textController = controller;
        return TextField(
          controller: controller,
          focusNode: focusNode,
          onEditingComplete: onEditingComplete,
          decoration: InputDecoration(
            hintText: 'Search Egyptian drugs...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      },
    );
  }
}

