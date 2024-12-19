#!/usr/bin/env python3
# version 4.3
import os
import sys
import subprocess
import shutil
from flask import Flask, render_template_string, request, redirect, url_for, send_from_directory, abort
from flask_socketio import SocketIO, emit
from werkzeug.utils import secure_filename
from threading import Thread

# Добавляем путь к конфигу 
config_path = '/app' 
sys.path.append(config_path)

from path_config import READS_FOLDER, OUTPUT_FOLDER, nextflow_path, nextflow_command, kraken2_db, GTDB_db

app = Flask(__name__)
socketio = SocketIO(app)

print(READS_FOLDER) 
print(OUTPUT_FOLDER) 
print(nextflow_path) 
print(nextflow_command)

# nextflow_service = 'nextflow.service'

nextflow_process = None

MAX_CONTENT_LENGTH = 1024 * 1024 * 1024 * 100  # 100 GB 
MAX_FILES = 100

def monitor_output_folder():        # Мониторинг папки output
    while True:
        socketio.sleep(2)
        files = os.listdir(OUTPUT_FOLDER)
        socketio.emit('update_output', {'files': files})

def stream_nextflow_output(process):
    try:
        for line in iter(process.stdout.readline, ''):
            socketio.emit('console_output', {'output': line})
        for line in iter(process.stderr.readline, ''):
            socketio.emit('console_output', {'output': line})

        return_code = process.wait()    # Ожидание завершения процесса
        
        if return_code != 0:
            # Если Nextflow завершился с ошибкой
            socketio.emit('console_output', {'output': f'Nextflow завершился с ошибкой: код {return_code}'})
            socketio.emit('nextflow_status', {'status': 'error'})
        else:
            socketio.emit('nextflow_complete')  # Сообщение о завершении работы Nextflow
    except Exception as e:
        # вывод ошибок при работе с процессом
        socketio.emit('console_output', {'output': f'Ошибка в процессе Nextflow: {str(e)}'})
        socketio.emit('nextflow_status', {'status': 'error'})

