# frozen_string_literal: true

module NanoBot
  module Logic
    module Helpers
      module Hash
        def self.symbolize_keys(object)
          case object
          when ::Hash
            object.each_with_object({}) do |(key, value), result|
              result[key.to_sym] = symbolize_keys(value)
            end
          when Array
            object.map { |e| symbolize_keys(e) }
          else
            object
          end
        end

        def self.fetch(object, path)
          node = object

          return nil unless node

          path.each do |key|
            unless node.is_a?(::Hash)
              node = nil
              break
            end
            node = node[key]
            break if node.nil?
          end

          node
        end
      end
    end
  end
end
