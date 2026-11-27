# Автоматичний деплой Node.js на EC2

Практичне заняття 12. Terraform створює інстанс EC2, пару ключів і Security Group. GitHub Actions збирає застосунок Node.js, перевіряє роботу з PostgreSQL, публікує Docker-образ і розгортає його через Docker Compose.

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

## Створення інфраструктури

Потрібні Terraform, сеанс AWS із доступом до EC2 і стандартна VPC у регіоні, вибраному в `terraform/terraform.tfvars`. Конфігурація використовує Ubuntu 24.04 x86-64. Можна перевизначити AMI через `ami_id`. EC2 встановлює Docker і Compose під час першого запуску.

У PowerShell із кореня репозиторію створіть окрему пару ключів для деплою. Для використання ключа в GitHub Actions залиште парольну фразу порожньою. Terraform імпортує файл `.pub` і використовує ім’я `key_name` під час створення EC2.

```powershell
terraform -v
New-Item -ItemType Directory -Force .local | Out-Null
ssh-keygen -t ed25519 -C optima-devops-12 -f .local/optima-lab12
terraform -chdir=terraform init
terraform -chdir=terraform plan
terraform -chdir=terraform apply
terraform -chdir=terraform output -raw instance_ip
```

Security Group відкриває TCP 3000 для HTTP і TCP 22 для GitHub Actions. У навчальній конфігурації `ssh_cidr` дозволяє підключення зі змінних IP-адрес GitHub-hosted runners. Для runner зі сталою адресою значення можна обмежити його CIDR. Доступ до SSH здійснюється за ключем.

## GitHub Actions

У **Settings → Secrets and variables → Actions** задайте секрети `DOCKERHUB_USERNAME` і `DOCKERHUB_TOKEN` для публікації образу в Docker Hub. Для деплою задайте такі секрети.

| Секрет | Значення |
| --- | --- |
| `EC2_HOST` | Публічна IPv4-адреса з `terraform output -raw instance_ip` |
| `EC2_USER` | `ubuntu` для стандартного AMI |
| `EC2_SSH_KEY_B64` | Приватний ключ `.local/optima-lab12` у Base64. У PowerShell використайте `[Convert]::ToBase64String([IO.File]::ReadAllBytes((Resolve-Path .local/optima-lab12).Path))`. |
| `EC2_KNOWN_HOSTS` | Рядок `<IP> ssh-ed25519 <публічний ключ сервера>`. Візьміть `ssh-ed25519 <ключ>` із рядка `OPTIMA_ED25519_HOST_KEY` у системному журналі EC2. |

Після налаштування секретів додайте змінну репозиторію `OPTIMA_LAB12_DEPLOY_ENABLED` зі значенням `true`. Кожен push у `main` запускає збірку, публікує образ у Docker Hub із тегами `main` і SHA коміту, а тоді розгортає саме цей SHA на EC2. Для повторної перевірки доступний ручний запуск із позначкою **Deploy to EC2 after the Docker checks**.

На EC2 пароль PostgreSQL генерується при першому деплої. Пайплайн перевіряє сторінку `http://<instance_ip>:3000/` і відповідь `postgresql: ok` від `/healthz`.

## Видалення ресурсів

Після перевірки вимкніть автодеплой, видаливши змінну `OPTIMA_LAB12_DEPLOY_ENABLED` або встановивши `false`. Збережіть `instance_id` та `security_group_id` із `terraform output` і виконайте `terraform -chdir=terraform destroy`. У консолі AWS перевірте, що інстанс має статус `Terminated`, а Security Group видалена.
