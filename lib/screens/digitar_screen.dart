import 'package:flutter/material.dart';

import '../models/medicamento.dart';
import '../services/banco.dart';
import '../services/estado.dart';
import '../services/notificacoes.dart';
import '../theme/tema.dart';
import '../utils/datas.dart';
import '../utils/validacao.dart';
import '../widgets/componentes.dart';

/// Tela "04 - Digitar" do Figma (Novo remédio / Editar).
///
/// [editar]: remédio existente. [rascunho]: dados vindos da IA (voz/foto)
/// para a pessoa conferir. [apenasDevolver]: não salva, só devolve o
/// remédio corrigido (usado na tela de resultado da receita).
class DigitarScreen extends StatefulWidget {
  final Medicamento? editar;
  final Medicamento? rascunho;
  final bool vindoDaIA;
  final bool apenasDevolver;

  const DigitarScreen({
    super.key,
    this.editar,
    this.rascunho,
    this.vindoDaIA = false,
    this.apenasDevolver = false,
  });

  @override
  State<DigitarScreen> createState() => _DigitarScreenState();
}

class _DigitarScreenState extends State<DigitarScreen> {
  static const _periodos = <(String, String)>[
    ('Manhã', '08:00'),
    ('Almoço', '13:00'),
    ('Jantar', '19:00'),
  ];

