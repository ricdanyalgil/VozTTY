# Validação 0.1.1 — 2026-10-23

Estado: desenvolvimento privado. A release v0.1.0 continua em rascunho. A publicação depende da aprovação do responsável.

## Confirmado

- Dez testes unitários passaram, incluindo a regressão do encerramento do motor.
- O pacote 0.1.1 foi instalado e identificado pelo VS Code como `danyalgil.voz-terminal@0.1.1`.
- A assinatura ad hoc do componente nativo instalado passou na verificação estrita.
- Teste acústico no Extension Development Host com o conteúdo exato do pacote instalado: frase sintética reproduzida pelos altifalantes e captada pelo microfone físico. Não usou entrada de ficheiro nem clipboard.
- Estados observados: preparar → gravar → cancelar → preparar → gravar → transcrever → inativo.
- Resultado: uma entrega de 60 caracteres ao pseudo-terminal; sem Return, Escape ou duplicação. O motor encerrou e o host terminou com código zero, sem SIGPIPE no log.
- O responsável confirmou depois o ditado com a própria voz num terminal zsh de uma janela normal do VS Code. O texto apareceu no prompt e o responsável respondeu “funcionou”. O conteúdo pessoal não é guardado neste relatório.

## Correção

Após devolver o evento final, o motor termina. A extensão escrevia ainda `cancel` no stdin desse processo, podendo atingir um pipe já fechado e gerar SIGPIPE no host do VS Code. Agora reutiliza o tratamento de SIGTERM do motor para encerrar com limpeza, mantendo a escalada para SIGKILL se necessário. O teste de regressão verifica que a conclusão e o cancelamento não escrevem nesse pipe.

A janela do Extension Development Host fecha automaticamente ao terminar o teste. Esse fecho também foi observado pelo responsável e distinguido do funcionamento numa janela normal, que permanece aberta.

## Por validar

Campos interativos reais de Claude Code, Codex CLI e Gemini CLI; ditados longos; recusa de permissões numa instalação nova; sessões remotas. O componente não está notarizado pela Apple. Não publicar o projeto ou a release sem aprovação.

## Repetir

`npm test` executa os testes unitários sem abrir o microfone.

O ponto de entrada `test/microphone.integration.js` exige o Extension Development Host, `VOZ_TEST_MICROPHONE=1` e `VOZ_TEST_RESULT` com o caminho do resultado. O teste abre o microfone, reproduz uma frase e fecha a sua janela ao terminar. Não usar essa janela para avaliar se a extensão mantém uma janela normal aberta.
