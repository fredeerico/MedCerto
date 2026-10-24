import 'package:flutter/material.dart';

import '../theme/tema.dart';
import '../widgets/componentes.dart';
import 'digitar_screen.dart';
import 'falar_screen.dart';
import 'lendo_receita_screen.dart';

/// Tela "Adicionar" do Figma: três jeitos de cadastrar
/// (H7 Flexibilidade e eficiência).
class AdicionarScreen extends StatelessWidget {
  const AdicionarScreen({super.key});

  void _abrir(BuildContext context, Widget tela) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => tela));

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        children: [
          Text('Novo remédio', style: TextStyle(fontSize: 17, color: corSuave(context))),
          const SizedBox(height: 4),
          const Text('Como você quer adicionar?',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, height: 1.15)),
          const SizedBox(height: 28),

          // FALAR (cartão grande vinho)
          Semantics(
            button: true,
            label: 'Falar: diga o nome, a dose e o horário',
            excludeSemantics: true,
            child: Material(
              color: Cores.vinho,
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _abrir(context, const FalarScreen()),
                child: Stack(
                  children: [
                    Positioned(
                      right: -40,
                      bottom: -50,
                      child: CirculoDecorativo(tamanho: 160, cor: Cores.vinhoClaro),
                    ),
                    const Positioned(
                      right: 20,
                      bottom: 28,
                      child: _OndaPequena(),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _QuadradoIcone(icone: Icons.mic_none, fundo: Cores.dourado),
                          const SizedBox(height: 38),
                          const Text('FALAR',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          const Text('Diga o nome, a dose e o horário',
                              style: TextStyle(color: Colors.white, fontSize: 17)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _CartaoOpcao(
                  icone: Icons.photo_camera_outlined,
                  fundoIcone: Cores.dourado,
                  titulo: 'Foto da receita',
                  subtitulo: 'A IA lê pra você',
                  borda: Cores.dourado,
                  onTap: () => _abrir(context, const LendoReceitaScreen()),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _CartaoOpcao(
                  icone: Icons.edit_outlined,
                  fundoIcone: Cores.rosaClaro,
                  titulo: 'Digitar',
                  subtitulo: 'Você preenche',
                  onTap: () => _abrir(context, const DigitarScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: Cores.verdeClaro, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.check, color: Cores.verde),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Você sempre confere antes de salvar.',
                    style: TextStyle(fontSize: 17)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuadradoIcone extends StatelessWidget {
  final IconData icone;
  final Color fundo;
  const _QuadradoIcone({required this.icone, required this.fundo});

  @override
  Widget build(BuildContext context) => Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(color: fundo, borderRadius: BorderRadius.circular(14)),
        child: Icon(icone, size: 30, color: Cores.vinhoEscuro),
      );
}

class _CartaoOpcao extends StatelessWidget {
  final IconData icone;
  final Color fundoIcone;
  final String titulo, subtitulo;
  final Color? borda;
  final VoidCallback onTap;

  const _CartaoOpcao({
    required this.icone,
    required this.fundoIcone,
    required this.titulo,
    required this.subtitulo,
    this.borda,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Cartao(
        onTap: onTap,
        corBorda: borda,
        child: SizedBox(
          height: 150,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _QuadradoIcone(icone: icone, fundo: fundoIcone),
              const Spacer(),
              Text(titulo,
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
              Text(subtitulo, style: TextStyle(fontSize: 16, color: corSuave(context))),
            ],
          ),
        ),
      );
}

class _OndaPequena extends StatelessWidget {
  const _OndaPequena();

  @override
  Widget build(BuildContext context) {
    const alturas = [14.0, 24, 18, 30, 20, 26, 12];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (final a in alturas)
          Container(
            width: 4,
            height: a.toDouble(),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
                color: Cores.dourado, borderRadius: BorderRadius.circular(2)),
          ),
      ],
    );
  }
}
