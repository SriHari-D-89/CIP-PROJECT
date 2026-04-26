import 'package:flutter/material.dart';
import '../../services/admin_service.dart';

class AdminSettingsView extends StatefulWidget {
  const AdminSettingsView({super.key});

  @override
  State<AdminSettingsView> createState() => _AdminSettingsViewState();
}

class _AdminSettingsViewState extends State<AdminSettingsView> {
  final _adminService = AdminService();
  DateTime? _semesterStartDate;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    final dateStr = await _adminService.getSetting('semester_start_date');
    if (dateStr != null) {
      setState(() {
        _semesterStartDate = DateTime.parse(dateStr);
      });
    }
    setState(() => _isLoading = false);
  }

  void _saveSettings() async {
    if (_semesterStartDate == null) return;
    
    setState(() => _isSaving = true);
    try {
      await _adminService.setSetting('semester_start_date', _semesterStartDate!.toIso8601String());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Academic Configuration', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              title: const Text('Semester Start Date'),
              subtitle: Text(_semesterStartDate == null 
                ? 'Not Set' 
                : '${_semesterStartDate!.day}/${_semesterStartDate!.month}/${_semesterStartDate!.year}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _semesterStartDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => _semesterStartDate = picked);
                }
              },
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveSettings,
              child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Configuration'),
            ),
          ),
          const Spacer(),
          const Center(
            child: Text(
              'This date limits how far back faculty can mark attendance.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
