-- Add device metadata to metric records.
-- Uses os.getenv to resolve the actual hostname rather than
-- relying on ${HOSTNAME} expansion in record_modifier which
-- does not support environment variable substitution.

local hostname = os.getenv("HOSTNAME") or io.popen("hostname"):read("*l") or "unknown"

function add_hostname(tag, timestamp, record)
    record["source"] = "edge"
    record["device_host"] = hostname
    return 1, timestamp, record
end
