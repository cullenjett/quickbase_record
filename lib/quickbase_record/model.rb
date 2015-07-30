require_relative 'table_definition'

module QuickbaseRecord
  module Model
    extend ActiveSupport::Concern
    include QuickbaseRecord::Queries
    include QuickbaseRecord::Client

    included do
      extend QuickbaseRecord::Queries
      extend ActiveModel::Naming
      extend ActiveModel::Callbacks
      include ActiveModel::Validations
      include ActiveModel::Conversion
    end

    module ClassMethods
      attr_accessor :fields, :dbid

      def define_fields
        table_definition = TableDefinition.new
        yield table_definition
        @dbid = table_definition.fields[:dbid]
        puts "TABLE DEFINITION: #{table_definition.fields}"
        @fields = table_definition.fields.reject { |field_name, field| field_name == :dbid }
      end
    end

    def initialize(attributes={})
      create_attr_accesssors
      assign_attributes(attributes) if attributes

      super()
    end

    def persisted?
      false
    end

    def create_attr_accesssors
      self.class.fields.each do |field_name, field|
        self.class.send(:attr_accessor, field_name)
      end
    end

    def assign_attributes(new_attributes)
      if !new_attributes.respond_to?(:stringify_keys)
        raise ArgumentError, "When assigning attributes, you must pass a hash as an argument."
      end
      return if new_attributes.blank?

      attributes = new_attributes.stringify_keys
      _assign_attributes(attributes)
    end

    def _assign_attributes(attributes)
      attributes.each do |k, v|
        _assign_attribute(k, v)
      end
    end

    def _assign_attribute(k, v)
      if respond_to?("#{k}=")
        public_send("#{k}=", v)
      end
    end
  end
end