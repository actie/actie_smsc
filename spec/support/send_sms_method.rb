# frozen_string_literal: true

RSpec.shared_examples 'send_sms_method' do
  describe '#send_sms' do
    before { Timecop.freeze('2019-11-09T12:25') }
    after { Timecop.return }

    subject(:request) { described_class.send_sms(phones, message, request_params) }

    let(:stub_template) { stub_request(:post, 'https://smsc.ru/sys/send.php').with(body: body_params).to_return(response) }
    let(:body_params) do
      {
        'cost' => '3',
        'phones' => '79991234567,79997654321',
        'mes' => message,
        'time' => '0911191225',
        'fmt' => fmt.to_s,
        'id' => '12345',
        'charset' => charset,
        'login' => 'test_login',
        'psw' => 'test_passwd',
        'translit' => '1',
        'other_parameter' => 'yes'
      }
    end
    let(:response) { OpenStruct.new(body: '12345,2,4.48,1231.21') }
    let(:fmt) { 1 }
    let(:charset) { 'koi8-r' }
    let(:phones) { %w[79991234567 79997654321] }
    let(:message) { 'test message' }
    let(:request_params) { { id: 12345, fmt: fmt, time: Time.now, charset: charset, translit: 1, other_parameter: 'yes' } }

    it 'makes a request with correct params' do
      stub = stub_template
      request
      expect(stub).to have_been_requested
    end

    context 'when configured for http' do
      before do
        allow_any_instance_of(ActieSmsc::Configuration).to receive(:use_https).and_return(false)
      end

      it 'makes a request using http' do
        stub = stub_request(:post, 'http://smsc.ru/sys/send.php').with(body: body_params)
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
          'https://smsc.ru/sys/send.php?charset=koi8-r&cost=3&fmt=1&id=12345&login=test_login&mes=test%20message&other_parameter=yes&phones=79991234567,79997654321&psw=test_passwd&time=0911191225&translit=1'
        )

        request
        expect(stub).to have_been_requested
      end
    end

    it 'returns correct value' do
      stub = stub_template
      expect(request).to eq(id: 12345, cnt: 2, cost: 4.48, balance: 1231.21)
    end

    context 'with JSON format' do
      let(:fmt) { 3 }
      let(:response) { OpenStruct.new(body: '{"id":"12345","cnt":"2","cost":"4.48","balance":"1231.21"}') }

      it 'returns correct value' do
        stub = stub_template
        expect(request).to eq('id' => '12345', 'cnt' => '2', 'cost' => '4.48', 'balance' => '1231.21')
      end
    end

    context 'with XML format' do
      let(:fmt) { 2 }
      let(:response) { OpenStruct.new(body: '<id>12345</id><cnt>2</cnt><cost>4.48</cost><balance>1231.21</balance>') }

      it 'returns correct value' do
        stub = stub_template
        expect(request).to eq('<id>12345</id><cnt>2</cnt><cost>4.48</cost><balance>1231.21</balance>')
      end
    end

    context 'with string format' do
      let(:fmt) { 0 }
      let(:response) { OpenStruct.new(body: 'OK - 2 SMS, ID - 12345, COST - 4.48') }

      it 'returns correct value' do
        stub = stub_template
        expect(request).to eq('OK - 2 SMS, ID - 12345, COST - 4.48')
      end
    end

    context 'with response object format' do
      let(:fmt) { :response }

      it 'returns correct value' do
        stub = stub_template
        expect(request).to be_a(Faraday::Response)
      end
    end

    context 'with error response' do
      let(:response) { OpenStruct.new(body: '0,-1') }

      it 'raises an exception' do
        stub = stub_template
        expect { request }.to raise_exception(ActieSmsc::SmscError, 'Error code: 1')
      end
    end
  end
end
