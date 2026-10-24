import 'package:flutter/material.dart';

import '../models/medicamento.dart';
import '../services/banco.dart';
import '../services/estado.dart';
import '../services/notificacoes.dart';
import '../theme/tema.dart';
import '../utils/datas.dart';
import '../widgets/componentes.dart';
import 'digitar_screen.dart';

class _Sugestao {
  Medicamento med;
  final bool duvida; // a IA não teve certeza ("Revise a dose")
  bool marcado;
  _Sugestao(this.med, {this.duvida = false}) : marcado = !duvida;
}

/// Tela "03 - Resultado foto da receita" do Figma.
/// Nada é salvo antes de a pessoa marcar (H5 Prevenção de erros).
class ResultadoReceitaScreen extends StatefulWidget {
  const ResultadoReceitaScreen({super.key});

  @override
  State<ResultadoReceitaScreen> createState() => _ResultadoReceitaScreenState();
}

class _ResultadoReceitaScreenState extends State<ResultadoReceitaScreen> {
  // Exemplo do que a IA devolveria (enquanto ela não está conectada).
  final List<_Sugestao> _itens = [
    _Sugestao(const Medicamento(
        nome: 'Losartana', dose: '50 mg', horarios: ['08:00', '20:00'], cor: 2)),
    _Sugestao(
        const Medicamento(
            nome: 'Metformina', dose: '850 mg', horarios: ['08:00', '20:00'], cor: 3),
        duvida: true),
    _Sugestao(const Medicamento(
        nome: 'Omeprazol', dose: '20 mg', horarios: ['08:00'], cor: 0)),
  ];
  bool _salvando = false;

  int get _marcados => _itens.where((s) => s.marcado).length;

  /// Toque no remédio com dúvida: abre o formulário para corrigir.
  Future<void> _revisar(_Sugestao s) async {
    final corrigido = await Navigator.of(context).push<Medicamento>(MaterialPageRoute(
      builder: (_) => DigitarScreen(rascunho: s.med, apenasDevolver: true),
    ));
    if (corrigido != null) {
      setState(() {
        s.med = corrigido;
        s.marcado = true;
      });
    }
  }

  Future<void> _salvar() async {
    setState(() => _salvando = true);
    final hoje = dataChave(DateTime.now());
    for (final s in _itens.where((s) => s.marcado)) {
      final m = s.med.copyWith(criadoEm: hoje);
      final id = await Banco.instance.salvarMedicamento(m);
      await Notificacoes.instance.agendarMedicamento(m.copyWith(id: id));
    }
    final n = _marcados;
    avisarMudanca();
    if (!mounted) return;
    Navigator.of(context).pop();
    abaAtual.value = 1;
    mostrarAviso(n == 1 ? '1 remédio salvo.' : '$n remédios salvos.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                children: [
                  Row(
                    children: [
                      const BotaoVoltar(),
                      const SizedBox(width: 14),
                      const Text('Receita lida',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _CabecalhoResultado(quantidade: _itens.length),
                  const SizedBox(height: 10),
                  const Align(alignment: Alignment.centerLeft, child: SeloSimulacao()),
                  const SizedBox(height: 14),
                  for (final s in _itens) ...[
                    _ItemSugestao(
                      sugestao: s,
                      onMarcar: (v) => setState(() => s.marcado = v),
                      onRevisar: () => _revisar(s),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: BotaoGrande(
                texto: _marcados == 1
                    ? 'Salvar remédio (1)'
                    : 'Salvar remédios ($_marcados)',
                icone: Icons.check,
                onPressed: _marcados == 0 || _salvando ? null : _salvar,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CabecalhoResultado extends StatelessWidget {
  final int quantidade;
  const _CabecalhoResultado({required this.quantidade});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Cores.vinhoEscuro,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Transform.rotate(
            angle: -0.08,
            child: Container(
              width: 84,
              height: 110,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final c in [null, Colors.green, null, Colors.orange, Colors.indigo])
                    Container(
                      height: c == null ? 4 : 10,
                      decoration: BoxDecoration(
                        color: c == null ? const Color(0xFFD9D4D5) : null,
                        border: c == null ? null : Border.all(color: c, width: 1.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Cores.dourado, size: 20),
                    SizedBox(width: 6),
                    Text('Receita lida',
                        style: TextStyle(
                            color: Cores.dourado,
                            fontSize: 17,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('$quantidade remédios encontrados',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.15)),
                const SizedBox(height: 6),
                const Text('Nada é salvo antes de você marcar',
                    style: TextStyle(color: Cores.rosa, fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemSugestao extends StatelessWidget {
  final _Sugestao sugestao;
  final ValueChanged<bool> onMarcar;
  final VoidCallback onRevisar;

  const _ItemSugestao({
    required this.sugestao,
    required this.onMarcar,
    required this.onRevisar,
  });

  @override
  Widget build(BuildContext context) {
    final m = sugestao.med;
    return Cartao(
      onTap: sugestao.duvida ? onRevisar : () => onMarcar(!sugestao.marcado),
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      child: Row(
        children: [
          IconeRemedio(cor: m.cor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sugestao.duvida ? '${m.nomeCompleto} ?' : m.nomeCompleto,
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                Text('${m.horarios.join(' e ')} · ${m.textoDias.toLowerCase()}',
                    style: TextStyle(fontSize: 16, color: corSuave(context))),
                const SizedBox(height: 4),
                sugestao.duvida
                    ? const Etiqueta(
                        texto: 'Revise a dose — toque aqui',
                        fundo: Cores.cremeAmarelo,
                        cor: Cores.marrom)
                    : const Etiqueta(
                        texto: 'Leitura clara', fundo: Cores.verdeClaro, cor: Cores.verde),
              ],
            ),
          ),
          Transform.scale(
            scale: 1.5,
            child: Checkbox(
              value: sugestao.marcado,
              onChanged: (v) => onMarcar(v ?? false),
              activeColor: Cores.vinho,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              semanticLabel: 'Salvar ${m.nome}',
            ),
          ),
        ],
      ),
    );
  }
}
