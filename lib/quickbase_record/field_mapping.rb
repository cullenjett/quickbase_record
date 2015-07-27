module QuickbaseRecord
  class FieldMapping
    attr_accessor :fields

    def initialize(fields={})
      @fields = fields
    end
  end
end