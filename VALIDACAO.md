> Publication update (2026-10-23): the maintainer authorized the public repository and both GitHub packages. Earlier private-development entries below are historical. The primary README and release notes contain the current English summary.

# Validação privada — 2026-10-23

Repositório privado, release v0.1.0 em rascunho. Nenhuma publicação pública autorizada. Extensão instalada: 0.1.1. Terminal próprio: primeira versão nativa 0.2.0, ainda experimental e sem notarização.

## Matriz verificada

| Ambiente | Entrada | Resultado |
| --- | --- | --- |
| Extensão VS Code | 10 testes unitários | Passaram; controlos, Unicode, terminal de origem, cancelamento, falhas e encerramento |
| Extensão VS Code / terminal normal | Microfone físico curto + voz do responsável | Teste acústico passou; responsável confirmou manualmente o ditado |
| Terminal nativo / PTY | Texto sem Enter; depois Enter explícito de controlo | O programa só recebeu uma submissão depois do Enter de controlo; resize passou |
| Terminal nativo / gravação longa controlada | Reprodução pelos altifalantes + microfone físico | 82,10 s de áudio; 82,11 s indicados pelo gravador; 182 palavras reconhecidas; início e fim preservados; prefixo anterior preservado; sem Enter |
| Terminal nativo / Codex CLI 0.163.0 | Transcrição longa em sessão nova | Rascunho visível, prefixo preservado, sessão ativa, sem Enter |
| Terminal nativo / Claude Code 2.1.309 | Transcrição longa em sessão nova | Bloco `Pasted text` mantido no compositor, prefixo preservado, sem Enter |
| VS Code / Codex CLI 0.163.0 | Ficheiro sintético longo, ASR real, processo CLI e PTY reais | 182 palavras, 1121 caracteres; bloco de conteúdo colado visível; sem Return |
| VS Code / Claude Code 2.1.309 | Mesmo percurso ASR → extensão → PTY → CLI | 182 palavras, 1121 caracteres; rascunho/bloco visível; sem Return |
| Gemini CLI | Abertura e autenticação | Bloqueado pelo serviço: cliente não suportado para a conta Google atual. Sem validação do compositor |

Os testes dos CLIs deixaram os textos **por enviar**. Não se pediu uma resposta aos modelos, nem se autorizou execução de tarefas por esses agentes. O percurso do VS Code usou o conteúdo da extensão instalada 0.1.1 e um pseudo-terminal de teste com processo CLI real; não é uma sessão do responsável reutilizada.

## Fala longa: calibração e limites

O parágrafo de teste tem 182 palavras e está em `test/fixtures/long-dictation.txt`. Dois primeiros ensaios acústicos produziram cerca de 160 palavras, com perda de partes do início ou do fim. Não foram tratados como aprovação da cobertura da fala.

A leitura direta do ficheiro sintético preservou início e fim, ajudando a separar reconhecimento/inserção da captação acústica. No ensaio controlado final, com estabilização antes da reprodução e sem novas janelas de CLI a arrancar durante a medição, a duração do ficheiro coincidiu com a do gravador e as 182 palavras chegaram ao prompt. A contagem não garante correspondência palavra por palavra: termos e pontuação podem ser substituídos.

Isto **não é** um benchmark de precisão nem uma validação da fala longa natural do responsável. Esse teste continua pendente. Nos ensaios de inserção, compara-se o texto efetivamente reconhecido com os bytes entregues ao PTY, não com uma transcrição inventada.

O motor devolve apenas as durações como metadados adicionais, sem guardar áudio ou histórico de texto. Os ficheiros locais de diagnóstico não são publicados no repositório. A imagem do README mostra apenas material sintético de teste.

## Gemini

O Gemini abriu inicialmente na versão 0.45.0, iniciou o seu próprio atualizador e passou para 0.65.0. O erro do serviço persistiu depois da atualização: `This client is no longer supported for Gemini Code Assist for individuals`. A janela de autenticação ficou disponível para o responsável; não se extraíram credenciais nem se contornou a autenticação. O teste é pendente, não aprovado.

## Segurança dos testes

