require 'quickbase_record'
require './spec/fakes/teacher_fake'

RSpec.describe QuickbaseRecord::Queries do
  describe '.find' do
    it "finds a single Teacher by ID" do
      teacher = TeacherFake.find(1)
      expect(teacher.id).to eq("1")
    end

    it "returns a Teacher object" do
      teacher = TeacherFake.find(1)
      expect(teacher).to be_a TeacherFake
    end
  end

  describe '.where' do
    it "returns an array of objects" do
      teachers = TeacherFake.where(id: 1)
      expect(teachers).to be_a Array
    end

    it "returns Teacher objects" do
      teachers = TeacherFake.where(id: 1)
      expect(teachers.first).to be_a TeacherFake
    end
  end

  describe '.query' do
    it "returns an array of objects" do
      teachers = TeacherFake.query("{id.EX.'1'}")
      expect(teachers).to be_a Array
    end

    it "returns Teacher objects" do
      teachers = TeacherFake.query("{id.EX.'1'}")
      expect(teachers.first).to be_a TeacherFake
    end

    it "accepts FIDs" do
      teachers = TeacherFake.query("{'3'.EX.'1'}")
      expect(teachers.first.id).to eq('1')
    end
  end

  describe '.build_query' do
    it "converts a hash into QuickBase query format" do
      hash = {id: 1}
      expect(TeacherFake.build_query(hash)).to eq("{'3'.EX.'1'}")
    end

    it "combines multiple key/value pairs with AND" do
      hash = {id: 1, name: 'Mrs. Brown'}
      expect(TeacherFake.build_query(hash)).to eq("{'3'.EX.'1'}AND{'6'.EX.'Mrs. Brown'}")
    end

    it "combines array values with OR" do
      hash = {id: [1, 2]}
      expect(TeacherFake.build_query(hash)).to eq("{'3'.EX.'1'}OR{'3'.EX.'2'}")
    end

    it "accepts custom comparitors via a nested hash" do
      hash = {id: {XEX: 1}}
      expect(TeacherFake.build_query(hash)).to eq("{'3'.XEX.'1'}")
    end

    it "combines custom array comparitors with OR" do
      hash = {id: {XEX: [1, 2]}}
      expect(TeacherFake.build_query(hash)).to eq("{'3'.XEX.'1'}OR{'3'.XEX.'2'}")
    end

    it "converts a string using field names to FIDs" do
      hash = "{name.EX.'Cullen Jett'}"
      expect(TeacherFake.build_query(hash)).to eq("{6.EX.'Cullen Jett'}")
    end

    it "throws an error for invaid field names" do
      hash = "{not_a_field_name.EX.'Cullen Jett'}"
      expect { TeacherFake.build_query(hash) }.to raise_error
    end
  end

  describe '#save' do
    it "edits a record with an existing ID" do
      teacher = TeacherFake.find(1)
      teacher.name = "Mildred Boddington"
      expect(teacher.save).to eq(1)
      expect(TeacherFake.find(1).name).to eq("Mildred Boddington")
      puts teacher.inspect
    end
  end
end