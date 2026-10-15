require 'sinatra'
require 'json'
require 'sqlite3'
require 'fileutils'

set :bind, '127.0.0.1'
set :server, :puma
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
