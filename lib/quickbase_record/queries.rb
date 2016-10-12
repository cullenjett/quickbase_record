require_relative 'client'

module QuickbaseRecord
  module Queries
    extend ActiveSupport::Concern
    include QuickbaseRecord::Client

    module ClassMethods
      def clist
        @clist ||= fields.reject{ |field_name, field| field_name == :dbid }.values.collect {|field| field.fid }.join('.')
      end

      def find(id, query_options={})
        query_options = build_query_options(query_options[:query_options])
        if query_options[:clist]
          clist = query_options.delete(:clist)
        else
          clist = self.clist
        end
        # TODO: ':id' in build_query needs to be the primary key field name instead
        query_hash = {}
        query_hash[self.new.primary_key_field_name] = id
        query = { query: build_query(query_hash), clist: clist }.merge(query_options)
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

        if options[:clist]
          clist = options.delete(:clist)
        else
          clist = self.clist
        end

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

      def save_collection(objects)
        converted_objects = objects.map { |obj| build_quickbase_request(obj) }

        qb_client.import_from_csv(dbid, converted_objects)
      end

      def batch_where(query_hash, count=1000)
        all_query_results = []
        skip = 0

        begin
          query_options = query_hash.delete(:query_options)
          batch_options = {options: "num-#{count}.skp-#{skip}"}

          query = query_hash.merge(query_options: query_options.merge(batch_options))
          query_result = where(query)
          all_query_results << query_result
          skip += count
        end until query_result.length < count

        all_query_results.flatten
      end

      def purge_records(query_hash)
        query = {}
        if query_hash.is_a? Numeric
          query[:qid] = query_hash
        else
          query[:query] = build_query(query_hash)
        end

        query_response = qb_client.purge_records(dbid, query)
      end

      def build_quickbase_request(object)
        converted_object = {}
        fields.each do |field_name, field|
          converted_object[field.fid] = object.send(field_name)
        end
        new.remove_unwritable_fields(converted_object)
      end

      def build_query(query_hash)
        return convert_query_string(query_hash) if query_hash.is_a? String

        query_hash.map do |field_name, values|
          if field_name.is_a? Hash
            return field_name.map do |field_name, value|
              fid = convert_field_name_to_fid(field_name)
              join_with_or(fid, [value])
            end.join('OR')
          end

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
              result[option_name] = convert_field_name_to_fid(value).to_s
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

      def join_with_and(fid, value, comparator="EX")
        "{'#{fid}'.#{comparator}.'#{value}'}"
      end

      def join_with_or(fid, array, comparator="EX")
        array.map do |value|
          if value.is_a? Hash
            join_with_custom(fid, value)
          else
            "{'#{fid}'.#{comparator}.'#{value}'}"
          end
        end.join("OR")
      end

      def join_with_custom(fid, hash)
        hash.map do |comparator, value|
          if value.is_a? Array
            join_with_or(fid, value, comparator)
          else
            "{'#{fid}'.#{comparator}.'#{value}'}"
          end
        end.join('AND')
      end

      def convert_field_name_to_fid(field_name)
        fields[field_name.to_sym].fid
      end

      def covert_fid_to_field_name(fid)
        fields.select { |field_name, field| field.fid == fid.to_i }.values.first.field_name
      end

      def convert_quickbase_response(response)
        result = {}

        response.each do |fid, value|
          field = fields.select { |field_name, field| field.fid == fid.to_i }.values.first
          field_name = field.field_name
          value = field.convert(value)
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
    def writable_fields
      @writable_fields ||= self.class.fields.reject{ |field_name, field| field.options.include?(:read_only) }
    end

    def primary_key_field_name
      @primary_key_field ||= self.class.fields.select { |field_name, field| field.options.include?(:primary_key) }.keys.first
    end

    def record_id_field_name
      @record_id_field_name ||= self.class.fields.select { |field_name, field| field.fid == 3 }.keys.first
    end

    def save
      primary_key = public_send(primary_key_field_name)
      current_object = {}
      self.class.fields.each do |field_name, field|
        current_object[field.fid] = public_send(field_name)
      end

      if current_object[3] #object has a record_id, so we'll edit it
        remove_unwritable_fields(current_object)
        qb_client.edit_record(self.class.dbid, primary_key, current_object)
      else
        remove_unwritable_fields(current_object)
        new_rid = qb_client.add_record(self.class.dbid, current_object)
        public_send("#{record_id_field_name}=", new_rid)
      end

      return self
    end

    def delete
      # we have to use [record id] because of the advantage_quickbase gem
      rid = public_send(record_id_field_name)
      return false unless rid

      successful = qb_client.delete_record(self.class.dbid, rid)
      return successful ? self : false
    end

    def update_attributes(attributes={})
      return false if attributes.blank?

      self.assign_attributes(attributes)
      updated_attributes = {}
      attributes.each { |field_name, value| updated_attributes[self.class.convert_field_name_to_fid(field_name)] = value }
      primary_key = public_send(primary_key_field_name)
      record_id = public_send(record_id_field_name)

      if record_id
        remove_unwritable_fields(updated_attributes)
        qb_client.edit_record(self.class.dbid, primary_key, updated_attributes)
      else
        remove_unwritable_fields(updated_attributes)
        new_id = qb_client.add_record(self.class.dbid, updated_attributes)
        public_send("#{record_id_field_name}=", new_id)
      end

      return self
    end

    def remove_unwritable_fields(hash)
      writable_fids = writable_fields.values.collect { |field| field.fid }

      hash.delete_if do |fid, value|
        value.nil? || !writable_fids.include?(fid)
      end
    end
  end
end