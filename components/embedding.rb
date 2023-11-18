# frozen_string_literal: true

require 'sweet-moon'

require 'open3'
require 'json'
require 'tempfile'

module NanoBot
  module Components
    class Embedding
      def self.ensure_safety!(safety)
        raise 'missing safety definitions' unless safety.key?(:sandboxed)
      end

      def self.lua(source:, parameters:, values:, safety:)
        ensure_safety!(safety)

        allowed = ''
        allowed = ', {math=math,string=string,table=table}' if safety[:sandboxed]

        state = SweetMoon::State.new
        code = "_, embedded = pcall(load([[\nreturn function(#{parameters.join(', ')})\n#{source}\nend\n]], nil, 't'#{allowed}))"

        state.eval(code)
        embedded = state.get(:embedded)
        embedded.call(values)
      end

      def self.fennel(source:, parameters:, values:, safety:)
        ensure_safety!(safety)

        path = "#{File.expand_path('../static/fennel', __dir__)}/?.lua"
        state = SweetMoon::State.new(package_path: path).fennel

        # TODO: global is deprecated...
        state.fennel.eval(
          "(global embedded (fn [#{parameters.join(' ')}] #{source}))", 1,
          safety[:sandboxed] ? { allowedGlobals: %w[math string table] } : nil
        )
        embedded = state.get(:embedded)
        embedded.call(values)
      end

      def self.clojure(source:, parameters:, values:, safety:)
        ensure_safety!(safety)

        raise 'TODO: sandboxed Clojure through Babashka not implemented' if safety[:sandboxed]

        raise 'invalid Clojure parameter name' if parameters.include?('injected-parameters')

        key_value = {}

        parameters.each_with_index { |key, index| key_value[key] = values[index] }

        parameters_json = key_value.to_json

        json_file = Tempfile.new(['nano-bot', '.json'])
        clojure_file = Tempfile.new(['nano-bot', '.clj'])

        begin
          json_file.write(parameters_json)
          json_file.close

          clojure_source = <<~CLOJURE
            (require '[cheshire.core :as json])
            (def injected-parameters (json/parse-string (slurp (java.io.FileReader. "#{json_file.path}"))))

            #{parameters.map { |p| "(def #{p} (get injected-parameters \"#{p}\"))" }.join("\n")}

            #{source}
          CLOJURE

          clojure_file.write(clojure_source)
          clojure_file.close

          bb_command = "bb --prn #{clojure_file.path} | bb -e \"(->> *in* slurp read-string print)\""

          stdout, stderr, status = Open3.capture3(bb_command)

          status.success? ? stdout : stderr
        ensure
          json_file&.unlink
          clojure_file&.unlink
        end
      end
    end
  end
end
