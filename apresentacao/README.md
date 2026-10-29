# Apresentação — Sinatra com Ruby

17 slides em formato 16:9, com foco na ferramenta Sinatra. A aplicação de tarefas
aparece ao final como exemplo dos recursos apresentados.

- `slides.pdf`: versão pronta para apresentar.
- `slides.html`: fonte editável e apresentação no navegador, sem dependências externas.

Abra o HTML no navegador. Use as setas, Page Up/Page Down, os botões no canto
inferior ou gestos verticais para navegar. Home e End vão ao início e ao fim.
Para editar, altere as seções do HTML; as cores ficam nas variáveis CSS de `:root`.

## Sequência

1. Tema e objetivos.
2. Sinatra, DSL e blocos Ruby.
3. Instalação mínima, fluxo HTTP e rotas.
4. Parâmetros, respostas, filtros, helpers e templates.
5. Escolhas de organização e responsabilidades.
6. Aplicação de tarefas: tecnologias, rota real e demonstração.
7. Conclusão e referências.

Os exemplos didáticos independentes estão identificados. Os trechos do projeto
correspondem a `app.rb`. A demonstração usa a instalação documentada no README
da raiz; para mostrar o erro 400, envie `{"title":" "}` em `POST /tasks`, com
`Content-Type: application/json` pelo Postman.

## Gerar novamente o PDF

Na raiz do repositório, com Google Chrome instalado:

```bash
google-chrome --headless --disable-gpu --no-pdf-header-footer \
  --print-to-pdf="$PWD/apresentacao/slides.pdf" \
  "file://$PWD/apresentacao/slides.html"
```

Alternativamente, imprima o HTML pelo navegador, salve como PDF, habilite os
planos de fundo e desabilite cabeçalhos e rodapés. O CSS define o tamanho 16:9.

Referência técnica: [documentação oficial do Sinatra](https://sinatrarb.com/intro.html).
