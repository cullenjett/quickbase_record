require './lib/quickbase_record'

class TeacherFake
  include QuickbaseRecord::Model

  define_fields do |t|
    t.dbid "bjzrx8cjn"
    t.number :id, 3, :primary_key, :read_only
    t.string :name, 6
    t.string :subject, 7
    t.number :salary, 8
    t.file_attachment :attachment, 9
  end
end