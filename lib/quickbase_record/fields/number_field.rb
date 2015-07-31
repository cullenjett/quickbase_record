require_relative 'field'

class NumberField < Field
  def initialize(*args)
    super(*args)
  end

  def convert(value)
    value.match(/\./) ? value.to_f : value.to_i
  end
end