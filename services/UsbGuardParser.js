// Parse CLI records without evaluating device-controlled strings.
function tokens(text) {
    var result = [], re = /"(?:\\.|[^"\\])*"|\{|\}|[^\s{}"]+/g, m;
    while ((m = re.exec(text)) !== null) result.push(m[0]);
    return result;
}
function unquote(s) {
    if (!s || s[0] !== '"') return s || "";
    return s.slice(1, -1).replace(/\\x([0-9a-f]{2})|\\(.)/gi, function(_, hex, c) {
        return hex ? String.fromCharCode(parseInt(hex, 16)) : c;
    });
}
function parse(raw, kind) {
    return String(raw || "").split(/\r?\n/).filter(function(l) { return l.trim(); }).map(function(line) {
        var m = line.match(/^\s*(\d+):\s+(\S+)(.*)$/);
        if (!m) throw new Error("Unrecognized USBGuard record");
        var ts = tokens(m[3]), attrs = {}, i = 0;
        while (i < ts.length) {
            var key = ts[i++], value = [];
            if (ts[i] === "{") {
                i++;
                while (i < ts.length && ts[i] !== "}") value.push(unquote(ts[i++]));
                i++;
            } else if (/^(all-of|one-of|none-of|equals|equals-ordered|match-all)$/.test(ts[i] || "")) {
                value.push(ts[i++]);
                if (ts[i] === "{") { i++; while (i < ts.length && ts[i] !== "}") value.push(unquote(ts[i++])); i++; }
            } else value.push(unquote(ts[i++]));
            attrs[key] = value.join(" ");
        }
        var interfaces = (attrs["with-interface"] || "").toLowerCase();
        var keyboard = /03:01:01/.test(interfaces), mouse = /03:01:02/.test(interfaces);
        var hid = /03:/.test(interfaces), hub = /09:/.test(interfaces);
        var name = attrs.name || "";
        var status = ({allow:"Allowed",block:"Blocked",reject:"Rejected"})[m[2]] || "Unknown";
        return { id:m[1], kind:kind, target:m[2], status:status, name:name,
            title:name || (kind === "rule" ? "Device rule" : "USB device"), usbId:attrs.id || "Any USB ID",
            serial:attrs.serial || "", hash:attrs.hash || "", port:attrs["via-port"] || "",
            interfaces:interfaces, manufacturer:"", connected:kind === "device", raw:line,
            keyboard:keyboard, mouse:mouse, hid:hid, hub:hub,
            composite:hid && interfaces.split(/\s+/).filter(function(x) { return /:/.test(x); }).length > 1,
            icon:keyboard ? "󰌌" : mouse ? "󰍽" : hub ? "󰕓" : /08:/.test(interfaces) ? "󰋊" : /0e:/.test(interfaces) ? "󰄀" : hid ? "󰌆" : "󰕓" };
    });
}
function search(d, query) {
    return [d.title,d.manufacturer,d.usbId,d.serial,d.id,d.hash].join(" ").toLowerCase().indexOf(query.toLowerCase()) >= 0;
}
function warning(d) {
    var types = [];
    if (d.keyboard) types.push("keyboard input");
    if (d.mouse) types.push("mouse input");
    if (d.composite) types.push("composite HID functions");
    else if (d.hid && !d.keyboard && !d.mouse) types.push("HID input or a security key");
    if (d.hub) types.push("a USB hub/controller and all devices attached to it");
    return types.length ? "This device appears to provide " + types.join(", ") + ". Disabling it may prevent you from controlling this computer. Have another input method available.\n\n" : "";
}
function command(action, d) {
    if (!d || !/^\d+$/.test(String(d.id))) throw new Error("Invalid USBGuard ID");
    if (action === "remove" && d.kind === "rule") return ["usbguard", "remove-rule", String(d.id)];
    if (d.kind !== "device") throw new Error("Device action requires a connected device");
    var spec = {allow:["allow-device"], block:["block-device"], reject:["reject-device"],
        alwaysAllow:["allow-device","--permanent"], alwaysBlock:["block-device","--permanent"]}[action];
    if (!spec) throw new Error("Unsupported action");
    return ["usbguard"].concat(spec, [String(d.id)]);
}
function humanError(raw) {
    if (/changed during authentication/i.test(raw)) return "The device or rule changed while you were authenticating. Refresh and review it before trying again.";
    if (/timed out/i.test(raw)) return "The USBGuard request timed out. Review the refreshed device state before retrying.";
    if (/Unauthenticated mutation refused/i.test(raw)) return "An outdated action handler was blocked. Close and reopen USBGuard to load the authenticated version.";
    if (/permission|denied|not permitted|access control/i.test(raw)) return "Permission denied while communicating with USBGuard. See diagnostics for the failing request.";
    if (/not found|no such device|does not exist|unknown device|invalid device/i.test(raw)) return "The selected device or rule is no longer available. Refresh and try again.";
    if (/connect|connection|socket|service/i.test(raw)) return "USBGuard is unavailable. Check that the daemon is running and your user has IPC access.";
    if (/permanent|rulefile|rulefolder|read.only/i.test(raw)) return "USBGuard could not save the permanent policy. Check its rule storage and policy permissions.";
    return "USBGuard could not complete the request. See diagnostics for details.";
}
