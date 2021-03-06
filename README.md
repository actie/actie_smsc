# ActieSmsc
![Build Status](https://travis-ci.org/actie/actie_smsc.svg?branch=master)

This gem implements SMSC service API and based on this library: https://smsc.ru/api/code/libraries/http_smtp/ruby/

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'actie_smsc'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install actie_smsc

## Configuration

To change the configuration, create the file `config/initializers/actie_smsc.rb` in your project. Like shown in example:

```ruby
ActieSmsc.configure do |config|
  config.login = ENV.fetch('SMSC_LOGIN')
  config.password = ENV.fetch('SMSC_PASSWORD')
  config.charset = 'windows-1251'
end
```

There are two required parameters: `login` and `password`.

The full parameters list for configuration with default values:
```
use_post = true # Use POST request instead of GET
use_https = true # Use HTTPS request instead of HTTP
charset = 'utf-8' # valid charsets are: utf-8, koi8-r and windows-1251
debug = false
logger = Logger.new($stdout)
```

## Usage

There are four public methods for different API endpoints. Each method returns a result hash, or number (balance). In case of invalid response `SmscError` will be raised with error code in message.

### Send sms

```ruby
ActieSmsc.send_sms(phones, message, translit: 0, time: nil, id: 0, format: nil, sender: nil, fmt: 1, query_params: {})
```

The required parameters are: `phones` - array or string separated by commas and `message` as string. Other parameters have default values and described in SMSC library.

* translit - transliterate message text. Values:1,2 or 0
* time - delivery time (could be a `Time, Date, DateTime` object, or a string). There are several string formats:
  +m (e.g. `+10`) - Send the message 10 minutes later.
  h1-h2 (e.g. `9-20`) - Message can be sent only in the period from 9 am to 20 pm. If it's too late, it'll be sent next day.
  DDMMYYhhmm - string format for the exact time, it's also used for a Time object.
  0ts (e.g. `01568230028`) - UNIX time format with a `0` as a prefix.
* id - message id. Value - integer from 1 to 2147483647.
* format - message format. Values: [:flash, :push, :hlr, :bin, :bin_hex, :ping, :mms, :mail, :call, :viber, :soc]
* sender - Sender name. To disable default name use empty line, or '.'
* query - hash with additional parameters which will be added to the request (e.g. `{ valid: '01:00', maxsms: 3, tz: 2 }`)

Method returns result hash:
```ruby
{ id: 7600, cnt: 1, cost: 12.32, balance: 1234.12 }
```

### Sms cost

```ruby
ActieSmsc.sms_cost(phones, message, translit: 0, format: nil, sender: nil, fmt: 1, query_params: {})
```

This method checks the message cost. It receives the same parameters as `send_sms` method.

Returns the result hash:
```ruby
{ cost: 12.32, cnt: 2 }
```

### Status

```ruby
ActieSmsc.status(id, phone, all: false, fmt: 1)
```

Returns the delivery status for exact message and exact phone. Receives the message ID and phone number. The additional parameter `all` used to increase the number of returned values.

Returns the result hash:
```ruby
{ status: 1, change_time: 2019-09-08 15:00:00 +0300, error_code: 0 }
```

If parameter `all` changed to `true`, result hash will additionaly include values:
```ruby
{
  send_time:      2019-09-08 15:00:00 +0300,
  phone:          '+71234567890',
  cost:           2.12,
  sender:         'GLOBUS',
  status_message: 'Доставлено',
  message:        'Текст собщения'
}
```

### Balance

```ruby
ActieSmsc.balance(fmt: 1)
```
This method returns the balance of your SMSC account as float number.

### Response format

There is poorly described parameter `fmt` which changes the response format. (You can find description here: https://smsc.ru/api/http/send/sms/).

The default value is 1 - it returns the string with numbers, which then parsed to the result hash.

2 - is an XML response, returned as a string.

3 - json response, returned as parsed hash.

0 - another form of string response `(OK - 1 SMS, ID - 1234)`.

Formats 2 and 3 are usefull for the debugging. Because you can find more detaild error descriptions:
```
{"error"=>"duplicate request, wait a minute", "error_code"=>9}
```

Additionaly you can use `fmt: :response` to get the full `Faraday::Response` object.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/actie/actie_smsc. T

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
