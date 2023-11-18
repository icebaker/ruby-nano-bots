# frozen_string_literal: true

require 'pry'
require 'rainbow'

require_relative '../../logic/helpers/hash'
require_relative '../../logic/cartridge/affixes'

module NanoBot
  module Controllers
    module Interfaces
      module REPL
        def self.boot(cartridge, session, prefix = nil, suffix = nil, as: 'repl')
          return unless Logic::Helpers::Hash.fetch(cartridge, %i[behaviors boot instruction])

          prefix ||= Logic::Cartridge::Affixes.get(cartridge, as.to_sym, :output, :prefix)
          suffix ||= Logic::Cartridge::Affixes.get(cartridge, as.to_sym, :output, :suffix)

          session.print(prefix) unless prefix.nil?
          session.boot(mode: as)
          session.print(suffix) unless suffix.nil?
        end

        def self.start(cartridge, session)
          prefix = Logic::Cartridge::Affixes.get(cartridge, :repl, :output, :prefix)
          suffix = Logic::Cartridge::Affixes.get(cartridge, :repl, :output, :suffix)

          boot(cartridge, session, prefix, suffix)

          session.print("\n") if Logic::Helpers::Hash.fetch(cartridge, %i[behaviors boot instruction])

          prompt = self.prompt(cartridge)

          Pry.config.prompt = Pry::Prompt.new(
            'REPL',
            'REPL Prompt',
            [proc { prompt }, proc { 'MISSING INPUT' }]
          )

          Logic::Cartridge::Streaming.enabled?(cartridge, :repl)

          Pry.commands.block_command(/(.*)/, 'handler') do |line|
            session.print(prefix) unless prefix.nil?
            session.evaluate_and_print(line, mode: 'repl')
            session.print(suffix) unless suffix.nil?
            session.print("\n")
            session.flush
          end

          Pry.start
        end

        def self.prompt(cartridge)
          prompt = Logic::Helpers::Hash.fetch(cartridge, %i[interfaces repl prompt])
          result = ''

          if prompt.is_a?(Array)
            prompt.each do |partial|
              result += if partial[:color]
                          Rainbow(partial[:text]).send(partial[:color])
                        else
                          partial[:text]
                        end
            end
          elsif prompt.is_a?(String)
            result = prompt
          else
            result = "🤖#{Rainbow('> ').blue}"
          end

          result
        end
      end
    end
  end
end
