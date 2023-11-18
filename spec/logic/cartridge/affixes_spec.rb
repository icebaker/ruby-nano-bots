# frozen_string_literal: true

require 'yaml'

require_relative '../../../logic/cartridge/affixes'

RSpec.describe NanoBot::Logic::Cartridge::Affixes do
  context 'interfaces' do
    let(:cartridge) { load_symbolized('cartridges/affixes.yml') }

    it 'gets the expected affixes' do
      expect(described_class.get(cartridge, :repl, :input, :prefix)).to eq('E')
      expect(described_class.get(cartridge, :repl, :input, :suffix)).to eq('F')
      expect(described_class.get(cartridge, :repl, :output, :prefix)).to eq('G')
      expect(described_class.get(cartridge, :repl, :output, :suffix)).to eq('H')

      expect(described_class.get(cartridge, :eval, :input, :prefix)).to eq('I')
      expect(described_class.get(cartridge, :eval, :input, :suffix)).to eq('J')
      expect(described_class.get(cartridge, :eval, :output, :prefix)).to eq('K')
      expect(described_class.get(cartridge, :eval, :output, :suffix)).to eq('L')
    end
  end

  context 'interfaces fallback' do
    let(:cartridge) { load_symbolized('cartridges/affixes.yml') }

    it 'gets the expected affixes' do
      cartridge[:interfaces][:repl][:input].delete(:prefix)
      cartridge[:interfaces][:repl][:input].delete(:suffix)
      cartridge[:interfaces][:eval][:input].delete(:prefix)
      cartridge[:interfaces][:eval][:input].delete(:suffix)

      cartridge[:interfaces][:repl][:output].delete(:prefix)
      cartridge[:interfaces][:repl][:output].delete(:suffix)
      cartridge[:interfaces][:eval][:output].delete(:prefix)
      cartridge[:interfaces][:eval][:output].delete(:suffix)

      expect(described_class.get(cartridge, :repl, :input, :prefix)).to eq('A')
      expect(described_class.get(cartridge, :repl, :input, :suffix)).to eq('B')
      expect(described_class.get(cartridge, :repl, :output, :prefix)).to eq('C')
      expect(described_class.get(cartridge, :repl, :output, :suffix)).to eq('D')

      expect(described_class.get(cartridge, :eval, :input, :prefix)).to eq('A')
      expect(described_class.get(cartridge, :eval, :input, :suffix)).to eq('B')
      expect(described_class.get(cartridge, :eval, :output, :prefix)).to eq('C')
      expect(described_class.get(cartridge, :eval, :output, :suffix)).to eq('D')
    end
  end

  context 'interfaces nil' do
    let(:cartridge) { load_symbolized('cartridges/affixes.yml') }

    it 'gets the expected affixes' do
      cartridge[:interfaces][:repl][:input][:prefix] = nil
      cartridge[:interfaces][:repl][:input][:suffix] = nil
      cartridge[:interfaces][:eval][:input][:prefix] = nil
      cartridge[:interfaces][:eval][:input][:suffix] = nil

      cartridge[:interfaces][:repl][:output][:prefix] = nil
      cartridge[:interfaces][:repl][:output][:suffix] = nil
      cartridge[:interfaces][:eval][:output][:prefix] = nil
      cartridge[:interfaces][:eval][:output][:suffix] = nil

      expect(described_class.get(cartridge, :repl, :input, :prefix)).to be_nil
      expect(described_class.get(cartridge, :repl, :input, :suffix)).to be_nil
      expect(described_class.get(cartridge, :repl, :output, :prefix)).to be_nil
      expect(described_class.get(cartridge, :repl, :output, :suffix)).to be_nil

      expect(described_class.get(cartridge, :eval, :input, :prefix)).to be_nil
      expect(described_class.get(cartridge, :eval, :input, :suffix)).to be_nil
      expect(described_class.get(cartridge, :eval, :output, :prefix)).to be_nil
      expect(described_class.get(cartridge, :eval, :output, :suffix)).to be_nil
    end
  end

  context 'default' do
    let(:cartridge) { {} }

    it 'gets the expected affixes' do
      expect(described_class.get(cartridge, :repl, :input, :prefix)).to be_nil
      expect(described_class.get(cartridge, :repl, :input, :suffix)).to be_nil
      expect(described_class.get(cartridge, :repl, :output, :prefix)).to eq("\n")
      expect(described_class.get(cartridge, :repl, :output, :suffix)).to eq("\n")

      expect(described_class.get(cartridge, :eval, :input, :prefix)).to be_nil
      expect(described_class.get(cartridge, :eval, :input, :suffix)).to be_nil
      expect(described_class.get(cartridge, :eval, :output, :prefix)).to be_nil
      expect(described_class.get(cartridge, :eval, :output, :suffix)).to eq("\n")
    end
  end
end
