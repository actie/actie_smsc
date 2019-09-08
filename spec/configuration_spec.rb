# frozen_string_literal: true

RSpec.describe ActieSmsc::Configuration do
  let(:config) { described_class.new }

  describe 'readers' do
    it 'returns correct value for use_post' do
      expect(config.use_post).to eq(true)
    end

    it 'returns correct value for use_https' do
      expect(config.use_https).to eq(true)
    end

    it 'returns correct value for charset' do
      expect(config.charset).to eq('utf-8')
    end

    it 'returns correct value for debug' do
      expect(config.debug).to eq(false)
    end

    it 'returns correct value for logger' do
      expect(config.logger).to be_a(Logger)
    end

    context 'when used in Rails app' do
      before do
        class Rails; end

        allow(Rails).to receive(:logger).and_return(Logger.new($stdout))
      end

      after { Object.send(:remove_const, :Rails) }

      it 'uses Rails.logger' do
        expect(Rails).to receive(:logger)
        expect(config.logger).to be_a(Logger)
      end
    end

    context 'required attributes' do
      it 'raises exception if login is not defined' do
        expect { config.login }.to raise_error(ActieSmsc::InvalidConfigurationError)
      end

      it 'raises exception if password is not defined' do
        expect { config.password }.to raise_error(ActieSmsc::InvalidConfigurationError)
      end
    end
  end

  describe 'writers' do
    it 'changes value for use_post' do
      expect { config.use_post = false }.to(
        change { config.use_post }.from(true).to(false)
      )
    end

    it 'changes value for use_https' do
      expect { config.use_https = false }.to(
        change { config.use_https }.from(true).to(false)
      )
    end

    it 'changes value for charset' do
      expect { config.charset = 'koi8-r' }.to(
        change { config.charset }.from('utf-8').to('koi8-r')
      )
    end

    it 'changes value for debug' do
      expect { config.debug = true }.to(
        change { config.debug }.from(false).to(true)
      )
    end

    it 'changes value for logger' do
      expect { config.logger = Logger.new($stdout) }.to(change { config.logger })
    end

    context 'charset validation' do
      it 'rejects invalid charset values' do
        expect { config.charset = 'utf-16' }.to raise_error(ActieSmsc::InvalidConfigurationError)
      end
    end
  end
end
