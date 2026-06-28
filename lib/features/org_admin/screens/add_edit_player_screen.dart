import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/branch_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/batch_model.dart';
import '../../../models/player_model.dart';
import '../../../models/sport_profile_model.dart';
import '../../../services/firestore_service.dart';

class _EnrollmentDraft {
  String sport;
  String category;
  String position;
  int jerseyNumber;
  String? batchId;

  _EnrollmentDraft({
    required this.sport,
    required this.category,
    required this.position,
    required this.jerseyNumber,
    this.batchId,
  });

  String get defaultPosition =>
      AppConstants.sportPositions[sport]?.first ?? '';

  static _EnrollmentDraft fromProfile(SportProfileModel p) =>
      _EnrollmentDraft(
        sport: p.sport,
        category: p.category,
        position: p.position,
        jerseyNumber: p.jerseyNumber,
        batchId: p.batchId.isEmpty ? null : p.batchId,
      );
}

class AddEditPlayerScreen extends StatefulWidget {
  final String? playerId;
  const AddEditPlayerScreen({super.key, this.playerId});

  @override
  State<AddEditPlayerScreen> createState() => _AddEditPlayerScreenState();
}

class _AddEditPlayerScreenState extends State<AddEditPlayerScreen> {
  final _formKey = GlobalKey<FormState>();

  // Personal
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  // Parent / Guardian
  final _parentNameCtrl = TextEditingController();
  final _parentPhoneCtrl = TextEditingController();
  final _parentEmailCtrl = TextEditingController();

  // Health
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _bloodGroupCtrl = TextEditingController();
  final _allergiesCtrl = TextEditingController();
  final _medicationsCtrl = TextEditingController();

  String? _branchId;
  bool _obscure = true;
  bool get _isEditing => widget.playerId != null;

