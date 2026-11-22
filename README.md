# Контейнеризація Node.js на EC2

Практичне заняття 9. Dockerfile використовує офіційний образ `node:lts`, установлює залежності через `npm install` і збирає сторінку командою `npm run build`. Файл `.dockerignore` виключає `node_modules`, `.env` та інші локальні файли зі збірки.

## Локальний запуск

Створіть локальний файл `.env` із записом `POSTGRES_PASSWORD=<ваш випадковий пароль>`. Зберігайте цей файл лише локально.

```sh
docker compose up -d --build --wait
docker compose ps
docker compose logs app
curl -fsS http://127.0.0.1:3000/
curl -fsS http://127.0.0.1:3000/healthz
docker compose down
```

Compose збирає сервіс `app` із Dockerfile та очікує готовності `db` з образом `postgres:15`. Дані PostgreSQL зберігаються в томі `postgres-data`. Застосунок виконує SQL-запит під час запуску й пише `Connected to PostgreSQL` у лог. Маршрут `/healthz` перевіряє з’єднання з базою. Вебсторінка доступна на хості через порт 3000, а PostgreSQL доступний у мережі Compose.

## GitHub Actions та EC2

Після push у `main` GitHub Actions перевіряє збірку Node.js і зберігає артефакт `node-build`. Наступна задача збирає Docker-образ, запускає обидва сервіси для перевірки й публікує образ у Docker Hub з тегами гілки та коміту.

Деплой запускається через **Actions → Node.js CI and Docker deployment → Run workflow** у гілці `main` із позначкою **Deploy to EC2 after the Docker checks**. Потрібні секрети `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN`, `EC2_HOST`, `EC2_USER`, `EC2_SSH_KEY_B64` та `EC2_KNOWN_HOSTS`. На EC2 потрібні Docker, плагін Docker Compose, curl і доступ через SSH для GitHub Actions.

Пайплайн передає файл Compose на EC2, задає `IMAGE_TAG` рівним SHA коміту й завантажує готовий образ із Docker Hub. Пароль PostgreSQL генерується на EC2 під час першого деплою та зберігається локально поруч із файлом Compose. Після запуску пайплайн перевіряє головну сторінку та готовність PostgreSQL.
