require 'quickbase_record/fields/field'
require 'quickbase_record/fields/string_field'
require 'quickbase_record/fields/number_field'
require 'quickbase_record/fields/date_field'
require 'quickbase_record/fields/file_attachment_field'

RSpec.describe StringField do
  describe '#convert' do
    it "returns a string" do
      expect(StringField.new.convert(123)).to eq('123')
    end
  end
end

RSpec.describe NumberField do
  describe '#convert' do
    it "returns a number" do
      expect(NumberField.new.convert('123')).to eq(123)
    end

    it "returns a float" do
      expect(NumberField.new.convert('123.45')).to eq(123.45)
    end
  end
end

RSpec.describe DateField do
  describe '#convert' do
    it "converts ms to a formated date string" do
      now_in_ms = Time.now.to_f * 1000
      now_as_string = DateTime.now.strftime('%m/%d/%Y')
      expect(DateField.new.convert(now_in_ms)).to eq(now_as_string)
    end

    it "returns an empty string when passed an empty string" do
      expect(DateField.new.convert("")).to eq("")
    end
  end
end