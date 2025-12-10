--[[
    PacketCloak - Wireshark Lua Dissector for Real-time Packet Anonymization
    
    This dissector provides three cloaking modes:
    - OFF: Show real packet data (default)
    - CLOAK_DATA: Anonymize only payload data
    - CLOAK_ALL: Anonymize both payload data and addresses
    
    Keyboard shortcuts:
    - Ctrl+Shift+C: Toggle between OFF and CLOAK_ALL
    - Ctrl+Shift+D: Toggle between OFF and CLOAK_DATA
    - Ctrl+Shift+A: Toggle between OFF and CLOAK_ALL (alternate)
    
    Author: Walter Hofstetter
    License: GPL-2.0
    Version: 0.2.16
--]]

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local SANITIZED_PATTERN = 0x5341  -- "SA" for Sanitized (0x53='S', 0x41='A')
local BASE_IP = "10.0.0.0"        -- Base network for anonymization
local BASE_MAC_PREFIX = "02:00:00:00:00"  -- Locally administered MAC prefix

-- Cloaking modes
local MODE_OFF = 0
local MODE_CLOAK_DATA = 1
local MODE_CLOAK_ALL = 2

-- Cloaking Strategies
local STRATEGY = {
    FULL = 1,       -- Cloak entire payload
    HTTP_LIKE = 2,  -- Preserve headers (\r\n\r\n), cloak body + sensitive headers
    TEXT_SMART = 3  -- Smart text protocol: sensitive cmds + body masking
}

-- Protocol Port Configuration
-- Map ports to cloaking strategies
local PROTOCOL_PORTS = {
    -- Full Cloaking (Raw text/data protocols)
    [20]    = STRATEGY.FULL,        -- FTP Data
    [23]    = STRATEGY.FULL,        -- Telnet
    [513]   = STRATEGY.FULL,        -- Rlogin
    [514]   = STRATEGY.FULL,        -- Rsh
    [6667]  = STRATEGY.FULL,        -- IRC
    [6379]  = STRATEGY.FULL,        -- Redis
    [11211] = STRATEGY.FULL,        -- Memcached
    
    -- Smart Text Protocols (Commands + Body)
    [21]    = STRATEGY.TEXT_SMART,  -- FTP Control
    [25]    = STRATEGY.TEXT_SMART,  -- SMTP
    [587]   = STRATEGY.TEXT_SMART,  -- SMTP Submission
    [110]   = STRATEGY.TEXT_SMART,  -- POP3
    [143]   = STRATEGY.TEXT_SMART,  -- IMAP
    [80]    = STRATEGY.HTTP_LIKE,   -- HTTP
    [8080]  = STRATEGY.HTTP_LIKE,   -- HTTP Alt
    [8000]  = STRATEGY.HTTP_LIKE,   -- HTTP Alt
    [8008]  = STRATEGY.HTTP_LIKE,   -- HTTP Alt
    [3128]  = STRATEGY.HTTP_LIKE,   -- HTTP Proxy (Squid)
    [8888]  = STRATEGY.HTTP_LIKE,   -- HTTP Alt
    [5060]  = STRATEGY.HTTP_LIKE,   -- SIP
    [554]   = STRATEGY.HTTP_LIKE,   -- RTSP
    [631]   = STRATEGY.HTTP_LIKE,    -- IPP (Internet Printing)
    [666]   = STRATEGY.HTTP_LIKE,    -- Common Mining/Stratum Port
    [3333]  = STRATEGY.HTTP_LIKE,    -- Mining Port
    [4444]  = STRATEGY.HTTP_LIKE,    -- Mining Port
    [5555]  = STRATEGY.HTTP_LIKE     -- Mining Port
}

-- ============================================================================
-- STATE MANAGEMENT
-- ============================================================================

-- Global state
local current_mode = MODE_OFF
local ip_mapping = {}
local ip_counter = 1
local mac_mapping = {}
local mac_counter = 1

-- Mode names for display
local mode_names = {
    [MODE_OFF] = "OFF",
    [MODE_CLOAK_DATA] = "CLOAK_DATA",
    [MODE_CLOAK_ALL] = "CLOAK_ALL"
}

-- ============================================================================
-- ANONYMIZATION FUNCTIONS
-- ============================================================================

-- Anonymize IPv4 address while maintaining conversation flows
local function anonymize_ipv4(ip_str)
    if not ip_str or ip_str == "" then
        return ip_str
    end
    
    if ip_mapping[ip_str] then
        return ip_mapping[ip_str]
    end
    
    -- Generate new IP in 10.0.0.0/8 range
    local octet3 = math.floor(ip_counter / 256)
    local octet4 = ip_counter % 256
    local new_ip = string.format("10.0.%d.%d", octet3, octet4)
    
    ip_mapping[ip_str] = new_ip
    ip_counter = ip_counter + 1
    
    return new_ip
end

