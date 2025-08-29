# Git Commit Telegram Bot

Автоматический сервис для создания постов в Telegram на основе коммитов из GitLab/Forgejo репозиториев с использованием Google Gemini AI.

## Возможности

- 🔐 Авторизация пользователей с защищенными паролями
- 🔗 Поддержка GitLab и Forgejo/Gitea
- 🤖 Автоматическая генерация постов с помощью Google Gemini 2.5 Pro
- 📱 Отправка постов в Telegram канал
- 🎨 Современный веб-интерфейс
- 📊 Дашборд с статистикой
- 🚀 Готов к деплою на Render

## Технологии

- **Backend**: Crystal Language
- **Web Framework**: Kemal
- **Database**: SQLite
- **AI**: Google Gemini API
- **Messaging**: Telegram Bot API
- **Frontend**: Bootstrap 5 + Font Awesome
- **Deployment**: Docker + Render

## Установка и запуск

### Локальная разработка

1. Установите Crystal Language:
   ```bash
   # Ubuntu/Debian
   curl -fsSL https://crystal-lang.org/install.sh | sudo bash
   
   # macOS
   brew install crystal-lang
   ```

2. Клонируйте репозиторий:
   ```bash
   git clone <repository-url>
   cd git-commit-telegram-bot
   ```

3. Установите зависимости:
   ```bash
   shards install
   ```

4. Запустите приложение:
   ```bash
   crystal run src/git_commit_telegram_bot.cr
   ```

5. При первом запуске откроется страница настройки, где вы сможете:
   - Настроить API ключи (Gemini, Telegram)
   - Создать первого пользователя-администратора
   - Все настройки автоматически сохранятся в файл `.env`

**Примечание:** Файл `.env` создается автоматически при первой настройке. Если вы хотите использовать переменные окружения напрямую, можете создать файл `.env` вручную или установить переменные окружения в системе.

### Деплой на Render

1. Создайте аккаунт на [Render](https://render.com)

2. Подключите ваш Git репозиторий

3. Создайте новый Web Service

4. Настройте переменные окружения:
   - `GEMINI_API_KEY` - ваш API ключ Gemini
   - `TELEGRAM_BOT_TOKEN` - токен Telegram бота
   - `TELEGRAM_CHANNEL_ID` - ID канала Telegram
   - `SESSION_SECRET` - секретный ключ для сессий

5. Деплой автоматически запустится

## Настройка

### 1. Создание Telegram бота

1. Найдите [@BotFather](https://t.me/botfather) в Telegram
2. Отправьте команду `/newbot`
3. Следуйте инструкциям для создания бота
4. Сохраните полученный токен

### 2. Добавление бота в канал

1. Создайте канал в Telegram
2. Добавьте бота как администратора канала
3. Получите ID канала (обычно начинается с `-100`)

### 3. Получение API ключа Gemini

1. Перейдите в [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Создайте новый API ключ
3. Скопируйте ключ

### 4. Настройка вебхуков

Для каждого репозитория настройте вебхук:

**GitLab:**
- URL: `https://your-app.onrender.com/webhook/gitlab`
- События: Push events

**Forgejo/Gitea:**
- URL: `https://your-app.onrender.com/webhook/forgejo`
- События: Push events

## Структура проекта

```
├── src/
│   ├── models/          # Модели данных
│   ├── services/        # Бизнес-логика
│   ├── views/           # HTML шаблоны
│   └── git_commit_telegram_bot.cr  # Главный файл
├── public/              # Статические файлы
├── config/              # Конфигурация
├── Dockerfile           # Docker конфигурация
├── render.yaml          # Render конфигурация
└── shard.yml           # Зависимости Crystal
```

## API Endpoints

- `GET /` - Главная страница (редирект на дашборд, логин или первоначальную настройку)
- `GET /first-time-setup` - Первоначальная настройка приложения (без авторизации)
- `POST /first-time-setup` - Сохранение первоначальной настройки
- `GET /login` - Страница входа
- `POST /login` - Авторизация
- `GET /register` - Страница регистрации
- `POST /register` - Регистрация пользователя
- `GET /setup` - Настройка API ключей (требует авторизации)
- `POST /setup` - Сохранение настроек
- `GET /dashboard` - Главный дашборд
- `GET /repositories` - Управление репозиториями
- `POST /repositories` - Добавление репозитория
- `POST /webhook/:provider` - Вебхук для GitLab/Forgejo
- `GET /logout` - Выход из системы

## Безопасность

- Пароли хешируются с помощью BCrypt
- Сессии защищены секретным ключом
- API ключи хранятся в переменных окружения
- Валидация входных данных

## Лицензия

MIT License

## Поддержка

Если у вас есть вопросы или проблемы, создайте issue в репозитории.