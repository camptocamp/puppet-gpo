require 'json'

module PuppetX
    class Gpo
        def valid_paths
            @@valid_paths ||= JSON.parse(File.read(valid_paths_file))
        end

        def valid_paths_file
            File.join(File.dirname(__FILE__), 'gpo/paths.json')
        end
    end
end

