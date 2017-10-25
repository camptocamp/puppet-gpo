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

            def get_by_key(scope, registry_key, setting_valuename)
                valid_paths.select { |p|
                    (p['policy_class'].downcase == scope || p['policy_class'] == 'Both') &&
                        p['setting_key'].downcase == registry_key &&
                        (p['setting_valuename'].downcase == setting_valuename || p['setting_valuetype'].upcase == '[HASHTABLE]')
                }[0]
            end
        end
    end
end
