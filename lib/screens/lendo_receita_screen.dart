import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/tema.dart';
import '../widgets/componentes.dart';
import 'resultado_receita_screen.dart';

/// Tela "02 - I.A lendo a receita" do Figma.
///
/// PROTÓTIPO: a câmera e a leitura por IA ainda não estão conectadas; a
/// tela simula as três etapas e mostra um resultado de exemplo.
class LendoReceitaScreen extends StatefulWidget {
  const LendoReceitaScreen({super.key});

  @override
  State<LendoReceitaScreen> createState() => _LendoReceitaScreenState();
}

class _LendoReceitaScreenState extends State<LendoReceitaScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scanner;
  int _etapa = 0; // 0 foto recebida, 1 encontrando, 2 organizando
  final List<Timer> _timers = [];

  @override
  void initState() {
    super.initState();
    _scanner = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _timers.add(Timer(const Duration(milliseconds: 1500), () => _irPara(1)));
    _timers.add(Timer(const Duration(milliseconds: 3000), () => _irPara(2)));
    _timers.add(Timer(const Duration(milliseconds: 4300), _concluir));
  }

  void _irPara(int etapa) {
    if (mounted) setState(() => _etapa = etapa);
  }

  void _concluir() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ResultadoReceitaScreen()),
    );
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _scanner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.sizeOf(context).width;
    final lado = largura * 0.64;
    return Scaffold(
      body: SafeArea(
        child: ColunaRolavel(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          alinhamento: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                const BotaoVoltar(),
                const SizedBox(width: 14),
                const Text('Lendo receita',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 18),
            // Quadro vinho com a receita e a linha dourada "escaneando".
            Container(
              width: lado,
              height: lado,
              decoration: BoxDecoration(
                color: Cores.vinho,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ..._cantos(lado),
                  Transform.rotate(
                    angle: -0.04,
                    child: Container(
                      width: lado * 0.55,
                      height: lado * 0.7,
                      padding: EdgeInsets.all(lado * 0.07),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          for (final f in [0.8, 0.95, 0.6, 0.9, 0.7, 0.5])
                            FractionallySizedBox(
                              widthFactor: f,
                              child: Container(
                                height: 5,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD9D4D5),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _scanner,
                    builder: (context, _) => Positioned(
                      top: lado * (0.18 + 0.62 * _scanner.value),
                      left: lado * 0.1,
                      right: lado * 0.1,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: Cores.dourado,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                                color: Cores.dourado.withValues(alpha: 0.6),
                                blurRadius: 10),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            const Text('Lendo sua receita',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('Leva até 10 segundos\nNada é salvo antes de você conferir.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, color: corSuave(context), height: 1.4)),
            const SizedBox(height: 10),
            const SeloSimulacao(),
            const Spacer(),
            const SizedBox(height: 20),
            Cartao(
              child: Column(
                children: [
                  _Etapa(texto: 'Foto recebida', estado: _etapa > 0 ? 2 : 1),
                  const SizedBox(height: 14),
                  _Etapa(
                      texto: 'Encontrando os remédios',
                      estado: _etapa > 1 ? 2 : (_etapa == 1 ? 1 : 0)),
                  const SizedBox(height: 14),
                  _Etapa(texto: 'Organizando os horários', estado: _etapa == 2 ? 1 : 0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Cantos dourados do "visor" da câmera.
  List<Widget> _cantos(double lado) {
    const t = 3.0;
    final c = lado * 0.12;
    final m = lado * 0.08;
    Widget canto({required bool cima, required bool esq}) => Positioned(
          top: cima ? m : null,
          bottom: cima ? null : m,
          left: esq ? m : null,
          right: esq ? null : m,
          child: Container(
            width: c,
            height: c,
            decoration: BoxDecoration(
              border: Border(
                top: cima ? const BorderSide(color: Cores.dourado, width: t) : BorderSide.none,
                bottom: cima ? BorderSide.none : const BorderSide(color: Cores.dourado, width: t),
                left: esq ? const BorderSide(color: Cores.dourado, width: t) : BorderSide.none,
                right: esq ? BorderSide.none : const BorderSide(color: Cores.dourado, width: t),
              ),
            ),
          ),
        );
    return [
      canto(cima: true, esq: true),
      canto(cima: true, esq: false),
      canto(cima: false, esq: true),
      canto(cima: false, esq: false),
    ];
  }
}

class _Etapa extends StatelessWidget {
  final String texto;
  final int estado; // 0 esperando, 1 em andamento, 2 pronto
  const _Etapa({required this.texto, required this.estado});

  @override
  Widget build(BuildContext context) {
    final Widget icone = switch (estado) {
      2 => Container(
          width: 34,
          height: 34,
          decoration:
              BoxDecoration(color: Cores.vinho, borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.check, color: Colors.white, size: 22),
        ),
      1 => Container(
          width: 34,
          height: 34,
          decoration:
              BoxDecoration(color: Cores.dourado, borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.auto_awesome, color: Cores.vinhoEscuro, size: 20),
        ),
      _ => Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Cores.textoSuave.withValues(alpha: 0.5)),
          ),
        ),
    };
    return Row(
      children: [
        icone,
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            texto,
            style: TextStyle(
              fontSize: 17,
              fontWeight: estado == 1 ? FontWeight.w800 : FontWeight.w500,
              color: estado == 0 ? corSuave(context) : null,
            ),
          ),
        ),
      ],
    );
  }
}
