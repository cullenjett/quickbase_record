require "quickbase_record/version"
require 'active_support/all'
require 'active_model'
require 'quickbase' # This is the file name for the 'advantage_quickbase' gem. Idk why Ben named it like that...
require_relative 'quickbase_record/configuration'
require_relative 'quickbase_record/field_mapping'
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