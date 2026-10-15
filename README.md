# Seminário TDS — API de tarefas com Sinatra

API REST para demonstrar o Sinatra no seminário acadêmico da UTFPR. Permite listar,
criar, atualizar e remover tarefas. Cada tarefa possui somente `id`, `title` e
`completed`, com persistência local em SQLite.

## Tecnologias e pré-requisitos

- Ruby 3.2 ou superior, com RubyGems e Bundler 2.6.9.
- Sinatra 4 para as rotas, `sqlite3` para acesso direto ao banco e JSON do Ruby.
- Puma e Rackup para iniciar o servidor local no Sinatra 4.
- Compilador C, Make e cabeçalhos de desenvolvimento do Ruby para as extensões das gems.
- Git para obter o projeto e Postman desktop para a demonstração.

Não é necessário instalar um servidor SQLite: a gem acessa um arquivo local.
As versões das dependências estão registradas no `Gemfile.lock`.

## Instalação

Em Ubuntu 24.04 ou Linux Mint 22, os pré-requisitos Ruby podem ser instalados com:

```bash
sudo apt update
sudo apt install ruby-full build-essential libsqlite3-dev
ruby --version
```

Em outros sistemas, instale Ruby 3.2 ou superior com as ferramentas de compilação
correspondentes. Instale o Postman desktop pelo [site oficial](https://www.postman.com/downloads/).

Obtenha o projeto e entre no diretório:

```bash
git clone https://github.com/FernandoBuligon/seminario-tds.git
cd seminario-tds
```

Instale o Bundler no diretório do usuário e as dependências no diretório do projeto:

```bash
gem install --user-install bundler -v 2.6.9
export PATH="$(ruby -r rubygems -e 'puts Gem.user_dir')/bin:$PATH"
bundle config set --local path vendor/bundle
bundle install
```

O `export` vale para o terminal atual; repita-o ao abrir outro terminal caso o
comando `bundle` não esteja no PATH. `.bundle/` e `vendor/bundle/` são ignorados pelo Git.

## Execução

Na raiz do projeto:

```bash
bundle exec ruby app.rb
```

O servidor atende em **http://127.0.0.1:4567**. Use `Ctrl+C` para encerrar e o
mesmo comando para reiniciar. O diretório `data/`, o arquivo `tasks.sqlite3` e a
tabela são criados automaticamente na primeira execução. O caminho do banco
é relativo ao `app.rb`, independentemente do diretório de onde o Ruby foi chamado.

Os dados permanecem salvos após encerrar o servidor. O banco não é versionado.

## Endpoints

| Método | Rota | Operação | Sucesso |
|---|---|---|---|
| GET | `/tasks` | Listar todas as tarefas por ordem de ID | 200 |
| POST | `/tasks` | Criar tarefa com `completed: false` | 201 |
| PATCH | `/tasks/:id` | Atualizar título e/ou conclusão | 200 |
| DELETE | `/tasks/:id` | Excluir tarefa | 204, sem corpo |

Envie os corpos de POST e PATCH como JSON com `Content-Type: application/json`.
Os exemplos abaixo usam o ID `1`; substitua pelo ID retornado na criação.

### Listar tarefas

`GET http://127.0.0.1:4567/tasks`

Resposta 200 com banco vazio:

```json
[]
```

### Criar tarefa

`POST http://127.0.0.1:4567/tasks`

```json
{
  "title": "Preparar seminário"
}
```

Resposta 201:

```json
{
  "id": 1,
  "title": "Preparar seminário",
  "completed": false
}
```

A listagem passa a retornar uma lista contendo esse objeto.

### Atualizar tarefa

`PATCH http://127.0.0.1:4567/tasks/1`

Para alterar somente o título:

```json
{
  "title": "Apresentar Sinatra"
}
```

Para concluir a tarefa:

```json
{
  "completed": true
}
```

Resposta 200 após essas duas requisições:

```json
{
  "id": 1,
  "title": "Apresentar Sinatra",
  "completed": true
}
```

Também é possível enviar os dois campos no mesmo PATCH. Os campos omitidos
preservam seus valores; `completed: false` permite desmarcar a conclusão.

### Excluir tarefa

`DELETE http://127.0.0.1:4567/tasks/1`

Não envie corpo. A resposta é 204, sem corpo. Uma nova listagem não inclui a tarefa.

### Validações e erros

- POST aceita somente `title`. PATCH aceita `title`, `completed` ou ambos.
- `title` deve ser uma string não vazia. Espaços nas extremidades são removidos.
- `completed` deve ser o booleano `true` ou `false`, sem aspas; `null` não é aceito.
- Corpos vazios, objetos vazios, JSON inválido, tipos incorretos e campos
  desconhecidos retornam 400.
- O ID na URL deve ser um inteiro positivo, sem zeros à esquerda; formatos
  inválidos retornam 400. IDs válidos que não existem retornam 404.
- Rotas inexistentes retornam 404. Falhas internas retornam 500 com erro JSON.

Exemplo de resposta 400 para `{"title":" "}`:

```json
{"error":"O título deve ser uma string não vazia."}
```

Exemplo de resposta 404:

```json
{"error":"Recurso não encontrado."}
```

## Demonstração e testes com Postman

1. Inicie a API. Para o cenário de banco vazio, use uma instalação nova ou
   exclua previamente as tarefas de demonstração pelos endpoints.
2. No Postman desktop, importe `tasks.postman_collection.json`. A variável
   `base_url` da coleção já contém `http://127.0.0.1:4567`.
3. Execute a pasta **CRUD e validações** no Collection Runner, na ordem salva.
   Ela lista o banco vazio, cria uma tarefa, lista novamente, altera o título,
   marca como concluída, atualiza ambos os campos e testa entradas inválidas.
   Ao final, exclui a tarefa e verifica os erros 404. O ID retornado pelo POST
   é guardado automaticamente para as próximas requisições.
4. Execute a pasta **Preparar persistência**, que cria uma tarefa adicional.
5. Encerre o servidor com `Ctrl+C` e execute novamente `bundle exec ruby app.rb`.
6. Execute a pasta **Conferir persistência**. Ela verifica a tarefa salva após o
   reinício e a remove para deixar o banco vazio.

Para fazer uma requisição individual, selecione o método e a URL. Em POST e
PATCH, escolha **Body → raw → JSON** e use um dos exemplos acima. Ao executar
manualmente as requisições da coleção, mantenha a ordem para preencher os IDs.

A coleção também pode ser executada com o
[Postman CLI oficial](https://learning.postman.com/docs/postman-cli/postman-cli-installation/):

```bash
postman collection run tasks.postman_collection.json -i 'CRUD e validações' --no-report-events
postman collection run tasks.postman_collection.json -i 'Preparar persistência' --no-report-events
# Encerre e reinicie o servidor no outro terminal antes do próximo comando.
postman collection run tasks.postman_collection.json -i 'Conferir persistência' --no-report-events
```

Os testes locais não precisam de login no Postman. Avisos do CLI sobre credenciais
referem-se à publicação dos resultados na nuvem. Não execute as três pastas de
uma vez para comprovar persistência: é necessário reiniciar entre as duas últimas.

### Verificações executadas

Validação realizada com Ruby 3.4.9, Sinatra 4.2.1, sqlite3 2.10.0, Puma 7.2.1
e Postman CLI 1.74.0:

| Pasta | Requisições | Verificações | Falhas |
|---|---:|---:|---:|
| CRUD e validações | 26 | 77 | 0 |
| Preparar persistência | 1 | 3 | 0 |
| Conferir persistência, após reinício real | 3 | 8 | 0 |
| **Total** | **30** | **88** | **0** |

Foram conferidos os códigos HTTP, JSON, corpo vazio do DELETE, tipos dos campos,
valores persistidos e atualizações parciais. Um título contendo texto SQL foi
armazenado literalmente, sem executar seu conteúdo. A conexão é fechada em
`ensure`, e as consultas com dados recebidos usam parâmetros.

Também foram executados testes diretos de SQLite em processos separados,
verificação de sintaxe Ruby e requisições HTTP básicas. Não houve erros no
terminal durante a execução normal da API. Os registros criados pelos testes
foram removidos pelos próprios endpoints.

**Não executado:** demonstração manual pela interface gráfica do Postman e
execução em outros sistemas ou versões do Ruby. A coleção e o roteiro estão
disponíveis para reproduzir a apresentação. Os testes foram locais pelo CLI.

## Estrutura do projeto

```text
seminario-tds/
├── app.rb                         # Configuração, SQLite, validações e rotas
├── Gemfile                        # Dependências diretas
├── Gemfile.lock                   # Versões resolvidas pelo Bundler
├── .gitignore                     # Banco e arquivos locais ignorados
├── README.md                      # Instalação, uso e demonstração
├── tasks.postman_collection.json   # Requisições e verificações do Postman
└── data/
    └── tasks.sqlite3              # Criado em execução; fora do Git
```

A aplicação fica em um único arquivo para facilitar a explicação no seminário.
O SQLite armazena `completed` como 0 ou 1; a API converte esses valores para
booleanos JSON. O servidor escuta somente na máquina local, conforme o objetivo
de demonstração acadêmica.
