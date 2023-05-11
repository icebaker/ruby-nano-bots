# frozen_string_literal: true

require_relative '../instance'

module NanoBot
  module Controllers
    module Interfaces
      module CLI
        def self.handle!
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
