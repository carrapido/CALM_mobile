import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/demo_client_access.dart';
import '../models/field_problem.dart';
import '../models/login_form.dart';
import '../models/profile_form.dart';
import '../models/user_profile.dart';
import '../routes/app_routes.dart';
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
import '../widgets/page_heading.dart';
import '../widgets/section_header.dart';
import '../widgets/status_note.dart';
import '../widgets/tab_page.dart';

/// Perfil: the client updates the phone they sign in with and, optionally, their NIP.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.profile = UserProfile.mock});

  final UserProfile profile;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _labelWidth = 96.0;

  late final _phoneController = TextEditingController(text: widget.profile.phone);
  final _currentNipController = TextEditingController();
  final _newNipController = TextEditingController();
  late String _savedPhone = widget.profile.phone;
  FieldProblem<ProfileField>? _shownProblem;
  bool _wasSaved = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _currentNipController.dispose();
    _newNipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invalidField = _shownProblem?.field;
    return TabPage(
      tab: AppTab.profile,
      children: [
        const PageHeading('Perfil'),
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
        const GroupFootnote('No es para pagar. Déjalo vacío si no lo cambias.'),
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
    if (_shownProblem == null && !_wasSaved) return;
    setState(() {
      _shownProblem = null;
      _wasSaved = false;
    });
  }

  Widget _saveArea() {
    final problem = _shownProblem;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        if (problem != null) FormAlert(problem.message),
        if (_wasSaved)
          const StatusNote('Guardamos tus cambios')
        else
          ActionButton.primary(label: 'Guardar cambios', onPressed: _save),
      ],
    );
  }

  void _save() {
    final problem = _currentProblem();
    setState(() {
      _shownProblem = problem;
      if (problem == null) _keepChanges();
    });
  }

  FieldProblem<ProfileField>? _currentProblem() {
    final form = ProfileForm(
      phone: _phoneController.text,
      currentNip: _currentNipController.text,
      newNip: _newNipController.text,
    );
    return form.firstProblem(currentNipMatches: DemoClientAccess.hasNip(form.currentNip));
  }

  // Until the API exists, nothing leaves the device: the card shows the new phone and the NIPs are wiped.
  void _keepChanges() {
    _savedPhone = _phoneController.text;
    _currentNipController.clear();
    _newNipController.clear();
    _wasSaved = true;
  }

  void _signOut() {
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
