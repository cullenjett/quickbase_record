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

    # it "formats fields as dates given a hash value" do
      # StudentFake.define_fields ({
      #   :dbid => 'bjzrx8ckw',
      #   :date_created => {date: 1},
      #   :id => 3,
      #   :name => 6,
      #   :grade => 7,
      #   :email => 8
      # })

    #   puts StudentFake.find(1).inspect

    #   expect(StudentFake.find(1).date_created).to eq('1/1/2015')
    # end
  end

  describe 'initialize' do
    it "dynamically creates attr_accessors for the class based on the configuration fields" do
      student = StudentFake.new(name: 'Cullen Jett')
      expect(student.respond_to?(:name)).to be true
      expect(student.respond_to?(:name=)).to be true
    end

    it "assigns passed in attributes to itself" do
      student = StudentFake.new(name: 'Cullen Jett')
      student.qb_client
      student.qb_client.ticket = "123"
      StudentFake.find(1)
      puts student.qb_client.ticket
      expect(student.name).to eq('Cullen Jett')
    end
  end
end