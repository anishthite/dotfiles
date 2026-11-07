-- Byte counters follow the default route, including Ethernet and VPN interfaces.
local M = {}
M.command = [[
iface=$(/sbin/route -n get default 2>/dev/null | awk '/interface:/ {print $2; exit}')
now=$(date +%s)
/usr/sbin/netstat -ibn 2>/dev/null | awk -v iface="$iface" -v now="$now" '
  $1 == iface && $3 ~ /^<Link#/ {print now, iface, $7, $10; exit}'
]]

function M.sample(text, previous)
  local time, interface, received, sent = (text or ""):match("^%s*(%d+)%s+(%S+)%s+(%d+)%s+(%d+)")
  if not time then return nil end
  local current = { time = tonumber(time), interface = interface, received = tonumber(received), sent = tonumber(sent) }
  if previous and previous.interface == interface then
    local elapsed = current.time - previous.time
    -- Discard wake gaps and counter resets instead of showing fictitious bursts.
    if elapsed > 0 and elapsed <= 15 and current.received >= previous.received and current.sent >= previous.sent then
      current.down = (current.received - previous.received) / elapsed
      current.up = (current.sent - previous.sent) / elapsed
    end
  end
  return current
end

function M.format(bytes)
  if not bytes then return "--" end
  local unit = 1
  local units = { "B", "K", "M", "G", "T" }
  while bytes >= 999.5 and unit < #units do bytes, unit = bytes / 1000, unit + 1 end
  return string.format(bytes < 10 and unit > 1 and "%.1f%s" or "%.0f%s", bytes, units[unit])
end

return M
