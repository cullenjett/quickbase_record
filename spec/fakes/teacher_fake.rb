require './lib/quickbase_record'

class TeacherFake
  include QuickbaseRecord::Model

  define_fields ({
    :dbid => "bjzrx8cjn",
    :id => 3,
    :name => 6,
    :subject => 7,
    :salary => 8
  })

end