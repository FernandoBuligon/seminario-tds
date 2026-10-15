require 'sinatra'
require 'json'
require 'sqlite3'
require 'fileutils'

set :bind, '127.0.0.1'
set :server, :puma
disable :show_exceptions
set :database_path, File.join(__dir__, 'data', 'tasks.sqlite3')

FileUtils.mkdir_p(File.dirname(settings.database_path))
SQLite3::Database.open(settings.database_path) do |database|
  database.execute <<~SQL
    CREATE TABLE IF NOT EXISTS tasks (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL CHECK (length(trim(title)) > 0),
      completed INTEGER NOT NULL DEFAULT 0 CHECK (completed IN (0, 1))
    )
  SQL
end

helpers do
  def invalid_input(message)
    halt 400, { error: message }.to_json
  end

  def task_id
    id = params['id']
    invalid_input('O id deve ser um inteiro positivo.') unless id.match?(/\A[1-9]\d*\z/)
    id
  end

  def json_attributes(allowed_fields)
    attributes = JSON.parse(request.body.read)
    unless attributes.is_a?(Hash) && !attributes.empty?
      invalid_input('Envie um objeto JSON com os campos da tarefa.')
    end
    unless (attributes.keys - allowed_fields).empty?
      invalid_input("Campos permitidos: #{allowed_fields.join(', ')}.")
    end

    if attributes.key?('title')
      title = attributes['title']
      unless title.is_a?(String) && !title.strip.empty?
        invalid_input('O título deve ser uma string não vazia.')
      end
      attributes['title'] = title.strip
    end

    if attributes.key?('completed') && ![true, false].include?(attributes['completed'])
      invalid_input('O campo completed deve ser true ou false.')
    end

    attributes
  rescue JSON::ParserError
    invalid_input('JSON inválido.')
  end

  def with_database
    database = SQLite3::Database.new(settings.database_path)
    database.results_as_hash = true
    database.busy_timeout = 5000
    yield database
  ensure
    database&.close
  end

  def task_data(row)
    return nil unless row

    { id: row['id'], title: row['title'], completed: row['completed'] == 1 }
  end

  def all_tasks
    with_database do |database|
      database.execute('SELECT id, title, completed FROM tasks ORDER BY id').map do |row|
        task_data(row)
      end
    end
  end

  def create_task(title)
    with_database do |database|
      database.execute('INSERT INTO tasks (title) VALUES (?)', [title])
      task_data(database.get_first_row('SELECT * FROM tasks WHERE id = ?', [database.last_insert_row_id]))
    end
  end

  def update_task(id, attributes)
    completed = attributes.key?('completed') ? (attributes['completed'] ? 1 : 0) : nil

    with_database do |database|
      # COALESCE preserva os campos que não foram enviados no PATCH.
      row = database.get_first_row(<<~SQL, [attributes['title'], completed, id])
        UPDATE tasks
        SET title = COALESCE(?, title), completed = COALESCE(?, completed)
        WHERE id = ?
        RETURNING id, title, completed
      SQL
      task_data(row)
    end
  end

  def delete_task(id)
    with_database do |database|
      database.execute('DELETE FROM tasks WHERE id = ?', [id])
      database.changes.positive?
    end
  end
end

before do
  content_type :json
end

get '/tasks' do
  all_tasks.to_json
end

post '/tasks' do
  attributes = json_attributes(['title'])
  task = create_task(attributes['title'])
  status 201
  task.to_json
end

patch '/tasks/:id' do
  id = task_id
  attributes = json_attributes(%w[title completed])
  task = update_task(id, attributes)
  halt 404 unless task
  task.to_json
end

delete '/tasks/:id' do
  halt 404 unless delete_task(task_id)
  status 204
  body ''
end

not_found do
  { error: 'Recurso não encontrado.' }.to_json
end

error do
  { error: 'Erro interno do servidor.' }.to_json
end
