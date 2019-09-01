# frozen_string_literal: true

require 'logger'

module ActieSmsc
  class InvalidConfigurationError < StandardError; end
  class InvalidConfigurationError < StandardError; end

  class Configuration
    VALID_CHARSETS = %w[utf-8 koi8-r windows-1251].freeze

    attr_accessor :use_post, :use_https, :debug, :logger, :log_enabled
    attr_writer :login, :password, :from_email
    attr_reader :charset

    def initialize
      @login = nil
      @password = nil
      @from_email = nil

      @use_post = true
      @use_https = true
      @charset = 'utf-8'
      @debug = false

      @logger = defined?(Rails) ? Rails.logger : Logger.new($stdout)
      @log_enabled = false
    end

    def login
      return @login if @login

      raise InvalidConfigurationError, 'login must be specified'
    end

    def password
      return @password if @password

      raise InvalidConfigurationError, 'password must be specified'
    end

    def from_email
      return @from_email if @from_email

      raise InvalidConfigurationError, 'from_email must be specified'
    end

    def charset=(new_charset)
      unless VALID_CHARSETS.include?(new_charset)
        raise InvalidConfigurationError, "charset should be one of #{VALID_CHARSETS}"
      end

      @charset = new_charset
    end
  end
end