@app.route('/')
def index():
    is_running = nextflow_process is not None and nextflow_process.poll() is None
    output_files = os.listdir(OUTPUT_FOLDER)
    return render_template_string('''
        <style>
            body { font-family: Arial, sans-serif; background-color: #cfd7f0; margin: 0; padding: 0; }
            h1 { background-color: #214168; color: white; padding: 10px; text-align: center; }
            h2 { color: #333; }
            .container { padding: 20px; max-width: 900px; margin: auto; }
            form { margin-bottom: 20px; }
            input, button { padding: 10px; margin: 5px 0; width: 100%; max-width: 250px; }
            button { height: 36px; width: 250px; font-size: 14px; background-color: #214168; color: white; border: none; cursor: pointer; border-radius: 5px;}
            button[disabled] { background-color: #ccc; }
            input[type="file"] { display: none; }
            .console-output { background-color: #214168; color: #fff; padding: 10px; height: 300px; overflow-y: auto; margin-bottom: 20px; font-size: 12px; line-height: 0.5;}
            .output-files { background-color: #214168; padding: 10px; margin-bottom: 20px; }
            .progress-bar { width: 100%; background-color: #214168; margin-bottom: 20px; }
            .progress-bar-fill { height: 20px; width: 0; background-color: #4caf50; text-align: center; color: white; line-height: 20px; white-space: nowrap;}
            .custom-file-upload { background-color: #214168; color: white; border: none; cursor: pointer; border-radius: 5px; padding: 10px; display: inline-block; font-size: 14px; }
            .file-info { font-size: 16px; color: #214168; margin-left: 10px; display: inline-block; vertical-align: middle; margin-right: 500; font-weight: bold; }
            .output-files a { color: white; }
            .output-files a:hover { color: yellow; }
            .output-files a:visited { color: lightgray; }
            .button-row { display: flex; gap: 10px; justify-content: space-between; align-items: center; align-items: flex-end}
            #version-number { position: fixed; top: 6px; right: 14px; background-color: rgba(0, 0, 0, 0.0); color: white; padding: 0px 10px; border-radius: 5px; font-size: 14px; z-index: 1000; display: flex; align-items: center; gap: 20px;}
            .upload-row { display: flex; align-items: center; justify-content: flex-start; gap: 10px; flex-wrap: wrap; }
            #upload-button {margin-right: auto;}
            #cancel-upload-button { display: none; }
            .upload-row button:last-child { margin-left: auto; }
            .no-underline { text-decoration: none; color: white; }
            .no-underline:hover, .no-underline:active, .no-underline:visited { color: white; }
        </style>
        <h1>Metagenome NF</h1>
        <div id="version-number">Версия 2.0
            <p><a href="https://docs.google.com/document/d/1wzGcBp868aPvKoOo0Jx8Z-lDEg5iVLzQVS-VXZIbthA/edit?tab=t.0#heading=h.4ikn9g84g3gq" target="_blank" class="no-underline">❔ Справка</a></p>
        </div>
        <div class="container">
            
                <form id="upload-form" action="/upload" method="post" enctype="multipart/form-data">
                    <div class="upload-row">
                        <label class="custom-file-upload">
                            Выбрать файлы
                            <input type="file" id="file-upload" name="reads_files" multiple required>
                        </label>
                        <span class="file-info" id="file-info">Файлы не выбраны</span>
                        <button type="submit" id="upload-button">Загрузить файлы</button>
                        <button type="button" id="cancel-upload-button" style="display: none;">Остановить загрузку</button>
                    </div>
                </form>

                <div class="progress-bar" id="progress-bar">
                    <div class="progress-bar-fill" id="progress-bar-fill">0%</div>
                </div>

            <div class="button-row">
                <form action="/run_nextflow" method="post" onsubmit="clearConsole()">
                    <input type="text" name="launch_name" placeholder="Введите название запуска" required pattern="[A-Za-z0-9_]+">
                    <button type="submit" {% if is_running %}disabled{% endif %}>Запустить анализ</button>
                </form>
                <form action="/stop_nextflow" method="post">
                    <button type="submit" {% if not is_running %}disabled{% endif %}>Остановить анализ</button>
                </form>
            </div>

            <h2>Ход выполнения анализа:</h2>
            <div class="console-output" id="console-container"></div>

            <h2>Результаты:</h2>
            <div class="output-files" id="output-container">
                {% for file in output_files %}
                    <p><a href="{{ url_for('browse_output', path=file) }}">{{ file }}</a></p>
                {% endfor %}
            </div>
            <a href="{{ url_for('download_all') }}">
                <button>Скачать файлы</button>
            </a>
        </div>
        <script src="{{ request.url_root }}static/socket.io.js"></script>
        <script>
            document.getElementById('file-upload').addEventListener('change', function() {
                var fileInput = this;
                var infoArea = document.getElementById('file-info');

                if (fileInput.files.length > 0) {
                    infoArea.textContent = fileInput.files.length + ' файл(ов) выбрано';
                } else {
                    infoArea.textContent = 'Файлы не выбраны';
                }
            });
        </script>
<script>
    var socket = io();

    // Прослушивание сообщений об ошибках или статусах
    socket.on('console_output', function(data) {
        console.log(data.output);  // Вывод в консоль браузера
    });

    // Можно добавить обработку статуса Nextflow
    socket.on('nextflow_status', function(data) {
        if (data.status === 'running') {
            console.log("Nextflow запущен.");
        } else if (data.status === 'error') {
            console.log("Произошла ошибка при запуске Nextflow.");
        }
    });
</script>        
        <script type="text/javascript">
            var socket = io();
            var terminalContainer = document.getElementById('console-container');
            var savedConsoleOutput = localStorage.getItem('consoleOutput') || '';

            // Инициализируем содержимое терминала
            terminalContainer.innerHTML = savedConsoleOutput;

            function scrollToBottom() {
                terminalContainer.scrollTop = terminalContainer.scrollHeight;
            }

            function clearConsole() {
                terminalContainer.innerHTML = '';
                localStorage.removeItem('consoleOutput');
            }
            
            socket.on('console_output', function(msg) {
                var newElement = document.createElement('p');
                newElement.innerHTML = msg.output;
                terminalContainer.appendChild(newElement);
                scrollToBottom();

                // Сохраняем в localStorage
                localStorage.setItem('consoleOutput', terminalContainer.innerHTML);
            });

            socket.on('update_output', function(msg) {
                var container = document.getElementById('output-container');
                container.innerHTML = '';
                msg.files.forEach(function(file) {
                    var newElement = document.createElement('p');
                    newElement.innerHTML = '<a href="/output/' + file + '">' + file + '</a>';
                    container.appendChild(newElement);
                });
            });

            socket.on('nextflow_status', function(status) {
                var statusElement = document.getElementById('nextflow-status');

                if (status.status === 'running') {
                    clearConsole();
                    statusElement.textContent = 'Nextflow запущен';
                }
                else if (status.status === 'stopped') {
                    statusElement.textContent = 'Nextflow остановлен';
                } else if (status.status === 'error') {
                    statusElement.textContent = 'Ошибка при запуске Nextflow';
                }
                // Перезагрузка страницы автоматически обновляет вывод файлов
            });

            // Логика завершения работы Nextflow
            socket.on('nextflow_complete', function() {
                // Автоматически обновляем список файлов в папке output
                window.location.reload();

                // "Нажимаем" кнопку остановки Nextflow
                var stopButton = document.querySelector('form[action="/stop_nextflow"] button');
                if (stopButton) {
                    stopButton.click();
                }
            });

            document.getElementById('upload-form').onsubmit = function(event) {
                event.preventDefault();

                var uploadButton = document.getElementById('upload-button');
                var cancelUploadButton = document.getElementById('cancel-upload-button');
                var progressBarFill = document.getElementById('progress-bar-fill');

                uploadButton.disabled = true; // Делаем кнопку неактивной
                cancelUploadButton.style.display = 'inline-block'; // Показываем кнопку остановки

                var form = event.target;
                var formData = new FormData(form);
                var xhr = new XMLHttpRequest();
                xhr.open('POST', form.action, true);

                xhr.upload.onprogress = function(event) {
                    if (event.lengthComputable) {
                        var percentComplete = Math.round((event.loaded / event.total) * 100);
                        progressBarFill.style.width = percentComplete + '%';
                        progressBarFill.innerText = percentComplete + '%';
                    }
                };

                xhr.onload = function() {
                    uploadButton.disabled = false; // Возвращаем кнопку в активное состояние
                    cancelUploadButton.style.display = 'none'; // Скрываем кнопку остановки

                    if (xhr.status === 200) {
                        // Изменяем текст на прогресс-баре на "Файлы загружены"
                        progressBarFill.innerText = "Файлы загружены";
                        progressBarFill.style.width = '100%';
                        // window.location.reload();
                    } else {
                        alert('Произошла ошибка при загрузке файлов');
                        progressBarFill.innerText = 'Ошибка загрузки';
                        progressBarFill.style.width = '0%';
                    }
                };


                xhr.onerror = function() {
                    alert('Загрузка прервана или произошла ошибка.');
                    progressBarFill.innerText = 'Загрузка прервана';
                    progressBarFill.style.width = '0%';
                    uploadButton.disabled = false;
                    cancelUploadButton.style.display = 'none';
                };

                xhr.send(formData);

                cancelUploadButton.onclick = function() {
                    if (xhr) {
                        xhr.abort(); // Прерываем загрузку
                        uploadButton.disabled = false; // Возвращаем кнопку загрузки в активное состояние
                        cancelUploadButton.style.display = 'none'; // Скрываем кнопку остановки
                        progressBarFill.innerText = 'Загрузка отменена';
                        progressBarFill.style.width = '0%';
                    }
                };
            };

            scrollToBottom();
        </script>
    ''', output_files=output_files, is_running=is_running)

