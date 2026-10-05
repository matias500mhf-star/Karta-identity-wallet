import 'package:flutter/material.dart';

import 'brand_theme.dart';

class KartaPrivacyPage extends StatelessWidget {
  const KartaPrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacidade KARTA')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          Text(
            'Privacidade e controlo dos seus dados',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 12),
          Text(
            'A KARTA é local-first. O perfil, as credenciais locais e as cópias de documentos permanecem no armazenamento privado da aplicação, salvo quando escolhe criar e enviar um backup online cifrado.',
            style: TextStyle(height: 1.5),
          ),
          SizedBox(height: 24),
          _PrivacySection(
            icon: Icons.phone_android_outlined,
            title: 'Dados no dispositivo',
            body:
                'Pode guardar nome, nacionalidade, credenciais locais, referências, datas, imagens, PDFs e outros ficheiros escolhidos por si. Os ficheiros do cofre são cifrados no dispositivo.',
          ),
          _PrivacySection(
            icon: Icons.fingerprint,
            title: 'PIN e biometria',
            body:
                'O PIN protege a KARTA. Quando ativa biometria, a verificação é feita pelo Android. A KARTA não recebe nem armazena a sua impressão digital, face ou modelo biométrico.',
          ),
          _PrivacySection(
            icon: Icons.backup_outlined,
            title: 'Backup',
            body:
                'O backup local é cifrado com a palavra-passe escolhida por si. Se optar pelo backup online, o servidor recebe apenas o envelope cifrado, o tamanho, um digest de integridade e a data de atualização. A palavra-passe do backup não é enviada.',
          ),
          _PrivacySection(
            icon: Icons.account_circle_outlined,
            title: 'Conta online opcional',
            body:
                'Quando o serviço online está configurado e cria uma conta, o serviço recebe o email e conserva um hash da palavra-passe da conta. A conta e o backup online podem ser eliminados a partir da própria aplicação.',
          ),
          _PrivacySection(
            icon: Icons.delete_outline,
            title: 'Eliminação de dados',
            body:
                'Apagar a conta online elimina a conta e os dados associados no serviço KARTA. A carteira local é independente e possui uma opção própria para ser apagada deste dispositivo.',
          ),
          _PrivacySection(
            icon: Icons.public_outlined,
            title: 'Política pública e eliminação fora da app',
            body:
                'Política: comercialhmatiasps.com/karta-privacidade.html\n'
                'Eliminar conta: comercialhmatiasps.com/karta-eliminar-conta.html',
          ),
          _PrivacySection(
            icon: Icons.warning_amber_rounded,
            title: 'Credenciais locais',
            body:
                'As credenciais criadas manualmente na KARTA são registos locais e não representam validação por uma entidade emissora nem substituem documentos oficiais.',
          ),
          SizedBox(height: 12),
          Text(
            'Contacto de privacidade: geral@comercialhmatiasps.com',
            style: TextStyle(
              color: HmatiasBrand.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacySection extends StatelessWidget {
  const _PrivacySection({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: HmatiasBrand.blue),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(body, style: const TextStyle(height: 1.45)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
