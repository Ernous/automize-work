class GeminiService
  GEMINI_API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent"

  def self.generate_post(commit_data : Hash(String, String)) : String?
    api_key = ENV["GEMINI_API_KEY"]?
    return nil unless api_key

    prompt = build_prompt(commit_data)
    
    request_body = {
      "contents" => [
        {
          "parts" => [
            {
              "text" => prompt
            }
          ]
        }
      ],
      "generationConfig" => {
        "temperature" => 0.7,
        "topK" => 40,
        "topP" => 0.95,
        "maxOutputTokens" => 1024
      }
    }

    begin
      response = HTTP::Client.post(
        "#{GEMINI_API_URL}?key=#{api_key}",
        headers: HTTP::Headers{
          "Content-Type" => "application/json"
        },
        body: request_body.to_json
      )

      if response.success?
        json = JSON.parse(response.body)
        candidates = json["candidates"]?
        if candidates && candidates.as_a.size > 0
          content = candidates[0]["content"]?
          if content
            parts = content["parts"]?
            if parts && parts.as_a.size > 0
              return parts[0]["text"]?.try(&.as_s)
            end
          end
        end
      end
    rescue ex
      puts "Error calling Gemini API: #{ex.message}"
    end

    nil
  end

  private def self.build_prompt(commit_data : Hash(String, String)) : String
    repository_name = commit_data["repository_name"]? || "Unknown"
    commit_hash = commit_data["commit_hash"]? || "Unknown"
    author = commit_data["author"]? || "Unknown"
    message = commit_data["message"]? || "No message"
    description = commit_data["description"]? || ""

    <<-PROMPT
    Создай интересный пост для Telegram канала о новом коммите в репозитории. 
    
    Информация о коммите:
    - Репозиторий: #{repository_name}
    - Хеш коммита: #{commit_hash}
    - Автор: #{author}
    - Сообщение коммита: #{message}
    #{description.empty? ? "" : "- Описание: #{description}"}
    
    Требования к посту:
    1. Используй эмодзи для привлечения внимания
    2. Сделай текст интересным и понятным для разработчиков
    3. Добавь хештеги: #разработка #коммит #обновления
    4. Длина поста должна быть 2-4 предложения
    5. Используй неформальный, дружелюбный тон
    6. Если в сообщении коммита есть технические детали, объясни их простыми словами
    
    Создай только текст поста без дополнительных комментариев.
    PROMPT
  end
end