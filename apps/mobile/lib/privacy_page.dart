import 'package:flutter/material.dart';

import 'brand_theme.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Privacidade e dados')),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: const [
            Text(
              'Política de Privacidade da KARTA',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 8),
            Text(
              'Última atualização: 5 de outubro de 2026',
              style: TextStyle(color: HmatiasBrand.muted),
            ),
            SizedBox(height: 20),
            Text(
              'A KARTA é um produto da HMATIAS – Prestação de Serviços SU, LDA. A carteira foi concebida para funcionar primeiro no dispositivo e não substitui um documento oficial emitido por uma entidade pública.',
              style: TextStyle(height: 1.5),
            ),
            SizedBox(height: 24),
            _PrivacySection(
              title: '1. Dados guardados localmente',
              body:
                  'O perfil de identidade, credenciais locais, documentos, imagens, PDFs, preferências de biometria, metadados de segurança e informação necessária para o PIN são guardados no armazenamento privado da aplicação. Os ficheiros do cofre são cifrados antes de serem guardados.',
            ),
            _PrivacySection(
              title: '2. PIN e biometria',
              body:
                  'A KARTA não guarda o PIN em texto simples. A verificação do PIN usa um derivado criptográfico e inclui limitação de tentativas. A biometria é validada pelo sistema operativo; a KARTA não recebe nem armazena impressões digitais, imagens faciais ou outros modelos biométricos.',
            ),
            _PrivacySection(
              title: '3. Câmara, ficheiros, QR e partilha',
              body:
                  'A câmara, galeria e seletor de ficheiros são usados apenas quando escolhe capturar, importar, ler um QR ou selecionar um documento. A partilha/exportação só ocorre quando inicia essa ação e usa o mecanismo de partilha do Android. Depois da partilha, o tratamento da cópia enviada fica sujeito à aplicação ou destinatário escolhido.',
            ),
            _PrivacySection(
              title: '4. Backups locais',
              body:
                  'Os backups criados pela KARTA são cifrados no dispositivo com a palavra-passe de backup definida pelo utilizador. A palavra-passe do backup não é incluída no ficheiro.',
            ),
            _PrivacySection(
              title: '5. Conta e backup online opcional',
              body:
                  'Quando o serviço online estiver configurado e o utilizador optar por o usar, a KARTA pode tratar o endereço de e-mail, um hash seguro da palavra-passe da conta, sessões de autenticação e o backup cifrado enviado pelo utilizador. O servidor valida a estrutura e integridade do backup, mas não possui a palavra-passe necessária para o decifrar.',
            ),
            _PrivacySection(
              title: '6. Publicidade e analítica',
              body:
                  'A versão atual da aplicação não integra publicidade, identificadores publicitários nem SDK de analítica comportamental dentro da app.',
            ),
            _PrivacySection(
              title: '7. Conservação e eliminação',
              body:
                  'Os dados locais permanecem no dispositivo até serem removidos pelo utilizador, pela função de apagar a carteira ou pela desinstalação da app, de acordo com o comportamento do Android. Quando existe uma conta online, a aplicação disponibiliza funções para apagar o backup online e eliminar a conta; a eliminação da conta remove os dados associados mantidos pelo serviço.',
            ),
            _PrivacySection(
              title: '8. Segurança',
              body:
                  'A KARTA usa armazenamento seguro do sistema, cifragem autenticada para o cofre, bloqueio de sessão, controlo de tentativas e HTTPS para o serviço online. Nenhum sistema é absolutamente imune a risco; mantenha o dispositivo atualizado e proteja o PIN e a palavra-passe de backup.',
            ),
            _PrivacySection(
              title: '9. Contacto',
              body:
                  'Responsável: HMATIAS – Prestação de Serviços SU, LDA · Viana, Luanda, Angola. Questões de privacidade: geral@comercialhmatiasps.com',
            ),
            _PrivacySection(
              title: 'Política pública',
              body:
                  'https://comercialhmatiasps.com/karta-privacidade.html',
            ),
            SizedBox(height: 20),
          ],
        ),
      );
}

class _PrivacySection extends StatelessWidget {
  const _PrivacySection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              SelectableText(
                body,
                style: const TextStyle(
                  color: HmatiasBrand.muted,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
