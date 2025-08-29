class CommitService
  def self.process_webhook(provider : String, payload : JSON::Any)
    case provider
    when "gitlab"
      process_gitlab_webhook(payload)
    when "forgejo"
      process_forgejo_webhook(payload)
    else
      puts "Unknown provider: #{provider}"
    end
  end

  private def self.process_gitlab_webhook(payload : JSON::Any)
    object_kind = payload["object_kind"]?.try(&.as_s)
    
    if object_kind == "push"
      commits = payload["commits"]?.try(&.as_a) || [] of JSON::Any
      project = payload["project"]?
      project_name = project["name"]?.try(&.as_s) || "Unknown"
      
      commits.each do |commit_data|
        process_commit(commit_data, project_name, "gitlab")
      end
    end
  end

  private def self.process_forgejo_webhook(payload : JSON::Any)
    # Forgejo/Gitea webhook structure is similar to GitLab
    object_kind = payload["object_kind"]?.try(&.as_s)
    
    if object_kind == "push"
      commits = payload["commits"]?.try(&.as_a) || [] of JSON::Any
      repository = payload["repository"]?
      repo_name = repository["name"]?.try(&.as_s) || "Unknown"
      
      commits.each do |commit_data|
        process_commit(commit_data, repo_name, "forgejo")
      end
    end
  end

  private def self.process_commit(commit_data : JSON::Any, repository_name : String, provider : String)
    commit_hash = commit_data["id"]?.try(&.as_s) || ""
    author_name = commit_data["author"]?["name"]?.try(&.as_s) || "Unknown"
    message = commit_data["message"]?.try(&.as_s) || ""
    
    # Find repository by name and provider
    repository = find_repository_by_name_and_provider(repository_name, provider)
    return unless repository

    # Check if commit already exists
    existing_commit = Commit.find_by_hash(commit_hash)
    return if existing_commit

    # Create commit record
    commit = Commit.create(
      repository_id: repository.id.not_nil!,
      commit_hash: commit_hash,
      author: author_name,
      message: message
    )

    # Generate post content using Gemini
    commit_data_hash = {
      "repository_name" => repository_name,
      "commit_hash" => commit_hash,
      "author" => author_name,
      "message" => message
    }

    post_text = GeminiService.generate_post(commit_data_hash)
    return unless post_text

    # Send to Telegram
    if TelegramService.send_message(post_text)
      # Save telegram post record
      save_telegram_post(commit.id.not_nil!, post_text)
      puts "Successfully processed commit #{commit_hash} for repository #{repository_name}"
    else
      puts "Failed to send Telegram message for commit #{commit_hash}"
    end
  end

  private def self.find_repository_by_name_and_provider(name : String, provider : String) : Repository?
    repositories = Repository.find_by_provider(provider)
    repositories.find { |repo| repo.name.downcase == name.downcase }
  end

  private def self.save_telegram_post(commit_id : Int32, post_text : String)
    DB.connect "sqlite3://./data/app.db" do |db|
      db.exec "INSERT INTO telegram_posts (commit_id, post_text) VALUES (?, ?)", commit_id, post_text
    end
  end
end