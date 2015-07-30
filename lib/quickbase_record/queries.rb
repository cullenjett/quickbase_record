require_relative 'client'

module QuickbaseRecord
  module Queries
    extend ActiveSupport::Concern
    include QuickbaseRecord::Client

    UNWRITABLE_FIELDS = ['dbid', 'id', 'date_created', 'date_modified', 'record_owner', 'last_modified_by']

    module ClassMethods
      # def dbid
      #   @dbid ||= fields[:dbid]
      # end

      def clist
        @clist ||= fields.reject{ |field_name, field| field_name == :dbid }.values.collect {|field| field.fid }.join('.')
      end

      def find(id, query_options = {})
        query_options = build_query_options(query_options[:query_options])
        clist = query_options.delete(:clist) if query_options[:clist]
        query = { query: build_query(id: id), clist: clist }.merge(query_options)
        query_response = qb_client.do_query(dbid, query).first

        return nil if query_response.nil?

        converted_response = convert_quickbase_response(query_response)
        new(converted_response)
      end

      def where(query_hash)
        if !query_hash.is_a? String
          options = build_query_options(query_hash.delete(:query_options))
        else
          options = {}
        end

        clist = options.delete(:clist) if options[:clist]

        query = { query: build_query(query_hash), clist: clist }.merge(options)
        query_response = qb_client.do_query(dbid, query)

        return [] if query_response.first.nil?

        build_collection(query_response)
      end

      def create(attributes={})
        object = new(attributes)
        object.save
        return object
      end

      def qid(id)
        query_options = { qid: id, clist: clist }
        query_response = qb_client.do_query(dbid, query_options)

        return [] if query_response.first.nil?

        build_array_of_new_objects(query_response)
      end

      def build_query(query_hash)
        return convert_query_string(query_hash) if query_hash.is_a? String

        query_hash.map do |field_name, values|
          fid = fields[field_name].fid

          if values.is_a? Array
            join_with_or(fid, values)
          elsif values.is_a? Hash
            join_with_custom(fid, values)
          else
            join_with_and(fid, values)
          end

        end.join("AND")
      end

      def build_query_options(options)
        return {} unless options

        result = {}

        options.each do |option_name, value|
          if option_name.to_sym == :options
            result[option_name] = value
            next
          end

          value.split('.').each do |value|
            if result[option_name]
              result[option_name] << ".#{convert_field_name_to_fid(value)}"
            else
              result[option_name] = convert_field_name_to_fid(value)
            end
          end
        end

        return result
      end

      def build_collection(query_response)
        query_response.map do |response|
          converted_response = convert_quickbase_response(response)
          new(converted_response)
        end
      end

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
        fields[field_name.to_sym].fid
      end

      def covert_fid_to_field_name(fid)
        # puts "FID: #{fid}"
        puts "FIELDS: #{fields.inspect}"
        fields.select { |field_name, field| field.fid == fid.to_i }.values.first.field_name
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

        fields.each do |field_name, field|
          match_string = "\{'?(#{field_name})'?\..*\.'?.*'?\}"

          if query_string.scan(/#{match_string}/).length > 0
            query_string.gsub!(field_name.to_s, field.fid.to_s)
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
      self.class.fields.each do |field_name, field|
        current_object[field.fid.to_s] = public_send(field_name)
      end

      if current_object['3'] #object has a record_id, so we'll edit it
        remove_unwritable_fields(current_object)
        qb_client.edit_record(self.class.dbid, self.id, current_object)
      else
        remove_unwritable_fields(current_object)
        new_rid = qb_client.add_record(self.class.dbid, current_object)
        id_field_name = self.class.fields.select { |field_name, field| field.fid == 3 }.keys.first
        public_send("#{id_field_name}=", new_rid)
      end

      return self
    end

    def delete
      # we have to use [record id] because of the advantage_quickbase gem
      id_field_name = self.class.fields.select { |field_name, field| field.fid == 3 }.keys.first
      rid = public_send(id_field_name)
      return false unless rid

      successful = qb_client.delete_record(self.class.dbid, rid)
      return successful ? self : false
    end

    def update_attributes(attributes={})
      return false if attributes.blank?

      self.assign_attributes(attributes)
      updated_attributes = {}
      # attributes.each { |field_name, value| updated_attributes[self.class.convert_field_name_to_fid(field_name)] = value }
      # updated_attributes.delete_if { |key, value| value.nil? }

      if self.id
        qb_client.edit_record(self.class.dbid, self.id, updated_attributes)
      else
        self.id = qb_client.add_record(self.class.dbid, updated_attributes)
      end

      return self
    end

    def remove_unwritable_fields(hash)
      hash.delete_if do |key, value|
        value.nil? || key.to_i <= 5 || key == :dbid
      end
    end
  end
end