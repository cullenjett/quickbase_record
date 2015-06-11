module QuickbaseRecord
  module Model
    extend ActiveSupport::Concern
    include ActiveModel::Validations
    include ActiveModel::Conversion
    include QuickbaseRecord::Queries
    include QuickbaseRecord::Client

    included do
      extend QuickbaseRecord::Queries
      extend ActiveModel::Naming
    end

    module ClassMethods
      def configuration
        @@configuration ||= Configuration.new
      end

      def configure
        yield configuration
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

    private

    def create_attr_accesssors
      self.class.configuration.fields.each do |field_name, fid|
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