const list = document.querySelector('#tasks');
const createForm = document.querySelector('#create-form');
const titleInput = document.querySelector('#title');
const error = document.querySelector('#error');
const status = document.querySelector('#status');
const empty = document.querySelector('#empty');
const reload = document.querySelector('#reload');

async function api(path, method = 'GET', data) {
  const response = await fetch(path, {
    method,
    headers: data ? { 'Content-Type': 'application/json' } : {},
    body: data ? JSON.stringify(data) : undefined
  });
  if (!response.ok) {
    const payload = await response.json();
    throw new Error(payload.error || 'Não foi possível realizar a operação.');
  }
  return response.status === 204 ? null : response.json();
}

// Bloqueia novos envios enquanto uma operação está em andamento.
async function perform(action) {
  error.textContent = '';
  document.querySelectorAll('button, input').forEach(control => { control.disabled = true; });
  try {
    await action();
  } catch (failure) {
    error.textContent = failure instanceof TypeError
      ? 'Não foi possível conectar ao servidor. Confira se ele está rodando e tente novamente.'
      : failure.message;
  } finally {
    document.querySelectorAll('button, input').forEach(control => { control.disabled = false; });
  }
}

function button(text, className = 'secondary') {
  const control = document.createElement('button');
  control.type = 'button';
  control.className = className;
  control.textContent = text;
  return control;
}

function renderTask(task) {
  const item = document.createElement('li');
  item.className = `task${task.completed ? ' completed' : ''}`;
  const row = document.createElement('div');
  row.className = 'task-row';
  const label = document.createElement('label');
  label.className = 'task-label';
  const checkbox = document.createElement('input');
  checkbox.type = 'checkbox';
  checkbox.checked = task.completed;
  const title = document.createElement('span');
  // Os títulos são texto, inclusive quando contêm caracteres HTML.
  title.textContent = task.title;
  label.append(checkbox, title);
  const actions = document.createElement('div');
  actions.className = 'actions';
  const edit = button('Editar');
  const remove = button('Excluir', 'danger');
  edit.setAttribute('aria-label', `Editar tarefa: ${task.title}`);
  remove.setAttribute('aria-label', `Excluir tarefa: ${task.title}`);
  actions.append(edit, remove);
  row.append(label, actions);

  const form = document.createElement('form');
  form.className = 'edit-form';
  form.hidden = true;
  form.id = `edit-${task.id}`;
  const editLabel = document.createElement('label');
  editLabel.htmlFor = `title-${task.id}`;
  editLabel.textContent = 'Editar título';
  const input = document.createElement('input');
  input.id = editLabel.htmlFor;
  input.value = task.title;
  input.required = true;
  const save = button('Salvar', '');
  save.type = 'submit';
  const cancel = button('Cancelar');
  const editActions = document.createElement('div');
  editActions.className = 'actions';
  editActions.append(save, cancel);
  form.append(editLabel, input, editActions);
  item.append(row, form);
  edit.setAttribute('aria-controls', form.id);
  edit.setAttribute('aria-expanded', 'false');
  edit.addEventListener('click', () => {
    form.hidden = !form.hidden;
    edit.setAttribute('aria-expanded', String(!form.hidden));
    if (!form.hidden) { input.focus(); input.select(); }
  });
  cancel.addEventListener('click', () => {
    form.hidden = true;
    input.value = task.title;
    edit.setAttribute('aria-expanded', 'false');
    edit.focus();
  });
  checkbox.addEventListener('change', () => perform(async () => {
    try {
      const updated = await api(`/tasks/${task.id}`, 'PATCH', { completed: checkbox.checked });
      task.completed = updated.completed;
      item.classList.toggle('completed', task.completed);
      status.textContent = task.completed ? 'Tarefa concluída.' : 'Tarefa marcada como pendente.';
    } catch (failure) {
      checkbox.checked = task.completed;
      throw failure;
    }
  }));
  form.addEventListener('submit', event => {
    event.preventDefault();
    perform(async () => {
      const updated = await api(`/tasks/${task.id}`, 'PATCH', { title: input.value });
      const replacement = renderTask(updated);
      item.replaceWith(replacement);
      status.textContent = 'Título atualizado.';
      // Aguarda a liberação dos controles antes de restaurar o foco.
      requestAnimationFrame(() => replacement.querySelector('button').focus());
    });
  });
  remove.addEventListener('click', () => perform(async () => {
    await api(`/tasks/${task.id}`, 'DELETE');
    item.remove();
    empty.hidden = list.children.length > 0;
    status.textContent = 'Tarefa excluída.';
    requestAnimationFrame(() => titleInput.focus());
  }));
  return item;
}

async function load() {
  const tasks = await api('/tasks');
  list.replaceChildren(...tasks.map(renderTask));
  empty.hidden = tasks.length > 0;
  status.textContent = tasks.length === 1 ? '1 tarefa na lista.' : `${tasks.length} tarefas na lista.`;
}

createForm.addEventListener('submit', event => {
  event.preventDefault();
  perform(async () => {
    const task = await api('/tasks', 'POST', { title: titleInput.value });
    list.append(renderTask(task));
    empty.hidden = true;
    createForm.reset();
    status.textContent = 'Tarefa adicionada.';
    requestAnimationFrame(() => titleInput.focus());
  });
});
reload.addEventListener('click', () => perform(load));
perform(async () => {
  try { await load(); }
  catch (failure) { status.textContent = 'Lista indisponível. Use Atualizar lista para tentar novamente.'; throw failure; }
});
