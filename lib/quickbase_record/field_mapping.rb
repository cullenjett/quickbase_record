module QuickbaseRecord
  class FieldMapping
    attr_accessor :fields

    def initialize(fields={})
      @fields = fields
    end

    def [] key
      fields[key]
    end
  end
end