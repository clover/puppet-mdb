# This is a lookup type thing that will load and cache a yaml file, and
# when lookups are performed will replace MDB[xxx] blocks with an array
# of the results of the query 'xxx', after performing normal hiera variable
# interpolation.
#
# This module is largely based on the stock eyaml module. Things that are
# good are their fault, things that suck are mine. -jay
Puppet::Functions.create_function(:mdb_lookup_key) do
    dispatch :mdb_lookup_key do
        param 'String[1]', :key
        param 'Hash[String[1], Any]', :options
        param 'Puppet::LookupContext', :context
    end

    def mdb_lookup_key(key, options, context)
        return context.cached_value(key) if context.cache_has_key(key)

        # Can't do this with an argument_mismatch dispatcher since there
        # is no way to declare a struct that at least contains some keys
        # but may contain other arbitrary keys.
        unless options.include?('path')
            raise ArgumentError,
              "'eyaml_lookup_key': one of 'path', 'paths' 'glob', 'globs'"\
              " or 'mapped_paths' must be declared in hiera.yaml"\
              " when using this lookup_key function"
        end

        # nil key is used to indicate that the cache contains the raw
        # content of the yaml file
        raw_data = context.cached_value(nil)
        if raw_data.nil?
            raw_data = load_data_hash(options, context)
            context.cache(nil, raw_data)
        end
        context.not_found unless raw_data.include?(key)
        context.cache(key, subst_mdb_recursive(raw_data[key], context, options))
    end


    def load_data_hash(options, context)
        path = options['path']
        context.cached_file_data(path) do |content|
            begin
                data = YAML.load(content, path)
                if data.is_a?(Hash)
                    Puppet::Pops::Lookup::HieraConfig.symkeys_to_string(data)
                else
                    msg = "%{path}: file does not contain a valid yaml hash" % { path: path }
                    raise Puppet::DataBinding::LookupError, msg if Puppet[:strict] == :error && data != false
                    Puppet.warning(msg)
                    {}
                end
            rescue YAML::SyntaxError => ex
                # Psych errors includes the absolute path to the file, so no
                # need to add that to the message
                raise Puppet::DataBinding::LookupError, "Unable to parse #{ex.message}"
            end
        end
    end


    def subst_mdb_recursive(value, context, options)
        case value

        when String
            subst_mdb_value(value, context, options)
        when Hash
            result = {}
            value.each_pair { |k, v| result[context.interpolate(k)] = subst_mdb_recursive(v, context, options) }
            result
        when Array
            value.map { |v| subst_mdb_recursive(v, context, options) }
        else
            value
        end
    end


    def subst_mdb_value(data, context, options)
        if mdbtag?(data)
            data = context.interpolate(data)
            query = data.gsub(/.*MDB\[(.*?)\].*/, "\\1")
            mdbresolve(query)
        else
            context.interpolate(data)
        end
    end


    def mdbtag?(data)
        /.*MDB\[.*?\]/ =~ data ? true : false
    end

    # This takes a string that has a required component (a query) and an
    # optional component (option flags), split it up and parse it before
    # actually doing the query.
    def mdbresolve(data)
        m = data.match(/^\s*([^ \]]+)\s*(\{\s*([^{}]+?)\s*\})?\s*$/)
        if m.nil?
            fail("mdb lookup expression '#{data}' appears invalid")
        end

        query = m[1]
        opts = process_opts(m[3])

        call_function('mdb_search', query, opts)
    end


    def process_opts(data)
        opts = { }

        if data.nil?
            return opts
        end

        # split on commas, with optional whitespace
        data.split(/\s*,\s*/).each do |o|
            # Now split on equal signs (or => so puppet syntax works)
            kv = o.split(/\s*=>?\s*/)
            if kv.size != 2
                fail("mdb lookup option '#{o}' is malformed")
            end

            # Convert true or false to booleans
            if kv[1].downcase == 'true'
                opts[kv[0]] = true
            elsif kv[1].downcase == 'false'
                opts[kv[0]] = false
            else
                opts[kv[0]] = kv[1]
            end
        end

        return opts
    end
end

