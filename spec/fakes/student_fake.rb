require './lib/quickbase_record'

class StudentFake
  include QuickbaseRecord::Model

  StudentFake.define_fields ({
    :dbid => 'bjzrx8ckw',
    :id => 3,
    :name => 6,
    :grade => 7,
    :email => 8
  })
end