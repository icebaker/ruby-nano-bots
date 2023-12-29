# frozen_string_literal: true

require 'yaml'

require_relative '../../../logic/cartridge/interaction'

RSpec.describe NanoBot::Logic::Cartridge::Interaction do
  context 'input' do
    let(:cartridge) { load_symbolized('cartridges/affixes.yml') }

    it 'prepares the input' do
      expect(described_class.input(cartridge, :repl, 'hello')).to eq(
        { content: 'hello', fennel: nil, lua: nil, clojure: nil, prefix: 'E', suffix: 'F' }
      )

      expect(described_class.input({}, :repl, 'hello')).to eq(
        { content: 'hello', fennel: nil, lua: nil, clojure: nil, prefix: nil, suffix: nil }
      )

      expect(described_class.input(cartridge, :eval, 'hello')).to eq(
        { content: 'hello', fennel: nil, lua: nil, clojure: nil, prefix: 'I', suffix: 'J' }
      )

      expect(described_class.input({}, :eval, 'hello')).to eq(
        { content: 'hello', fennel: nil, lua: nil, clojure: nil, prefix: nil, suffix: nil }
      )
    end

    it 'prepares the non-streaming output' do
      expect(described_class.output(cartridge, :repl, { message: 'hello' }, false, true)).to eq(
        { message: { content: 'hello', fennel: nil, lua: nil, clojure: nil } }
      )

      expect(described_class.output({}, :repl, { message: 'hello' }, false, true)).to eq(
        { message: { content: 'hello', fennel: nil, lua: nil, clojure: nil } }
      )

      expect(described_class.output(cartridge, :eval, { message: 'hello' }, false, true)).to eq(
        { message: { content: 'hello', fennel: nil, lua: nil, clojure: nil } }
      )

      expect(described_class.output({}, :eval, { message: 'hello' }, false, true)).to eq(
        { message: { content: 'hello', fennel: nil, lua: nil, clojure: nil } }
      )
    end
  end
end
