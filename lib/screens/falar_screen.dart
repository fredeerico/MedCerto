import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/medicamento.dart';
import '../theme/tema.dart';
import '../widgets/componentes.dart';
import 'digitar_screen.dart';

/// Tela "01 - Receita Falada para I.A" do Figma.
///
/// PROTÓTIPO: a gravação e a IA ainda não estão conectadas (isso depende do
/// backend Django + modelo de IA). A tela simula o que a pessoa vai ver e,
/// em "Terminei de falar", abre o formulário já preenchido para conferir
/// (a IA nunca salva sozinha — H5).
class FalarScreen extends StatefulWidget {
  const FalarScreen({super.key});

  @override
  State<FalarScreen> createState() => _FalarScreenState();
}

class _FalarScreenState extends State<FalarScreen>
    with SingleTickerProviderStateMixin {
  static const _frase =
      '"Metformina, oitocentos e cinquenta, um comprimido depois do almoço."';

  late final AnimationController _onda;
  Timer? _digitacao;
  int _letras = 0;

  @override
  void initState() {
    super.initState();
    _onda = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _digitacao = Timer.periodic(const Duration(milliseconds: 45), (t) {
      if (_letras >= _frase.length) {
        t.cancel();
      } else {
        setState(() => _letras++);
      }
    });
  }

  @override
  void dispose() {
    _onda.dispose();
    _digitacao?.cancel();
    super.dispose();
  }

  void _terminei() {
    // O que a IA devolveria a partir da fala acima.
    const rascunho = Medicamento(
      nome: 'Metformina',
      dose: '850 mg',
      quantidade: 1,
      observacao: 'depois do almoço',
      horarios: ['13:00'],
    );
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => const DigitarScreen(rascunho: rascunho, vindoDaIA: true),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.sizeOf(context).width;
    return Scaffold(
      backgroundColor: Cores.vinhoEscuro,
      body: Stack(
        children: [
          Positioned(
            top: largura * 0.45,
            left: -largura * 0.1,
            child: CirculoDecorativo(
                tamanho: largura * 1.2, cor: Cores.vinho.withValues(alpha: 0.45)),
          ),
          SafeArea(
            child: ColunaRolavel(
                children: [
                  Row(
                    children: [
                      FadeTransition(
                        opacity: _onda,
                        child: const CircleAvatar(radius: 7, backgroundColor: Cores.dourado),
                      ),
                      const SizedBox(width: 10),
                      const Text('OUVINDO',
                          style: TextStyle(
                              color: Cores.dourado,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1)),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Fechar',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white, size: 30),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text('Pode falar a receita, vou anotar!',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          height: 1.15)),
                  const SizedBox(height: 10),
                  const SeloSimulacao(escuro: true),
                  const SizedBox(height: 28),
                  Center(child: _Onda(animacao: _onda)),
                  const SizedBox(height: 28),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('O QUE ENTENDI',
                            style: TextStyle(
                                color: Cores.rosa,
                                fontSize: 16,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Text(_frase.substring(0, _letras),
                            style: const TextStyle(color: Colors.white, fontSize: 19)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  BotaoGrande(
                    texto: 'Terminei de falar',
                    icone: Icons.check,
                    fundo: Cores.dourado,
                    corTexto: Cores.vinhoEscuro,
                    onPressed: _letras >= _frase.length ? _terminei : null,
                  ),
                  const SizedBox(height: 14),
                  BotaoGrande(
                    texto: 'Prefiro digitar',
                    contorno: true,
                    corTexto: Colors.white,
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const DigitarScreen()),
                    ),
                  ),
                ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Onda extends StatelessWidget {
  final Animation<double> animacao;
  const _Onda({required this.animacao});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animacao,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 17; i++)
              Container(
                width: 7,
                height: 14 +
                    80 *
                        (0.25 +
                            0.75 *
                                ((sin(i * 0.9 + animacao.value * pi) + 1) / 2)) *
                        (1 - (i - 8).abs() / 10),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: Cores.dourado.withValues(alpha: (i - 8).abs() > 5 ? 0.5 : 1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ],
        );
      },
    );
  }
}
