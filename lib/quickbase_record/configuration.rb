module QuickbaseRecord
  class Configuration
    attr_accessor :realm, :username, :password, :token

    def initialize
      @realm = ''
      @username = ''
      @password = ''
      @token = ''
    end
  end
end