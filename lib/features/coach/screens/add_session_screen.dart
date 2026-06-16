import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/session_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class AddSessionScreen extends StatefulWidget {
  const AddSessionScreen({super.key});

  @override
  State<AddSessionScreen> createState() => _AddSessionScreenState();
}

class _AddSessionScreenState extends State<AddSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _type = AppConstants.sessionTypeTraining;
  String? _sport;
  String? _category;
  DateTime _dateTime = DateTime.now().add(const Duration(hours: 2));

  @override
  void dispose() {
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx)
              .colorScheme
              .copyWith(primary: AppTheme.primaryGreen),
        ),
        child: child!,
      ),
    );
    if (date != null && mounted) {
      setState(() {
        _dateTime = DateTime(
            date.year, date.month, date.day, _dateTime.hour, _dateTime.minute);
      });
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx)
              .colorScheme
              .copyWith(primary: AppTheme.primaryGreen),
        ),
        child: child!,
      ),
    );
    if (time != null && mounted) {
      setState(() {
        _dateTime = DateTime(_dateTime.year, _dateTime.month, _dateTime.day,
            time.hour, time.minute);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_sport == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a sport')));
      return;
    }
    final user = context.read<AuthProvider>().userModel!;
    final success = await context.read<SessionProvider>().createSession(
          title: _titleCtrl.text.trim(),
          type: _type,
          dateTime: _dateTime,
          location: _locationCtrl.text.trim(),
          notes: _notesCtrl.text.trim(),
          category: _category,
          sport: _sport,
          organizationId: user.organizationId,
          branchId: user.branchId ?? '',
          coachUid: user.uid,
          coachName: user.name,
        );
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Session scheduled! Players will be notified.'),
        backgroundColor: AppTheme.successGreen,
      ));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SessionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Session'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type selector
              const Text('Session Type',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _TypeButton(
                      label: 'Training',
                      icon: Icons.fitness_center,
                      selected: _type == AppConstants.sessionTypeTraining,
                      onTap: () => setState(
                          () => _type = AppConstants.sessionTypeTraining),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TypeButton(
                      label: 'Match',
                      icon: Icons.emoji_events,
                      selected: _type == AppConstants.sessionTypeMatch,
                      onTap: () => setState(
                          () => _type = AppConstants.sessionTypeMatch),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Sport selector
              const Text('Sport',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: AppConstants.sports.map((s) {
                    final selected = _sport == s;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label:
                            Text(s[0].toUpperCase() + s.substring(1)),
                        selected: selected,
                        onSelected: (_) =>
                            setState(() => _sport = s),
                        selectedColor: AppTheme.primaryGreen,
                        labelStyle: TextStyle(
                          color: selected
                              ? AppTheme.onPrimary
                              : AppTheme.textGrey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                    labelText: 'Title',
                    prefixIcon: Icon(Icons.title)),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter title' : null,
              ),
              const SizedBox(height: 12),

              // Date & Time row
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                            labelText: 'Date',
                            prefixIcon:
                                Icon(Icons.calendar_today_outlined)),
                        child: Text(DateFormat('d MMM yyyy').format(_dateTime)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _pickTime,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                            labelText: 'Time',
                            prefixIcon:
                                Icon(Icons.access_time_outlined)),
                        child:
                            Text(DateFormat('h:mm a').format(_dateTime)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _locationCtrl,
                decoration: const InputDecoration(
                    labelText: 'Location',
                    prefixIcon: Icon(Icons.location_on_outlined)),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter location' : null,
              ),
              const SizedBox(height: 12),

              // Category (optional)
              DropdownButtonFormField<String?>(
                initialValue: _category,
                decoration: const InputDecoration(
                    labelText: 'Category (optional)',
                    prefixIcon: Icon(Icons.group_outlined)),
                hint: const Text('All players'),
                items: [
                  const DropdownMenuItem(
                      value: null, child: Text('All players')),
                  ...AppConstants.categories.map((c) =>
                      DropdownMenuItem(value: c, child: Text(c))),
                ],
                onChanged: (v) => setState(() => _category = v),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    prefixIcon: Icon(Icons.notes),
                    alignLabelWithHint: true),
              ),

              if (provider.error != null) ...[
                const SizedBox(height: 12),
                Text(provider.error!,
                    style: const TextStyle(color: AppTheme.errorRed)),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: provider.isLoading ? null : _save,
                  child: provider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Schedule Session'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.primaryGreen : Colors.grey;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryGreen.withValues(alpha: 0.08)
              : AppTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected
                  ? AppTheme.primaryGreen
                  : AppTheme.borderDark),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
