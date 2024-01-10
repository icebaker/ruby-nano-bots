# frozen_string_literal: true

require_relative '../../components/storage'

RSpec.describe NanoBot::Components::Storage do
  it 'symbolizes keys' do
    expect(
      described_class.cartridges_path(
        components: { home: '/home/aqua', ENV: {}, directory?: ->(_) { true } }
      )
    ).to eq('/home/aqua/.local/share/nano-bots/cartridges')

    expect(
      described_class.cartridges_path(
        components: {
          home: '/home/aqua',
          ENV: { 'NANO_BOTS_CARTRIDGES_DIRECTORY' => '/home/aqua/my-cartridges' },
          directory?: ->(_) { true }
        }
      )
    ).to eq('/home/aqua/my-cartridges')

    expect(
      described_class.cartridges_path(
        components: {
          home: '/home/aqua',
          ENV: {
            'NANO_BOTS_CARTRIDGES_DIRECTORY' => '/home/aqua/my-cartridges',
            'NANO_BOTS_CARTRIDGES_PATH' => '/home/aqua/lime/my-cartridges'
          },
          directory?: ->(_) { true }
        }
      )
    ).to eq('/home/aqua/lime/my-cartridges:/home/aqua/my-cartridges')

    expect(
      described_class.cartridges_path(
        components: {
          home: '/home/aqua',
          ENV: {
            'NANO_BOTS_CARTRIDGES_DIRECTORY' => '/home/aqua/my-cartridges',
            'NANO_BOTS_CARTRIDGES_PATH' => '/home/aqua/lime/my-cartridges:/home/aqua/ivory/my-cartridges'
          },
          directory?: lambda do |path|
            { '/home/aqua/my-cartridges' => true,
              '/home/aqua/lime/my-cartridge' => false,
              '/home/aqua/ivory/my-cartridges' => true }[path]
          end
        }
      )
    ).to eq('/home/aqua/ivory/my-cartridges:/home/aqua/my-cartridges')
  end
end
