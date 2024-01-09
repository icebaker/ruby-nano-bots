# frozen_string_literal: true

require_relative '../../../logic/cartridge/parser'

RSpec.describe NanoBot::Logic::Cartridge::Parser do
  context 'markdown' do
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
end
