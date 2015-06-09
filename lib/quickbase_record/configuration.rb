module QuickbaseRecord
  class Configuration
    attr_accessor :realm, :username, :password, :fields

    def initialize
      @realm = ''
      @username = ''
      @password = ''
      @fields = {}
    end

    def [] key
      fields[key]
    end
  end
end