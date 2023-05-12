# frozen_string_literal: true

require_relative '../instance'
require_relative '../../static/gem'

module NanoBot
  module Controllers
    module Interfaces
      module CLI
        def self.handle!
          case ARGV[0]
          when 'version'
            puts NanoBot::GEM[:version]
            exit
          when 'help', '', nil
            puts "Ruby Nano Bots #{NanoBot::GEM[:version]}"
            puts '  rnb cartridge.yml - eval "Hello!"'
            puts '  rnb cartridge.yml - repl'
            puts '  rnb cartridge.yml - debug'
            puts '  rnb cartridge.yml STATE-KEY eval "Hello!"'
            puts '  rnb cartridge.yml STATE-KEY repl'
            puts '  rnb cartridge.yml STATE-KEY debug'
            puts '  rnb version'
            exit
          end

          params = { cartridge_path: ARGV[0], state: ARGV[1], command: ARGV[2] }

          bot = Instance.new(cartridge_path: params[:cartridge_path], state: params[:state])

          case params[:command]
          when 'eval'
            params[:input] = ARGV[3..]&.join(' ')
            params[:input] = $stdin.read.chomp if params[:input].nil? || params[:input].empty?
            bot.eval(params[:input])
          when 'repl'
            bot.repl
          when 'debug'
            bot.debug
          else
            raise "TODO: [#{params[:command]}]"
          end
        end
      end
    end
  end
end
