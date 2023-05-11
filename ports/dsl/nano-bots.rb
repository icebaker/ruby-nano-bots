# frozen_string_literal: true

require 'dotenv/load'

require_relative '../../static/gem'
require_relative '../../controllers/instance'
require_relative '../../controllers/interfaces/cli'

module NanoBot
  def self.new(cartridge:, state: '-')
    Controllers::Instance.new(cartridge_path: cartridge, state:)
  end

  def self.cli
    Controllers::Interfaces::CLI.handle!
  end

  def self.repl(cartridge:, state: '-')
    Controllers::Instance.new(cartridge_path: cartridge, state:).repl
  end

  def self.version
    NanoBot::GEM[:version]
  end
end