- Sessões novas, diretórios temporários e prompts sintéticos.
- Codex em sandbox de leitura e sem daemon partilhado.
- Claude em safe mode, sem ferramentas nem MCP adicionais. Confirmação de pasta limitada a um diretório de teste vazio.
- Gemini mantido sem confiança na pasta e sem extensões adicionais.
- Ausência de Return confirmada na entrega ao PTY. Claude/Codex podem representar colagens longas como blocos recolhidos; isso não significa envio.
- Assinaturas ad hoc verificadas, incluindo o helper incorporado no terminal.

## Correções e implementação

A extensão 0.1.1 já corrigia a escrita de `cancel` num pipe que podia estar fechado, gerando SIGPIPE depois da transcrição. Usa o encerramento gracioso do helper por SIGTERM e mantém a escalada para SIGKILL se necessário.

O novo terminal utiliza o mesmo helper, uma shell em PTY, AppKit e xterm.js em WebKit. A saída do PTY é passada como bytes, a entrada de voz usa o caminho de paste do xterm e a escrita respeita bracketed paste quando o programa o solicita. O frontend só carrega recursos locais e bloqueia navegação externa. Erros de entrega preservam o ditado numa janela de recuperação.

Durante a construção, os testes detetaram uma leitura de pipe que esperava mais bytes antes de atualizar o frontend; foi substituída por leitura POSIX da quantidade disponível. Os testes nativos cobrem a shell e a ausência de submissão sem Enter.

Os primeiros testes de CLI no VS Code tinham pressupostos errados sobre blocos de colagem e prontidão do ecrã de confiança. O harness foi corrigido e os dois testes finais passaram. Não houve alteração do comportamento de envio da extensão para os fazer passar.

## Por validar

- Fala longa natural do responsável e mais condições acústicas.
- Compositor do Gemini depois de resolver o método de autenticação.
- Instalação limpa com permissões recusadas e interrupções de áudio.
- Sessões remotas e uso prolongado/recursos sob carga.
- Terminal nativo: estabilidade continuada, acessibilidade completa e distribuição notarizada. Ainda só tem uma janela/sessão, sem tabs nem restauro.
- Recaptura visual do build final: o Mac bloqueou antes da captura após os ajustes menores de foco/cor do microfone. A revisão independente devolveu `recapture`; não houve aprovação visual final. A captura atual do README é do ensaio anterior do protótipo.

Os testes automatizados fecham apenas as suas próprias janelas quando terminam. Uma janela normal do VozTTY ou do VS Code permanece aberta.

## Continuação — cliente Google suportado (23/10/2026)

A pesquisa nas fontes oficiais confirmou a migração de contas pessoais para Antigravity CLI: https://github.com/google-gemini/gemini-cli/discussions/27274 e https://antigravity.google/docs/getting-started/. Instalado `agy` 1.4.6 pela distribuição oficial via Homebrew Cask. Aberto dentro de uma cópia do VozTTY, em modo `plan`, fora do repositório privado. O fluxo avançou do login para a configuração e mostrou Gemini 4 Argon. Parou nos termos de serviço, que precisam de decisão do responsável; a partilha de interações surge marcada por defeito. Não se aceitou o acordo nem se alterou essa opção. A inserção de rascunho longo no Antigravity ainda não foi validada.

## Antigravity e tema preto — 23/10/2026

Após o responsável concluir login e termos, Antigravity CLI 1.4.6 abriu Gemini 4 Argon. Teste no compositor real do terminal nativo, tema preto: 182 palavras/1130 caracteres de uma transcrição sintética previamente reconhecida; prefixo preservado, bloco de colagem visível, bytes recebidos iguais ao texto, processo ativo e nenhum Enter enviado. Evidência local: work/antigravity-black-final.json. Isto valida inserção no terminal próprio; microfone direto com Antigravity e extensão VS Code com Antigravity ainda não foram repetidos.

## Confirmação manual do responsável — Antigravity

Em 23/10/2026, o responsável repetiu o teste com o microfone e confirmou sucesso no Antigravity, mostrando o rascunho “Testando o microfone testando o microfone.” no compositor. Confirma ditado curto com a voz natural; não equivale a um novo teste longo.

