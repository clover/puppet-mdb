# Do an mdb search
Puppet::Functions.create_function(:mdb_search) do
    # Do an mdb search and returns an array with the results
    # @param expression
    #   The mdb search string to execute
    # @param opts
    #   A hash of options and their values. Currently acceptable values are
    #   `rettag=X` (return tag X from matching endpoints, instead of the names
    #   of matching endpoints), and `empty_ok=true|false` (whether compilation
    #   should continue if a mdb result is empty)
    # @return [Array[String]] Results of the mdb query
    # @example List all endpoints with p937 as an HN (empty list ok)
    #     mdb_search("hn=p937.dev.clover.com", { empty_ok => true })
    dispatch :mdb_search do
        param 'String', :expression
        # optional_param 'Boolean', :fail_ok
        optional_param 'Hash', :opts
        return_type 'Array'
    end

    def mdb_search(expression, opts = { })
        # FIXME: validate lookup key
        args = [ ]
        begin
            args = [ '/usr/local/bin/mdb', 'tags', 'search', expression ]

            rettag = opts.fetch("rettag", "")
            if rettag != ""
                args.push("--rettag", rettag)
            end

            Puppet.info("mdb call: " + args.join(","))
            ret = Puppet::Util::Execution.execute(args).to_str
        rescue Puppet::ExecutionFailure => detail
            raise Puppet::ParseError, "failed to execute mdb: #{detail}", detail.backtrace
        end

        Puppet.debug("mdb lookup '" + expression + ' returns: ' + ret)

        empty_ok = opts.fetch("empty_ok", false)
        retarr = ret.split("\n")
        if empty_ok == false && (ret.length == 0 || retarr.length == 0)
            fail("mdb lookup '" + expression + "' returned no results")
        end

        return retarr.sort()
    end
end

