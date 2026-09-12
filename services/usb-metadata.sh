#!/usr/bin/env bash
# Read-only sysfs enrichment. USBGuard remains authoritative for status and IDs.
for path in /sys/bus/usb/devices/*; do
    [[ -r "$path/idVendor" && -r "$path/idProduct" ]] || continue
    vendor=$(<"$path/idVendor")
    product_id=$(<"$path/idProduct")
    manufacturer=""; product=""
    [[ ! -r "$path/manufacturer" ]] || manufacturer=$(<"$path/manufacturer")
    [[ ! -r "$path/product" ]] || product=$(<"$path/product")
    manufacturer=${manufacturer//$'\t'/ }; manufacturer=${manufacturer//$'\n'/ }
    product=${product//$'\t'/ }; product=${product//$'\n'/ }
    printf '%s\t%s:%s\t%s\t%s\n' "${path##*/}" "$vendor" "$product_id" "$manufacturer" "$product"
done
