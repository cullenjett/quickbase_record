module QuickbaseRecord
  module Client
    include ActiveSupport::Concern

    module ClassMethods
      def qb_client
        realm = QuickbaseRecord.configuration.realm
        username = QuickbaseRecord.configuration.username
        password = QuickbaseRecord.configuration.password

        @qb_client ||= AdvantageQuickbase::API.new(realm, username, password)
      end
    end

    def qb_client
      realm = QuickbaseRecord.configuration.realm
      username = QuickbaseRecord.configuration.username
      password = QuickbaseRecord.configuration.password

      @qb_client ||= AdvantageQuickbase::API.new(realm, username, password)
    end

  end
end