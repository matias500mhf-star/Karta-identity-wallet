# KARTA Alpha 0.9 — validação para o lançamento

Estado em 16/09/2026: Alpha de testes, sem servidor online ativo e sem publicação na Google Play.

## Evidência técnica

- Código Android: `0cd33d9fae4b5f720887371f343e697d7800d39c`.
- Flutter analyze, testes Flutter e compilação do APK: concluídos com sucesso no [run Android](https://github.com/matias500mhf-star/Karta-identity-wallet/actions/runs/35093384987).
- [APK Alpha 0.9 (artefacto temporário do GitHub)](https://github.com/matias500mhf-star/Karta-identity-wallet/actions/runs/35093384987/artifacts/10445337492). Requer acesso ao GitHub e expira segundo a retenção do workflow.
- Migrações, compilação API e testes com PostgreSQL: [run API aprovado](https://github.com/matias500mhf-star/Karta-identity-wallet/actions/runs/35093385040).
- O APK é debug. O ecrã online informa que o serviço está em preparação, pois não foi configurado um endpoint. Não permite testar backup online nesta compilação.

## Antes de instalar sobre uma carteira existente

Não desinstalar a versão atual para resolver incompatibilidade de assinatura. Os builds debug de execuções distintas podem usar certificados diferentes. A compatibilidade entre o APK instalado e o candidato ainda não foi verificada.

1. Manter o telemóvel original e os documentos intactos.
2. Exportar um backup local encriptado e guardar a palavra-passe separadamente.
3. Confirmar o restauro numa instalação vazia num segundo dispositivo de testes, usando documentos fictícios.
4. Com os dois APKs e Android SDK build-tools disponíveis, executar:

```sh
python scripts/check_android_update.py previous.apk candidate.apk
```

A ferramenta verifica assinaturas válidas, igualdade de certificados, identificador do pacote e aumento do versionCode. Não instala nem transmite ficheiros. Recusa rotações de chave que exijam análise específica. Mesmo com resultado positivo, é necessário validar preservação de dados no telemóvel.

## Roteiro físico — todos os resultados ainda pendentes

Usar PDF fictício e perfil de teste; não enviar passaporte, PIN, palavras-passe ou backups reais para issues ou repositórios.

| Verificação | Ação | Resultado esperado |
| --- | --- | --- |
| PDF | Importar, abrir e descarregar um PDF de teste | Conteúdo legível e ficheiro exportado completo |
| Biometria | Ativar, autenticar, cancelar e tentar novamente | Cancelamento não dá acesso; autenticação válida abre a carteira |
| Sem biometria | Usar dispositivo sem inscrição biométrica | Opção indisponível explicada; acesso por PIN continua utilizável |
| Bloqueio | Colocar em segundo plano e regressar; testar inatividade | Pedir autenticação antes de mostrar documentos |
| Partilha | Selecionar uma app instalada na folha de partilha; cancelar outra tentativa | Apenas o ficheiro escolhido é partilhado; cancelar não envia nada |
| QR | Ler código KARTA, texto, URL externa e código malformado | Classificação correta; não abrir automaticamente links externos |
| Backup local | Exportar e restaurar numa instalação vazia de teste | Perfil e documentos recuperados; PIN original solicitado |
| Backup inválido | Usar palavra-passe errada e ficheiro alterado | Restauro recusado e carteira existente preservada |
| Atualização | Atualizar uma instalação de teste com assinatura compatível | Perfil, PIN e documentos anteriores continuam utilizáveis |
| Sem rede | Abrir e usar a carteira em modo de avião | Funções locais continuam acessíveis |
| Online em staging | Após alojamento: usar duas contas fictícias, perder rede, terminar sessão e apagar conta | Isolamento de contas, erros claros e carteira local preservada |

Registar: versão Android, modelo, versão KARTA, resultado, passos para reproduzir e evidência sem dados pessoais. Um teste automatizado aprovado não substitui estes resultados.

## Bloqueios comerciais e responsáveis

| Etapa | Trabalho seguinte | Dependência |
| --- | --- | --- |
| Assinatura | Definir e proteger a chave de distribuição, validar atualização real | Conta e segredos de assinatura controlados pela HMATIAS |
| Servidor | Configurar HTTPS, base de dados, limites, monitorização e recuperação | Conta de alojamento, região e orçamento definidos |
| Segurança | Rever cofre, recuperação, sessões, API e proteção de dados | Revisão independente e correções confirmadas |
| Privacidade | Concluir informação específica da app, retenção e eliminação | Decisões reais sobre alojamento, backups e registos |
| Loja | Preparar conta, apresentação, testes e submissão | Play Console HMATIAS e versão assinada validada |

Não há uma data de lançamento confirmada. As etapas acima são critérios de conclusão, não promessas de aprovação da loja.

## Divulgação

Apresentar como produto HMATIAS em testes Alpha. A [pré-visualização do site](https://deploy-preview-23--hmatias.netlify.app) tem o K animado e o roteiro de lançamento. A proposta continua no [PR do site](https://github.com/matias500mhf-star/hmatias-website/pull/23), sem alteração da produção. A revisão visual e a falha do build separado Cloudflare continuam pendentes.

Percurso de divulgação: K do cabeçalho → página KARTA → contacto para acompanhar os testes. Usar demonstrações com documentos fictícios. Não anunciar servidor ativo, disponibilidade na Google Play, Face ID em iOS ou validação oficial de identidade como funcionalidades concluídas.