Na continuação, a aplicação instalada abriu Codex 0.163.0 e a UI mostrou o ditado natural do responsável “Testando o microfone no OpenI Codex.” como rascunho. Nenhum prompt foi submetido pelo agente. A sessão herdou a configuração local YOLO e abriu em /; definir uma pasta de projeto e permissões antes de executar trabalho. A transcrição de nomes próprios pode precisar de revisão.

## Confirmação manual do responsável — Claude Code

Em 23/10/2026, o responsável mostrou Claude Code 2.1.309, Opus 5.5, aberto na pasta VozTTY. A frase ditada “Testando o microfone no Cloud, testando o microfone do Cloud.” foi recebida e respondida pelo Claude. Confirma o percurso de voz natural até ao CLI, com substituição do nome Claude por Cloud; rever nomes próprios antes de enviar. O envio foi feito pelo responsável, não pelo teste automatizado. Com esta confirmação, os três clientes — Codex, Claude Code e Antigravity — têm teste manual curto de microfone confirmado. Não equivale a teste longo com a voz natural. Os avisos de regras e expiração do login pertencem à configuração do Claude e não foram alterados.

## Organização visual e destaque de perguntas — 23/10/2026

- Perguntas reconhecidas pelos marcadores ›, ❯ e > em azul suave, incluindo quebras automáticas; saída normal mantém o tom claro e as cores ANSI originais. Não são alterados bytes do PTY, texto ou envio.
- Cabeçalho com identidade/estado agrupados; rodapé com legenda e atalhos; margens de leitura ampliadas.
- 12 testes unitários: 10 da extensão e 2 de reconhecimento visual, Unicode, quebras e linhas reutilizadas.
- Codex real: 182 palavras/1130 caracteres, prefixo e bloco mantidos, transporte exato, nenhum Enter, uma linha com destaque e seleção preservada. Evidência local: work/conversation-codex.json.
- Prévia nativa capturada com conversa sintética identificada: assets/terminal-conversation.png. Não apresenta conteúdo gerado por um modelo.
- A primeira verificação do destaque correu antes do primeiro desenho de uma janela em segundo plano; foi corrigida a espera visual no teste. Um aviso de atualização do Codex interrompeu a segunda execução; o teste passou a dispensá-lo com Escape, sem instalar atualizações ou alterar definições globais.
- Limite: são marcadores visuais, não metadados de autor. Citações com o mesmo prefixo podem ficar azuis; continuações com quebra explícita sem marcador podem conservar a cor do CLI. O tema da extensão VS Code não foi alterado.

## Correção do ícone macOS — 23/10/2026

Confirmado no ICNS instalado: o fundo verde estava presente e o símbolo ausente. A conversão do SVG não preservou o caminho com stroke. Substituído o símbolo por geometria preenchida equivalente e reexportados os dez tamanhos standard/Retina. O novo build-icon.sh verifica os dois componentes do símbolo antes da conversão e o símbolo depois de descodificar o ICNS. Sem alterar permissões ou encerrar sessões para limpar caches do Dock.

## Corte na lateral / ajuste de colunas — 23/10/2026

Reproduzido no binário anterior: o pai medido pelo FitAddon tinha padding, mas a medição usava a largura total como espaço para a grelha. A grelha ficou fora do limite direito (8 px medidos), com 131 colunas a 1120 px. Margens movidas para body; o pai do xterm ficou sem padding, mantendo o mesmo espaçamento visual.

Teste nativo de regressão em WKWebView: 1120 → 620 → 800 → 1440 → 1120 px. Com a correção, colunas 125 → 66 → 87 → 163 → 125, sem extravasamento à direita ou em baixo. O teste espera a conclusão do FitAddon em cada tamanho, em vez de aceitar uma grelha antiga menor. Antes falhou; depois passou. Evidência local: work/bounds-before.json e work/bounds-final.json. Não depende de login, voz ou prompts enviados.

## Controlos da janela — 23/10/2026