@app.route('/upload', methods=['POST'])
def upload():
    # Удаление старых файлов из папки reads
    if os.path.exists(READS_FOLDER):
        for old_file in os.listdir(READS_FOLDER):
            old_file_path = os.path.join(READS_FOLDER, old_file)
            if os.path.isfile(old_file_path):
                os.remove(old_file_path)
    else:
        os.makedirs(READS_FOLDER)

    # Сохранение загруженных файлов
    if 'reads_files' in request.files:
        uploaded_files = request.files.getlist('reads_files')
        for file in uploaded_files:
            filename = secure_filename(file.filename)
            file.save(os.path.join(READS_FOLDER, filename))
    return redirect(url_for('index'))

@app.route('/output/<path:path>')
def browse_output(path):
    full_path = os.path.join(OUTPUT_FOLDER, path)

    if os.path.isdir(full_path):
        # Если это папка, то отобразить список файлов и папок внутри
        files = os.listdir(full_path)
        return render_template_string('''
            <style>
            body { font-family: Arial, sans-serif; background-color: #cfd7f0; margin: 0; padding: 0; }
            h1 { background-color: #214168; color: white; padding: 10px; text-align: center; }
            .container { padding: 20px; max-width: 900px; margin: auto; }
            form { margin-bottom: 20px; }
            input, button { padding: 10px; margin: 5px 0; width: 100%; max-width: 300px; }
            button { font-size: 14px; background-color: #214168; color: white; border: none; cursor: pointer; border-radius: 5px;}
            .back-button { position: absolute; bottom: 50px; }
            </style>
            <h1>Просмотр {{ path }}</h1>
            <div class="container">
                <a href="{{ url_for('download_current', path=path) }}">
                    <button>Скачать текущую директорию</button>
                </a>
                <ul>
                    {% for file in files %}
                        <li><a href="{{ url_for('browse_output', path=path + '/' + file) }}">{{ file }}</a></li>
                    {% endfor %}
                </ul>
                <button class="back-button" onclick="history.back()">Назад</button>
            </div>
        ''', path=path, files=files)
    elif os.path.isfile(full_path):
        # Если это файл, то позволить его скачать
        return send_from_directory(OUTPUT_FOLDER, path)
    else:
        abort(404)

