# frozen_string_literal: true

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
end
