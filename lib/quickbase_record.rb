require "quickbase_record/version"
require_relative 'quickbase_record/configuration'
require_relative 'quickbase_record/client'
require_relative 'quickbase_record/queries'
require_relative 'quickbase_record/model'

module QuickbaseRecord
  class << self
    attr_accessor :configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield configuration
  end
end