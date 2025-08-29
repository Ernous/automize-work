class Repository
  property id : Int32?
  property name : String
  property url : String
  property provider : String
  property webhook_secret : String?
  property created_at : Time?

  def initialize(@id, @name, @url, @provider, @webhook_secret = nil, @created_at = nil)
  end

  def self.create(name : String, url : String, provider : String, webhook_secret : String? = nil) : Repository
    DB.connect "sqlite3://./data/app.db" do |db|
      result = db.exec "INSERT INTO repositories (name, url, provider, webhook_secret) VALUES (?, ?, ?, ?)", 
        name, url, provider, webhook_secret
      id = result.last_insert_id.to_i32
      Repository.new(id, name, url, provider, webhook_secret, Time.utc)
    end
  end

  def self.all : Array(Repository)
    repositories = [] of Repository
    DB.connect "sqlite3://./data/app.db" do |db|
      db.query "SELECT id, name, url, provider, webhook_secret, created_at FROM repositories ORDER BY created_at DESC" do |rs|
        rs.each do
          repositories << Repository.new(
            rs.read(Int32),
            rs.read(String),
            rs.read(String),
            rs.read(String),
            rs.read(String?),
            rs.read(Time?)
          )
        end
      end
    end
    repositories
  end

  def self.find_by_id(id : Int32) : Repository?
    DB.connect "sqlite3://./data/app.db" do |db|
      db.query_one? "SELECT id, name, url, provider, webhook_secret, created_at FROM repositories WHERE id = ?", id do |rs|
        Repository.new(
          rs.read(Int32),
          rs.read(String),
          rs.read(String),
          rs.read(String),
          rs.read(String?),
          rs.read(Time?)
        )
      end
    end
  end

  def self.find_by_provider(provider : String) : Array(Repository)
    repositories = [] of Repository
    DB.connect "sqlite3://./data/app.db" do |db|
      db.query "SELECT id, name, url, provider, webhook_secret, created_at FROM repositories WHERE provider = ?", provider do |rs|
        rs.each do
          repositories << Repository.new(
            rs.read(Int32),
            rs.read(String),
            rs.read(String),
            rs.read(String),
            rs.read(String?),
            rs.read(Time?)
          )
        end
      end
    end
    repositories
  end
end