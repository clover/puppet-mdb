require 'json'

Puppet::Functions.create_function(:mdb_endpoint) do
    dispatch :mdb_endpoint do
        param 'String', :endpoint
        optional_param 'Boolean', :fail_ok
        return_type 'Hash'
    end

    def mdb_endpoint(endpoint, fail_ok = false)
        args = [ ] 
        begin
            args = [ '/usr/local/bin/mdb', 'endpoint', 'dump', endpoint ]
            Puppet.info("mdb call: " + args.join(","))
            ret = Puppet::Util::Execution.execute(args).to_str
        rescue Puppet::ExecutionFailure => detail
            raise Puppet::ParseError, "failed to execute mdb (dump): #{detail}", detail.backtrace
        end

        Puppet.debug("mdb lookup (dump) for '" + endpoint + ' returns: ' + ret)

        rethash = JSON.parse(ret)

        if fail_ok == false && (ret.length == 0 || rethash.length == 0)
            fail("mdb lookup (dump) for '" + endpoint + "' returned no results")
        end

        return rethash
    end
end