-- Anonymize IPv6 address while maintaining conversation flows
local function anonymize_ipv6(ip_str)
    if not ip_str or ip_str == "" then
        return ip_str
    end
    
    if ip_mapping[ip_str] then
        return ip_mapping[ip_str]
    end
    
    -- Generate new IPv6 in fd00::/8 range (unique local addresses)
    local addr_id = ip_counter
    local new_ip = string.format("fd00::%x", addr_id)
    
    ip_mapping[ip_str] = new_ip
    ip_counter = ip_counter + 1
    
    return new_ip
end

-- Extract MAC address from string that might contain vendor name
-- Handles formats like "Netgear_b6:93:f1", "HewlettPacka_1c:47:ae", "aa:bb:cc:dd:ee:ff"
-- Also handles partial MACs like "b6:93:f1" (last 3 octets)
local function extract_mac_address(mac_str)
    if not mac_str or mac_str == "" then
        return nil
    end
    
    -- First, try to extract MAC after underscore (vendor name separator)
    -- Format: "VendorName_XX:XX:XX" or "VendorName_XX:XX:XX:XX:XX:XX"
    local after_underscore = string.match(mac_str, "_([0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F])")
    if after_underscore then
        return string.lower(after_underscore)
    end
    
    -- Try full MAC pattern (XX:XX:XX:XX:XX:XX) anywhere in string
    local full_mac_pattern = "([0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F])"
    local full_mac = string.match(mac_str, full_mac_pattern)
    if full_mac then
        return string.lower(full_mac)
    end
    
    -- Try partial MAC pattern (XX:XX:XX) - last 3 octets
    -- This often appears with vendor names like "Netgear_b6:93:f1"
    local short_pattern = "([0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F])"
    local short_mac = string.match(mac_str, short_pattern)
    if short_mac then
        return string.lower(short_mac)
    end
    
    -- If no pattern found, check if it's already a clean MAC address
    if string.match(mac_str, "^[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]") then
        return string.lower(mac_str)
    end
    
    return nil
end

-- Anonymize MAC address while maintaining device identity
local function anonymize_mac(mac_str)
    if not mac_str or mac_str == "" then
        return mac_str
    end
    
    -- Extract actual MAC address from string (handles vendor name prefixes)
    local clean_mac = extract_mac_address(mac_str)
    if not clean_mac then
        -- If we can't extract MAC, return original (shouldn't happen normally)
        return mac_str
    end
    
    -- Use clean MAC for mapping (this ensures same MAC maps to same cloaked MAC)
    if mac_mapping[clean_mac] then
        return mac_mapping[clean_mac]
    end
    
    -- Also check if original string (with vendor name) is in mapping
    local orig_lower = string.lower(mac_str)
    if mac_mapping[orig_lower] then
        return mac_mapping[orig_lower]
    end
    
    -- Generate new MAC: 02:00:00:00:00:XX (locally administered)
    local new_mac = string.format("%s:%02x", BASE_MAC_PREFIX, mac_counter)
    
    -- Map both clean MAC and original string to same cloaked MAC
    mac_mapping[clean_mac] = new_mac
    mac_mapping[orig_lower] = new_mac
    mac_counter = mac_counter + 1
    
    return new_mac
end

-- Helper to convert byte array to hex string
local function bytes_to_hex(bytes)
    local hex = {}
    for i = 1, #bytes do
        table.insert(hex, string.format("%02x", bytes[i]))
    end
    return table.concat(hex)
end

-- ============================================================================
-- MODE TOGGLE FUNCTIONS
-- ============================================================================

local function toggle_mode_to_cloak_all()
    if current_mode == MODE_CLOAK_ALL then
        current_mode = MODE_OFF
    else
        current_mode = MODE_CLOAK_ALL
    end
    
    -- Clear mappings when switching modes
    ip_mapping = {}
    ip_counter = 1
    mac_mapping = {}
    mac_counter = 1
    
    -- Force reload (this requires user to reload/refilter)
    print(string.format("[PacketCloak] Mode changed to: %s", mode_names[current_mode]))
    print("[PacketCloak] Press Ctrl+R to reload capture and apply changes")
end

local function toggle_mode_to_cloak_data()
    if current_mode == MODE_CLOAK_DATA then
        current_mode = MODE_OFF
    else
        current_mode = MODE_CLOAK_DATA
    end
    
    -- Clear mappings when switching modes
    ip_mapping = {}
    ip_counter = 1
    mac_mapping = {}
    mac_counter = 1
    
    print(string.format("[PacketCloak] Mode changed to: %s", mode_names[current_mode]))
    print("[PacketCloak] Press Ctrl+R to reload capture and apply changes")
end

-- Toggle function that cycles through modes
local function toggle_mode()
    if current_mode == MODE_OFF then
        current_mode = MODE_CLOAK_DATA
    elseif current_mode == MODE_CLOAK_DATA then
        current_mode = MODE_CLOAK_ALL
    else
        current_mode = MODE_OFF
    end
    
    -- Clear mappings when switching modes
    ip_mapping = {}
    ip_counter = 1
    mac_mapping = {}
    mac_counter = 1
    
    print(string.format("[PacketCloak] Mode changed to: %s", mode_names[current_mode]))
    print("[PacketCloak] Press Ctrl+R to reload capture and apply changes")
