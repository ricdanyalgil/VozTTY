# Continuar o VozTTY

## Estado

- GitHub deve continuar privado; release v0.1.0 deve continuar em rascunho. Não publicar sem aprovação do responsável.
- Extensão VS Code 0.1.1 instalada e confirmada manualmente pelo responsável.
- Terminal próprio nativo 0.2.0 implementado em `terminal/`, compilado e instalado localmente como `/Applications/VozTTY.app`. Um terminal/janela, shell real, microfone, cancelamento e revisão antes de Enter. Sem tabs, restauro ou notarização.
- README principal em inglês, com imagem real do protótipo, duas formas de uso, arquitetura, resultados e limites. Guia português atualizado.

## Evidência

- Dez testes da extensão passaram; testes nativos de sanitização, PTY, resize e submissão explícita passaram.
- Ensaio acústico controlado no terminal próprio: 82 segundos, 182 palavras, início/fim e prefixo anterior preservados, sem Enter. Ensaios anteriores tiveram perdas; não é benchmark de precisão nem teste longo com a voz natural do responsável.
- Claude e Codex receberam rascunhos longos sem envio, tanto pelo PTY de teste do VS Code com a extensão instalada como pelo terminal próprio. Colagens podem aparecer como blocos recolhidos nos CLIs.
- Gemini atualizou-se de 0.45.0 para 0.65.0 mas o serviço continuou a recusar autenticação da conta atual, indicando que o cliente não é suportado para Gemini Code Assist for individuals. Não contornar autenticação nem solicitar chaves pelo chat.

## Próximo passo exato

1. O Mac bloqueou durante a captura final. Pedir ao responsável que o desbloqueie manualmente; não tentar desbloqueio nem ler a UI por outro caminho.
2. Abrir a aplicação instalada em janela normal e recapturar a versão atual. A imagem do README é de um ensaio anterior do protótipo. A revisão independente respondeu `recapture`, porque faltou uma captura posterior aos pequenos ajustes de foco/cor do microfone. Não chamar a UI final aprovada antes dessa recaptura.
3. Testar uma fala longa natural do responsável no terminal próprio; verificar começo, fim, edição posterior e ausência de Enter.
4. Se o responsável resolver a autenticação do Gemini por um método suportado diretamente no CLI, repetir o teste do compositor sem enviar o prompt. Caso contrário manter como bloqueado, não aprovado.
5. Continuar estabilização antes de considerar a primeira versão pública.

## Repetir verificações

`npm test`, `./terminal/build.sh` e os comandos em `terminal/README.md`. As fontes de testes só entram no binário com `-D VOZ_TEST`. Uma janela automatizada pode fechar ao concluir; a aplicação normal deve permanecer aberta.

`VALIDACAO.md` contém o registo de escopo e limitações. Os diagnósticos locais do trabalho ficam fora do repositório; não publicar ditados pessoais, dados de conta ou gravações.

## Próximo passo atualizado — Antigravity

O responsável confirmou o login Google, mas Gemini CLI continuou recusado pelo serviço. Confirmada a migração oficial e instalado Antigravity CLI (`agy` 1.4.6). A janela VozTTY com Antigravity avançou para os termos de serviço e mostra Gemini 4 Argon em modo plan. O responsável deve rever a opção de partilha de interações e concluir Done; não aceitar termos em seu nome. Depois verificar prompt e repetir inserção de 182 palavras sem Enter. Não substituir o comando gemini por alias nem alterar autenticação. Revisão visual completa continua adiada por preferência do responsável.
