class Commit
  property id : Int32?
  property repository_id : Int32
  property commit_hash : String
  property author : String
  property message : String
  property description : String?
  property created_at : Time?

  def initialize(@id, @repository_id, @commit_hash, @author, @message, @description = nil, @created_at = nil)
  end

  def self.create(repository_id : Int32, commit_hash : String, author : String, message : String, description : String? = nil) : Commit
    DB.connect "sqlite3://./data/app.db" do |db|
      result = db.exec "INSERT INTO commits (repository_id, commit_hash, author, message, description) VALUES (?, ?, ?, ?, ?)", 
        repository_id, commit_hash, author, message, description
      id = result.last_insert_id.to_i32
      Commit.new(id, repository_id, commit_hash, author, message, description, Time.utc)
    end
  end

  def self.all : Array(Commit)
    commits = [] of Commit
    DB.connect "sqlite3://./data/app.db" do |db|
      db.query "SELECT id, repository_id, commit_hash, author, message, description, created_at FROM commits ORDER BY created_at DESC" do |rs|
        rs.each do
          commits << Commit.new(
            rs.read(Int32),
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
    commits
  end

  def self.find_by_repository(repository_id : Int32) : Array(Commit)
    commits = [] of Commit
    DB.connect "sqlite3://./data/app.db" do |db|
      db.query "SELECT id, repository_id, commit_hash, author, message, description, created_at FROM commits WHERE repository_id = ? ORDER BY created_at DESC", repository_id do |rs|
        rs.each do
          commits << Commit.new(
            rs.read(Int32),
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
    commits
  end

  def self.find_by_hash(commit_hash : String) : Commit?
    DB.connect "sqlite3://./data/app.db" do |db|
      db.query_one? "SELECT id, repository_id, commit_hash, author, message, description, created_at FROM commits WHERE commit_hash = ?", commit_hash do |rs|
        Commit.new(
          rs.read(Int32),
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

  def repository : Repository?
    Repository.find_by_id(@repository_id)
  end
end