@app.route('/download_current/<path:path>')
def download_current(path):
    full_path = os.path.join(OUTPUT_FOLDER, path)
    zip_filename = f"{os.path.basename(full_path)}.zip"
    zip_path = os.path.join("/tmp", zip_filename)

    # Удаляем старый архив, если он существует
    if os.path.exists(zip_path):
        os.remove(zip_path)

    # Архивируем текущую директорию
    shutil.make_archive(zip_path.replace('.zip', ''), 'zip', full_path)

    # Отправляем архив пользователю
    return send_from_directory('/tmp', zip_filename, as_attachment=True)

@app.route('/download_all')
def download_all():
    # Путь к архиву
    zip_filename = "output.zip"
    zip_path = os.path.join("/tmp", zip_filename)

    # Удаляем старый архив, если он существует
    if os.path.exists(zip_path):
        os.remove(zip_path)

    # Архивируем папку OUTPUT_FOLDER
    shutil.make_archive(zip_path.replace('.zip', ''), 'zip', OUTPUT_FOLDER)

    # Отправляем архив пользователю
    return send_from_directory("/tmp", zip_filename, as_attachment=True)

@app.route('/status')
def status():
    is_running = nextflow_process is not None and nextflow_process.poll() is None
    return {'is_running': is_running}

@app.route('/run_nextflow', methods=['POST'])
def run_nextflow():
    global nextflow_process
    if nextflow_process is None or nextflow_process.poll() is not None:
        try:
            # Получение параметра launch_name
            launch_name = request.form.get('launch_name')
            if not launch_name:
                raise ValueError("Не указан параметр launch_name.")

            # Формирование команды Nextflow
            current_command = nextflow_command + ['--launch_name', launch_name]

            # Запуск Nextflow
            nextflow_process = subprocess.Popen(current_command, cwd=nextflow_path, stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)

            # Отправляем статус "Nextflow запущен" в консоль
            socketio.emit('console_output', {'output': 'Nextflow запущен'})
            socketio.emit('console_output', {'output': f'Nextflow запущен с параметром launch_name: {launch_name}'})

            # Запуск потока для чтения вывода Nextflow
            thread = Thread(target=stream_nextflow_output, args=(nextflow_process,))
            thread.start()

            socketio.start_background_task(target=monitor_output_folder)
            socketio.emit('nextflow_status', {'status': 'running', 'clear_console': True})
            return redirect(url_for('index'))

        except Exception as e:
            # Отправляем сообщение об ошибке в консоль
            socketio.emit('console_output', {'output': f'Ошибка при запуске Nextflow: {str(e)}'})
            socketio.emit('nextflow_status', {'status': 'error'})

            return redirect(url_for('index'))
    else:
        # Если процесс уже запущен
        socketio.emit('console_output', {'output': 'Nextflow уже запущен'})
    
    return redirect(url_for('index'))

@app.route('/stop_nextflow', methods=['POST'])
def stop_nextflow():
    global nextflow_process
    # if nextflow_process is not None:
    #     nextflow_process.terminate()
    #     nextflow_process = None

    # # Оповещение о завершении процесса
    # socketio.emit('console_output', {'output': 'Nextflow process terminated'})
    # socketio.emit('nextflow_status', {'status': 'stopped'})
    if nextflow_process and nextflow_process.poll() is None:
        try:
            nextflow_process.kill()  # Используем kill вместо terminate
            socketio.emit('console_output', {'output': 'Nextflow успешно остановлен'})
            socketio.emit('nextflow_status', {'status': 'stopped'})
        except Exception as e:
            socketio.emit('console_output', {'output': f'Ошибка при остановке Nextflow: {str(e)}'})
        finally:
            nextflow_process = None
                
    return redirect(url_for('index'))

if __name__ == '__main__':
    socketio.run(app, host='0.0.0.0', port=6532, allow_unsafe_werkzeug=True)