Barra de título nativa visível e três botões permanentes no cabeçalho: minimizar, maximizar/restaurar e fechar. Usam ações nativas NSWindow, com labels acessíveis e tooltips. Verificados no CUA numa instância de prévia com conteúdo sintético: os três botões estão presentes; maximizar/restaurar funcionou; fechar mostrou a confirmação e Keep Open preservou a sessão. O botão minimizar foi acionado; a inspeção CUA voltou a apresentar a janela, pelo que não se confirmou persistência no Dock. Sem encerrar sessões do responsável.

## Public release preparation — 2026-10-23

The maintainer explicitly authorized public GitHub distribution of both products. Extension 0.1.2 adds English command names, status/error text and permission descriptions without changing the dictation lifecycle or command IDs. The shared helper's own messages are now English. Terminal 0.2.0 includes the existing window/layout/icon fixes and a bundled MIT license.

Release checks passed: 12 JavaScript unit tests; native text/PTY/resize checks; packaged VSIX 0.1.2 exercised in an isolated VS Code Extension Development Host with real Apple recognition on the synthetic 182-word audio, exact terminal delivery and no automatic Enter; archive contents and checksum checks; deep/strict code-signature verification after extracting the native ZIP. Test hooks and internal design/checkpoint files are excluded from installable packages. Finder metadata was removed by staging the final archive outside the synced Documents directory before verifying the extracted signature.

The full Git history was scanned for secrets. Two generic-key matches were inside the unmodified xterm.js bundle; its bytes were verified against the official @xterm/xterm 6.0.0 npm archive (SHA-256 14903579ff54664cd72f8e8699e6961a6272c21863ec1c3b118cdc8af5d4a972). Only those exact historical fingerprints were excluded from the local audit; no other findings remained. Diagnostics, recordings and scanner reports stay outside the repository. Packages remain ad hoc signed and not Apple-notarized.

Publication verified: GitHub repository PUBLIC; v0.2.0 published as a public prerelease with both binary packages and SHA256SUMS.txt. All three assets downloaded without authentication and matched the local files byte for byte. English README accessible without login. No VS Code Marketplace publication was performed.

## Native 0.2.1 usability update — 2026-10-23

Removed the duplicate window buttons from the content header at the maintainer's request. Standard macOS close/minimize/zoom controls remain. The voice header now uses readable language names, a clearer Dictate action, shorter keyboard hints and clearer listening/review guidance. Existing language IDs and preferences are preserved through menu-item represented values.

The native layout regression passed at 1120 → 620 → 800 → 1440 → 1120 px with no grid overflow. All three displayed language choices map to the supported pt-BR, pt-PT and en-US identifiers; the test restores its original selection without changing saved preferences. Local evidence: work/native-021-layout.json. No new microphone run was performed for this UI-only patch.

Native 0.2.1 installed with a verified code signature. Public prerelease v0.2.1 includes the new native ZIP, unchanged VSIX 0.1.2 and checksums. All assets downloaded without authentication and matched local files byte for byte. Previous release assets were not overwritten.

## Native voice panel — source build 0.2.2

Controlled acoustic checks through the physical microphone passed in English and Brazilian Portuguese: real level events moved the seven bars; Pause stopped metering; speech played during Pause was excluded; the first and final sentences on either side of Pause were retained; Stop & insert also worked while paused; PTY bytes matched the transcript without Return. These checks use synthetic speaker playback, not a natural-voice accuracy benchmark. Window-fit checks with the panel visible passed at 620, 800, 1120 and 1440 pixels, and all recording states produced the expected enabled/disabled controls. Twelve JavaScript unit checks and native PTY/sanitization checks also passed. The public 0.2.1 assets and VS Code extension are unchanged.

## Continuous voice history — native source build 0.2.3

Fifteen JavaScript checks pass, including time-positioned level history, completed/ongoing pause intervals, expiry after 20 seconds, and rejection of invalid geometry. Native layout checks with synthetic level history and pause bands pass at 620, 800, 1120 and 1440 px without grid overflow. The narrow layout retains more terminal space. The visual preview is explicitly synthetic. A fresh physical-microphone recheck waited for macOS authorization and timed out before recording; diagnostic instrumentation in an untracked test copy confirmed the wait at AVCaptureDevice.requestAccess. This run does not claim a new acoustic pass. The helper protocol and recognition engine are unchanged from 0.2.2.
