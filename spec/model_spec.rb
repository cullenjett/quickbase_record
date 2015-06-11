require './spec/fakes/student_fake'

RSpec.describe QuickbaseRecord::Model do
  describe '.configure' do
    it "sets the field mapping for field names to FIDs on the class' configuration object" do
      expect(StudentFake.configuration.fields[:id]).to eq(3)
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