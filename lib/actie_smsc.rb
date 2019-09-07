# frozen_string_literal: true

require 'actie_smsc/version'
require 'actie_smsc/configuration'
require 'faraday'

module ActieSmsc
  class SmscError < StandardError; end

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

      check_response_for_exception(resp.body)

      body = resp.body.split(',')
      {
        id: body[0].to_i,
        cnt: body[1].to_i,
        cost: body[2].to_f,
        balance: body[3].to_f
      }
    end

    def sms_cost(phones, message, translit: 0, format: nil, sender: nil, **query_params)
      request_params = { cost: 1, phones: phones_string(phones), mes: message }
      request_params[:translit] = (0..2).include?(translit) ? translit : 0
      request_params[:format] = format_string(format) if format_string(format)
      request_params[:sender] = sender if sender
      request_params.merge!(query_params)

      resp = request('send', request_params)

      check_response_for_exception(resp.body)

      body = resp.body.split(',')
      { cost: body[0].to_f, cnt: body[1].to_i }
    end

    def status(id, phone, all: false)
      request_params = { phone: phone, id: id }
      request_params[:all] = (all && all != 0) ? 1 : 0

      resp = request('status', request_params)

      check_response_for_exception(resp.body)
      body = resp.body.split(',')
      result = {
        status: body[0].to_i,
        change_time: Time.at(body[1].to_i),
        error_code: body[2].to_i
      }
      # TODO: Implement HLR requests data:
      # для отправленного SMS (<статус>, <время изменения>, <код ошибки sms>)
      # для HLR-запроса (<статус>, <время изменения>, <код ошибки sms>, <код IMSI SIM-карты>, <номер сервис-центра>,
      # <код страны регистрации>, <код оператора абонента>, <название страны регистрации>, <название оператора абонента>,
      # <название роуминговой страны>, <название роумингового оператора>)

      if all
        result.merge!(
          send_time: Time.at(body[-7].to_i),
          phone: body[-6],
          cost: body[-5].to_f,
          sender: body[-4],
          status_message: CGI.unescape(body[-3]),
          message: body[-2]
        )
      end
      result
    end

    def balance
      resp = request('balance')

      check_response_for_exception(resp.body)

      resp.body.to_f
    end

    private

    def base_url
      "#{ !config.use_https ? 'http' : 'https' }://smsc.ru"
    end

    def base_params
      {
        login: config.login,
        psw: config.password,
        charset: config.charset,
        fmt: 1
      }
    end

    def connection
      Faraday.new(url: base_url)
    end

    def request(endpoint, params = {})
      req_method = !config.use_post ? :get : :post

      connection.public_send(req_method, "/sys/#{endpoint}.php") do |req|
        if req_method == :get
          req.params = base_params.merge(params)
        else
          req.body = base_params.merge(params)
        end
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

    def check_response_for_exception(body)
      code = body.split(',')[1].to_i

      raise SmscError, "Error code: #{code.abs}" if code < 0
    end
  end
end
