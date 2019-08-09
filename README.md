# Data Stewardship Wizard - Server Application
> It's a server part of the wizard application.

[![Build Status](https://travis-ci.org/ds-wizard/dsw-server.svg?branch=master)](https://travis-ci.org/ds-wizard/dsw-server)
[![License](https://img.shields.io/badge/license-Apache%202-blue.svg)](LICENSE.md)

## Features

- User Management
- Organization Management
- Knowledge Model Management
- Knowledge Model Editor
- Migration Tool for obsolete Knowledge Models
- Questionnaire
- Migration Tool for obsolete Questionnaires
- Data Management Plan Generator
- Feedback

## Demo

The application is currently deployed on a server provided by FIT CTU. Here are the addresses of running applications:

- **Server:** https://api.demo.ds-wizard.org
- **Client:** https://demo.ds-wizard.org

## Documentation

**General Documentation:**

> https://dswserver.docs.apiary.io

- includes project overview
- includes configuration
- includes contribution guide
- includes architecture description

**API Documentation:**

> https://docs.ds-wizard.org

## Contribute

### Requirements

 - **Stack** (recommended 1.9.3 or higher)
 - **MongoDB** (recommended 3.4.10 or higher)
 - **RabbitMQ** (recommended 3.7.8 or higher, optional)
 - **wkhtmltopdf** (recommended 0.12.5 or higher) - *for exports in PDF format only*
 - **Pandoc** (recommended 2.2.1 or higher) - *for exports in non HTML/PDF formats only*
 - **Docker** (recommended 17.09.0-ce or higher) - *for build of production image*

### Build & Run

For running application it's need to run MongoDB database and set up connection in configuration file.

Run these comands from the root of the project

```bash
$ hpack
$ stack build
$ stack exec dsw-server
```

### Run tests

Run these comands from the root of the project

```bash
$ hpack
$ stack build
$ stack test --jobs=1 --fast
```

### Format code

Create a bash script which will do the work for you. Run the script from the root of the project

```bash
$ find lib -name '*.hs' | while read line ; do hindent $line ; done
$ find test -name '*.hs' | while read line ; do hindent $line ; done
```

### Code coverage

Run these comands from the root of the project

```bash
$ hpack
$ stack build
$ stack test --jobs=1 --fast --coverage --ghc-options "-fforce-recomp"`
```

### Build an app version and built date

Run these comands from the `scripts` folder

```bash
$ ./build-info.sh
```

### Naming conventions
- **Handler** - a module containing handler functions
- **DTO** - a module containing structures which represents request/response in API
- **Middleware** - a module containing middleware functions
- **Service** - a module containing service functions
- **Mapper** - a module containing mapper functions
- **DAO** - a module containing functions for a manipulation with data in database
- **Migration** - a module containing functions for running initial database migrations

## License
This project is licensed under the Apache License v2.0 - see the [LICENSE](LICENSE.md) file for more details.
