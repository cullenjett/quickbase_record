class Field
  attr_accessor :field_name, :fid, :type, :options

  def initialize(args={})
    @field_name = args[:field_name]
    @fid = args[:fid]
    @type = args[:type]
    @options = args[:options]
  end
end