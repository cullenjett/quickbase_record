require_relative 'field'

class DateField < Field
  def initialize(*args)
    super(*args)
  end

  def convert(value)
    return nil if value == ""
    Time.at(value.to_i / 1000).strftime("%m/%d/%Y")
  end
end