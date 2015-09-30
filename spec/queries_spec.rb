require './spec/fakes/teacher_fake'
require './spec/fakes/classroom_fake'

RSpec.describe QuickbaseRecord::Queries do
  describe '.find' do
    it "calls do_query with the right arguments" do
      expect(TeacherFake).to receive(:do_query)
      TeacherFake.find(1)
    end

    it "finds a single Teacher given an ID" do
      teacher = TeacherFake.find(1)
      expect(teacher.id).to eq(1)
    end

    it "returns an object of the Teacher class" do
      teacher = TeacherFake.find(1)
      expect(teacher).to be_a TeacherFake
    end

    it "returns nil if no QuickBase records are found" do
      teacher = TeacherFake.find(999999)
      expect(teacher).to eq(nil)
    end

    it "accepts query options" do
      teacher = TeacherFake.find(1, query_options: {clist: 'id'})
      expect(teacher.name).to be_nil
    end
  end

  describe '.where' do
    it "returns an array of objects" do
      teachers = TeacherFake.where(id: 1)
      expect(teachers).to be_a Array
    end

    it "returns an object of the Teacher class" do
      teachers = TeacherFake.where(id: 1)
      expect(teachers.first).to be_a TeacherFake
    end

    it "accepts a string in QuickBase query format" do
      teachers = TeacherFake.where("{'3'.EX.'1'}")
      expect(teachers.first.id).to eq(1)
    end

    it "accepts a string in QuickBase query format using field names" do
      teachers = TeacherFake.where("{'id'.EX.'1'}")
      expect(teachers.first.id).to eq(1)
    end

    it "returns an empty array if no QuickBase records are found" do
      teachers = TeacherFake.where(name: 'Not a real TeacherFake name...')
      expect(teachers).to eq([])
    end

    it "accepts query options" do
      teachers = TeacherFake.where(subject: ['Biology', 'Gym'], query_options: {slist: 'subject', options: 'sortorder-D'})
      expect(teachers.first.subject).to eq('Gym')
    end

    it "accepts modified clists" do
      teachers = TeacherFake.where(id: {XEX: ''}, query_options: {clist: 'id.salary'})
      expect(teachers.first.id).to be_present
      expect(teachers.first.subject).not_to be_present
    end
  end

  describe '.create' do
    it "saves the object immediately" do
      teacher = TeacherFake.create(name: 'Professor Dumbledore')
      expect(teacher.id.to_i).to be > 1
      teacher.delete
    end
  end

  describe '.qid' do
    it "returns an array of objects" do
      teachers = TeacherFake.qid(1)
      expect(teachers).to be_a Array
    end

    it "returns an object of the Teacher class" do
      teachers = TeacherFake.qid(1)
      expect(teachers.first).to be_a TeacherFake
    end
  end

  describe '.build_quickbase_request' do
    it "converts an object to a hash of fid: value" do
      teacher = TeacherFake.new(name: 'Mrs. Buttersworth', subject: 'Buttering')
      expect(TeacherFake.build_quickbase_request(teacher)).to eq({6 => 'Mrs. Buttersworth', 7 => 'Buttering'})
    end
  end

  describe '.save_collection' do
    it "does something" do
      teacher1 = TeacherFake.new(name: 'Save collection teacher 1')
      teacher2 = TeacherFake.new(name: 'Save collection teacher 2')
      expect(TeacherFake.save_collection([teacher1, teacher2])).to be_truthy
    end
  end

  describe '.purge_records' do
    it "deletes all matching query records" do
      teacher1 = TeacherFake.create(name: 'I should be deleted')
      TeacherFake.purge_records(name: teacher1.name)
      expect(TeacherFake.find(teacher1.id)).to be_nil
    end

    it "accepts a QID" do
      teacher1 = TeacherFake.create(name: 'Purge McSplurge')
      expect(TeacherFake.qid(5).length).to eq(1)
      TeacherFake.purge_records(5)
      expect(TeacherFake.qid(5)).to eq([])
    end
  end

  describe '#save' do
    it "doesn't save :read_only fields" do
      classroom = ClassroomFake.find(101)
      classroom.assign_attributes(subject_plus_room: "this shouldn't save")
      classroom.save
      expect(ClassroomFake.find(101).subject_plus_room).not_to eq("this shouldn't save")
    end

    context "when record ID is the primary key" do
      it "creates a new record in QuickBase for an object without an ID and sets it's new ID" do
        cullen = TeacherFake.new(name: 'Cullen Jett', salary: '1,000,000.00')
        cullen.save
        expect(cullen.id).to be_truthy
      end

      it "returns the object on successful save" do
        cullen = TeacherFake.where(name: 'Cullen Jett').first
        expect(cullen.save).to be_a TeacherFake
      end

      it "edits an object that has an existing ID" do
        cullen = TeacherFake.where(name: 'Cullen Jett').first
        cullen.subject = 'Ruby on Rails'
        cullen.name = "THE #{cullen.name}"
        expect(cullen.save.id).to be_truthy
      end

      it "uploads files" do
        cullen = TeacherFake.where(name: 'THE Cullen Jett').first
        cullen.attachment = {name: 'Test Attachment', file: 'LICENSE.txt'}
        cullen.save
        cullen = TeacherFake.find(cullen.id)
        expect(cullen.attachment[:filename]).to eq('Test Attachment')
        cullen.delete
      end
    end

    context "when record ID is not the primary key" do
      it "creates a new record if the object doesn't have a record ID" do
        math = ClassroomFake.new(id: 1, subject: 'Math')
        math.save
        expect(ClassroomFake.find(1)).not_to be_nil
        math.delete
      end

      it "sets the object's record id for new records" do
        english = ClassroomFake.new(id: 2, subject: 'English', date_created: 'this should not save')
        english.save
        expect(english.record_id).to be_present
        expect(english.record_id).not_to eq(2)
        english.delete
      end

      it "edits a record if it has a record ID" do
        science = ClassroomFake.find(101)
        science.subject = 'SCIENCE!'
        science.save
        expect(science.subject).to eq('SCIENCE!')
        science.update_attributes(subject: 'Science')
      end
    end
  end

  describe '#delete' do
    context "when record ID is the primary key" do
      it "deletes an object from QuickBase" do
        socrates = TeacherFake.new(name: 'Socrates')
        socrates.save
        expect(socrates.delete).to eq(socrates)
      end

      it "returns false if the object doesn't yet have an ID" do
        expect(TeacherFake.new(name: 'Socrates').delete).to be false
      end
    end

    context "when record ID is not the primary key" do
      it "deletes the record from QuickBase" do
        gym = ClassroomFake.new(id: 3, subject: 'Gym')
        gym.save
        expect(gym.delete).to eq(gym)
      end
    end
  end

  describe '#assign_attributes' do
    it "assigns an objects attributes given a hash attributes and their values" do
      teacher = TeacherFake.new(name: 'teacher1', salary: 35000)
      teacher.assign_attributes(name: 'teacher2', salary: 40000)
      expect(teacher.name).to eq('teacher2')
      expect(teacher.salary).to eq(40000)
    end

    it "doesn't save the object" do
      teacher = TeacherFake.new(name: 'teacher1', salary: 35000)
      teacher.assign_attributes(name: 'teacher2', salary: 40000)
      expect(teacher.id).to be_falsey
    end
  end

  describe '#update_attributes' do
    it "assigns an objects attributes given a hash of attributes" do
      teacher = TeacherFake.new(name: 'teacher1', salary: 35000)
      teacher.update_attributes(name: 'teacher2', salary: 40000)
      expect(teacher.name).to eq('teacher2')
      expect(teacher.salary).to eq(40000)
      teacher.delete
    end

    it "saves the object" do
      teacher = TeacherFake.new(name: 'teacher1', salary: 35000)
      teacher.update_attributes(name: 'teacher2', salary: 40000)
      expect(teacher.id).to be_truthy
      teacher.delete
    end

    it "returns false if no attributes are passed" do
      teacher = TeacherFake.new()
      teacher.update_attributes()
      expect(teacher.update_attributes()).to be false
    end

    it "doesn't save :read_only attributes" do
      classroom = ClassroomFake.find(101)
      classroom.update_attributes(subject_plus_room: "this shouldn't save")
      expect(ClassroomFake.find(101).subject_plus_room).not_to eq("this shouldn't save")
    end
  end

  # This is sort of a private method, but it seems pretty important so I'm keeping these tests.
  # It could probably stand to be extracted into a separate class...
  describe '.build_query' do
    it "converts a hash into QuickBase query format with EX as the default comparitor" do
      hash = {id: 1}
      expect(TeacherFake.build_query(hash)).to eq("{'3'.EX.'1'}")
    end

    it "combines multiple key/value pairs with AND" do
      hash = {id: 1, name: 'Mrs. Brown'}
      expect(TeacherFake.build_query(hash)).to eq("{'3'.EX.'1'}AND{'6'.EX.'Mrs. Brown'}")
    end

    it "combines values that are arrays with OR" do
      hash = {id: [1, 2]}
      expect(TeacherFake.build_query(hash)).to eq("{'3'.EX.'1'}OR{'3'.EX.'2'}")
    end

    it "combines an all array query with OR" do
      hash = [{id: 1, name: 'Cullen Jett'}]
      expect(TeacherFake.build_query(hash)).to eq("{'3'.EX.'1'}OR{'6'.EX.'Cullen Jett'}")
    end

    it "accepts custom comparators via a nested hash" do
      hash = {id: {XEX: 1}}
      expect(TeacherFake.build_query(hash)).to eq("{'3'.XEX.'1'}")
    end

    it "combines custom comparators using arrays with OR" do
      hash = {id: {XEX: [1, 2]}}
      expect(TeacherFake.build_query(hash)).to eq("{'3'.XEX.'1'}OR{'3'.XEX.'2'}")
    end

    it "combines different comparators with OR" do
      hash = {id: [{XEX: 123}, {OAF: 'today'}]}
      expect(TeacherFake.build_query(hash)).to eq("{'3'.XEX.'123'}OR{'3'.OAF.'today'}")
    end

    it "combines different comparators with AND" do
      hash = {id: {XEX: 123, OAF: 'today'}}
      expect(TeacherFake.build_query(hash)).to eq("{'3'.XEX.'123'}AND{'3'.OAF.'today'}")
    end

    it "converts field names to FIDs" do
      hash = "{name.EX.'Cullen Jett'}"
      expect(TeacherFake.build_query(hash)).to eq("{6.EX.'Cullen Jett'}")
    end

    it "throws an error for invaid field names" do
      hash = "{not_a_field_name.EX.'Cullen Jett'}"
      expect { TeacherFake.build_query(hash) }.to raise_error
    end
  end

  describe '.build_query_options' do
    it "returns a hash" do
      options = {clist: 'id.salary'}
      expect(TeacherFake.build_query_options(options)).to be_a Hash
    end

    it "converts field names to FIDs" do
      options = {clist: 'name'}
      expect(TeacherFake.build_query_options(options)).to eq({clist: '6'})
    end

    it "splits clist and slist on '.'" do
      options = {clist: 'name.subject', slist: 'name.salary'}
      expect(TeacherFake.build_query_options(options)).to eq({clist: '6.7', slist: '6.8'})
    end
  end
end