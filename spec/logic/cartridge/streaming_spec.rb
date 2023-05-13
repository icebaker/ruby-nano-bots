# frozen_string_literal: true

require 'yaml'

require_relative '../../../logic/cartridge/streaming'

RSpec.describe NanoBot::Logic::Cartridge::Streaming do
  context 'provider' do
    let(:cartridge) { load_cartridge('streaming.yml') }

    it 'checks if stream is enabled' do
      cartridge[:provider][:settings][:stream] = false
      expect(described_class.enabled?(cartridge, :repl)).to be(false)
    end
  end

  context 'repl' do
    let(:cartridge) { load_cartridge('streaming.yml') }

    it 'checks if stream is enabled' do
      cartridge[:interfaces][:repl][:output][:stream] = false
      expect(described_class.enabled?(cartridge, :repl)).to be(false)
    end
  end

  context 'interface + repl' do
    let(:cartridge) { load_cartridge('streaming.yml') }

    it 'checks if stream is enabled' do
      cartridge[:interfaces][:output][:stream] = false
      cartridge[:interfaces][:repl][:output][:stream] = true
      expect(described_class.enabled?(cartridge, :repl)).to be(true)
    end
  end

  context 'interface' do
    let(:cartridge) { load_cartridge('streaming.yml') }

    it 'checks if stream is enabled' do
      cartridge[:interfaces][:output][:stream] = false
      cartridge[:interfaces][:repl][:output].delete(:stream)
      expect(described_class.enabled?(cartridge, :repl)).to be(false)
    end
  end

  context '- repl' do
    let(:cartridge) { load_cartridge('streaming.yml') }

    it 'checks if stream is enabled' do
      cartridge[:interfaces][:repl][:output].delete(:stream)
      expect(described_class.enabled?(cartridge, :repl)).to be(true)
    end
  end

  context '- interface' do
    let(:cartridge) { load_cartridge('streaming.yml') }

    it 'checks if stream is enabled' do
      cartridge[:interfaces][:output].delete(:stream)
      cartridge[:interfaces][:repl][:output].delete(:stream)
      expect(described_class.enabled?(cartridge, :repl)).to be(true)
    end
  end

  context '- provider' do
    let(:cartridge) { load_cartridge('streaming.yml') }

    it 'checks if stream is enabled' do
      cartridge[:provider][:settings].delete(:stream)
      cartridge[:interfaces][:output].delete(:stream)
      cartridge[:interfaces][:repl][:output].delete(:stream)
      expect(described_class.enabled?(cartridge, :repl)).to be(true)
    end
  end
end
