require 'quickbase_record/fields/string_field'
require 'quickbase_record/fields/number_field'
require 'quickbase_record/fields/date_field'
require 'quickbase_record/fields/file_attachment_field'
require 'quickbase_record/fields/boolean_field'

class TableDefinition
  attr_accessor :fields

  def initialize
    @fields = {}
  end

  def dbid(dbid_string)
    fields[:dbid] = dbid_string
  end

  def string(field_name, fid, *options)
    field_name = field_name.to_sym
    fid = fid.to_i

    fields[field_name] = StringField.new(field_name: field_name, fid: fid, options: options)
  end

  def number(field_name, fid, *options)
    field_name = field_name.to_sym
    fid = fid.to_i

    fields[field_name] = NumberField.new(field_name: field_name, fid: fid, options: options)
  end

  def file_attachment(field_name, fid, *options)
    field_name = field_name.to_sym
    fid = fid.to_i

    fields[field_name] = FileAttachmentField.new(field_name: field_name, fid: fid, options: options)
  end

  def date(field_name, fid, *options)
    field_name = field_name.to_sym
    fid = fid.to_i

    fields[field_name] = DateField.new(field_name: field_name, fid: fid, options: options)
  end

  def boolean(field_name, fid, *options)
    field_name = field_name.to_sym
    fid = fid.to_i

    fields[field_name] = BooleanField.new(field_name: field_name, fid: fid, options: options)
  end
end