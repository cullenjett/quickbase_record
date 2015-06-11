require './spec/fakes/student_fake'

RSpec.describe QuickbaseRecord::Model do
  describe '.define_fields' do
    it "sets the field mapping for field names to FIDs" do
      StudentFake.define_fields do
        {
          dbid: 'bjzrx8ckw',
          id: 3,
          name: 6,
          grade: 7,
          email: 8
        }
      end

      expect(StudentFake.fields[:id]).to eq(3)
    end
  end

  describe 'initialize' do
    it "dynamically creates attr_accessors for the class based on the configuration fields" do
      student = StudentFake.new(name: 'Cullen Jett')
      expect(student.respond_to?(:name)).to be true
      expect(student.respond_to?(:name=)).to be true
    end

    it "assigns passed in attributes to itself" do
      student = StudentFake.new(name: 'Cullen Jett')
      expect(student.name).to eq('Cullen Jett')
    end
  end
end