# frozen_string_literal: true

require 'webmock/rspec'
require 'timecop'
require 'pry'

RSpec.describe ActieSmsc do
  it 'has a version number' do
    expect(described_class::VERSION).not_to be nil
  end

  describe '#config' do
    it 'returns and instance of Configuration class' do
      expect(described_class.config).to be_kind_of(described_class::Configuration)
    end
  end

  describe '#configure' do
    subject(:configure) do
      described_class.configure { |config| config.charset = 'koi8-r' }
    end

    after { described_class.configure { |config| config.charset = 'utf-8' } }

    it 'changes configuration parameters' do
      expect { configure }.to change { described_class.config.charset }.from('utf-8').to('koi8-r')
    end
  end

  before do
    allow_any_instance_of(ActieSmsc::Configuration).to receive(:login).and_return('test_login')
    allow_any_instance_of(ActieSmsc::Configuration).to receive(:password).and_return('test_passwd')
  end

  describe '#send_sms' do
    before { Timecop.freeze('2019-11-09T12:25') }
    after { Timecop.return }

    subject(:request) { described_class.send_sms(phones, message, request_params) }

    let(:phones) { %w[79991234567 79997654321] }
    let(:message) { 'test message' }
    let(:request_params) { { id: 12345, fmt: 2, time: Time.now, charset: 'koi8-r', translit: 1, other_parameter: 'yes' } }

    it 'makes a request with correct params' do
      stub = stub_request(:post, 'https://smsc.ru/sys/send.php').with(
        body: {
          'cost' => '3',
          'phones' => '79991234567,79997654321',
          'mes' => message,
          'time' => '0911191225',
          'fmt' => '2',
          'id' => '12345',
          'charset' => 'koi8-r',
          'login' => 'test_login',
          'psw' => 'test_passwd',
          'translit' => '1',
          'other_parameter' => 'yes'
        }
      )
      request
      expect(stub).to have_been_requested
    end

    context 'when configured for http' do
      before do
        allow_any_instance_of(ActieSmsc::Configuration).to receive(:use_https).and_return(false)
      end

      it 'makes a request using http' do
        stub = stub_request(:post, 'http://smsc.ru/sys/send.php').with(
          body: {
            'cost' => '3',
            'phones' => '79991234567,79997654321',
            'mes' => message,
            'time' => '0911191225',
            'fmt' => '2',
            'id' => '12345',
            'charset' => 'koi8-r',
            'login' => 'test_login',
            'psw' => 'test_passwd',
            'translit' => '1',
            'other_parameter' => 'yes'
          }
        )
        request
        expect(stub).to have_been_requested
      end
    end

    context 'when configured for a GET request' do
      before do
        allow_any_instance_of(ActieSmsc::Configuration).to receive(:use_post).and_return(false)
      end

      it 'makes a request using GET' do
        stub = stub_request(
          :get,
          'https://smsc.ru/sys/send.php?charset=koi8-r&cost=3&fmt=2&id=12345&login=test_login&mes=test%20message&other_parameter=yes&phones=79991234567,79997654321&psw=test_passwd&time=0911191225&translit=1'
        )

        request
        expect(stub).to have_been_requested
      end
    end
  end

  # TODO: Тестировать изменение cost=1/3 (в params или body)
  describe '#sms_cost' do
    subject(:request) { described_class.sms_cost(phones, message, request_params) }

    let(:phones) { %w[79991234567 79997654321] }
    let(:message) { 'test message' }
    let(:request_params) { {} }

    it 'makes a request with correct params' do
      stub = stub_request(:post, 'https://smsc.ru/sys/send.php').with(
        body: {
          'cost' => '1',
          'phones' => '79991234567,79997654321',
          'mes' => message,
          'fmt' => '1',
          'charset' => 'utf-8',
          'login' => 'test_login',
          'psw' => 'test_passwd',
          'translit' => '0'
        }
      )
      request
      expect(stub).to have_been_requested
    end
  end

  describe '#status' do
    subject(:request) { described_class.status(123, '79991234567') }

    it 'makes a request with correct params' do
      stub = stub_request(:post, 'https://smsc.ru/sys/status.php').with(
        body: {
          'id' => '123',
          'phone' => '79991234567',
          'fmt' => '1',
          'charset' => 'utf-8',
          'login' => 'test_login',
          'psw' => 'test_passwd',
          'all' => '0'
        }
      )
      request
      expect(stub).to have_been_requested
    end

    context 'with other parameters' do
      subject(:request) { described_class.status(123, '79991234567', all: true, fmt: 2) }

      it 'makes a request with correct params' do
        stub = stub_request(:post, 'https://smsc.ru/sys/status.php').with(
          body: {
            'id' => '123',
            'phone' => '79991234567',
            'fmt' => '2',
            'charset' => 'utf-8',
            'login' => 'test_login',
            'psw' => 'test_passwd',
            'all' => '1'
          }
        )
        request
        expect(stub).to have_been_requested
      end
    end
  end

  describe '#balance' do
    subject(:request) { described_class.balance }

    it 'makes a request with correct params' do
      stub = stub_request(:post, 'https://smsc.ru/sys/balance.php').with(
          body: {
            'fmt' => '1',
            'charset' => 'utf-8',
            'login' => 'test_login',
            'psw' => 'test_passwd'
          }
        )
      request
      expect(stub).to have_been_requested
    end
  end
end
