QuickbaseRecord.configure do |config|
  config.realm = "ais"
  config.username = ENV["QB_USERNAME"]
  config.password = ENV["QB_PASSWORD"]
end