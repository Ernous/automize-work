require "kemal"
require "dotenv"
require "db"
require "sqlite3"
require "http/client"
require "json"
require "bcrypt"

# Load environment variables
Dotenv.load

# Database setup
DB.open "sqlite3://./data/app.db" do |db|
  # Create tables if they don't exist
  db.exec "CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  )"
  
  db.exec "CREATE TABLE IF NOT EXISTS repositories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    url TEXT NOT NULL,
    provider TEXT NOT NULL,
    webhook_secret TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  )"
  
  db.exec "CREATE TABLE IF NOT EXISTS commits (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    repository_id INTEGER,
    commit_hash TEXT NOT NULL,
    author TEXT NOT NULL,
    message TEXT NOT NULL,
    description TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (repository_id) REFERENCES repositories (id)
  )"
  
  db.exec "CREATE TABLE IF NOT EXISTS telegram_posts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    commit_id INTEGER,
    post_text TEXT NOT NULL,
    sent_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (commit_id) REFERENCES commits (id)
  )"
end

# Require all modules
require "./models/*"
require "./services/*"
require "./controllers/*"
require "./views/*"

# Configure Kemal
Kemal.config.port = ENV["PORT"]?.try(&.to_i) || 3000
Kemal.config.host_binding = "0.0.0.0"

# Static file serving
public_folder "public"

# Session configuration
Kemal::Session.config do |config|
  config.secret = ENV["SESSION_SECRET"]? || "your-secret-key"
  config.gc_interval = 2.minutes
end

# Routes
get "/" do |env|
  if env.session.string?("user_id")
    env.redirect "/dashboard"
  else
    render "src/views/login.ecr"
  end
end

get "/login" do |env|
  render "src/views/login.ecr"
end

post "/login" do |env|
  username = env.params.body["username"]?
  password = env.params.body["password"]?
  
  if username && password
    user = User.find_by_username(username)
    if user && BCrypt::Password.new(user.password_hash).verify(password)
      env.session.string("user_id", user.id.to_s)
      env.redirect "/dashboard"
    else
      env.flash("error", "Invalid username or password")
      env.redirect "/login"
    end
  else
    env.flash("error", "Please provide username and password")
    env.redirect "/login"
  end
end

get "/register" do |env|
  render "src/views/register.ecr"
end

post "/register" do |env|
  username = env.params.body["username"]?
  password = env.params.body["password"]?
  confirm_password = env.params.body["confirm_password"]?
  
  if username && password && confirm_password
    if password == confirm_password
      begin
        password_hash = BCrypt::Password.create(password)
        user = User.create(username, password_hash)
        env.session.string("user_id", user.id.to_s)
        env.redirect "/setup"
      rescue ex
        env.flash("error", "Username already exists")
        env.redirect "/register"
      end
    else
      env.flash("error", "Passwords don't match")
      env.redirect "/register"
    end
  else
    env.flash("error", "Please fill all fields")
    env.redirect "/register"
  end
end

get "/setup" do |env|
  unless env.session.string?("user_id")
    env.redirect "/login"
  end
  render "src/views/setup.ecr"
end

post "/setup" do |env|
  unless env.session.string?("user_id")
    env.redirect "/login"
  end
  
  gemini_api_key = env.params.body["gemini_api_key"]?
  telegram_bot_token = env.params.body["telegram_bot_token"]?
  telegram_channel_id = env.params.body["telegram_channel_id"]?
  
  if gemini_api_key && telegram_bot_token && telegram_channel_id
    # Save configuration
    ConfigService.save_config({
      "GEMINI_API_KEY" => gemini_api_key,
      "TELEGRAM_BOT_TOKEN" => telegram_bot_token,
      "TELEGRAM_CHANNEL_ID" => telegram_channel_id
    })
    env.redirect "/dashboard"
  else
    env.flash("error", "Please fill all required fields")
    env.redirect "/setup"
  end
end

get "/dashboard" do |env|
  unless env.session.string?("user_id")
    env.redirect "/login"
  end
  
  repositories = Repository.all
  render "src/views/dashboard.ecr"
end

get "/repositories" do |env|
  unless env.session.string?("user_id")
    env.redirect "/login"
  end
  
  repositories = Repository.all
  render "src/views/repositories.ecr"
end

post "/repositories" do |env|
  unless env.session.string?("user_id")
    env.redirect "/login"
  end
  
  name = env.params.body["name"]?
  url = env.params.body["url"]?
  provider = env.params.body["provider"]?
  
  if name && url && provider
    repository = Repository.create(name, url, provider)
    env.flash("success", "Repository added successfully")
  else
    env.flash("error", "Please fill all fields")
  end
  
  env.redirect "/repositories"
end

# Webhook endpoint for GitLab/Forgejo
post "/webhook/:provider" do |env|
  provider = env.params.url["provider"]
  payload = env.request.body.try(&.get_to_end)
  
  if payload
    begin
      json = JSON.parse(payload)
      CommitService.process_webhook(provider, json)
      env.response.status_code = 200
      env.response.print "OK"
    rescue ex
      env.response.status_code = 400
      env.response.print "Bad Request"
    end
  else
    env.response.status_code = 400
    env.response.print "No payload"
  end
end

get "/logout" do |env|
  env.session.destroy
  env.redirect "/"
end

# Start the server
Kemal.run