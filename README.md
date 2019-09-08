# ActieSmsc

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
charset = 'utf-8'
debug = false
logger = Logger.new($stdout)
```

## Usage

There are four public methods for different API endpoints. Each method returns a result hash, or number (balance). In case of invalid response `SmscError` will be raised with error code in message.

### Send sms

```ruby
ActieSmsc.send_sms(phones, message, translit: 0, time: nil, id: 0, format: nil, sender: nil, **query_params)
```

The required parameters are: `phones` - array or string separated by commas and `message` as string. Other parameters have default values and described in SMSC library.

```
translit - transliterate message text. Values:1,2 or 0
time - delivery time (DDMMYYhhmm, h1-h2, 0ts, +m)
id - message id. Value - integer number from 1 to 2147483647.
format - message format. Values: [:flash, :push, :hlr, :bin, :bin_hex, :ping, :mms, :mail, :call, :viber, :soc]
sender - Sender name. To disable default name use empty line, or '.'
query - hash with additional parameters which will be added to the request (e.g. { valid: '01:00', maxsms: 3, tz: 2 })
```

Method returns result hash:
```ruby
{ id: 7600, cnt: 1, cost: 12.32, balance: 1234.12 }
```

### Sms cost

```ruby
ActieSmsc.sms_cost(phones, message, translit: 0, format: nil, sender: nil, **query_params)
```

This method checks the message cost. It receives the same parameters as `send_sms` method.

Returns the result hash:
```ruby
{ cost: 12.32, cnt: 2 }
```

### Status

```ruby
ActieSmsc.status(id, phone, all: false)
```

Returns the delivery status for exact message and exact phone. Receives the message ID and phone number. The additional parameter `all` used to increase the number of returned values.

The result hash is different for Sms and HLR requests.

For sms:
```ruby
{ status: 1, change_time: 2019-09-08 15:00:00 +0300, error_code: 0 }
```

For HLR:
```ruby
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
ActieSmsc.balance
```
This method returns the balance of your SMSC account as float number.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/actie/actie_smsc. T

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
