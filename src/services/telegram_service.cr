class TelegramService
  TELEGRAM_API_URL = "https://api.telegram.org/bot"

  def self.send_message(text : String) : Bool
    bot_token = ENV["TELEGRAM_BOT_TOKEN"]?
    channel_id = ENV["TELEGRAM_CHANNEL_ID"]?
    
    return false unless bot_token && channel_id

    begin
      response = HTTP::Client.post(
        "#{TELEGRAM_API_URL}#{bot_token}/sendMessage",
        headers: HTTP::Headers{
          "Content-Type" => "application/json"
        },
        body: {
          "chat_id" => channel_id,
          "text" => text,
          "parse_mode" => "HTML"
        }.to_json
      )

      if response.success?
        json = JSON.parse(response.body)
        return json["ok"]?.try(&.as_bool) || false
      end
    rescue ex
      puts "Error sending Telegram message: #{ex.message}"
    end

    false
  end

  def self.get_bot_info : Hash(String, String)?
    bot_token = ENV["TELEGRAM_BOT_TOKEN"]?
    return nil unless bot_token

    begin
      response = HTTP::Client.get("#{TELEGRAM_API_URL}#{bot_token}/getMe")
      
      if response.success?
        json = JSON.parse(response.body)
        if json["ok"]?.try(&.as_bool) == true
          result = json["result"]?
          if result
            return {
              "id" => result["id"]?.try(&.to_s) || "",
              "username" => result["username"]?.try(&.as_s) || "",
              "first_name" => result["first_name"]?.try(&.as_s) || ""
            }
          end
        end
      end
    rescue ex
      puts "Error getting bot info: #{ex.message}"
    end

    nil
  end

  def self.test_connection : Bool
    bot_info = get_bot_info
    return false unless bot_info

    # Try to send a test message
    test_message = "🤖 <b>Тест подключения</b>\n\nБот успешно подключен к каналу! ✅"
    send_message(test_message)
  end
end