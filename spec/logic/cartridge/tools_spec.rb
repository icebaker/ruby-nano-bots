# frozen_string_literal: true

require 'yaml'

require_relative '../../../logic/cartridge/tools'

RSpec.describe NanoBot::Logic::Cartridge::Tools do
  context 'interfaces override' do
    context 'defaults' do
      let(:cartridge) { {} }

      it 'uses default values when appropriate' do
        expect(described_class.feedback?(cartridge, :repl, :executing)).to be(false)
        expect(described_class.feedback?(cartridge, :eval, :executing)).to be(false)

        expect(described_class.feedback?(cartridge, :repl, :responding)).to be(true)
        expect(described_class.feedback?(cartridge, :eval, :responding)).to be(true)
      end
    end

    context 'top-level overrides' do
      let(:cartridge) do
        { interfaces: { tools: { feedback: false } } }
      end

      it 'overrides default values when appropriate' do
        expect(described_class.feedback?(cartridge, :repl, :executing)).to be(false)
        expect(described_class.feedback?(cartridge, :eval, :executing)).to be(false)

        expect(described_class.feedback?(cartridge, :repl, :responding)).to be(false)
        expect(described_class.feedback?(cartridge, :eval, :responding)).to be(false)
      end
    end

    context 'top-level overrides' do
      let(:cartridge) do
        { interfaces: { tools: { feedback: true } } }
      end

      it 'overrides default values when appropriate' do
        expect(described_class.feedback?(cartridge, :repl, :executing)).to be(true)
        expect(described_class.feedback?(cartridge, :eval, :executing)).to be(true)

        expect(described_class.feedback?(cartridge, :repl, :responding)).to be(true)
        expect(described_class.feedback?(cartridge, :eval, :responding)).to be(true)
      end
    end

    context 'top-level-specific overrides' do
      let(:cartridge) do
        { interfaces: { tools: { executing: { feedback: false }, responding: { feedback: true } } } }
      end

      it 'overrides default values when appropriate' do
        expect(described_class.feedback?(cartridge, :repl, :executing)).to be(false)
        expect(described_class.feedback?(cartridge, :eval, :executing)).to be(false)

        expect(described_class.feedback?(cartridge, :repl, :responding)).to be(true)
        expect(described_class.feedback?(cartridge, :eval, :responding)).to be(true)
      end
    end

    context 'repl interface overrides' do
      let(:cartridge) do
        { interfaces: {
          tools: { executing: { feedback: false }, responding: { feedback: true } },
          repl: { tools: { executing: { feedback: true }, responding: { feedback: false } } }
        } }
      end

      it 'overrides default values when appropriate' do
        expect(described_class.feedback?(cartridge, :repl, :executing)).to be(true)
        expect(described_class.feedback?(cartridge, :eval, :executing)).to be(false)

        expect(described_class.feedback?(cartridge, :repl, :responding)).to be(false)
        expect(described_class.feedback?(cartridge, :eval, :responding)).to be(true)
      end
    end

    context 'eval interface overrides' do
      let(:cartridge) do
        { interfaces: {
          tools: { executing: { feedback: false }, responding: { feedback: true } },
          eval: { tools: { executing: { feedback: true }, responding: { feedback: false } } }
        } }
      end

      it 'overrides default values when appropriate' do
        expect(described_class.feedback?(cartridge, :repl, :executing)).to be(false)
        expect(described_class.feedback?(cartridge, :eval, :executing)).to be(true)

        expect(described_class.feedback?(cartridge, :repl, :responding)).to be(true)
        expect(described_class.feedback?(cartridge, :eval, :responding)).to be(false)
      end
    end
  end
end
