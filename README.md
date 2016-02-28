# codeclimate-markdownlint

Code Climate Engine to run [markdownlint][mdl]

## Installation

```
git clone https://github.com/jpignata/codeclimate-markdownlint
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
