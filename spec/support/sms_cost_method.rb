# frozen_string_literal: true

RSpec.shared_examples 'sms_cost_method' do
  describe '#sms_cost' do
    subject(:request) { described_class.sms_cost(phones, message, request_params) }

    let(:stub_template) { stub_request(:post, 'https://smsc.ru/sys/send.php').with(body: body_params).to_return(response) }
    let(:body_params) do
      {
        'cost' => '1',
        'phones' => '79991234567,79997654321',
        'mes' => message,
        'fmt' => fmt.to_s,
        'id' => '12345',
        'charset' => charset,
        'login' => 'test_login',
        'psw' => 'test_passwd',
        'translit' => '1',
        'other_parameter' => 'yes'
      }
    end
    let(:response) { OpenStruct.new(body: '4.48,2') }
    let(:fmt) { 1 }
    let(:charset) { 'koi8-r' }
    let(:phones) { %w[79991234567 79997654321] }
    let(:message) { 'test message' }
    let(:request_params) { { id: 12345, fmt: fmt, charset: charset, translit: 1, other_parameter: 'yes' } }

    it 'makes a request with correct params' do
      stub = stub_template
      request
      expect(stub).to have_been_requested
    end

    it 'returns correct value' do
      stub = stub_template
      expect(request).to eq(cnt: 2, cost: 4.48)
    end

    context 'with JSON format' do
      let(:fmt) { 3 }
      let(:response) { OpenStruct.new(body: '{"cnt":"2","cost":"4.48"}') }

      it 'returns correct value' do
        stub = stub_template
        expect(request).to eq('cnt' => '2', 'cost' => '4.48')
      end
    end

    context 'with XML format' do
      let(:fmt) { 2 }
      let(:response) { OpenStruct.new(body: '<cnt>2</cnt><cost>4.48</cost>') }

      it 'returns correct value' do
        stub = stub_template
        expect(request).to eq('<cnt>2</cnt><cost>4.48</cost>')
      end
    end

    context 'with string format' do
      let(:fmt) { 0 }
      let(:response) { OpenStruct.new(body: 'OK - 2 SMS, COST - 4.48') }

      it 'returns correct value' do
        stub = stub_template
        expect(request).to eq('OK - 2 SMS, COST - 4.48')
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
