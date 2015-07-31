class Field
  attr_accessor :field_name, :fid, :options

  def initialize(args={})
    @field_name = args[:field_name]
    @fid = args[:fid]
    @options = args[:options]
  end

  def convert(value)
    Raise "#{self.class} must implement #convert to be a true subclass of Field"
  end
end