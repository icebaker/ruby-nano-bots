# frozen_string_literal: true

require 'dotenv/load'

require_relative '../../static/gem'
require_relative '../../controllers/cartridges'
require_relative '../../controllers/instance'
require_relative '../../controllers/security'
require_relative '../../controllers/interfaces/cli'
require_relative '../../components/stream'
require_relative 'nano-bots/cartridges'

module NanoBot
  def self.new(cartridge: '-', state: '-', environment: {})
    Controllers::Instance.new(
      cartridge_path: cartridge,
      state:,
      stream: Components::Stream.new,
      environment:
    )
  end

  def self.security
    Controllers::Security
  end

  def self.cartridges
    Cartridges
  end

  def self.cli
    Controllers::Interfaces::CLI.handle!
  end

  def self.repl(cartridge: '-', state: '-', environment: {})
    Controllers::Instance.new(
      cartridge_path: cartridge, state:, stream: $stdout, environment:
    ).repl
  end

  def self.version
    NanoBot::GEM[:version]
  end

  def self.specification
    NanoBot::GEM[:specification]
  end
end
