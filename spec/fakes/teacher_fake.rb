require './lib/quickbase_record'

QuickbaseRecord.configure do |config|
  config.realm = "ais"
  config.username = ENV["QB_USERNAME"]
  config.password = ENV["QB_PASSWORD"]
end

class TeacherFake
  include QuickbaseRecord::Model

  define_fields do
    {
      dbid: "bjzrx8cjn",
      id: 3,
      name: 6,
      subject: 7,
      salary: 8
    }
  end
end