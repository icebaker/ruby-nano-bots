# frozen_string_literal: true

require 'pry'
require 'rainbow'

require_relative '../../logic/helpers/hash'
require_relative '../../logic/cartridge/affixes'

module NanoBot
  module Controllers
    module Interfaces
      module REPL
        COMMANDS_TO_BE_REMOVED = [
          'help', 'cd', 'find-method', 'ls', 'pry-backtrace', 'raise-up', 'reset', 'watch',
          'whereami', 'wtf?', '!', 'amend-line', 'edit', 'hist', 'show-input', 'ri', 'show-doc',
          'show-source', 'stat', 'import-set', 'play', '!!!', '!!@', '$', '?', '@', 'file-mode',
          'history', 'quit', 'quit-program', 'reload-method', 'show-method', 'cat',
          'change-inspector', 'change-prompt', 'clear-screen', 'fix-indent', 'list-inspectors',
          'save-file', 'shell-mode', 'pry-version', 'reload-code', 'toggle-color', '!pry',
          'disable-pry', 'jump-to', 'nesting', 'switch-to',
          'pry-theme'
        ].freeze

        COMMANDS_TO_KEEP = [
          '/whereami[!?]+/', '.<shell command>', 'exit', 'exit-all', 'exit-program'
        ].freeze

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

          handler = proc do |line|
            session.print(prefix) unless prefix.nil?
            session.evaluate_and_print(line, mode: 'repl')
            session.print(suffix) unless suffix.nil?
            session.print("\n")
            session.flush
          end

          pry_prompt = Pry::Prompt.new(
            'REPL',
            'REPL Prompt',
            [proc { prompt }, proc { 'MISSING INPUT' }]
          )

          pry_instance = Pry.new({ prompt: pry_prompt })

          pry_instance.config.correct_indent = false

          pry_instance.config.completer = Struct.new(:initialize, :call) do
            def initialize(...); end
            def call(...); end
          end

          first_whereami = true

          pry_instance.config.commands.block_command(/whereami --quiet(.*)/, '/whereami[!?]+/') do |line|
            unless first_whereami
              handler.call(line.nil? ? 'whereami --quiet' : "whereami --quiet#{line}")
            end
            first_whereami = false
          end

          pry_instance.config.commands.block_command(/\.(.*)/, '.<shell command>') do |line|
            handler.call(line.nil? ? '.' : ".#{line}")
          end

          COMMANDS_TO_BE_REMOVED.each do |command|
            pry_instance.config.commands.block_command(command, 'handler') do |line|
              handler.call(line.nil? ? command : "#{command} #{line}")
            end
          end

          pry_instance.commands.block_command(/(.*)/, 'handler', &handler)

          Pry::REPL.new(pry_instance).start
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
