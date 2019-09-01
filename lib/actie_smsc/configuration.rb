# frozen_string_literal: true

module ActieSmsc
  class InvalidConfigurationError < StandardError; end

  class Configuration
    attr_accessor :use_post, :use_https, :charset, :debug, :logger, :log_enabled
    attr_writer :login, :password, :from_email

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
  end
end
