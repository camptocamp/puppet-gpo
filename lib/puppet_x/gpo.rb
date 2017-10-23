require 'json'

module PuppetX
    class Gpo
        def valid_paths
            @@valid_paths ||= JSON.parse(File.read(valid_paths_file))
        end

        def valid_paths_file
            File.join(File.dirname(__FILE__), 'gpo/paths.json')
        end

        def item_by_path(path)
            valid_paths.select { |p|
                path == "#{p['admx_file']}::#{p['policy_id']}::#{p['setting_valuename']}".downcase
            }[0]
        end
    end
end
