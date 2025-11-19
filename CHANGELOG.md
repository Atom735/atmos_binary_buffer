# Changes

## 1.0.1

- update documentation: split into ENG and RU sections (ENG on top)
- update README version to 1.0.1

## 1.0.0

- fix zigzag encoding/decoding for web compatibility (use `>>` instead of `>>>`)
- fix `ByteData.view` and typed list views to properly handle buffers with `offsetInBytes`
- fix all `writeList*AV` methods to account for buffer offset when creating views
- update documentation with detailed zigzag encoding description
- add web compatibility limitations section to documentation

## 0.17.0

- added endian to reader/writer

## 0.16.6

- fix troubles with read lists views from offsetted view

## 0.16.5

- fix missed symbol in code

## 0.16.4

- set new pack algorithm

## 0.16.3

- add read/write for list of sizes (packed uint) values
    `readListSize`/`writeListSize`

- add read/write for packed integer value and list of thats values
    `readPackedInt`/`writePackedInt`/`readListPackedInt`/`writeListPackedInt`

## 0.16.2

- fixed README

## 0.16.1

- Set last Dart SDK (2.16.1) dependecy
- Publish on pub.dev

## 0.0.1

- Initial version.
