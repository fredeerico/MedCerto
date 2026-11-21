import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';

enum ResultadoDigital { ok, cancelado, indisponivel, semCadastro, bloqueado, erro }

/// Entrada pela digital (ou rosto) usando o sistema do celular.
///
/// O app NÃO lê a digital: ele pede ao Android para mostrar a tela padrão
/// "Toque no sensor" e só recebe de volta "deu certo" ou "não deu".
/// Pacote: local_auth (mantido pela equipe do Flutter).
class Biometria {
  Biometria._();
  static final Biometria instance = Biometria._();

  final LocalAuthentication _auth = LocalAuthentication();

  /// O celular tem sensor E pelo menos uma digital cadastrada?
  Future<bool> disponivel() async {
    try {
      if (!await _auth.isDeviceSupported()) return false;
      final tipos = await _auth.getAvailableBiometrics();
      return tipos.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<ResultadoDigital> entrar() async {
    try {
      if (!await _auth.isDeviceSupported()) return ResultadoDigital.indisponivel;
      final tipos = await _auth.getAvailableBiometrics();
      if (tipos.isEmpty) return ResultadoDigital.semCadastro;

      final ok = await _auth.authenticate(
        localizedReason: 'Toque no sensor para entrar no MedCerto',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
        authMessages: const [
          AndroidAuthMessages(
            signInTitle: 'Entrar no MedCerto',
            signInHint: 'Toque no sensor de digital',
            cancelButton: 'Usar o PIN',
          ),
        ],
      );
      return ok ? ResultadoDigital.ok : ResultadoDigital.cancelado;
    } catch (e) {
      final texto = e.toString().toLowerCase();
      if (texto.contains('lockout') || texto.contains('locked')) {
        return ResultadoDigital.bloqueado;
      }
      if (texto.contains('notenrolled') || texto.contains('no_biometrics')) {
        return ResultadoDigital.semCadastro;
      }
      if (texto.contains('usercanceled') ||
          texto.contains('usercancelled') ||
          texto.contains('cancel')) {
        return ResultadoDigital.cancelado;
      }
      return ResultadoDigital.erro;
    }
  }

  /// Mensagem simples para mostrar ao usuário (null = não mostra nada).
  static String? mensagem(ResultadoDigital r) => switch (r) {
        ResultadoDigital.ok || ResultadoDigital.cancelado => null,
        ResultadoDigital.indisponivel =>
          'Este celular não tem leitor de digital. Use o PIN.',
        ResultadoDigital.semCadastro =>
          'Nenhuma digital cadastrada no celular. Cadastre em Configurações > '
              'Biometria e segurança, ou use o PIN.',
        ResultadoDigital.bloqueado =>
          'Muitas tentativas com a digital. Use o PIN.',
        ResultadoDigital.erro =>
          'Não foi possível usar a digital agora. Use o PIN.',
      };
}
