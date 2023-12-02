# frozen_string_literal: true

require_relative '../components/crypto'

module NanoBot
  module Controllers
    module Security
      def self.decrypt(content)
        Components::Crypto.decrypt(content)
      end

      def self.encrypt(content, soft: false)
        Components::Crypto.encrypt(content, soft:)
      end

      def self.check
        password = ENV.fetch('NANO_BOTS_ENCRYPTION_PASSWORD', nil)
        password = 'UNSAFE' unless password && password != ''

        {
          encryption:
            Components::Crypto.encrypt('SAFE') != 'SAFE' &&
              Components::Crypto.encrypt('SAFE') != Components::Crypto.encrypt('SAFE') &&
              Components::Crypto.decrypt(Components::Crypto.encrypt('SAFE')) == 'SAFE',
          password: password != 'UNSAFE'
        }
      end
    end
  end
end
