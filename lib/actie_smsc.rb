# frozen_string_literal: true

require 'actie_smsc/version'
require 'actie_smsc/configuration'
require 'faraday'

module ActieSmsc
  class << self
    def config
      @config ||= Configuration.new
    end

    def configure
      yield(config)
    end

    def send_sms(phones, message, translit: 0, time: nil, id: 0, format: nil, sender: nil, **query_params)
      request_params = { cost: 3, phones: phones_string(phones), mes: message, id: id }
      request_params[:translit] = (0..2).include?(translit) ? translit : 0
      request_params[:format] = format_string(format) if format_string(format)
      request_params[:sender] = sender if sender
      request_params[:time] = time if time
      request_params.merge!(query_params)

      resp = request('send', request_params)

      # TODO: Протестировать
      # (id, cnt, cost, balance) или (id, -error)
      # if config.debug
      #   if m[1] > "0"
      #     puts "Сообщение отправлено успешно. ID: #{m[0]}, всего SMS: #{m[1]}, стоимость: #{m[2]}, баланс: #{m[3]}\n"
      #   else
      #     puts "Ошибка №#{m[1][1]}" + (m[0] > "0" ? ", ID: #{m[0]}" : "") + "\n";
      #   end
      # end

      resp
    end

    # def send_sms_mail
    # end

    def sms_cost(phones, message, translit: 0, format: nil, sender: nil, **query_params)
      request_params = { cost: 1, phones: phones_string(phones), mes: message }
      request_params[:translit] = (0..2).include?(translit) ? translit : 0
      request_params[:format] = format_string(format) if format_string(format)
      request_params[:sender] = sender if sender
      request_params.merge!(query_params)

      resp = request('send', request_params)

      # TODO: Протестировать
      # (cost, cnt) или (0, -error)
      # if config.debug
      #   if m[1] > "0"
      #     puts "Стоимость рассылки: #{m[0]}. Всего SMS: #{m[1]}\n"
      #   else
      #     puts "Ошибка №#{m[1][1]}\n"
      #   end
      # end

      resp
    end

    def status(id, phone, all: false)
      request_params = { phone: phone, id: id }
      request_params[:all] = all && all != 0 ? 1 : 0

      resp = request('status', request_params)

      # TODO: Протестировать
      # (status, time, err, ...) или (0, -error)
      # if config.debug
      #   if m[1] != "" && m[1] >= "0"
      #     puts "Статус SMS = #{m[0]}" + (m[1] > "0" ? ", время изменения статуса - " + Time.at(m[1].to_i).strftime("%d.%m.%Y %T") : "") + "\n"
      #   else
      #     puts "Ошибка №#{m[1][1]}\n"
      #   end
      # end

      # if all && m.size > 9 && ((defined?(m[14])).nil? || m[14] != "HLR")
      #   m = (m.join(",")).split(",", 9)
      # end

      resp
    end

    def balance
      resp = request('balance')

      # TODO: Протестировать
      # (balance) или (0, -error)
      # if config.debug
      #   if m.length < 2
      #     puts "Сумма на счете: #{m[0]}\n"
      #   else
      #     puts "Ошибка №#{m[1][1]}\n"
      #   end
      # end

      # return m.length < 2 ? m[0] : false
      resp
    end

    private

    def base_url
      "#{ !config.use_https ? 'http' : 'https' }://smsc.ru"
    end

    def connection
      Faraday.new(
        url: base_url,
        params: {
          login: config.login,
          psw: config.password,
          charset: config.charset,
          fmt: 1 # TODO: Add config for responce formats https://smsc.ru/api/http/
        }
      )
    end

    def request(endpoint, params = nil)
      req_method = !config.use_post ? :get : :post

      connection.public_send(req_method, "/sys/#{endpoint}.php") do |req|
        # TODO: Понять можно ли отправлять параметры в body POST запроса, или обязательно в query_params, особенно login & password
        # req.params.merge!(params)
        req.body = params
      end
    end

    def format_string(format)
      {
        flash:   'flash=1',
        push:    'push=1',
        hlr:     'hlr=1',
        bin:     'bin=1',
        bin_hex: 'bin=2',
        ping:    'ping=1',
        mms:     'mms=1',
        mail:    'mail=1',
        call:    'call=1',
        viber:   'viber=1',
        soc:     'soc=1'
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
