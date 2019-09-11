# frozen_string_literal: true

RSpec.shared_examples 'balance_method' do
  describe '#balance' do
    subject(:request) { described_class.balance(fmt: fmt) }

    let(:stub_template) do
      stub_request(:post, 'https://smsc.ru/sys/balance.php').with(
        body: {
          'fmt' => fmt.to_s,
          'charset' => 'utf-8',
          'login' => 'test_login',
          'psw' => 'test_passwd'
        }
      ).to_return(response)
    end
    let(:fmt) { 1 }
    let(:response) { OpenStruct.new(body: '123.43') }

    it 'makes a request with correct params' do
      stub = stub_template
      request
      expect(stub).to have_been_requested
    end

    it 'returns correct value' do
      stub = stub_template
      expect(request).to eq(123.43)
    end

    context 'with JSON format' do
      let(:fmt) { 3 }
      let(:response) { OpenStruct.new(body: '{"balance":"123.43"}') }

      it 'returns correct value' do
        stub = stub_template
        expect(request).to eq('balance' => '123.43')
      end
    end

    context 'with XML format' do
      let(:fmt) { 2 }
      let(:response) { OpenStruct.new(body: '<balance>123.43</balance>') }

      it 'returns correct value' do
        stub = stub_template
        expect(request).to eq('<balance>123.43</balance>')
      end
    end

    context 'with string format' do
      let(:fmt) { 0 }
      let(:response) { OpenStruct.new(body: '123.43') }

      it 'returns correct value' do
        stub = stub_template
        expect(request).to eq('123.43')
      end
    end

    context 'with response object format' do
      let(:fmt) { :response }
      let(:response) { OpenStruct.new(body: '123.43') }

      it 'returns correct value' do
        stub = stub_template
        expect(request).to be_a(Faraday::Response)
      end
    end
  end
end
