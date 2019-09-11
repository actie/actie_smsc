# frozen_string_literal: true

RSpec.shared_examples 'send_sms_method' do
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
end
