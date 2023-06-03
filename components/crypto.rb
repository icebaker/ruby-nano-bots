# frozen_string_literal: true

require 'singleton'
require 'rbnacl'
require 'base64'

module NanoBot
  module Components
    class Crypto
      include Singleton

      def initialize
        password = ENV.fetch('NANO_BOTS_ENCRYPTION_PASSWORD', nil)

        password = 'UNSAFE' unless password && password != ''

        @box = RbNaCl::SecretBox.new(RbNaCl::Hash.sha256(password))
        @fixed_nonce = RbNaCl::Hash.sha256(password)[0...@box.nonce_bytes]
      end

      def encrypt(content, soft: false)
        nonce = soft ? @fixed_nonce : RbNaCl::Random.random_bytes(@box.nonce_bytes)
        Base64.urlsafe_encode64(nonce + @box.encrypt(nonce, content))
      end

      def decrypt(content)
        decoded_content = Base64.urlsafe_decode64(content)
        nonce = decoded_content[0...@box.nonce_bytes]
        cipher_text = decoded_content[@box.nonce_bytes..]

        @box.decrypt(nonce, cipher_text)
      end

      def self.encrypt(content, soft: false)
        instance.encrypt(content, soft:)
      end

      def self.decrypt(content)
        instance.decrypt(content)
      end
    end
  end
end
