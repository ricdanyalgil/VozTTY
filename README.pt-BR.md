# VozTTY — A sua voz no terminal

**Fale o próximo prompt sem sair do terminal.** Projeto privado a caminho de uma versão open source com licença MIT. [English](README.md) · [Releases](https://github.com/ricdanyalgil/VozTTY/releases)

**Estado de publicação:** desenvolvimento privado e primeira release em rascunho. O repositório e a versão só devem tornar-se públicos depois de validar a primeira versão e de o responsável aprovar a publicação. A licença MIT já está preparada para essa abertura futura.

Microfone na barra do terminal, com reconhecimento local no Mac e inserção direta no prompt. Não lê nem escreve no clipboard e não acrescenta Enter.

## Terminal próprio para Mac — prévia 0.2.0

Já existe uma primeira aplicação nativa: uma janela, uma sessão de shell real e o botão **Dictate / Stop & insert** na própria barra. Usa AppKit, WebKit e xterm.js local, sem runtime Node.js. O mesmo motor de voz serve a extensão e o terminal próprio.

Com as ferramentas de desenvolvimento da Apple instaladas:

```sh
./terminal/build.sh
open terminal/VozTTY.app
```

Por omissão abre `/bin/zsh -l`. Execute os seus comandos `claude`, `codex` ou `gemini` dentro da shell; não estão incluídos na aplicação. Ainda não há tabs, divisões, restauro de sessões ou notarização. Fechar uma sessão ativa pede confirmação e descarta o texto não enviado.

## Usar no VS Code

1. Abra o terminal integrado e selecione a sessão em que quer escrever.
2. Clique no ícone de microfone na barra do painel, junto aos controlos do terminal. Também pode executar **Voz: Começar ditado no terminal** na Paleta de Comandos.
3. Aguarde o indicador **Voz: a gravar**. No primeiro uso, autorize o microfone no pedido do macOS; um modelo de idioma pode precisar de ser descarregado pela Apple.
4. Fale e clique no botão de parar para terminar. A extensão transcreve e insere o texto diretamente no prompt, conservando a pontuação.
5. Reveja e continue a escrever. Você escolhe quando enviar.

**Control + Option + V** começa ou termina uma gravação com o terminal focado. **Esc** cancela. Durante a preparação ou transcrição, clique no indicador da barra inferior para cancelar.

A gravação pertence à sessão em que começou. Mudar de terminal ou fechar essa sessão cancela o ditado. O texto que já estava no prompt não é apagado. O texto é inserido na posição atual do cursor quando a transcrição termina.

## Idioma e requisitos

Em Definições do VS Code, procure **Voz: Language**. Idioma inicial: `pt-BR`; também estão disponíveis `pt-PT` e `en-US`, sujeitos ao suporte da Apple no computador.

Requer VS Code desktop, Apple Silicon e macOS 26 ou superior. A extensão é executada localmente, inclusive em janelas Remote SSH/Containers. A captura e inserção num terminal remoto ainda precisam de validação. VS Code no navegador, Linux, Windows e Mac Intel não são suportados por esta versão.

## Limites desta primeira versão

- O texto entra no prompt depois de parar; não há transcrição palavra a palavra durante a gravação.
- O áudio é guardado temporariamente numa pasta privada do utilizador e apagado ao concluir ou cancelar normalmente. Um encerramento forçado pode deixar áudio no diretório temporário do macOS.
- Não há envio de áudio para uma API da nossa ferramenta, histórico de transcrições nem leitura de credenciais dos assistentes. A Apple pode descarregar modelos de idioma quando necessário.
- Quebras de linha e espaços repetidos são reduzidos a espaços; controlos de terminal são removidos. A pontuação, acentos e palavras permanecem.
- O reconhecimento tem até 60 segundos para devolver o resultado depois de parar. O texto final tem limite de 64 KiB nesta versão. Um erro ou cancelamento descarta o novo ditado; o texto já existente no prompt permanece.
- Não identifica o campo interno de cada CLI: a inserção vai para a entrada do terminal selecionado. Use num prompt de texto; um programa que reage imediatamente a caracteres pode reagir à transcrição.
- O componente nativo tem assinatura local ad hoc; ainda não é uma distribuição notarizada pela Apple.

## Instalar o pacote

No VS Code, abra **Extensions → … → Install from VSIX…** e selecione o ficheiro `voztty-0.1.1-darwin-arm64.vsix` fornecido pelo responsável ou compilado a partir do repositório privado. Se o painel Terminal não mostrar o microfone depois da instalação, execute **Developer: Reload Window** quando puder interromper a janela atual.

## Desenvolvimento

`./build-helper.sh` compila o componente Swift com as ferramentas da Apple. `npm test` executa os testes da entrega de texto, sem gravar áudio. Não há dependências npm de produção.

O teste `test/integration.js` é executado pelo Extension Development Host do VS Code: usa uma gravação sintética definida em `VOZ_TEST_AUDIO`, o motor real da Apple e um pseudo-terminal de teste para confirmar que o texto chega uma única vez e sem Enter. Não abre o microfone nem executa comandos de shell.

## Validação da versão 0.1.1

Os dez testes automatizados passaram. No VS Code, o teste acústico reproduziu uma frase sintética pelos altifalantes e captou-a pelo microfone físico: chegou uma única transcrição ao terminal, sem Enter ou Escape. Cancelar, recomeçar e encerrar o motor também passaram. A versão corrige uma tentativa de escrita num canal já fechado que gerava `SIGPIPE` após a transcrição.

O teste `test/microphone.integration.js` exige `VOZ_TEST_MICROPHONE=1` e `VOZ_TEST_RESULT` com o caminho do resultado JSON. Abre o microfone e reproduz a frase no dispositivo de saída atual, sem alterar as definições de áudio. Guarda apenas estados e contagens. O responsável também confirmou o ditado com a própria voz num terminal normal do VS Code. Os testes posteriores passaram nos campos reais do Claude Code e Codex, tanto pelo terminal de teste do VS Code como no terminal próprio, sem Enter. O Gemini continua bloqueado pela autenticação do serviço.

No terminal próprio, o ensaio acústico longo controlado captou 82 segundos e entregou 182 palavras, com início, fim e prefixo anterior preservados. Ensaios acústicos anteriores perderam partes do texto; continuam a ser necessários testes com fala longa natural do responsável. Não é um benchmark de precisão. Consulte [VALIDACAO.md](VALIDACAO.md).

Ainda falta avaliar a recusa de permissões numa instalação nova, sessões remotas, uso continuado do terminal próprio e autenticação/compositor do Gemini.

## Organização visual do terminal próprio

Fundo preto, perguntas reconhecidas pelo marcador do CLI em azul suave e saída normal em cinzento claro. Cabeçalho com estado do microfone e rodapé com legenda e atalhos. A cor é apenas visual: não altera o texto, as permissões ou o envio. Usa os marcadores ›, ❯ e >; citações com o mesmo formato podem receber o destaque e continuações com quebra explícita podem conservar as cores do CLI.
