# frozen_string_literal: true

require 'actie_smsc/version'
require 'actie_smsc/configuration'
require 'faraday'
require 'json'
require 'date'

module ActieSmsc
  class SmscError < StandardError; end

  class << self
    def config
      @config ||= Configuration.new
    end

    def configure
      yield(config)
    end

    def send_sms(phones, message, translit: 0, time: nil, id: 0, format: nil, sender: nil, fmt: 1, **query_params)
      request_params = { cost: 3, phones: phones_string(phones), mes: message, id: id, fmt: fmt }
      request_params[:translit] = (0..2).include?(translit) ? translit : 0
      request_params[format] = format_value(format) if format_value(format)
      request_params[:sender] = sender if sender
      request_params[:time] = time_string(time) if time
      request_params.merge!(query_params)

      resp = request('send', request_params)

      check_response_for_exception(resp.body)

      case fmt
      when 2,0
        resp.body
      when 3
        JSON.parse(resp.body)
      when :response
        resp
      else
        body = resp.body.split(',')
        {
          id: body[0].to_i,
          cnt: body[1].to_i,
          cost: body[2].to_f,
          balance: body[3].to_f
        }
      end
    end

    def sms_cost(phones, message, translit: 0, format: nil, sender: nil, fmt: 1, **query_params)
      request_params = { cost: 1, phones: phones_string(phones), mes: message, fmt: fmt }
      request_params[:translit] = (0..2).include?(translit) ? translit : 0
      request_params[format] = format_value(format) if format_value(format)
      request_params[:sender] = sender if sender
      request_params.merge!(query_params)

      resp = request('send', request_params)

      check_response_for_exception(resp.body)

      case fmt
      when 2,0
        resp.body
      when 3
        JSON.parse(resp.body)
      when :response
        resp
      else
        body = resp.body.split(',')
        { cost: body[0].to_f, cnt: body[1].to_i }
      end
    end

    def status(id, phone, all: false, fmt: 1)
      request_params = { phone: phone, id: id, fmt: fmt }
      request_params[:all] = (all && all != 0) ? 1 : 0

      resp = request('status', request_params)

      check_response_for_exception(resp.body)

      case fmt
      when 2,0
        resp.body
      when 3
        JSON.parse(resp.body)
      when :response
        resp
      else
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

        if all != 0
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
    end

    def balance(fmt: 1)
      resp = request('balance', fmt: fmt)

      check_response_for_exception(resp.body)

      case fmt
      when 2,0
        resp.body
      when 3
        JSON.parse(resp.body)
      when :response
        resp
      else
        resp.body.to_f
      end
    end

    private

    def base_url
      "#{ !config.use_https ? 'http' : 'https' }://smsc.ru"
    end

    def base_params
      {
        login: config.login,
        psw: config.password,
        charset: config.charset
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

    def format_value(format)
      {
        flash:   1,
        push:    1,
        hlr:     1,
        bin:     1,
        bin_hex: 2,
        ping:    1,
        mms:     1,
        mail:    1,
        call:    1,
        viber:   1,
        soc:     1
      }[format]
    end

    def time_string(time)
      if time.is_a?(Time) || time.is_a?(Date)
        time.strftime('%d%m%y%H%M')
      else
        time
      end
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
