require_relative 'field'

class DateField < Field
  def initialize(*args)
    super(*args)
  end

  def convert(value)
    value
  end
end