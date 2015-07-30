require_relative 'field'

class StringField < Field
  def initialize(*args)
    super(*args)
  end

  def convert(value)
    value.to_s
  end
end