end

-- ============================================================================
-- PROTOCOL DETECTION
-- ============================================================================

local function is_igmp_packet(pinfo)
    -- Check if packet is IGMP (protocol number 2)
    if pinfo.cols.protocol == "IGMP" then
        return true
    end
    return false
end

-- ============================================================================
-- PRE-DISSECTORS (Shim IPv4/IPv6 to anonymize before built-in dissectors)
-- ============================================================================

-- Convert IPv4 dotted string to 4 bytes
local function ipv4_to_bytes(ip)
    local b1, b2, b3, b4 = ip:match("^(%d+)%.(%d+)%.(%d+)%.(%d+)$")
    if not b1 then return nil end
    return {tonumber(b1), tonumber(b2), tonumber(b3), tonumber(b4)}
end

-- Recompute IPv4 header checksum (16-bit one's complement over header)
local function recompute_ipv4_checksum(bytes)
    local vihl = bytes[1]
    local ihl_words = (vihl % 16) -- lower nibble
    local header_len = ihl_words * 4
    -- zero checksum field (bytes 11-12, 0-based offset 10-11)
    bytes[11], bytes[12] = 0, 0
    local sum = 0
    for i = 1, header_len, 2 do
        local hi = bytes[i] or 0
        local lo = bytes[i+1] or 0
        sum = sum + hi * 256 + lo
        -- fold carries
        sum = (sum & 0xFFFF) + math.floor(sum / 0x10000)
    end
    -- final fold
    sum = (sum & 0xFFFF) + math.floor(sum / 0x10000)
    local csum = (0xFFFF - (sum & 0xFFFF)) & 0xFFFF
    bytes[11] = math.floor(csum / 256)
    bytes[12] = csum % 256
end

-- Recompute TCP checksum
-- Requires: bytes (full IP packet), tcp_start (from IP header), tcp_len, src_ip (table), dst_ip (table)
local function recompute_tcp_checksum(bytes, tcp_start, tcp_len, src_ip, dst_ip)
    -- Pseudo-header sum
    local sum = 0
    
    -- Src IP
    sum = sum + (src_ip[1] * 256 + src_ip[2])
    sum = sum + (src_ip[3] * 256 + src_ip[4])
    
    -- Dst IP
    sum = sum + (dst_ip[1] * 256 + dst_ip[2])
    sum = sum + (dst_ip[3] * 256 + dst_ip[4])
    
    -- Reserved (0) + Proto (6 for TCP)
    sum = sum + 6
    
    -- TCP Length
    sum = sum + tcp_len
    
    -- Zero out existing checksum (bytes 17-18 in TCP header, 0-based 16-17)
    -- tcp_start is 1-based index in 'bytes'
    bytes[tcp_start + 16] = 0
    bytes[tcp_start + 17] = 0
    
    -- TCP Header + Payload
    for i = 0, tcp_len - 1, 2 do
        local hi = bytes[tcp_start + i] or 0
        local lo = bytes[tcp_start + i + 1] or 0
        sum = sum + hi * 256 + lo
    end
    
    -- Fold 32-bit sum to 16-bit
    while sum > 0xFFFF do
        sum = (sum & 0xFFFF) + math.floor(sum / 0x10000)
    end
    
    local csum = (0xFFFF - sum) & 0xFFFF
    bytes[tcp_start + 16] = math.floor(csum / 256)
    bytes[tcp_start + 17] = csum % 256
end

-- Recompute UDP checksum
-- Requires: bytes (full IP packet), udp_start (from IP header), udp_len, src_ip (table), dst_ip (table)
local function recompute_udp_checksum(bytes, udp_start, udp_len, src_ip, dst_ip)
    -- Zero out existing checksum (bytes 7-8 of UDP header, 0-based 6-7)
    bytes[udp_start + 6] = 0
    bytes[udp_start + 7] = 0

    local sum = 0

    -- Pseudo-header: src IP, dst IP, zero, proto (17), udp length
    sum = sum + (src_ip[1] * 256 + src_ip[2])
    sum = sum + (src_ip[3] * 256 + src_ip[4])
    sum = sum + (dst_ip[1] * 256 + dst_ip[2])
    sum = sum + (dst_ip[3] * 256 + dst_ip[4])
    sum = sum + 17
    sum = sum + udp_len

    -- UDP header + payload
    for i = 0, udp_len - 1, 2 do
        local hi = bytes[udp_start + i] or 0
        local lo = bytes[udp_start + i + 1] or 0
        sum = sum + hi * 256 + lo
    end

    -- Fold 32-bit sum to 16-bit
    while sum > 0xFFFF do
        sum = (sum & 0xFFFF) + math.floor(sum / 0x10000)
    end

    local csum = (0xFFFF - sum) & 0xFFFF
    bytes[udp_start + 6] = math.floor(csum / 256)
    bytes[udp_start + 7] = csum % 256
end

local dissector_ip = Dissector.get("ip")
local dissector_ipv6 = Dissector.get("ipv6")

-- IPv4 shim dissector (registered on ethertype 0x0800)
local packetcloak_ipv4 = Proto("packetcloak_ipv4", "PacketCloak IPv4 Shim")
function packetcloak_ipv4.dissector(tvb, pinfo, tree)
    if current_mode == MODE_OFF then
        return dissector_ip:call(tvb, pinfo, tree)
    end
    
    -- Read entire packet into table (1-based)
    local len = tvb:len()
    local b = {string.byte(tvb:raw(0, len), 1, len)}
    
    -- Parse IP Header
    local vihl = b[1]
    local ihl = (vihl % 16) * 4
    local total_len = b[3] * 256 + b[4]
    local protocol = b[10]
    
    -- Get IP addresses
    local src_ip_bytes = {b[13], b[14], b[15], b[16]}
    local dst_ip_bytes = {b[17], b[18], b[19], b[20]}
    local src_ip_str = string.format("%d.%d.%d.%d", b[13], b[14], b[15], b[16])
    local dst_ip_str = string.format("%d.%d.%d.%d", b[17], b[18], b[19], b[20])
    
    -- 1. IP Cloaking (only in CLOAK_ALL)
    if current_mode == MODE_CLOAK_ALL then
        local new_src = anonymize_ipv4(src_ip_str)
        local new_dst = anonymize_ipv4(dst_ip_str)
        local new_src_bytes = ipv4_to_bytes(new_src)
        local new_dst_bytes = ipv4_to_bytes(new_dst)
        
        if new_src_bytes then 
            for i=1,4 do b[12+i] = new_src_bytes[i] end 
            src_ip_bytes = new_src_bytes
        end
        if new_dst_bytes then 
            for i=1,4 do b[16+i] = new_dst_bytes[i] end 
            dst_ip_bytes = new_dst_bytes
        end
        
        -- Fix IP checksum
        recompute_ipv4_checksum(b)
    end
    
    -- 2a. TCP Payload Cloaking (CLOAK_ALL or CLOAK_DATA)
    if (current_mode == MODE_CLOAK_ALL or current_mode == MODE_CLOAK_DATA) and protocol == 6 then
        local actions = {} 
        
        local tcp_start = ihl + 1 -- 1-based index
        if tcp_start + 20 <= len then -- Min TCP header
            local tcp_off_byte = b[tcp_start + 12]
            local tcp_header_len = math.floor(tcp_off_byte / 16) * 4
            local payload_start = tcp_start + tcp_header_len
            local payload_len = total_len - ihl - tcp_header_len
            
            -- Get Ports
            local src_port = b[tcp_start] * 256 + b[tcp_start + 1]
            local dst_port = b[tcp_start + 2] * 256 + b[tcp_start + 3]
            
            if payload_len > 0 then
                local do_cloak = false
                local cloak_start_offset = 0
                local strategy = PROTOCOL_PORTS[src_port] or PROTOCOL_PORTS[dst_port]
                -- actions table is already defined in scope above
                
                if not strategy and payload_len > 4 then
                    -- Heuristic: Check if payload starts with HTTP verbs
                    local start_bytes = ""
                    local check_len = math.min(payload_len, 10)
                    for i = 0, check_len-1 do
                        start_bytes = start_bytes .. string.char(b[payload_start + i])
                    end
                    
                    if string.match(start_bytes, "^GET ") or 
                       string.match(start_bytes, "^POST ") or 
                       string.match(start_bytes, "^PUT ") or 
                       string.match(start_bytes, "^HEAD ") or 
                       string.match(start_bytes, "^HTTP/") then
                        strategy = STRATEGY.HTTP_LIKE
                    end
                end

                if strategy == STRATEGY.FULL then
                    -- Cloak everything
                    do_cloak = true
                    cloak_start_offset = 0
                elseif strategy == STRATEGY.HTTP_LIKE then
                    -- HTTP/SIP/RTSP: Preserve headers, cloak body
                    -- Search for double CRLF
                    local payload_str = ""
                    -- Optimization: Only read enough to find header end (max 2KB)
                    local search_limit = math.min(payload_len, 2048) 
                    for i = 0, search_limit-1 do
                        payload_str = payload_str .. string.char(b[payload_start + i])
                    end
                    
                    local modified_payload = false
                    
                    -- 1. Always try to mask sensitive headers in HTTP-like traffic
                    -- (regardless of whether we see the end of headers)
                    local header_section_lower = string.lower(payload_str)
                    
                    -- List of sensitive headers to mask
                    local sensitive_headers = {
                        "authorization:",
                        "proxy-authorization:",
                        "cookie:",
                        "set-cookie:",
                        "x-auth-token:",
                        "apikey:",
                        "api-key:"
                    }
                    
                    for _, header_name in ipairs(sensitive_headers) do
                        local start_idx = 0
                        while true do
                            local s, e = string.find(header_section_lower, header_name, start_idx + 1, true)
                            if not s then break end
                            
                            -- Find end of line (\r\n) for this header
                            -- Note: This searches in original payload_str (case sensitive) to find CRLF
                            local val_start = e + 1
                            local line_end = string.find(payload_str, "\r\n", val_start, true)
                            
                            if line_end then
                                -- Mask the value part
                                -- Calculate absolute offset in 'b'
                                -- payload_start is 1-based index in b
                                -- s, e, val_start, line_end are 1-based indices in payload_str
                                
                                -- Mask from val_start to line_end-1
                                for k = val_start, line_end - 1 do
                                    -- Skip leading whitespace if we want, but masking it all is safer
                                    b[payload_start + k - 1] = 0x2A -- '*'
                                end
                                modified_payload = true
                                table.insert(actions, "Credentials (Headers)")
                            end
                            
                            start_idx = e
                        end
                    end
                    
                    -- 2. Check for end of headers to cloak body
                    local header_end = string.find(payload_str, "\r\n\r\n", 1, true)
                    if header_end then
                        do_cloak = true
                        cloak_start_offset = header_end + 3 -- Start after \r\n\r\n
                    end
                    
                    -- If we modified payload (masked headers) but didn't trigger full cloaking
                    -- we still need to fix checksum
                    if modified_payload and not do_cloak then
                        recompute_tcp_checksum(b, tcp_start, total_len - ihl, src_ip_bytes, dst_ip_bytes)
                    end
                elseif strategy == STRATEGY.TEXT_SMART then
                    -- Smart Text: Mask arguments for sensitive commands AND mask body after blank line
                    local payload_str = ""
                    local search_limit = math.min(payload_len, 2048) 
                    for i = 0, search_limit-1 do
                        payload_str = payload_str .. string.char(b[payload_start + i])
                    end
                    
                    local payload_lower = string.lower(payload_str)
                    local modified_payload = false
                    
                    -- 1. Mask Sensitive Commands (FTP, SMTP, POP3, IMAP)
                    local sensitive_cmds = {
                        "user ", "pass ", "acct ",          -- FTP
                        "auth ", "mail from:", "rcpt to:",  -- SMTP
                        "login ", "authenticate "           -- IMAP/POP3
                    }
                    
                    for _, cmd in ipairs(sensitive_cmds) do
                        local start_idx = 0
                        while true do
                            local s, e = string.find(payload_lower, cmd, start_idx + 1, true)
                            if not s then break end
                            
                            -- Found command, look for end of line
                            local val_start = e + 1
                            local line_end = string.find(payload_str, "\r\n", val_start, true)
                            if not line_end then
                                line_end = string.find(payload_str, "\n", val_start, true)
                            end
                            
                            if line_end then
                                -- Mask argument
                                for k = val_start, line_end - 1 do
                                    b[payload_start + k - 1] = 0x2A -- '*'
                                end
                                modified_payload = true
                                table.insert(actions, "Credentials (Command)")
                            end
                            
                            start_idx = e
                        end
                    end
                    
                    -- 2. Mask Body (after blank line) - for Email bodies in SMTP
                    local header_end = string.find(payload_str, "\r\n\r\n", 1, true)
                    if header_end then
                        local cloak_start = header_end + 3 -- Start after \r\n\r\n (keep the blank line)
                        -- Cloak rest of payload
                        for i = cloak_start, payload_len - 1 do
                            b[payload_start + i] = 0x2A -- '*'
                        end
                        modified_payload = true
                        table.insert(actions, "Payload Data")
                    end

                    if modified_payload then
                        recompute_tcp_checksum(b, tcp_start, total_len - ihl, src_ip_bytes, dst_ip_bytes)
                    end
                end
                
                if do_cloak then
                    table.insert(actions, "Full Payload Data")
                    for i = cloak_start_offset, payload_len - 1 do
                        if (i % 2) == 0 then
                            b[payload_start + i] = 0x53 -- 'S'
                        else
                            b[payload_start + i] = 0x41 -- 'A'
                        end
                    end
                    
                    -- Fix TCP Checksum (REQUIRED if we touch payload or IP)
                    recompute_tcp_checksum(b, tcp_start, total_len - ihl, src_ip_bytes, dst_ip_bytes)
                elseif current_mode == MODE_CLOAK_ALL then
                    -- If we didn't touch payload but changed IP, we MUST fix TCP checksum
                    recompute_tcp_checksum(b, tcp_start, total_len - ihl, src_ip_bytes, dst_ip_bytes)
                end
            elseif current_mode == MODE_CLOAK_ALL then
                 -- No payload, but changed IP -> fix TCP checksum
                 recompute_tcp_checksum(b, tcp_start, total_len - ihl, src_ip_bytes, dst_ip_bytes)
            end
        end
        
        -- Serialize actions to pinfo.private (as string) to avoid type errors
        if #actions > 0 then
            local action_str = table.concat(actions, ", ")
            pinfo.private["packetcloak_actions"] = action_str
        end
    end

    -- 2b. UDP Payload Cloaking (CLOAK_ALL or CLOAK_DATA) - SNMP community/PDU
    if (current_mode == MODE_CLOAK_ALL or current_mode == MODE_CLOAK_DATA) and protocol == 17 then
        local actions = {}
        local udp_start = ihl + 1
        if udp_start + 8 <= len then -- UDP header is 8 bytes
            local src_port = b[udp_start] * 256 + b[udp_start + 1]
            local dst_port = b[udp_start + 2] * 256 + b[udp_start + 3]
            local udp_len = b[udp_start + 4] * 256 + b[udp_start + 5]
            local payload_len = udp_len - 8
            local payload_start = udp_start + 8

            -- SNMP runs on 161/162
            local is_snmp = (src_port == 161 or src_port == 162 or dst_port == 161 or dst_port == 162)

            if is_snmp and payload_len > 0 then
                -- Minimal BER parse to mask only community string
                local function read_ber_length(buf, idx, max_idx)
                    local len_byte = buf[idx]
                    if not len_byte then return nil end
                    if len_byte < 128 then
                        return len_byte, idx + 1
                    else
                        local n = len_byte - 0x80
                        if n <= 0 or idx + n > max_idx then return nil end
                        local val = 0
                        for i = 1, n do
                            val = val * 256 + buf[idx + i]
                        end
                        return val, idx + n + 1
                    end
                end

                local p = payload_start
                local pend = payload_start + payload_len - 1

                -- Expect SEQUENCE (0x30)
                if b[p] == 0x30 then
                    local seq_len, idx1 = read_ber_length(b, p + 1, pend)
                    if seq_len and idx1 and idx1 <= pend then
                        -- Expect version: INTEGER (0x02)
                        if b[idx1] == 0x02 then
                            local vlen, idx2 = read_ber_length(b, idx1 + 1, pend)
                            if vlen and idx2 then
                                local after_version = idx2 + vlen
                                if after_version <= pend and b[after_version] == 0x04 then
                                    local clen, cstart = read_ber_length(b, after_version + 1, pend)
                                    if clen and cstart and (cstart + clen - 1) <= pend then
                                        -- Mask community string only
                                        for i = cstart, cstart + clen - 1 do
                                            b[i] = 0x2A -- '*'
                                        end
                                        table.insert(actions, "SNMP Community")
                                        recompute_udp_checksum(b, udp_start, udp_len, src_ip_bytes, dst_ip_bytes)
                                    end
                                end
                            end
                        end
                    end
                end

                -- If we failed to parse/mask, still note attempted SNMP handling
                if #actions == 0 then
                    table.insert(actions, "SNMP (unmodified)")
                end
            elseif is_snmp then
                -- No payload but SNMP packet; still log action
                table.insert(actions, "SNMP Payload (empty)")
            end
        end

        if #actions > 0 then
            local action_str = table.concat(actions, ", ")
            pinfo.private["packetcloak_actions"] = action_str
        end
    end
    
    -- Convert bytes to hex string for ByteArray.new
    local hex_str = bytes_to_hex(b)
    local new_tvb = ByteArray.new(hex_str):tvb("Cloaked Packet")
    return dissector_ip:call(new_tvb, pinfo, tree)
end

-- IPv6 shim dissector (registered on ethertype 0x86dd)
local packetcloak_ipv6 = Proto("packetcloak_ipv6", "PacketCloak IPv6 Shim")
function packetcloak_ipv6.dissector(tvb, pinfo, tree)
    if current_mode == MODE_OFF then
        return dissector_ipv6:call(tvb, pinfo, tree)
    end
    -- IPv6 cloaking is handled in post-dissector via column modification
    -- because IPv6 address parsing/rewriting is complex and could corrupt checksums
    -- Pass through to standard IPv6 dissector
    return dissector_ipv6:call(tvb, pinfo, tree)
end

-- Register shims on ethertype
local ethertype = DissectorTable.get("ethertype")
ethertype:add(0x0800, packetcloak_ipv4)
ethertype:add(0x86dd, packetcloak_ipv6)
-- Note: MAC address cloaking is handled in post-dissector via column modification

-- ============================================================================
-- POST-DISSECTOR
-- ============================================================================

-- Create a post-dissector that runs after all other dissectors
local packetcloak = Proto("packetcloak", "PacketCloak Anonymizer")

-- Set plugin version info for Wireshark's About dialog
set_plugin_info({
    version = "0.2.16",
    description = "Real-time packet anonymization and cloaking dissector",
    author = "Walter Hofstetter",
    repository = "https://github.com/netwho/PacketCloak"
})

-- Create fields for our protocol
local f_mode = ProtoField.string("packetcloak.mode", "Cloaking Mode")
local f_cloaked_src_ip = ProtoField.string("packetcloak.src_ip", "Cloaked Source IP")
local f_cloaked_dst_ip = ProtoField.string("packetcloak.dst_ip", "Cloaked Destination IP")
local f_cloaked_src_mac = ProtoField.string("packetcloak.src_mac", "Cloaked Source MAC")
local f_cloaked_dst_mac = ProtoField.string("packetcloak.dst_mac", "Cloaked Destination MAC")
local f_cloaked_data = ProtoField.string("packetcloak.data", "Cloaked Payload")
local f_cloaked_info = ProtoField.string("packetcloak.info", "Cloaked Content")

packetcloak.fields = {f_mode, f_cloaked_src_ip, f_cloaked_dst_ip, f_cloaked_src_mac, f_cloaked_dst_mac, f_cloaked_data, f_cloaked_info}

-- Main dissector function
function packetcloak.dissector(tvb, pinfo, tree)
    -- If mode is OFF, do nothing
    if current_mode == MODE_OFF then
        return
    end

    -- Reset per-packet actions (avoid leakage between packets)
    pinfo.private["packetcloak_actions"] = nil
    
    -- Skip IGMP packets
    if is_igmp_packet(pinfo) then
        return
    end
    
    -- Add subtree for PacketCloak
    local subtree = tree:add(packetcloak, tvb())
    subtree:add(f_mode, mode_names[current_mode])
    
    -- Handle address cloaking (CLOAK_ALL mode only)
    if current_mode == MODE_CLOAK_ALL then
        -- Get addresses - IPv4 addresses should already be cloaked by shim
        local src_ip = tostring(pinfo.src)
        local dst_ip = tostring(pinfo.dst)
        
        -- For IPv4: addresses are already cloaked by shim, but we need to ensure columns are set
        -- For IPv6: we need to cloak them here since shim doesn't modify bytes
        if src_ip and src_ip ~= "" and src_ip ~= "0.0.0.0" then
            -- Check if it's IPv6 (contains colons)
            if string.find(src_ip, ":") then
                -- IPv6 - anonymize it
                src_ip = anonymize_ipv6(src_ip)
            end
            -- Set column to show cloaked address in summary window
            pinfo.cols.src = src_ip
            subtree:add(f_cloaked_src_ip, src_ip)
        end
        
        if dst_ip and dst_ip ~= "" and dst_ip ~= "0.0.0.0" then
            -- Check if it's IPv6 (contains colons)
            if string.find(dst_ip, ":") then
                -- IPv6 - anonymize it
                dst_ip = anonymize_ipv6(dst_ip)
            end
            -- Set column to show cloaked address in summary window
            pinfo.cols.dst = dst_ip
            subtree:add(f_cloaked_dst_ip, dst_ip)
        end
        
        -- Cloak MAC addresses (if available)
        -- Read MAC addresses directly from packet bytes to avoid vendor name resolution
        -- Ethernet header: dst MAC (bytes 0-5), src MAC (bytes 6-11)
        local eth_src = nil
        local eth_dst = nil
        
        -- Try to read MAC addresses directly from packet bytes first
        if tvb:len() >= 12 then
            -- Read destination MAC (bytes 0-5)
            local dst_bytes = {}
            for i = 0, 5 do
                dst_bytes[i+1] = tvb:range(i, 1):uint()
            end
            eth_dst = string.format("%02x:%02x:%02x:%02x:%02x:%02x", 
                dst_bytes[1], dst_bytes[2], dst_bytes[3], 
                dst_bytes[4], dst_bytes[5], dst_bytes[6])
            
            -- Read source MAC (bytes 6-11)
            local src_bytes = {}
            for i = 6, 11 do
                src_bytes[i-5] = tvb:range(i, 1):uint()
            end
            eth_src = string.format("%02x:%02x:%02x:%02x:%02x:%02x", 
                src_bytes[1], src_bytes[2], src_bytes[3], 
                src_bytes[4], src_bytes[5], src_bytes[6])
        else
            -- Fallback: try to get from pinfo if packet is too short
            local eth_src_raw = pinfo.dl_src
            local eth_dst_raw = pinfo.dl_dst
            
            if eth_src_raw then
                eth_src = tostring(eth_src_raw)
            end
            
            if eth_dst_raw then
                eth_dst = tostring(eth_dst_raw)
            end
        end
        
        -- Cloak source MAC
        if eth_src and eth_src ~= "" and eth_src ~= "00:00:00:00:00:00" then
            local cloaked_mac = anonymize_mac(eth_src)
            if cloaked_mac and cloaked_mac ~= eth_src then
                subtree:add(f_cloaked_src_mac, cloaked_mac)
                -- Always update columns to show cloaked MAC in summary window (without vendor names)
                -- This ensures vendor names don't appear in the packet list
                pinfo.cols.dl_src = cloaked_mac
            end
        end
        
        -- Cloak destination MAC
        if eth_dst and eth_dst ~= "" and eth_dst ~= "00:00:00:00:00:00" then
            local cloaked_mac = anonymize_mac(eth_dst)
            if cloaked_mac and cloaked_mac ~= eth_dst then
                subtree:add(f_cloaked_dst_mac, cloaked_mac)
                -- Always update columns to show cloaked MAC in summary window (without vendor names)
                -- This ensures vendor names don't appear in the packet list
                pinfo.cols.dl_dst = cloaked_mac
            end
        end
    end
    
    -- Handle payload cloaking (both CLOAK_DATA and CLOAK_ALL modes)
    if current_mode == MODE_CLOAK_DATA or current_mode == MODE_CLOAK_ALL then
        -- Add cloaking indicator to info column
        local info = tostring(pinfo.cols.info)
        if not string.find(info, "[CLOAKED]", 1, true) then
            pinfo.cols.info = "[CLOAKED] " .. info
        end
        
        -- Add detailed actions info if available
        -- Retrieve as string
        local action_str = tostring(pinfo.private["packetcloak_actions"] or "")
        
        -- Add detailed cloaking information
        local cloaking_note = "Payload data has been cloaked"
        
        -- Append specific actions to the main note if available
        if action_str ~= "" and action_str ~= "nil" then
            cloaking_note = cloaking_note .. " (" .. action_str .. ")"
        else
            -- Fallback for generic protocols
            local protocol = tostring(pinfo.cols.protocol)
            if protocol == "HTTP" or protocol == "SMTP" or protocol == "TELNET" or 
               protocol == "FTP" or protocol == "POP" or protocol == "IMAP" then
                cloaking_note = cloaking_note .. " (clear text protocols like " .. protocol .. " are protected)"
            end
        end
        
        subtree:add(f_cloaked_data, cloaking_note)
        
        -- Note about hex dump limitation
        subtree:add(f_cloaked_data, "Note: Hex dump shows original packet bytes (Wireshark limitation)")
        
        if action_str ~= "" and action_str ~= "nil" then
            subtree:add(f_cloaked_info, action_str)
        end
    end
end

-- ============================================================================
-- REGISTRATION
-- ============================================================================

-- Register as post-dissector (runs after all other dissectors)
register_postdissector(packetcloak)

-- Register keyboard shortcuts
-- Note: Wireshark's Lua API doesn't directly support keyboard shortcuts
-- Users need to configure these in Wireshark's preferences or use menu items
-- These functions are exposed for potential menu integration

print("[PacketCloak] Loaded successfully!")
print("[PacketCloak] Current mode: " .. mode_names[current_mode])
print("[PacketCloak] Toggle modes via: Tools > PacketCloak menu")
print("[PacketCloak] Or configure keyboard shortcuts in: Edit > Preferences > Shortcuts")
print("[PacketCloak] Note: After changing mode, press Ctrl+R to reload capture")

-- ============================================================================
-- UI CONTROL FUNCTIONS
-- ============================================================================

-- ============================================================================
-- MENU INTEGRATION (Optional - requires Wireshark 3.2+)
-- ============================================================================

-- Try to register menu items if supported
if register_menu then
    register_menu("PacketCloak/Toggle Mode (Cycle)", toggle_mode, MENU_TOOLS_UNSORTED)
    register_menu("PacketCloak/Toggle CLOAK_ALL", toggle_mode_to_cloak_all, MENU_TOOLS_UNSORTED)
    register_menu("PacketCloak/Toggle CLOAK_DATA", toggle_mode_to_cloak_data, MENU_TOOLS_UNSORTED)
    print("[PacketCloak] Menu items registered under Tools > PacketCloak")
    print("[PacketCloak] To assign keyboard shortcuts:")
    print("[PacketCloak]   1. Go to Edit > Preferences > Shortcuts")
    print("[PacketCloak]   2. Search for 'PacketCloak'")
    print("[PacketCloak]   3. Assign your preferred key combination")
end

-- ============================================================================
-- PREFERENCE SETTINGS
-- ============================================================================

-- Add preferences for the protocol
packetcloak.prefs.default_mode = Pref.enum("Default Mode", MODE_OFF, 
    "Default cloaking mode on startup", 
    {
        {1, "OFF", MODE_OFF},
        {2, "CLOAK_DATA", MODE_CLOAK_DATA},
        {3, "CLOAK_ALL", MODE_CLOAK_ALL}
    })

-- Preference change handler
function packetcloak.prefs_changed()
    current_mode = packetcloak.prefs.default_mode
    
    -- Clear mappings
    ip_mapping = {}
    ip_counter = 1
    mac_mapping = {}
    mac_counter = 1
    
    print(string.format("[PacketCloak] Mode changed to: %s", mode_names[current_mode]))
end

print("[PacketCloak] Version 0.2.16 initialized")