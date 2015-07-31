class Field
  attr_accessor :field_name, :fid, :options

  def initialize(args={})
    @field_name = args[:field_name]
    @fid = args[:fid]
    @options = args[:options]
  end
end