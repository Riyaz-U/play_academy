import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/branch_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/sport_profile_model.dart';
import '../../../services/firestore_service.dart';

class _EnrollmentDraft {
  String sport;
  String category;
  String position;
  int jerseyNumber;

  _EnrollmentDraft({
    required this.sport,
    required this.category,
    required this.position,
    required this.jerseyNumber,
  });

  String get defaultPosition =>
      AppConstants.sportPositions[sport]?.first ?? '';

  static _EnrollmentDraft fromProfile(SportProfileModel p) =>
      _EnrollmentDraft(
        sport: p.sport,
        category: p.category,
        position: p.position,
        jerseyNumber: p.jerseyNumber,
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
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

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
    super.dispose();
  }

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
      );
      if (success) {
        // Sync sport profiles
        final existing =
            await FirestoreService().streamSportProfiles(widget.playerId!).first;
        final existingBySport = {for (final e in existing) e.sport: e};
        final newBySport = {for (final d in _enrollments) d.sport: d};

        // Update / create
        for (final draft in _enrollments) {
          final existing = existingBySport[draft.sport];
          if (existing == null) {
            await provider.addSportProfile(
              widget.playerId!,
              SportProfileModel(
                sport: draft.sport,
                branchId: _branchId!,
                category: draft.category,
                position: draft.position,
                jerseyNumber: draft.jerseyNumber,
                stats: SportProfileModel.defaultStats(draft.sport),
                enrolledAt: DateTime.now(),
              ),
            );
          } else if (existing.position != draft.position ||
              existing.category != draft.category ||
              existing.jerseyNumber != draft.jerseyNumber) {
            await provider.updateSportProfile(
              widget.playerId!,
              existing.copyWith(
                category: draft.category,
                position: draft.position,
                jerseyNumber: draft.jerseyNumber,
              ),
            );
          }
        }

        // Delete removed sports
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
              const _Label('Personal Info'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Full Name',
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
                          labelText: 'Phone',
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
                          labelText: 'Age',
                          prefixIcon: Icon(Icons.cake_outlined)),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter age';
                        if (int.tryParse(v) == null) return 'Invalid';
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
                    labelText: 'Branch',
                    prefixIcon: Icon(Icons.location_on_outlined)),
                hint: const Text('Select branch'),
                items: branches
                    .map((b) =>
                        DropdownMenuItem(value: b.id, child: Text(b.name)))
                    .toList(),
                onChanged: (v) => setState(() => _branchId = v),
                validator: (v) => v == null ? 'Select branch' : null,
              ),
              const SizedBox(height: 24),

              // ── Section 2: Credentials (add only) ────────────────────
              if (!_isEditing) ...[
                const _Label('Login Credentials'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                      labelText: 'Email',
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
                    labelText: 'Temporary Password',
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

              // ── Section 3: Sport Enrollments ──────────────────────────
              Row(
                children: [
                  const _Label('Sport Enrollments'),
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
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  const _EnrollmentCard({
    super.key,
    required this.draft,
    required this.index,
    required this.canRemove,
    required this.usedSports,
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
      ..add(widget.draft.sport); // always include current sport
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
                child: DropdownButtonFormField<String>(
                  key: ValueKey(
                      'cat_${draft.category}_${widget.index}'),
                  initialValue: draft.category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  items: AppConstants.categories
                      .map((c) =>
                          DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    draft.category = v;
                    widget.onChanged();
                  },
                ),
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
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: AppTheme.textDark));
}
