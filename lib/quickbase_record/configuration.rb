module QuickbaseRecord
  class Configuration
    attr_accessor :realm, :username, :password

    def initialize
      @realm = ''
      @username = ''
      @password = ''
    end
  end
end