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
    # Сначала проверяем переменные окружения
    env_value = ENV[key]?
    return env_value if env_value
    
    # Затем проверяем .env файл
    load_config[key]?
  end

  def self.is_configured? : Bool
    gemini_key = get_config_value("GEMINI_API_KEY")
    telegram_token = get_config_value("TELEGRAM_BOT_TOKEN")
    telegram_channel = get_config_value("TELEGRAM_CHANNEL_ID")
    
    !gemini_key.nil? && !telegram_token.nil? && !telegram_channel.nil?
  end

  def self.get_missing_configs : Array(String)
    missing = [] of String
    
    missing << "GEMINI_API_KEY" if get_config_value("GEMINI_API_KEY").nil?
    missing << "TELEGRAM_BOT_TOKEN" if get_config_value("TELEGRAM_BOT_TOKEN").nil?
    missing << "TELEGRAM_CHANNEL_ID" if get_config_value("TELEGRAM_CHANNEL_ID").nil?
    
    missing
  end

  def self.has_any_config : Bool
    File.exists?(CONFIG_FILE) || 
    !ENV["GEMINI_API_KEY"]?.nil? || 
    !ENV["TELEGRAM_BOT_TOKEN"]?.nil? || 
    !ENV["TELEGRAM_CHANNEL_ID"]?.nil?
  end
end