# frozen_string_literal: true

RSpec.shared_examples 'status_method' do
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
end
