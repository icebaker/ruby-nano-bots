# frozen_string_literal: true

require 'babosa'

require_relative '../logic/helpers/hash'
require_relative 'crypto'

module NanoBot
  module Components
    class Storage
      EXTENSIONS = %w[yml yaml markdown mdown mkdn md].freeze

      def self.end_user(cartridge, environment)
        user = ENV.fetch('NANO_BOTS_END_USER', nil)

        if cartridge[:provider][:id] == 'openai' &&
           !cartridge[:provider][:settings][:user].nil? &&
           !cartridge[:provider][:settings][:user].to_s.strip.empty?
          user = cartridge[:provider][:settings][:user]
        end

        candidate = environment && (
          environment['NANO_BOTS_END_USER'] ||
          environment[:NANO_BOTS_END_USER]
        )

        user = candidate if !candidate.nil? && !candidate.to_s.strip.empty?

        user = if user.nil? || user.to_s.strip.empty?
                 'unknown'
               else
                 user.to_s.strip
               end

        Crypto.encrypt(user, soft: true)
      end

      def self.build_path_and_ensure_state_file!(key, cartridge, environment: {})
        path = [
          Logic::Helpers::Hash.fetch(cartridge, %i[state path]),
          Logic::Helpers::Hash.fetch(cartridge, %i[state directory]),
          ENV.fetch('NANO_BOTS_STATE_PATH', nil),
          ENV.fetch('NANO_BOTS_STATE_DIRECTORY', nil)
        ].find do |candidate|
          !candidate.nil? && !candidate.empty?
        end

        path = "#{user_home!.sub(%r{/$}, '')}/.local/state/nano-bots" if path.nil?

        path = "#{path.sub(%r{/$}, '')}/ruby-nano-bots"

        path = "#{path}/#{cartridge[:meta][:author].to_slug.normalize}"
        path = "#{path}/#{cartridge[:meta][:name].to_slug.normalize}"
        path = "#{path}/#{cartridge[:meta][:version].to_s.gsub('.', '-').to_slug.normalize}"
        path = "#{path}/#{end_user(cartridge, environment)}"
        path = "#{path}/#{Crypto.encrypt(key, soft: true)}"
        path = "#{path}/state.json"

        FileUtils.mkdir_p(File.dirname(path))

        unless File.exist?(path)
          File.write(
            path,
            Crypto.encrypt(JSON.generate({ key:, history: [] }))
          )
        end

        path
      end

      def self.cartridges_path(components: {})
        components[:directory?] = ->(path) { File.directory?(path) } unless components.key?(:directory?)
        components[:ENV] = ENV unless components.key?(:ENV)

        default = "#{user_home!(components:).sub(%r{/$}, '')}/.local/share/nano-bots/cartridges"

        from_environment = [
          components[:ENV].fetch('NANO_BOTS_CARTRIDGES_PATH', nil),
          components[:ENV].fetch('NANO_BOTS_CARTRIDGES_DIRECTORY', nil)
        ].compact

        elected = [
          from_environment.empty? ? nil : from_environment.join(':'),
          default
        ].compact.uniq.filter do |path|
          path.split(':').any? { |candidate| components[:directory?].call(candidate) }
        end.compact.first

        return default unless elected

        elected = elected.split(':').filter do |path|
          components[:directory?].call(path)
        end.compact

        elected.size.positive? ? elected.join(':') : default
      end

      def self.cartridge_path(path)
        partial = File.join(File.dirname(path), File.basename(path, File.extname(path)))

        candidates = [path]

        EXTENSIONS.each do |extension|
          candidates << "#{partial}.#{extension}"
        end

        directories = [
          ENV.fetch('NANO_BOTS_CARTRIDGES_PATH', nil),
          ENV.fetch('NANO_BOTS_CARTRIDGES_DIRECTORY', nil)
        ].compact.map do |directory|
          directory.split(':')
        end.flatten.map { |directory| directory.sub(%r{/$}, '') }

        directories.each do |directory|
          partial = File.join(File.dirname(partial), File.basename(partial, File.extname(partial)))

          partial = partial.sub(%r{^\.?/}, '')

          candidates << "#{directory}/#{partial}"

          EXTENSIONS.each do |extension|
            candidates << "#{directory}/#{partial}.#{extension}"
          end
        end

        directory = "#{user_home!.sub(%r{/$}, '')}/.local/share/nano-bots/cartridges"

        partial = File.join(File.dirname(partial), File.basename(partial, File.extname(partial)))

        partial = partial.sub(%r{^\.?/}, '')

        candidates << "#{directory}/#{partial}"

        EXTENSIONS.each do |extension|
          candidates << "#{directory}/#{partial}.#{extension}"
        end

        candidates = candidates.uniq

        candidates.find do |candidate|
          File.exist?(candidate) && File.file?(candidate)
        end
      end

      def self.user_home!(components: {})
        return components[:home] if components[:home]

        [Dir.home, `echo ~`.strip, '~'].find do |candidate|
          !candidate.nil? && !candidate.empty?
        end
      end
    end
  end
end