  final _nome = TextEditingController();
  final _dose = TextEditingController();
  final _obs = TextEditingController();
  final _caixa = TextEditingController();
  int _quantidade = 1;
  final Set<String> _horarios = {};
  bool _todoDia = true;
  final Set<int> _dias = {};
  Map<String, String> _erros = {};
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    final base = widget.editar ?? widget.rascunho;
    if (base != null) {
      _nome.text = base.nome;
      _dose.text = base.dose;
      _obs.text = base.observacao;
      _quantidade = base.quantidade;
      _horarios.addAll(base.horarios);
      _todoDia = base.todoDia;
      _dias.addAll(base.dias);
      if (base.caixa > 0) _caixa.text = '${base.estoque}';
    } else {
      _horarios.add('08:00');
    }
  }

  @override
  void dispose() {
    _nome.dispose();
    _dose.dispose();
    _obs.dispose();
    _caixa.dispose();
    super.dispose();
  }

  bool get _editando => widget.editar != null;

  List<String> get _extras => ordenarHorarios(
      _horarios.where((h) => !_periodos.any((p) => p.$2 == h)));

  Future<void> _outroHorario() async {
    final escolhido = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 12, minute: 0),
      helpText: 'Escolha o horário',
      cancelText: 'Cancelar',
      confirmText: 'Pronto',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (escolhido == null) return;
    setState(() {
      _horarios.add(hhmm(escolhido.hour, escolhido.minute));
      _erros.remove('horarios');
    });
  }

  Future<void> _salvar() async {
    final resultado = validarMedicamento(
      nome: _nome.text,
      dose: _dose.text,
      quantidade: _quantidade,
      horarios: _horarios.toList(),
      todoDia: _todoDia,
      dias: _dias.toList(),
      estoque: _caixa.text,
    );
    setState(() => _erros = resultado.erros);
    if (!resultado.ok) {
      mostrarAviso('Falta pouco: confira o que está em vermelho.');
      return;
    }

    final base = widget.editar;
    final textoCaixa = _caixa.text.trim();
    final estoque = textoCaixa.isEmpty ? 0 : int.parse(textoCaixa);
    final caixa = textoCaixa.isEmpty
        ? 0
        : (base == null || estoque > base.caixa ? estoque : base.caixa);

    final m = Medicamento(
      id: base?.id,
      nome: _nome.text.trim(),
      dose: normalizarDose(_dose.text),
      quantidade: _quantidade,
      observacao: _obs.text.trim(),
      horarios: ordenarHorarios(_horarios),
      todoDia: _todoDia,
      dias: _todoDia ? const [] : (_dias.toList()..sort()),
      estoque: estoque,
      caixa: caixa,
      ativo: base?.ativo ?? true,
      cor: base?.cor ?? widget.rascunho?.cor ?? DateTime.now().second % paresPilula.length,
      criadoEm: base?.criadoEm ?? dataChave(DateTime.now()),
    );

    if (widget.apenasDevolver) {
      Navigator.of(context).pop(m);
      return;
    }

    setState(() => _salvando = true);
    final id = await Banco.instance.salvarMedicamento(m);
    await Notificacoes.instance.agendarMedicamento(m.copyWith(id: id));
    avisarMudanca();
    if (!mounted) return;
    Navigator.of(context).pop(true);
    if (!_editando) abaAtual.value = 1;
    mostrarAviso(
        '${m.nome} salvo. Vou avisar às ${m.horarios.join(', ')}.');
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
                      Expanded(
                        child: Text(
                          _editando ? 'Editar remédio' : 'Novo remédio',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  if (widget.vindoDaIA || widget.rascunho != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Cores.cremeAmarelo,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.auto_awesome, color: Cores.marrom),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Preenchi com o que entendi. Confira antes de salvar.',
                              style: TextStyle(fontSize: 16, color: Cores.marrom),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),

                  const TituloSecao('Nome'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nome,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      hintText: 'Ex.: Metformina',
                      errorText: _erros['nome'],
                    ),
                    onChanged: (_) => setState(() => _erros.remove('nome')),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const TituloSecao('Dose'),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _dose,
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w700),
                              decoration: InputDecoration(
                                hintText: '850 mg',
                                errorText: _erros['dose'],
                                errorMaxLines: 3,
                              ),
                              onChanged: (_) => setState(() => _erros.remove('dose')),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const TituloSecao('Comprimidos'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _BotaoQuadrado(
                                icone: Icons.remove,
                                rotulo: 'Menos um comprimido',
                                onTap: _quantidade > 1
                                    ? () => setState(() => _quantidade--)
                                    : null,
                              ),
                              SizedBox(
                                width: 40,
                                child: Text('$_quantidade',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontSize: 24, fontWeight: FontWeight.w800)),
                              ),
                              _BotaoQuadrado(
                                icone: Icons.add,
                                rotulo: 'Mais um comprimido',
                                onTap: _quantidade < 10
                                    ? () => setState(() => _quantidade++)
                                    : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const TituloSecao('Quando você toma?'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (var i = 0; i < _periodos.length; i++) ...[
                        if (i > 0) const SizedBox(width: 10),
                        Expanded(
                          child: _Escolha(
                            titulo: _periodos[i].$1,
                            subtitulo: _periodos[i].$2,
                            selecionado: _horarios.contains(_periodos[i].$2),
                            onTap: () => setState(() {
                              final h = _periodos[i].$2;
                              _horarios.contains(h) ? _horarios.remove(h) : _horarios.add(h);
                              _erros.remove('horarios');
                            }),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (_extras.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final h in _extras)
                          InputChip(
                            label: Text(h,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                            backgroundColor: Cores.vinho,
                            deleteIconColor: Colors.white,
                            deleteButtonTooltipMessage: 'Tirar $h',
                            onDeleted: () => setState(() => _horarios.remove(h)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                      ],
                    ),
                  ],
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _outroHorario,
                      icon: const Icon(Icons.add, color: Cores.vinho),
                      label: const Text('Outro horário',
                          style: TextStyle(
                              fontSize: 17,
                              color: Cores.vinho,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline)),
                    ),
                  ),
                  if (_erros['horarios'] != null)
                    _TextoErro(_erros['horarios']!),
                  const SizedBox(height: 14),

                  const TituloSecao('Dias'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _Escolha(
                          titulo: 'Todo dia',
                          subtitulo: 'sem pausa',
                          selecionado: _todoDia,
                          onTap: () => setState(() {
                            _todoDia = true;
                            _erros.remove('dias');
                          }),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Escolha(
                          titulo: 'Alguns dias',
                          subtitulo: 'escolher',
                          selecionado: !_todoDia,
                          onTap: () => setState(() => _todoDia = false),
                        ),
                      ),
                    ],
                  ),
                  if (!_todoDia) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (var d = 1; d <= 7; d++)
                          _BotaoDia(
                            letra: iniciaisDias[d - 1],
                            nome: diasCurtos[d - 1],
                            selecionado: _dias.contains(d),
                            onTap: () => setState(() {
                              _dias.contains(d) ? _dias.remove(d) : _dias.add(d);
                              _erros.remove('dias');
                            }),
                          ),
                      ],
                    ),
                  ],
                  if (_erros['dias'] != null) _TextoErro(_erros['dias']!),
                  const SizedBox(height: 24),

                  const TituloSecao('Observação (opcional)'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _obs,
                    style: const TextStyle(fontSize: 18),
                    decoration: const InputDecoration(hintText: 'Ex.: depois do almoço'),
                  ),
                  const SizedBox(height: 20),

                  const TituloSecao('Comprimidos na caixa (opcional)'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _caixa,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 18),
                    decoration: InputDecoration(
                      hintText: 'Ex.: 30 — para avisar quando estiver acabando',
                      errorText: _erros['estoque'],
                    ),
                    onChanged: (_) => setState(() => _erros.remove('estoque')),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: BotaoGrande(
                texto: widget.apenasDevolver
                    ? 'Usar estes dados'
                    : (_editando ? 'Salvar alterações' : 'Salvar remédio'),
                icone: Icons.check,
                onPressed: _salvando ? null : _salvar,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Escolha extends StatelessWidget {
  final String titulo, subtitulo;
  final bool selecionado;
  final VoidCallback onTap;

  const _Escolha({
    required this.titulo,
    required this.subtitulo,
    required this.selecionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final corTexto = selecionado ? Colors.white : Cores.texto;
    return Semantics(
      selected: selecionado,
      button: true,
      child: Material(
        color: selecionado ? Cores.vinho : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: selecionado
              ? BorderSide.none
              : BorderSide(
                  color: altoContraste(context) ? Colors.black : const Color(0xFFEDE5E2),
                  width: 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(titulo,
                    style: TextStyle(
                        fontSize: 19, fontWeight: FontWeight.w800, color: corTexto)),
                Text(subtitulo, style: TextStyle(fontSize: 15, color: corTexto)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BotaoQuadrado extends StatelessWidget {
  final IconData icone;
  final String rotulo;
  final VoidCallback? onTap;
  const _BotaoQuadrado({required this.icone, required this.rotulo, this.onTap});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: rotulo,
        enabled: onTap != null,
        excludeSemantics: true,
        child: Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
                color: onTap == null ? Cores.rosa : Cores.vinho, width: 2),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: SizedBox(
              width: 56,
              height: 60,
              child: Icon(icone,
                  size: 28, color: onTap == null ? Cores.rosa : Cores.vinhoEscuro),
            ),
          ),
        ),
      );
}

class _BotaoDia extends StatelessWidget {
  final String letra, nome;
  final bool selecionado;
  final VoidCallback onTap;
  const _BotaoDia({
    required this.letra,
    required this.nome,
    required this.selecionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selecionado,
        label: nome,
        excludeSemantics: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            width: 44,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selecionado ? Cores.vinho : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: selecionado ? Cores.vinho : Cores.rosa, width: 1.5),
            ),
            child: Text(letra,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: selecionado ? Colors.white : Cores.texto)),
          ),
        ),
      );
}

class _TextoErro extends StatelessWidget {
  final String texto;
  const _TextoErro(this.texto);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Cores.erro, size: 20),
            const SizedBox(width: 6),
            Expanded(
              child: Text(texto,
                  style: const TextStyle(color: Cores.erro, fontSize: 15)),
            ),
          ],
        ),
      );
}
