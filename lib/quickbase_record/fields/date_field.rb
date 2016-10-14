require_relative 'field'

class DateField < Field
  def initialize(*args)
    super(*args)
  end

  def convert(value)
    return "" if value == ""
    DateTime.strptime((value.to_i/1000).to_s, "%s").strftime("%m/%d/%Y")
  end
end