  List<_EnrollmentDraft> _enrollments = [];
  bool _loadingProfiles = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isEditing) {
        _loadExisting();
      } else {
        _enrollments = [_defaultEnrollment()];
      }
    });
  }

  _EnrollmentDraft _defaultEnrollment() {
    final sport = AppConstants.sports.first;
    return _EnrollmentDraft(
      sport: sport,
      category: AppConstants.categories[2],
      position: AppConstants.sportPositions[sport]?.first ?? '',
      jerseyNumber: 1,
    );
  }

  Future<void> _loadExisting() async {
    setState(() => _loadingProfiles = true);
    final p = context
        .read<PlayerProvider>()
        .players
        .where((p) => p.uid == widget.playerId)
        .firstOrNull;
    if (p != null) {
      _nameCtrl.text = p.name;
      _emailCtrl.text = p.email;
      _ageCtrl.text = p.age.toString();
      _phoneCtrl.text = p.phone;
      _branchId = p.branchId;
      _bioCtrl.text = p.bio ?? '';
      _parentNameCtrl.text = p.parentName ?? '';
      _parentPhoneCtrl.text = p.parentPhone ?? '';
      _parentEmailCtrl.text = p.parentEmail ?? '';
      _heightCtrl.text = p.health.height ?? '';
      _weightCtrl.text = p.health.weight ?? '';
      _bloodGroupCtrl.text = p.health.bloodGroup ?? '';
      _allergiesCtrl.text = p.health.allergies ?? '';
      _medicationsCtrl.text = p.health.medications ?? '';

      final profiles =
          await FirestoreService().streamSportProfiles(p.uid).first;
      setState(() {
        _enrollments = profiles.map(_EnrollmentDraft.fromProfile).toList();
        if (_enrollments.isEmpty) _enrollments = [_defaultEnrollment()];
        _loadingProfiles = false;
      });
    } else {
      setState(() => _loadingProfiles = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _ageCtrl.dispose();
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    _parentNameCtrl.dispose();
    _parentPhoneCtrl.dispose();
    _parentEmailCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _bloodGroupCtrl.dispose();
    _allergiesCtrl.dispose();
    _medicationsCtrl.dispose();
    super.dispose();
  }

  PlayerHealth get _health => PlayerHealth(
        height: _heightCtrl.text.trim().isEmpty
            ? null
            : _heightCtrl.text.trim(),
        weight: _weightCtrl.text.trim().isEmpty
            ? null
            : _weightCtrl.text.trim(),
        bloodGroup: _bloodGroupCtrl.text.trim().isEmpty
            ? null
            : _bloodGroupCtrl.text.trim(),
        allergies: _allergiesCtrl.text.trim().isEmpty
            ? null
            : _allergiesCtrl.text.trim(),
        medications: _medicationsCtrl.text.trim().isEmpty
            ? null
            : _medicationsCtrl.text.trim(),
      );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_branchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a branch')));
      return;
    }
    if (_enrollments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Add at least one sport enrollment')));
      return;
    }

    final age = int.tryParse(_ageCtrl.text) ?? 0;
    for (final e in _enrollments) {
      if (!AppConstants.isCategoryValidForAge(e.category, age)) {
        final max = AppConstants.categoryMaxAge[e.category];
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Age $age is too old for ${e.category} (max age $max) in ${e.sport}'),
          backgroundColor: AppTheme.errorRed,
        ));
        return;
      }
    }

    final provider = context.read<PlayerProvider>();
    final adminUid = context.read<AuthProvider>().userModel!.uid;
    final orgId = context.read<AuthProvider>().userModel!.organizationId;

    bool success;
    if (_isEditing) {
      success = await provider.updatePlayer(
        uid: widget.playerId!,
        name: _nameCtrl.text.trim(),
        age: int.tryParse(_ageCtrl.text) ?? 0,
        phone: _phoneCtrl.text.trim(),
        branchId: _branchId!,
        parentName: _parentNameCtrl.text.trim().isEmpty
            ? null
            : _parentNameCtrl.text.trim(),
        parentPhone: _parentPhoneCtrl.text.trim().isEmpty
            ? null
            : _parentPhoneCtrl.text.trim(),
        parentEmail: _parentEmailCtrl.text.trim().isEmpty
            ? null
            : _parentEmailCtrl.text.trim(),
        bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
        health: _health,
      );
      if (success) {
        // Sync sport profiles
        final existing =
            await FirestoreService().streamSportProfiles(widget.playerId!).first;
        final existingBySport = {for (final e in existing) e.sport: e};
        final newBySport = {for (final d in _enrollments) d.sport: d};

        for (final draft in _enrollments) {
          final old = existingBySport[draft.sport];
          if (old == null) {
            await provider.addSportProfile(
              widget.playerId!,
              SportProfileModel(
                sport: draft.sport,
                branchId: _branchId!,
                category: draft.category,
                position: draft.position,
                jerseyNumber: draft.jerseyNumber,
                batchId: draft.batchId ?? '',
                stats: SportProfileModel.defaultStats(draft.sport),
                enrolledAt: DateTime.now(),
              ),
            );
          } else if (old.position != draft.position ||
              old.category != draft.category ||
              old.jerseyNumber != draft.jerseyNumber ||
              (draft.batchId ?? '') != old.batchId) {
            await provider.updateSportProfile(
              widget.playerId!,
              old.copyWith(
                category: draft.category,
                position: draft.position,
                jerseyNumber: draft.jerseyNumber,
                batchId: draft.batchId ?? '',
              ),
            );
          }
        }

        for (final sport in existingBySport.keys) {
          if (!newBySport.containsKey(sport)) {
            await provider.deleteSportProfile(widget.playerId!, sport);
          }
        }
      }
    } else {
      final sportProfiles = _enrollments
          .map((d) => SportProfileModel(
                sport: d.sport,
                branchId: _branchId!,
                category: d.category,
                position: d.position,
                jerseyNumber: d.jerseyNumber,
                batchId: d.batchId ?? '',
                stats: SportProfileModel.defaultStats(d.sport),
                enrolledAt: DateTime.now(),
              ))
          .toList();

      success = await provider.createPlayer(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
        age: int.tryParse(_ageCtrl.text) ?? 0,
        phone: _phoneCtrl.text.trim(),
        organizationId: orgId,
        branchId: _branchId!,
        adminUid: adminUid,
        sportProfiles: sportProfiles,
        parentName: _parentNameCtrl.text.trim().isEmpty
            ? null
            : _parentNameCtrl.text.trim(),
        parentPhone: _parentPhoneCtrl.text.trim().isEmpty
            ? null
            : _parentPhoneCtrl.text.trim(),
        parentEmail: _parentEmailCtrl.text.trim().isEmpty
            ? null
            : _parentEmailCtrl.text.trim(),
        bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
        health: _health,
      );
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isEditing
            ? 'Player updated successfully'
            : 'Player account created'),
        backgroundColor: AppTheme.successGreen,
      ));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final branches = context.watch<BranchProvider>().branches;
    final provider = context.watch<PlayerProvider>();

    if (_loadingProfiles) {
      return Scaffold(
        appBar: AppBar(title: Text(_isEditing ? 'Edit Player' : 'Add Player')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Player' : 'Add Player'),
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
              // ── Section 1: Personal Info ──────────────────────────────
              const _SectionHeader('Personal Info'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    prefixIcon: Icon(Icons.person)),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                          labelText: 'Phone *',
                          prefixIcon: Icon(Icons.phone)),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Enter phone' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _ageCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Age *',
                          prefixIcon: Icon(Icons.cake_outlined)),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter age';
                        final n = int.tryParse(v);
                        if (n == null) return 'Invalid number';
                        if (n < 1 || n > 100) return 'Enter a valid age';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey(_branchId),
                initialValue: _branchId,
                decoration: const InputDecoration(
                    labelText: 'Branch *',
                    prefixIcon: Icon(Icons.location_on_outlined)),
                hint: const Text('Select branch'),
                items: branches
                    .map((b) =>
                        DropdownMenuItem(value: b.id, child: Text(b.name)))
                    .toList(),
                onChanged: (v) => setState(() => _branchId = v),
                validator: (v) => v == null ? 'Select branch' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bioCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Bio (optional)',
                  prefixIcon: Icon(Icons.notes_outlined),
                  alignLabelWithHint: true,
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 24),

              // ── Section 2: Credentials (add only) ────────────────────
              if (!_isEditing) ...[
                const _SectionHeader('Login Credentials'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                      labelText: 'Email *',
                      prefixIcon: Icon(Icons.email_outlined)),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter email';
                    if (!v.contains('@')) return 'Invalid email';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Temporary Password *',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter password';
                    if (v.length < 6) return 'Min 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                const Text(
                  'Share these credentials with the player to login.',
                  style: TextStyle(color: AppTheme.textGrey, fontSize: 12),
                ),
                const SizedBox(height: 24),
              ],

              // ── Section 3: Parent / Guardian ──────────────────────────
              const _SectionHeader('Parent / Guardian'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _parentNameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Parent Name',
                    prefixIcon: Icon(Icons.person_outline)),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _parentPhoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                          labelText: 'Parent Phone',
                          prefixIcon: Icon(Icons.phone_outlined)),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        if (v.trim().length < 7) return 'Too short';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _parentEmailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                          labelText: 'Parent Email',
                          prefixIcon: Icon(Icons.email_outlined)),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        if (!v.contains('@') || !v.contains('.')) {
                          return 'Invalid email';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Section 4: Health ─────────────────────────────────────
              const _SectionHeader('Health Info'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _heightCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Height (cm)',
                          prefixIcon: Icon(Icons.height)),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final n = double.tryParse(v.trim());
                        if (n == null || n <= 0) return 'Invalid height';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _weightCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Weight (kg)',
                          prefixIcon: Icon(Icons.monitor_weight_outlined)),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final n = double.tryParse(v.trim());
                        if (n == null || n <= 0) return 'Invalid weight';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bloodGroupCtrl,
                decoration: const InputDecoration(
                    labelText: 'Blood Group',
                    prefixIcon: Icon(Icons.bloodtype_outlined),
                    hintText: 'e.g. A+, O-'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _allergiesCtrl,
                decoration: const InputDecoration(
                    labelText: 'Allergies',
                    prefixIcon: Icon(Icons.warning_amber_outlined)),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _medicationsCtrl,
                decoration: const InputDecoration(
                    labelText: 'Current Medications',
                    prefixIcon: Icon(Icons.medication_outlined)),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 24),

              // ── Section 5: Sport Enrollments ──────────────────────────
              Row(
                children: [
                  const _SectionHeader('Sport Enrollments'),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _canAddMore
                        ? () => setState(() =>
                            _enrollments.add(_nextEnrollment()))
                        : null,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Sport'),
                    style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryGreen,
                        textStyle: const TextStyle(fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ..._enrollments.asMap().entries.map((entry) {
                final i = entry.key;
                final draft = entry.value;
                return _EnrollmentCard(
                  key: ValueKey('enrollment_$i'),
                  draft: draft,
                  index: i,
                  canRemove: _enrollments.length > 1,
                  usedSports: _enrollments
                      .where((e) => e != draft)
                      .map((e) => e.sport)
                      .toSet(),
                  branchId: _branchId,
                  playerAge: int.tryParse(_ageCtrl.text) ?? 0,
                  onChanged: () => setState(() {}),
                  onRemove: () =>
                      setState(() => _enrollments.removeAt(i)),
                );
              }),

              if (provider.error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorRed.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(provider.error!,
                      style: const TextStyle(color: AppTheme.errorRed)),
                ),
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
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(_isEditing ? 'Save Changes' : 'Create Player'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  bool get _canAddMore =>
      _enrollments.length < AppConstants.sports.length;

  _EnrollmentDraft _nextEnrollment() {
    final usedSports = _enrollments.map((e) => e.sport).toSet();
    final sport = AppConstants.sports
            .where((s) => !usedSports.contains(s))
            .firstOrNull ??
        AppConstants.sports.first;
    return _EnrollmentDraft(
      sport: sport,
      category: AppConstants.categories[2],
      position: AppConstants.sportPositions[sport]?.first ?? '',
      jerseyNumber: 1,
    );
  }
}

// ── Individual enrollment card ────────────────────────────────────────────────
class _EnrollmentCard extends StatefulWidget {
  final _EnrollmentDraft draft;
  final int index;
  final bool canRemove;
  final Set<String> usedSports;
  final String? branchId;
  final int playerAge;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  const _EnrollmentCard({
    super.key,
    required this.draft,
    required this.index,
    required this.canRemove,
    required this.usedSports,
    this.branchId,
    required this.playerAge,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  State<_EnrollmentCard> createState() => _EnrollmentCardState();
}

class _EnrollmentCardState extends State<_EnrollmentCard> {
  late TextEditingController _jerseyCtrl;

  @override
  void initState() {
    super.initState();
    _jerseyCtrl =
        TextEditingController(text: widget.draft.jerseyNumber.toString());
  }

  @override
  void dispose() {
    _jerseyCtrl.dispose();
    super.dispose();
  }

  Set<String> get _availableSports {
    return AppConstants.sports
        .where((s) => !widget.usedSports.contains(s))
        .toSet()
      ..add(widget.draft.sport);
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    final positions =
        AppConstants.sportPositions[draft.sport] ?? <String>[];
    final positionValid = positions.contains(draft.position);
    if (!positionValid && positions.isNotEmpty) {
      draft.position = positions.first;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryGreen,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${widget.index + 1}',
                    style: const TextStyle(
                        color: AppTheme.onPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: ValueKey('sport_${draft.sport}_${widget.index}'),
                  initialValue: draft.sport,
                  decoration: const InputDecoration(
                    labelText: 'Sport',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  items: _availableSports
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child:
                                Text(s[0].toUpperCase() + s.substring(1)),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    draft.sport = v;
                    draft.position =
                        AppConstants.sportPositions[v]?.first ?? '';
                    widget.onChanged();
                  },
                ),
              ),
              if (widget.canRemove)
                IconButton(
                  icon: const Icon(Icons.close,
                      size: 18, color: AppTheme.textGrey),
                  onPressed: widget.onRemove,
                  tooltip: 'Remove',
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Builder(builder: (context) {
                  final age = widget.playerAge;
                  final validCategories = AppConstants.categories
                      .where((c) =>
                          AppConstants.isCategoryValidForAge(c, age))
                      .toList();
                  // Auto-correct if current selection is no longer valid
                  if (age > 0 &&
                      !AppConstants.isCategoryValidForAge(
                          draft.category, age)) {
                    draft.category =
                        validCategories.isNotEmpty
                            ? validCategories.first
                            : AppConstants.categories.last;
                  }
                  return DropdownButtonFormField<String>(
                    key: ValueKey(
                        'cat_${draft.category}_${widget.index}_$age'),
                    initialValue: draft.category,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    items: (age > 0 ? validCategories : AppConstants.categories)
                        .map((c) =>
                            DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      draft.category = v;
                      widget.onChanged();
                    },
                  );
                }),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: ValueKey(
                      'pos_${draft.position}_${widget.index}_${draft.sport}'),
                  initialValue:
                      positionValid ? draft.position : positions.firstOrNull,
                  decoration: const InputDecoration(
                    labelText: 'Position',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  items: positions
                      .map((p) =>
                          DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    draft.position = v;
                    widget.onChanged();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: 120,
            child: TextFormField(
              controller: _jerseyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Jersey #',
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              onChanged: (v) {
                draft.jerseyNumber = int.tryParse(v) ?? 0;
                widget.onChanged();
              },
              validator: (v) =>
                  (v == null || int.tryParse(v) == null) ? 'Invalid' : null,
            ),
          ),
          const SizedBox(height: 10),
          if (widget.branchId != null)
            StreamBuilder<List<BatchModel>>(
              stream: FirestoreService()
                  .streamBatchesByBranch(widget.branchId!)
                  .map((list) =>
                      list.where((b) => b.sport == draft.sport).toList()),
              builder: (context, snapshot) {
                final batches = snapshot.data ?? [];
                if (batches.isEmpty) return const SizedBox.shrink();
                // Clear batchId if it no longer belongs to this sport
                if (draft.batchId != null &&
                    !batches.any((b) => b.id == draft.batchId)) {
                  draft.batchId = null;
                }
                return DropdownButtonFormField<String?>(
                  key: ValueKey('batch_${draft.sport}_${widget.branchId}'),
                  initialValue: draft.batchId,
                  decoration: const InputDecoration(
                    labelText: 'Batch (optional)',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  hint: const Text('No batch'),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('No batch')),
                    ...batches.map((b) => DropdownMenuItem(
                        value: b.id,
                        child: Text('${b.name} · ${b.category}'))),
                  ],
                  onChanged: (v) {
                    draft.batchId = v;
                    widget.onChanged();
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: AppTheme.textDark));
}
