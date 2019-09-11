# frozen_string_literal: true

RSpec.shared_examples 'sms_cost_method' do
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
end
