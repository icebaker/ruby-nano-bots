# frozen_string_literal: true

require 'dotenv/load'

require_relative '../../static/gem'
require_relative '../../controllers/cartridges'
require_relative '../../controllers/instance'
require_relative '../../controllers/interfaces/cli'
require_relative '../../components/stream'

module NanoBot
  def self.new(cartridge: '-', state: '-')
    Controllers::Instance.new(cartridge_path: cartridge, state:, stream: Components::Stream.new)
  end

  def self.cartridges
    Controllers::Cartridges.all
  end

  def self.cli
    Controllers::Interfaces::CLI.handle!
  end

  def self.repl(cartridge: '-', state: '-')
    Controllers::Instance.new(cartridge_path: cartridge, state:, stream: $stdout).repl
  end

  def self.version
    NanoBot::GEM[:version]
  end
end
