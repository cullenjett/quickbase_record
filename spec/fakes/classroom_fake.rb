require './lib/quickbase_record'

class ClassroomFake
  include QuickbaseRecord::Model

  # primary key is not record id
  define_fields ({
    dbid: 'bj4yju38j',
    date_created: 1,
    record_id: 3,
    id: 6,
    subject: 7
  })
end