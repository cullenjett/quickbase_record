require_relative 'field'

class TableDefinition
  attr_accessor :fields

  def initialize
    @fields = {}
  end

  def dbid(dbid_string)
    fields[:dbid] = dbid_string
  end

  def string(field_name, fid, options={})
    field_name = field_name.to_sym
    fid = fid.to_i

    fields[field_name] = Field.new(field_name: field_name, fid: fid, type: :string, options: options)
  end

  def number(field_name, fid, options={})
    field_name = field_name.to_sym
    fid = fid.to_i

    fields[field_name] = Field.new(field_name: field_name, fid: fid, type: :number, options: options)
  end

  def date(field_name, fid, options={})
    field_name = field_name.to_sym
    fid = fid.to_i

    fields[field_name] = Field.new(field_name: field_name, fid: fid, type: :date, options: options)
  end
end