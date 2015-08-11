class BooleanField < Field
  def initialize(*args)
    super(*args)
  end

  def convert(value)
    value == "1"
  end
end