module QuickbaseRecord
  module Client
    include ActiveSupport::Concern

    module ClassMethods
      def qb_client
        self.new.qb_client
      end
    end

    def qb_client
      realm = QuickbaseRecord.configuration.realm
      token = QuickbaseRecord.configuration.token

      if QuickbaseRecord.configuration.username != ""
        username = QuickbaseRecord.configuration.username
        password = QuickbaseRecord.configuration.password
      else
        usertoken = QuickbaseRecord.configuration.usertoken
      end

      @qb_client = AdvantageQuickbase::API.new(realm, username, password, token, nil, usertoken)
    end
  end
end