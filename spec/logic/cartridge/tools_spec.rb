# frozen_string_literal: true

require 'yaml'

require_relative '../../../logic/cartridge/tools'

RSpec.describe NanoBot::Logic::Cartridge::Tools do
  context 'interfaces override' do
    context 'defaults' do
      let(:cartridge) { {} }

      it 'uses default values when appropriate' do
        expect(described_class.feedback?(cartridge, :repl, :call)).to be(true)
        expect(described_class.feedback?(cartridge, :eval, :call)).to be(true)

        expect(described_class.feedback?(cartridge, :repl, :response)).to be(false)
        expect(described_class.feedback?(cartridge, :eval, :response)).to be(false)
      end
    end

    context 'top-level overrides' do
      let(:cartridge) do
        { interfaces: { tools: { feedback: false } } }
      end

      it 'overrides default values when appropriate' do
        expect(described_class.feedback?(cartridge, :repl, :call)).to be(false)
        expect(described_class.feedback?(cartridge, :eval, :call)).to be(false)

        expect(described_class.feedback?(cartridge, :repl, :response)).to be(false)
        expect(described_class.feedback?(cartridge, :eval, :response)).to be(false)
      end
    end

    context 'top-level overrides' do
      let(:cartridge) do
        { interfaces: { tools: { feedback: true } } }
      end

      it 'overrides default values when appropriate' do
        expect(described_class.feedback?(cartridge, :repl, :call)).to be(true)
        expect(described_class.feedback?(cartridge, :eval, :call)).to be(true)

        expect(described_class.feedback?(cartridge, :repl, :response)).to be(true)
        expect(described_class.feedback?(cartridge, :eval, :response)).to be(true)
      end
    end

    context 'top-level-specific overrides' do
      let(:cartridge) do
        { interfaces: { tools: { call: { feedback: false }, response: { feedback: true } } } }
      end

      it 'overrides default values when appropriate' do
        expect(described_class.feedback?(cartridge, :repl, :call)).to be(false)
        expect(described_class.feedback?(cartridge, :eval, :call)).to be(false)

        expect(described_class.feedback?(cartridge, :repl, :response)).to be(true)
        expect(described_class.feedback?(cartridge, :eval, :response)).to be(true)
      end
    end

    context 'repl interface overrides' do
      let(:cartridge) do
        { interfaces: {
          tools: { call: { feedback: false }, response: { feedback: true } },
          repl: { tools: { call: { feedback: true }, response: { feedback: false } } }
        } }
      end

      it 'overrides default values when appropriate' do
        expect(described_class.feedback?(cartridge, :repl, :call)).to be(true)
        expect(described_class.feedback?(cartridge, :eval, :call)).to be(false)

        expect(described_class.feedback?(cartridge, :repl, :response)).to be(false)
        expect(described_class.feedback?(cartridge, :eval, :response)).to be(true)
      end
    end

    context 'eval interface overrides' do
      let(:cartridge) do
        { interfaces: {
          tools: { call: { feedback: false }, response: { feedback: true } },
          eval: { tools: { call: { feedback: true }, response: { feedback: false } } }
        } }
      end

      it 'overrides default values when appropriate' do
        expect(described_class.feedback?(cartridge, :repl, :call)).to be(false)
        expect(described_class.feedback?(cartridge, :eval, :call)).to be(true)

        expect(described_class.feedback?(cartridge, :repl, :response)).to be(true)
        expect(described_class.feedback?(cartridge, :eval, :response)).to be(false)
      end
    end
  end
end
