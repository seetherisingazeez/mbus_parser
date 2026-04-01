## 0.0.4 (2026-04-01)

- feat: add support for device type information to the M-Bus parser

## 0.0.3 (2026-04-01)

- feat: add support for payload-only decryption and custom IV configuration to the M-Bus parser

## 0.0.2 (2026-04-01)

- Added support for custom drivers to override VIF translations on specific ranges

## 0.0.1 (2026-04-01)

- Initial stable release.
- Implemented core EN 13757-3 / EN 13757-4 algorithms.
- Full AES-128-CBC cryptographic decryption pipeline (Security Mode 5) built-in natively via `pointycastle`.
- Added highly robust truncation tolerance to correctly unpack valid records even if trailing bytes contain transmission errors.
- Handled all standard Value Information Fields (VIF) and Data Information Fields (DIF).
- Support for complex secondary addressing, historical records, and multidimensional arrays for devices logging extensive logs.
