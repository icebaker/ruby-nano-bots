# frozen_string_literal: true

require_relative '../../../logic/helpers/hash'

RSpec.describe NanoBot::Logic::Helpers::Hash do
  it 'symbolizes keys' do
    expect(described_class.symbolize_keys({ 'a' => 'b', 'c' => { 'd' => ['e'] } })).to eq(
      { a: 'b', c: { d: ['e'] } }
    )
  end

  it 'stringify keys' do
    expect(described_class.stringify_keys({ a: 'b', c: { d: [:e] } })).to eq(
      { 'a' => 'b', 'c' => { 'd' => [:e] } }
    )
  end

  it 'fetch a path of keys' do
    expect(described_class.fetch({ a: 'b', c: { d: ['e'] } }, %i[c d])).to eq(
      ['e']
    )

    expect(described_class.fetch({ a: 'b', c: { d: ['e'] } }, %i[c e])).to be_nil

    expect(described_class.fetch({ a: 'b', c: { d: ['e'] } }, %i[a b])).to be_nil
  end
end
