class User
  property id : Int32?
  property username : String
  property password_hash : String
  property created_at : Time?

  def initialize(@id, @username, @password_hash, @created_at = nil)
  end

  def self.create(username : String, password_hash : String) : User
    DB.connect "sqlite3://./data/app.db" do |db|
      result = db.exec "INSERT INTO users (username, password_hash) VALUES (?, ?)", username, password_hash
      id = result.last_insert_id.to_i32
      User.new(id, username, password_hash, Time.utc)
    end
  end

  def self.find_by_username(username : String) : User?
    DB.connect "sqlite3://./data/app.db" do |db|
      db.query_one? "SELECT id, username, password_hash, created_at FROM users WHERE username = ?", username do |rs|
        User.new(
          rs.read(Int32),
          rs.read(String),
          rs.read(String),
          rs.read(Time?)
        )
      end
    end
  end

  def self.find_by_id(id : Int32) : User?
    DB.connect "sqlite3://./data/app.db" do |db|
      db.query_one? "SELECT id, username, password_hash, created_at FROM users WHERE id = ?", id do |rs|
        User.new(
          rs.read(Int32),
          rs.read(String),
          rs.read(String),
          rs.read(Time?)
        )
      end
    end
  end
end