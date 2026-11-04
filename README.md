Контейнеризація Node.js на EC2
Практичне заняття 9. Dockerfile збирає HTML командою npm run build і запускає HTTP-сервер на порту 3000.
GitHub Actions публікує образ у відкритому репозиторії Docker Hub bondarenko-node-ci з тегами гілки та коміту. EC2 завантажує образ за тегом коміту, замінює контейнер nodeapp і перевіряє HTTP-відповідь.
Потрібні секрети GitHub: DOCKERHUB_USERNAME, DOCKERHUB_TOKEN, EC2_HOST, EC2_USER, EC2_SSH_KEY_B64, EC2_KNOWN_HOSTS. На EC2 потрібні Docker, curl і доступ через SSH для виконавця GitHub Actions. Порт 3000 опубліковано лише на локальній адресі EC2.
Перевірка на EC2: sudo docker ps та curl -fsS http://127.0.0.1:3000/.
