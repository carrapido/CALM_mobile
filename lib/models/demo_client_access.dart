/// Stand-in for the demo client's NIP, still used by Perfil to confirm a NIP change.
/// Entrada no longer needs it: signing in goes through `ClientAccess` against Supabase.
class DemoClientAccess {
  DemoClientAccess._();

  static const _nip = '2580';

  static bool hasNip(String nip) => nip == _nip;
}
