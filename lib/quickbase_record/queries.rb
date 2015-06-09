require_relative 'configuration'
require_relative 'client'

module QuickbaseRecord
  module Queries
    extend ActiveSupport::Concern
    include QuickbaseRecord::Client

    UNWRITABLE_FIELDS = ['dbid', 'id', 'date_created', 'date_modified', 'record_owner', 'last_modified_by']

    module ClassMethods
      def fields
        @fields ||= self.configuration.fields
      end

      def dbid
        @dbid ||= fields[:dbid]
      end

      def clist
        @clist ||= fields.reject{ |field_name| field_name == :dbid }.values.join('.')
      end

      def find(id)
        query_options = { query: build_query(id: id), clist: clist }
        query_response = qb_client.do_query(dbid, query_options).first
        converted_response = convert_quickbase_response(query_response)

        new(converted_response)
      end

      def where(query_hash)
        query_options = { query: build_query(query_hash), clist: clist }
        query_response = qb_client.do_query(dbid, query_options)

        array_of_new_objects = query_response.map do |response|
          converted_response = convert_quickbase_response(response)
          new(converted_response)
        end

        return array_of_new_objects
      end

      def query(query_string)
        query_string = convert_query_string(query_string)
        query_options = { query: query_string, clist: clist }
        query_response = qb_client.do_query(dbid, query_options)

        array_of_new_objects = query_response.map do |response|
          converted_response = convert_quickbase_response(response)
          new(converted_response)
        end

        return array_of_new_objects
      end

      def build_query(query_hash)
        return query_hash if query_hash.is_a? String

        query_hash.map do |field_name, values|
          fid = convert_field_name_to_fid(field_name)
          if values.is_a? Array
            join_with_or(fid, values)
          else
            join_with_and(fid, values)
          end
        end.join("AND")
      end

      def join_with_and(fid, value)
        "{'#{fid}'.EX.'#{value}'}"
      end

      def join_with_or(fid, array)
        array.map do |value|
          "{'#{fid}'.EX.'#{value}'}"
        end.join("OR")
      end

      def convert_field_name_to_fid(field_name)
        self.configuration[field_name.to_sym].to_s
      end

      def covert_fid_to_field_name(fid)
        self.configuration.fields.invert[fid.to_i]
      end

      def convert_quickbase_response(response)
        result = {}

        response.each do |fid, value|
          field_name = covert_fid_to_field_name(fid)
          result[field_name] = value
        end

        result
      end

      def convert_query_string(query_string)
        fields.each do |field_name, fid|
          field_name = field_name.to_s
          match_string = "\{'?(#{field_name})'?\..*\.'?.*'?\}"
          if query_string.scan(/#{match_string}/).length > 0
            query_string.gsub!(field_name, fid.to_s)
          end
        end

        puts "QUERY STRING: #{query_string}"
        query_string
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
    end

  end
end