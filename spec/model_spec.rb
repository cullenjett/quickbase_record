require './spec/fakes/student_fake'

RSpec.describe QuickbaseRecord::Model do
  describe '.define_fields' do
    it "sets the class field mappings for field names => FIDs" do
      StudentFake.define_fields ({
        :dbid => 'bjzrx8ckw',
        :id => 3,
        :name => 6,
        :grade => 7,
        :email => 8
      })

      expect(StudentFake.fields[:id]).to eq(3)
    end

    it "accepts data types" do
      StudentFake.define_fields do |t|
        t.string :dbid, "abc123"
        t.number :id, 3, :primary_key
        t.date :date_created, 4
        t.string :name, 6
        t.number :grade, 7, :read_only
        t.string :email, 8
      end

      expect(StudentFake.fields[:id].fid).to eq(3)
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