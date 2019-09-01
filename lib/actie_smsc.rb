# frozen_string_literal: true

require 'actie_smsc/version'
require 'actie_smsc/configuration'

module ActieSmsc
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end
  end
end
