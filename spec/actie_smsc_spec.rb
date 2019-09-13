# frozen_string_literal: true

require 'timecop'
require 'webmock/rspec'

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

  include_examples 'send_sms_method'
  include_examples 'sms_cost_method'
  include_examples 'status_method'
  include_examples 'balance_method'
end
