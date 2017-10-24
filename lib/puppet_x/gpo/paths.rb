require 'json'

module PuppetX
    module Gpo
        class Paths
            def valid_paths
                @@valid_paths ||= JSON.parse(File.read(valid_paths_file))
            end

            def valid_paths_file
                File.join(File.dirname(__FILE__), 'paths.json')
            end

            def get_item(scope, admx_file, policy_id, setting_valuename)
                valid_paths.select { |p|
                    (p['policy_class'].downcase == scope || p['policy_class'] == 'Both') &&
                        p['admx_file'].downcase == admx_file &&
                        p['policy_id'].downcase == policy_id &&
                        p['setting_valuename'].downcase == setting_valuename
                }[0]
            end
        end
    end
end
