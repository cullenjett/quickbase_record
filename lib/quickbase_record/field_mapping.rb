module QuickbaseRecord
  class FieldMapping
    attr_accessor :fields

    def initialize(fields={})
      # @fields = create_fields(fields)
      @fields = fields
    end

    def create_fields(fields_hash)
      converted_fields_hash = {}
      fields_hash.each do |key, value|
        converted_fields_hash[key] = Field.new(value)
      end
      return converted_fields_hash
    end
  end

  class Field
    attr_accessor :value

    def initialize(value)
      @value = format_value(value)
    end

    def format_value(value)
      return value if value.is_a? Integer


    end
  end
end