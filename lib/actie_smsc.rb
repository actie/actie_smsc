# frozen_string_literal: true

require 'actie_smsc/version'
require 'actie_smsc/configuration'

module ActieSmsc


  class << self
    def config
      @config ||= Configuration.new
    end

    def configure
      yield(config)
    end

    def send_sms(phones, message, translit: 0, time: nil, id: 0, format: nil, sender: nil, **query_params)
      request_params = { cost: 3, phones: phones_string(phones), mes: message, translit: translit, id: id }
      request_params[:format] = format_string(format) if format_string(format)
      request_params[:sender] = sender if sender
      request_params[:time] = time if time
      request_params.merge!(query_params)

      resp = request('send', request_params)

      # (id, cnt, cost, balance) или (id, -error)
      if config.debug
        if m[1] > "0"
          puts "Сообщение отправлено успешно. ID: #{m[0]}, всего SMS: #{m[1]}, стоимость: #{m[2]}, баланс: #{m[3]}\n"
        else
          puts "Ошибка №#{m[1][1]}" + (m[0] > "0" ? ", ID: #{m[0]}" : "") + "\n";
        end
      end

      resp
    end

    # def send_sms_mail
    # end

    def sms_cost(phones, message, translit: 0, format: nil, sender: nil, **query_params)
      request_params = { cost: 1, phones: phones_string(phones), mes: message, translit: translit }
      request_params[:format] = format_string(format) if format_string(format)
      request_params[:sender] = sender if sender
      request_params.merge!(query_params)

      resp = request('send', request_params)

      # (cost, cnt) или (0, -error)
      if config.debug
        if m[1] > "0"
          puts "Стоимость рассылки: #{m[0]}. Всего SMS: #{m[1]}\n"
        else
          puts "Ошибка №#{m[1][1]}\n"
        end
      end

      resp
    end

    # def status
    # end

    # def balance
    # end

    private

    def base_url
      "#{config.use_https ? 'https' : 'http'}://smsc.ru/sys/"
    end

    def connection
      Faraday.new(
        url: base_url,
        params: {
          login: config.login,
          psw: config.password,
          charset: config.charset,
          fmt: 1 # TODO: Add config for formats
        }
      )
    end

    def request(endpoint, params)
      req_method = !config.use_post ? :get : :post

      connection.public_send(req_method, "#{endpoint}.php") do |req|
        req.params.merge!(params)
      end
    end

    def format_string(format)
      {
        flash: 'flash=1',
        push:  'push=1',
        hlr:   'hlr=1',
        bin1:  'bin=1',
        bin2:  'bin=2',
        ping:  'ping=1',
        mms:   'mms=1',
        mail:  'mail=1',
        call:  'call=1'
      }[format]
    end

    def phones_string(phones)
      if phones.is_a?(Array)
        phones.join(',')
      else
        phones
      end
    end
  end
end
