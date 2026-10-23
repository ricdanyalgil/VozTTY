# VozTTY — Ditado no Terminal do VS Code

**Fale o próximo prompt sem sair do terminal.** Projeto open source com licença MIT. [English](README.md) · [Releases](https://github.com/ricdanyalgil/VozTTY/releases)

Microfone na barra do terminal, com reconhecimento local no Mac e inserção direta no prompt. Não lê nem escreve no clipboard e não acrescenta Enter.

## Usar

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

No VS Code, abra **Extensions → … → Install from VSIX…** e selecione o ficheiro `voztty-0.1.0-darwin-arm64.vsix` disponível em Releases. Se o painel Terminal não mostrar o microfone depois da instalação, execute **Developer: Reload Window** quando puder interromper a janela atual.

## Desenvolvimento

`./build-helper.sh` compila o componente Swift com as ferramentas da Apple. `npm test` executa os testes da entrega de texto, sem gravar áudio. Não há dependências npm de produção.

O teste `test/integration.js` é executado pelo Extension Development Host do VS Code: usa uma gravação sintética definida em `VOZ_TEST_AUDIO`, o motor real da Apple e um pseudo-terminal de teste para confirmar que o texto chega uma única vez e sem Enter. Não abre o microfone nem executa comandos de shell.
