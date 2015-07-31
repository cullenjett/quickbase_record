require 'yaml'
creds = YAML.load_file("spec/config.yml")

QuickbaseRecord.configure do |config|
  config.realm = "ais"
  config.username = creds["username"]
  config.password = creds["password"]
end