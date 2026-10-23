# Continuar o VozTTY

## Estado atual — 23/10/2026

- Repositório GitHub privado; release v0.1.0 em rascunho. Não publicar sem aprovação explícita.
- Extensão VS Code 0.1.1 instalada e confirmada pelo responsável.
- Terminal próprio nativo 0.2.0 instalado em /Applications/VozTTY.app, com fundo preto inspirado no Codex, um terminal/sessão, microfone, cancelamento e revisão antes de Enter.
- README em inglês com imagens, instalação, arquitetura e resultados; VALIDACAO.md mantém o histórico e os limites dos testes.
- Codex, Claude Code e Antigravity (agy, sucessor oficial do Gemini CLI para contas pessoais) têm teste manual curto de microfone confirmado pelo responsável.
- Claude Code 2.1.309 aberto na pasta VozTTY; ditado recebido e respondido. Reconheceu Claude como Cloud. Não alterar automaticamente nomes no motor.
- O responsável escolheu Full Access no Codex. A sessão observada estava em /; indicar pasta de projeto ao iniciar trabalho. Não alterar permissões escolhidas sem motivo relacionado com a tarefa.

## Evidência

- 10 testes da extensão e verificações nativas de sanitização, PTY, resize e Enter explícito passaram.
- Ensaio acústico controlado: 82 segundos, 182 palavras, início/fim e prefixo preservados, sem Enter. Ensaios anteriores perderam palavras. Não é benchmark de precisão nem fala longa natural do responsável.
- Claude/Codex: rascunhos longos no VS Code e no terminal próprio. Antigravity 1.4.6 / Gemini 4 Argon: 182 palavras, bytes iguais ao texto e bloco de colagem no terminal próprio, sem Enter.
- Compilação, assinatura local e sintaxe JavaScript verificadas no tema preto. Captura atual em outputs/voztty-black.png, fora do repositório; inclui dados de conta, não publicar.
- Login e termos do Antigravity concluídos pelo responsável. Gemini CLI legado permanece incompatível com o acesso pessoal; usar agy. Não criar alias enganador nem extrair credenciais.

## Próximos passos

1. Testar fala longa natural do responsável: início, fim, edição e envio apenas manual.
2. Se necessário, repetir o teste do Antigravity pela extensão VS Code; ainda não foi validado nesse ambiente.
3. Continuar estabilização e uso prolongado antes de considerar lançamento público. Faltam notarização, testes de permissões numa instalação nova e sessões remotas.
4. Revisão visual completa ainda não foi aprovada. Não iniciar redesign adicional sem pedido.

Não guardar/publicar gravações pessoais, credenciais ou dados de conta. Diagnósticos locais ficam em work/. Testes de integração entram apenas com -D VOZ_TEST; a aplicação instalada é a versão normal.

## Layout atualizado

Novo layout do terminal próprio: perguntas azuis com fundo azul discreto, respostas com as cores normais do CLI, cabeçalho em duas linhas e rodapé com legenda/atalhos. Prévia sintética identificada em assets/terminal-conversation.png, sem dados de conta. Codex real validado com 182 palavras, nenhuma submissão, destaque e seleção preservados. `npm test` agora inclui os dois testes do classificador visual (12 no total). Ler os limites em terminal/README.md: prefixos visuais podem coincidir com citações e não existe metadata universal de papéis nos CLIs. Não recolorir ou modificar o fluxo PTY. As janelas já abertas conservam a versão carregada; a nova UI aplica-se a novas instâncias.

## Ícone macOS corrigido

O ICNS anterior tinha o fundo verde sem o símbolo. SVG corrigido para formas preenchidas; terminal/build-icon.sh regenera tamanhos standard/Retina e verifica o símbolo. Recompilar e reinstalar mantém as janelas abertas; o Dock pode precisar que a aplicação seja reaberta para largar o ícone em cache. Não terminar sessões do responsável para forçar a atualização.

## Corte lateral corrigido

O FitAddon calculava a largura do pai com padding como se estivesse toda disponível para texto. Margens movidas para body, deixando o elemento medido sem padding; preservada a aparência. Teste nativo VOZ_TEST_MODE=layout reproduz o erro anterior e verifica limites/dimensionamento após redimensionar. A correção é carregada por novas instâncias, sem terminar sessões abertas.
