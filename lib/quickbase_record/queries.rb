require_relative 'client'

module QuickbaseRecord
  module Queries
    extend ActiveSupport::Concern
    include QuickbaseRecord::Client

    UNWRITABLE_FIELDS = ['dbid', 'id', 'date_created', 'date_modified', 'record_owner', 'last_modified_by']

    module ClassMethods
      def dbid
        @dbid ||= fields[:dbid]
      end

      def clist
        @clist ||= fields.reject{ |field_name| field_name == :dbid }.values.join('.')
      end

      def find(id)
        query_options = { query: build_query(id: id), clist: clist }
        query_response = qb_client.do_query(dbid, query_options).first

        return false if query_response.nil?

        converted_response = convert_quickbase_response(query_response)
        new(converted_response)
      end

      def where(query_hash)
        query_options = { query: build_query(query_hash), clist: clist }
        query_response = qb_client.do_query(dbid, query_options)

        build_array_of_new_objects(query_response)
      end

      def create(attributes={})
        raise StandardErrror, "You cannot call #{self}.create() with an :id attribute" if attributes.include?(:id)
        object = new(attributes)
        object.save
        return object
      end

      def qid(id)
        query_options = { qid: id, clist: clist }
        query_response = qb_client.do_query(dbid, query_options)

        build_array_of_new_objects(query_response)
      end

      def build_query(query_hash)
        return convert_query_string(query_hash) if query_hash.is_a? String

        query_hash.map do |field_name, values|
          fid = convert_field_name_to_fid(field_name)
          if values.is_a? Array
            join_with_or(fid, values)
          elsif values.is_a? Hash
            join_with_custom(fid, values)
          else
            join_with_and(fid, values)
          end
        end.join("AND")
      end

      private

      def build_array_of_new_objects(query_response)
        query_response.map do |response|
          converted_response = convert_quickbase_response(response)
          new(converted_response)
        end
      end

      def join_with_and(fid, value, comparitor="EX")
        "{'#{fid}'.#{comparitor}.'#{value}'}"
      end

      def join_with_or(fid, array, comparitor="EX")
        array.map do |value|
          "{'#{fid}'.#{comparitor}.'#{value}'}"
        end.join("OR")
      end

      def join_with_custom(fid, hash)
        comparitor = hash.keys.first
        value = hash.values.first

        if value.is_a? Array
          join_with_or(fid, value, comparitor)
        else
          "{'#{fid}'.#{comparitor}.'#{value}'}"
        end

      end

      def convert_field_name_to_fid(field_name)
        self.fields[field_name.to_sym].to_s
      end

      def covert_fid_to_field_name(fid)
        self.fields.invert[fid.to_i]
      end

      def convert_quickbase_response(response)
        result = {}

        response.each do |fid, value|
          field_name = covert_fid_to_field_name(fid)
          result[field_name] = value
        end

        return result
      end

      def convert_query_string(query_string)
        match_found = false
        uses_field_name = query_string.match(/\{'?(.*)'?\..*\.'?.*'?\}/)[1].to_i == 0

        return query_string unless uses_field_name

        fields.each do |field_name, fid|
          field_name = field_name.to_s
          match_string = "\{'?(#{field_name})'?\..*\.'?.*'?\}"
          if query_string.scan(/#{match_string}/).length > 0
            query_string.gsub!(field_name, fid.to_s)
            match_found = true
          end
        end

        if !match_found
          raise ArgumentError, "Invalid arguments on #{self}.query() - no matching field name found. \nMake sure the field is part of your class configuration."
        end

        return query_string
      end
    end

    # INSTANCE METHODS
    def save
      current_object = {}
      self.class.fields.each do |field_name, fid|
        current_object[fid] = public_send(field_name) unless UNWRITABLE_FIELDS.include?(field_name.to_s)
        current_object[self.class.fields[:id]] = self.id if self.id
      end
      self.id = qb_client.import_from_csv(self.class.dbid, [current_object]).first
      return self
    end

    def delete
      return false if !self.id
      successful = qb_client.delete_record(self.class.dbid, self.id)
      return successful ? self.id : false
    end

    def update_attributes(attributes={})
      return false if attributes.blank?
      self.assign_attributes(attributes)
      self.save
      return self
    end
  end
end