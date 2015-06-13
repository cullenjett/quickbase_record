require './spec/fakes/teacher_fake'

RSpec.describe QuickbaseRecord::Queries do
  describe '.find' do
    it "finds a single Teacher given an ID" do
      teacher = TeacherFake.find(1)
      expect(teacher.id).to eq("1")
    end

    it "returns an object of the Teacher class" do
      teacher = TeacherFake.find(1)
      expect(teacher).to be_a TeacherFake
    end

    it "returns nil if no QuickBase records are found" do
      teacher = TeacherFake.find(999999)
      expect(teacher).to eq(nil)
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
      expect(teachers.first.id).to eq('1')
    end

    it "accepts a string in QuickBase query format using field names" do
      teachers = TeacherFake.where("{'id'.EX.'1'}")
      expect(teachers.first.id).to eq('1')
    end

    it "returns an empty array if no QuickBase records are found" do
      teachers = TeacherFake.where(name: 'Not a real TeacherFake name...')
      expect(teachers).to eq([])
    end
  end

  describe '.create' do
    it "saves the object immediately" do
      teacher = TeacherFake.create(name: 'Professor Dumbledore')
      expect(teacher.id).to be > 1
      teacher.delete
    end

    it "throws an error if an :id argument is passed" do
      expect { TeacherFake.create(id: 1, name: 'Professor Dumbledore') }.to raise_error
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

  describe '#save' do
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
      cullen.delete
    end
  end

  describe '#delete' do
    it "deletes an object from QuickBase" do
      socrates = TeacherFake.new(name: 'Socrates')
      socrates.save
      old_id = socrates.id
      expect(socrates.delete).to eq(old_id)
    end

    it "returns false if the object doesn't yet have an ID" do
      expect(TeacherFake.new(name: 'Socrates').delete).to be false
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
    it "assigns an objects attributes given a hash attributes and their values" do
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

    it "accepts custom comparitors via a nested hash" do
      hash = {id: {XEX: 1}}
      expect(TeacherFake.build_query(hash)).to eq("{'3'.XEX.'1'}")
    end

    it "combines custom comparitors using arrays with OR" do
      hash = {id: {XEX: [1, 2]}}
      expect(TeacherFake.build_query(hash)).to eq("{'3'.XEX.'1'}OR{'3'.XEX.'2'}")
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
end