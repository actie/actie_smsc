# frozen_string_literal: true

require 'webmock/rspec'
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
    subject(:request) { described_class.send_sms(phones, message, request_params) }

    let(:phones) { %w[79991234567 79997654321] }
    let(:message) { 'test message' }
    let(:request_params) { {} }

    it 'makes a request with correct params' do
      stub = stub_request(:post, 'https://smsc.ru/sys/send.php?charset=utf-8&fmt=1&login=test_login&psw=test_passwd')
      request
      expect(stub).to have_been_requested
    end

    context 'when configured for http' do
      before do
        allow_any_instance_of(ActieSmsc::Configuration).to receive(:use_https).and_return(false)
      end

      it 'makes a request using http' do
        stub = stub_request(:post, 'http://smsc.ru/sys/send.php?charset=utf-8&fmt=1&login=test_login&psw=test_passwd')
        request
        expect(stub).to have_been_requested
      end
    end

    context 'when configured for a GET request' do
      before do
        allow_any_instance_of(ActieSmsc::Configuration).to receive(:use_post).and_return(false)
      end

      it 'makes a request using GET' do
        stub = stub_request(:get, 'https://smsc.ru/sys/send.php?charset=utf-8&fmt=1&login=test_login&psw=test_passwd')
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
      stub = stub_request(:post, 'https://smsc.ru/sys/send.php?charset=utf-8&fmt=1&login=test_login&psw=test_passwd')
      request
      expect(stub).to have_been_requested
    end
  end

  describe '#status' do
    subject(:request) { described_class.status(123, '79991234567') }

    it 'makes a request with correct params' do
      stub = stub_request(:post, 'https://smsc.ru/sys/status.php?charset=utf-8&fmt=1&login=test_login&psw=test_passwd')
      request
      expect(stub).to have_been_requested
    end
  end

  describe '#balance' do
    subject(:request) { described_class.balance }

    it 'makes a request with correct params' do
      stub = stub_request(:post, 'https://smsc.ru/sys/balance.php?charset=utf-8&fmt=1&login=test_login&psw=test_passwd')
      request
      expect(stub).to have_been_requested
    end
  end
end
