# codeclimate-markdownlint

[![Code Climate](https://codeclimate.com/github/codeclimate-community/codeclimate-markdownlint/badges/gpa.svg)](https://codeclimate.com/github/codeclimate-community/codeclimate-markdownlint)
[![Test Coverage](https://codeclimate.com/github/codeclimate-community/codeclimate-markdownlint/badges/coverage.svg)](https://codeclimate.com/github/codeclimate-community/codeclimate-markdownlint/coverage)

Code Climate Engine to run [markdownlint][mdl]

## Installation

```
git clone https://github.com/codeclimate-community/codeclimate-markdownlint
cd codeclimate-markdownlint
make
```

## Usage

**.codeclimate.yml**

```yml
engines:
  markdownlint:
    enabled: true
```

```
codeclimate analyze
```

[mdl]: https://github.com/mivok/markdownlint
