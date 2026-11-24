import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/field_problem.dart';
import '../models/login_form.dart';
import '../models/profile_form.dart';
import '../models/profile_update.dart';
import '../models/user_profile.dart';
import '../routes/app_routes.dart';
import '../services/client_data.dart';
import '../themes/app_colors.dart';
import '../themes/app_theme.dart';
import '../utils/telefono_formatter.dart';
import '../widgets/action_button.dart';
import '../widgets/app_tab_bar.dart';
import '../widgets/destructive_row.dart';
import '../widgets/form_alert.dart';
import '../widgets/group_footnote.dart';
import '../widgets/inset_group.dart';
import '../widgets/labeled_field_row.dart';
import '../widgets/loaded.dart';
import '../widgets/page_heading.dart';
import '../widgets/section_header.dart';
import '../widgets/session_end.dart';
import '../widgets/status_note.dart';
import '../widgets/tab_page.dart';

/// Perfil: the client updates the phone they sign in with and, optionally, their NIP.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _heading = PageHeading('Perfil');

  @override
  Widget build(BuildContext context) {
    final data = ClientDataScope.of(context);
    return Loaded<UserProfile>(
      load: data.profile,
      // A failure without a session shows no tabs: they would lead to screens that are not hers.
      pending: (status, hasFailed) => TabPage(
        tab: AppTab.profile,
        showsTabBar: !hasFailed || data.isSignedIn,
        children: [_heading, status],
      ),
      builder: (_, profile) => _ProfileView(profile),
    );
  }
}

class _ProfileView extends StatefulWidget {
  const _ProfileView(this.profile);

  final UserProfile profile;

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView> {
  static const _labelWidth = 96.0;

  late final _phoneController = TextEditingController(text: widget.profile.phone);
  final _currentNipController = TextEditingController();
  final _newNipController = TextEditingController();
  late String _savedPhone = widget.profile.phone;
  FieldProblem<ProfileField>? _shownProblem;
  bool _wasSaved = false;
  bool _isSaving = false;

  // The workshop's refusal; it may name no field, which a FieldProblem cannot express.
  String? _refusal;
  ProfileField? _refusedField;

  @override
  void dispose() {
    _phoneController.dispose();
    _currentNipController.dispose();
    _newNipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invalidField = _refusedField ?? _shownProblem?.field;
    return TabPage(
      tab: AppTab.profile,
      children: [
        ProfileScreen._heading,
        _IdentityCard(name: widget.profile.fullName, initials: widget.profile.initials, phone: _savedPhone),
        const SectionHeader('Celular'),
        InsetGroup(children: [_phoneRow(invalidField)]),
        const GroupFootnote('Con este número entras y te avisamos por WhatsApp.'),
        const SectionHeader('NIP'),
        InsetGroup(
          children: [
            _nipRow('Actual', _currentNipController, isInvalid: invalidField == ProfileField.currentNip),
            _nipRow('Nuevo', _newNipController, isInvalid: invalidField == ProfileField.newNip),
          ],
        ),
        const GroupFootnote('No es para pagar. Escribe el actual para cambiar tu NIP o tu celular.'),
        const SizedBox(height: 24),
        _saveArea(),
        const SizedBox(height: 24),
        DestructiveRow(label: 'Cerrar sesión', onTap: _signOut),
      ],
    );
  }

  Widget _phoneRow(ProfileField? invalidField) {
    return LabeledFieldRow(
      label: 'Número',
      hint: '998 123 4567',
      controller: _phoneController,
      labelWidth: _labelWidth,
      isInvalid: invalidField == ProfileField.phone,
      keyboardType: TextInputType.phone,
      inputFormatters: [TelefonoFormatter()],
      onChanged: _onEdited,
    );
  }

  Widget _nipRow(String label, TextEditingController controller, {required bool isInvalid}) {
    return LabeledFieldRow(
      label: label,
      hint: '4 dígitos',
      controller: controller,
      labelWidth: _labelWidth,
      isInvalid: isInvalid,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(LoginForm.nipLength),
      ],
      obscureText: true,
      onChanged: _onEdited,
    );
  }

  // Any edit takes back both the message and "Guardamos tus cambios": they describe the last save.
  void _onEdited(String _) {
    if (_shownProblem == null && !_wasSaved && _refusal == null) return;
    setState(() {
      _shownProblem = null;
      _wasSaved = false;
      _refusal = null;
      _refusedField = null;
    });
  }

  Widget _saveArea() {
    final message = _refusal ?? _shownProblem?.message;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        if (message != null) FormAlert(message),
        if (_wasSaved)
          const StatusNote('Guardamos tus cambios')
        else
          ActionButton.primary(label: 'Guardar cambios', onPressed: _save),
      ],
    );
  }

  /// The form's own rules first; whether the current NIP is right is the workshop's call.
  Future<void> _save() async {
    if (_isSaving) return;
    final form = _form();
    final problem = form.firstProblem(currentNipMatches: true);
    if (problem != null) {
      setState(() => _shownProblem = problem);
      return;
    }

    setState(() => _isSaving = true);
    final outcome = await ClientDataScope.of(context).saveProfile(
      ProfileChange(
        phoneDigits: form.phoneDigits,
        currentNip: form.currentNip,
        newNip: form.newNip,
      ),
    );
    if (!mounted) return;
    if (outcome is ProfileSignedOut) return endSession(context);
    setState(() {
      _isSaving = false;
      switch (outcome) {
        case ProfileSaved(:final profile):
          _keepChanges(profile);
        case ProfileSignedOut():
          break;
        case ProfileRefused(:final message, :final field):
          _refusal = message;
          _refusedField = field;
      }
    });
  }

  ProfileForm _form() {
    return ProfileForm(
      phone: _phoneController.text,
      currentNip: _currentNipController.text,
      newNip: _newNipController.text,
      savedPhone: _savedPhone,
    );
  }

  // The card shows the phone the workshop saved; the NIPs never stay on screen.
  void _keepChanges(UserProfile saved) {
    _savedPhone = saved.phone;
    _currentNipController.clear();
    _newNipController.clear();
    _wasSaved = true;
  }

  Future<void> _signOut() async {
    await ClientDataScope.of(context).signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.initial, (_) => false);
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.name, required this.initials, required this.phone});

  final String name;
  final String initials;
  final String phone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCanvas,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        spacing: 14,
        children: [
          _InitialsAvatar(initials),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppText.sheetTitle.copyWith(fontSize: 20, height: 26 / 20, letterSpacing: 0)),
                Text(phone, style: AppText.callout),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar(this.initials);

  final String initials;

  @override
  Widget build(BuildContext context) {
    // The name beside it already says who this is.
    return ExcludeSemantics(
      child: Container(
        width: 52,
        height: 52,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle),
        child: Text(
          initials,
          style: AppText.button.copyWith(
            fontSize: 19,
            height: 24 / 19,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
