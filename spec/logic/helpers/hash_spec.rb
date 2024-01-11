# frozen_string_literal: true

require_relative '../../../logic/helpers/hash'

RSpec.describe NanoBot::Logic::Helpers::Hash do
  it 'symbolizes keys' do
    expect(described_class.symbolize_keys({ 'a' => 'b', 'c' => { 'd' => ['e'] } })).to eq(
      { a: 'b', c: { d: ['e'] } }
    )
  end

  it 'deep merges' do
    expect(described_class.deep_merge(
             { a: { x: 1, y: 2 }, b: 3 },
             { a: { y: 99, z: 4 }, c: 5 }
           )).to eq(
             { a: { x: 1, y: 99, z: 4 }, b: 3, c: 5 }
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
