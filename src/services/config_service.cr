class ConfigService
  CONFIG_FILE = ".env"

  def self.save_config(config : Hash(String, String))
    File.open(CONFIG_FILE, "w") do |file|
      config.each do |key, value|
        file.puts "#{key}=#{value}"
      end
    end
  end

  def self.load_config : Hash(String, String)
    config = {} of String => String
    
    if File.exists?(CONFIG_FILE)
      File.each_line(CONFIG_FILE) do |line|
        line = line.strip
        next if line.empty? || line.starts_with?("#")
        
        if line.includes?("=")
          key, value = line.split("=", 2)
          config[key.strip] = value.strip
        end
      end
    end
    
    config
  end

  def self.get_config_value(key : String) : String?
    load_config[key]?
  end

  def self.is_configured? : Bool
    gemini_key = ENV["GEMINI_API_KEY"]?
    telegram_token = ENV["TELEGRAM_BOT_TOKEN"]?
    telegram_channel = ENV["TELEGRAM_CHANNEL_ID"]?
    
    !gemini_key.nil? && !telegram_token.nil? && !telegram_channel.nil?
  end
end