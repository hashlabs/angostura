# CHANGELOG

## [Unreleased]
### Added
* [aws.compute.utils.launch_configuration] Using overlay2 as Docker storage driver
* [aws.compute.utils.launch_configuration] Adding `root_block_device`
* [aws.compute.services.sentry] Exposing SENTRY_SERVER_EMAIL
* [aws.compute.utils.launch_configuration] Adding swapfile with `user_data`
* Bastion host module

### Changed
* [aws.compute.services.drone] Exposing Drone's Docker image
* [aws.compute.services.sentry] memory reservation
* [aws.compute.utils.launch_configuration] Now pulls ECS image using
  `aws_ami`

### Fixed
* [aws.compute.services.sentry] SMTP_USERNAME variable was missing

## [0.0.2] - 2016-12-29
### Added
* [aws.compute.services.sentry] reducing memory reservation
* Sentry module
* [aws.network.vpc] removing `region` variable
* VPC module

### Changed
* Launch configuration default ami to match the one in us-east-1

## 0.0.1 - 2016-12-24
### Added
* Launch configuration module
* Drone module

[Unreleased]: https://github.com/hashlabs/angostura/compare/0.0.2...HEAD
[0.0.2]: https://github.com/hashlabs/angostura/compare/0.0.1...0.0.2
