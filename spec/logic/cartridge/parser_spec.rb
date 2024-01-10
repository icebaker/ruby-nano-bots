# frozen_string_literal: true

require_relative '../../../logic/cartridge/parser'

RSpec.describe NanoBot::Logic::Cartridge::Parser do
  context 'markdown' do
    context 'default' do
      let(:raw) { File.read('spec/data/cartridges/markdown.md') }

      it 'parses markdown cartridge' do
        expect(described_class.parse(raw, format: 'md')).to eq(
          { meta: {
              symbol: '🤖',
              name: 'ChatGPT 4 Turbo',
              author: 'icebaker',
              version: '0.0.1',
              license: 'CC0-1.0',
              description: 'A helpful assistant.'
            },
            behaviors: { interaction: { directive: 'You are a helpful assistant.' } },
            provider: {
              id: 'openai',
              credentials: { 'access-token': 'ENV/OPENAI_API_KEY' },
              settings: {
                user: 'ENV/NANO_BOTS_END_USER',
                model: 'gpt-4-1106-preview'
              }
            } }
        )
      end
    end

    context 'tools' do
      let(:raw) { File.read('spec/data/cartridges/tools.md') }

      it 'parses markdown cartridge' do
        expect(described_class.parse(raw, format: 'md')).to eq(
          { meta: {
              symbol: '🕛',
              name: 'Date and Time',
              author: 'icebaker',
              version: '0.0.1',
              license: 'CC0-1.0',
              description: 'A helpful assistant.'
            },
            behaviors: {
              interaction: {
                directive: 'You are a helpful assistant.'
              }
            },
            provider: {
              id: 'openai',
              credentials: { 'access-token': 'ENV/OPENAI_API_KEY' },
              settings: {
                user: 'ENV/NANO_BOTS_END_USER',
                model: 'gpt-4-1106-preview'
              }
            },
            tools: [
              { name: 'random-number',
                description: 'Generates a random number within a given range.',
                parameters: {
                  type: 'object',
                  properties: {
                    from: {
                      type: 'integer',
                      description: 'The minimum expected number for random generation.'
                    },
                    to: {
                      type: 'integer',
                      description: 'The maximum expected number for random generation.'
                    }
                  },
                  required: %w[from to]
                },
                clojure: "(let [{:strs [from to]} parameters]\n  (+ from (rand-int (+ 1 (- to from)))))\n" },
              { name: 'date-and-time',
                description: 'Returns the current date and time.',
                fennel: "(os.date)\n" }
            ] }
        )
      end
    end

    context 'block' do
      let(:raw) { File.read('spec/data/cartridges/block.md') }

      it 'parses markdown cartridge' do
        expect(described_class.parse(raw, format: 'md')).to eq(
          { safety: { functions: { sandboxed: false } } }
        )
      end
    end
  end
end
