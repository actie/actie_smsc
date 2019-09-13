# frozen_string_literal: true

RSpec.shared_examples 'status_method' do
  before { Timecop.freeze('2019-11-09T12:25') }
  after { Timecop.return }

  describe '#status' do
    subject(:request) { described_class.status(123, '79991234567', all: all, fmt: fmt) }

    let(:stub_template) { stub_request(:post, 'https://smsc.ru/sys/status.php').with(body: body_params).to_return(response) }
    let(:body_params) do
      {
        'id' => '123',
        'phone' => '79991234567',
        'fmt' => fmt.to_s,
        'charset' => 'utf-8',
        'login' => 'test_login',
        'psw' => 'test_passwd',
        'all' => all.to_s
      }
    end
    let(:response) { OpenStruct.new(body: "1,#{Time.now.to_i},0") }
    let(:fmt) { 1 }
    let(:all) { 0 }

    it 'makes a request with correct params' do
      stub = stub_template
      request
      expect(stub).to have_been_requested
    end

    it 'returns correct value' do
      stub = stub_template
      expect(request).to eq(status: 1, change_time: Time.now, error_code: 0)
    end

    context 'with all parameter' do
      let(:response) { OpenStruct.new(body: "1,#{Time.now.to_i},0,#{Time.now.to_i},79991234567,2.12,GLOBUS,Доставлено,test_message,0") }
      let(:all) { 1 }

      it 'makes a request with correct params' do
        stub = stub_template
        request
        expect(stub).to have_been_requested
      end

      it 'returns correct value' do
        stub = stub_template
        expect(request).to eq(
          status:         1,
          change_time:    Time.now,
          error_code:     0,
          send_time:      Time.now,
          phone:          '79991234567',
          cost:           2.12,
          sender:         'GLOBUS',
          status_message: 'Доставлено',
          message:        'test_message'
        )
      end
    end

    context 'with JSON format' do
      let(:fmt) { 3 }
      let(:response) { OpenStruct.new(body: %({"status":"1","change_time":"#{Time.now.to_i}","error_code":"0"})) }

      it 'returns correct value' do
        stub = stub_template
        expect(request).to eq('status' => '1', 'change_time' => "#{Time.now.to_i}", 'error_code' => '0')
      end
    end

    context 'with XML format' do
      let(:fmt) { 2 }
      let(:response) { OpenStruct.new(body: "<status>1</status><change_time>#{Time.now.to_i}</change_time><error_code>0</error_code>") }

      it 'returns correct value' do
        stub = stub_template
        expect(request).to eq("<status>1</status><change_time>#{Time.now.to_i}</change_time><error_code>0</error_code>")
      end
    end

    context 'with string format' do
      let(:fmt) { 0 }
      let(:response) { OpenStruct.new(body: 'STATUS - OK, ERROR - 0') }

      it 'returns correct value' do
        stub = stub_template
        expect(request).to eq('STATUS - OK, ERROR - 0')
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
