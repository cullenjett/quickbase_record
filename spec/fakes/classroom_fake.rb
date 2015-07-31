require './lib/quickbase_record'

class ClassroomFake
  include QuickbaseRecord::Model

  # primary key is not record id
  define_fields do |t|
    t.dbid 'bj4yju38j'
    t.date :date_created, 1, :read_only
    t.number :record_id, 3, :read_only
    t.number :id, 6, :primary_key
    t.string :subject, 7
    t.string :subject_plus_room, 8, :read_only
  end
end