module QuickbaseRecord
  class Configuration
    attr_accessor :realm, :username, :password, :token, :usertoken

    def initialize
      @realm = ''
      @username = ''
      @password = ''
      @token = ''
      @usertoken = ''
    end
  end
end