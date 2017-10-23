require 'json'

module PuppetX
    module Gpo
        def self.valid_paths
            file = File.join(File.dirname(__FILE__), 'gpo/paths.json')
            JSON.parse(File.read(file))
        end
    end
end

