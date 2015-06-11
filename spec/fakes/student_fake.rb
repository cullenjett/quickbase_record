require './lib/quickbase_record'

QuickbaseRecord.configure do |config|
  config.realm = "ais"
  config.username = ENV["QB_USERNAME"]
  config.password = ENV["QB_PASSWORD"]
end

class StudentFake
  include QuickbaseRecord::Model

  define_fields do
    {
      dbid: 'bjzrx8ckw',
      id: 3,
      name: 6,
      grade: 7,
      email: 8
    }
  end
end