# mi_thermald configs

The HyperOS mi_thermald scenario configs (`hp-normal` and India `nolimits`
as tuned by lostark13), each without its `device battery` rule, so
mi_thermald no longer limits the charge current. Charging is left to
qti_battery_charger's smart charging and the ADSP charger firmware.

Everything else in each config is unchanged. The encrypted ones are
AES-128-CBC like the stock ones and decrypt to the stock text minus that
one rule; the `chg-only` ones are plain text, as in the vendor blobs.
The scenario maps (`thermal-map*.conf`, `thermal-region-map.conf`) have no
rules and still come from the vendor blobs.
