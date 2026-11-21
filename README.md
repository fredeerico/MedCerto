# MedCerto 💊

**Seus remédios, na hora certa.**

Aplicativo Android de lembrete de medicamentos feito para **pessoas idosas**: letras grandes, botões grandes, uma ação por tela e confirmação de cada dose.

> Projeto acadêmico da UC **Usabilidade e Desenvolvimento WEB (A3)** · Grupo 02 · 2026/02

🌐 **Versão web:** [medcerto-web.onrender.com](https://medcerto-web.onrender.com) · 📄 **Documentação:** [GitBook do projeto](https://a3-medcerto-grupo-02.gitbook.io/a3-medcerto-grupo-02)

---

## ✅ Funcionalidades

- **Entrada com PIN ou digital**
- **Cadastro digitando**, com sugestão de nomes de um catálogo de 6.012 remédios da ANVISA (via API)
- **Horário sem erro:** botões grandes de + e − ou digitação; dose opcional (mg, g ou ml)
- **Alarme em tela cheia**, mesmo com o celular bloqueado, o app fechado e sem internet
- **"Já tomei"** e **"+10 min"**, com novo aviso "Você já tomou?" após 30 minutos e opção de desfazer
- **Tela Hoje** com o status de cada dose, histórico de 7 dias e aviso de caixa acabando
- **Acessibilidade:** tamanho da letra, alto contraste, som e vibração do alarme

🔜 **Versão futura:** cadastro por voz e por foto da receita com IA, e acompanhamento pela família.

## 🏗️ Arquitetura

**Local primeiro:** remédios, horários e doses ficam no celular (SQLite), e os alarmes são agendados no próprio Android. A nuvem só fornece o catálogo de nomes, pela [API Django REST](https://github.com/Thiago-Vieira1/app-medcerto) publicada no Render. Sem internet, o cadastro e os alarmes continuam funcionando.

**Tecnologias:** Flutter (Dart) · Material 3 · `sqflite` · `flutter_local_notifications` · `local_auth` · `http`

## 🚀 Como rodar (terminal)

**Pré-requisitos:** [Flutter](https://docs.flutter.dev/get-started/install) instalado (`flutter doctor` sem erros) e um celular Android com a **depuração USB** ligada, ou um emulador.

```bash
git clone https://github.com/fredeerico/MedCerto.git
cd MedCerto
flutter pub get
flutter devices      # confere se o celular aparece
flutter run          # instala e abre o app no celular
```

O app já usa a API publicada no Render (`https://medcerto-api.onrender.com`); não é preciso rodar o back-end.

**Gerar e instalar o APK:**

```bash
flutter build apk --release
# arquivo em: build/app/outputs/flutter-apk/app-release.apk
flutter install --release   # instala no celular conectado
```

**Testes:**

```bash
flutter test         # 36 testes (validação, busca e barra inferior)
```

**No celular (Android 14 ou mais novo):** permita as notificações e ative **"Notificações em tela cheia"** em Configurações → Aplicativos → MedCerto. Em aparelhos **Samsung**, coloque a bateria do app em **"Sem restrições"** para o alarme não atrasar.

## 👥 Equipe

| Equipe | Frente | Integrantes |
|---|---|---|
| E1 | Front-end (app e versão web) | Frederico Barbosa e Mariana Martins |
| E2 | Back-end (API Django) | Ruan Vitor e Thiago Vieira |
| E3 | Protótipo, testes e métricas | Daniel Luca e Olicio Souza |
| E4 | Requisitos, arquitetura e documentação | Gabriel Adriano e Sabrina Rayssa |

<sub>Projeto acadêmico, sem fins comerciais. O MedCerto não substitui orientação médica.</sub>
