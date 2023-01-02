# [Hekate](http://www.ancient.eu/Hecate/)

[![CircleCI](https://circleci.com/gh/CardTapp/hekate.svg?style=svg)](https://circleci.com/gh/CardTapp/hekate)
[![codecov](https://codecov.io/gh/cardtapp/hekate/branch/master/graph/badge.svg)](https://codecov.io/gh/krimsonkla/hekate)
[![Maintainability](https://api.codeclimate.com/v1/badges/1f576a8d9c31d00c3e3e/maintainability)](https://codeclimate.com/github/CardTapp/hekate/maintainability)
![Snyk Vulnerabilities for GitHub Repo](https://img.shields.io/snyk/vulnerabilities/github/krimsonkla/hekate)

Hekate is a gem for encrypting, storing and consuming rails application secrets as Amazon SSM parameters

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'hekate'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hekate
    
Add the following to application.rb
    
    require "hekate"
    Hekate::Engine.application = "yourapplicationname"

When included in a rails application Hekate will read application secrets directly from AWS SMS Parameter Store based on the RAILS_ENV, AWS_REGION environment variables and store them as ENV variables

SSM parameters are loaded in much the same fashion as with the dotenv gem. Root items are loaded first, then overloaded with more specific settings.

For example, when the following keys exist in the parameter store

    myapp.root.SOMEKEY = basevalue
    myapp.staging.SOMEKEY = stagingvalue
    
The resulting environment settings would be

    ENV["SOMEKEY"] = stagingvalue
    
    
## Usage
### AWS Authentication
Hekate requires AWS authentication in order to read or set parameters and assumes credentials are provided via one of the available amazon authentication methods. Please see amazon documentation for more details

### AWS Security
Note: this gem takes no responsibility for the security of your stored secrets/parameters. You will need to configure IAM security policies to provide read/write access to the kms encryption keys and parameters as necessary.

Below are some sample amazon iam security policies to get you started. These could be made more secure by restricting to specific resources rather than specifying a wild card.


Hekate User - read only parameter access for developers or servers
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Stmt1497208350000",
            "Effect": "Allow",
            "Action": [
                "ssm:DescribeParameters",
                "ssm:GetParameters"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Sid": "Stmt1497208350001",
            "Effect": "Allow",
            "Action": "kms:Decrypt",
            "Resource": "*"
        }
    ]
}
```

Hekate Admin -  read/write access for a parameter maintainer
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Stmt1497208350000",
            "Effect": "Allow",
            "Action": [
                "ssm:DescribeParameters",
                "ssm:GetParameters",
                "ssm:PutParameter"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Sid": "Stmt1497208350001",
            "Effect": "Allow",
            "Action": "kms:*",
            "Resource": "*"
        }
    ]
}

### Environment Configuration
Use the following environment settings to customize Hekate

ENV["HAKATE_DISABLE"] = any value - Disable hekate and fall back to .env files
ENV["HEKATE_SSM_TIMEOUT"] - float representing the the time to wait for a connection to SSM to be made. A timeout will result in hekate falling back to offline mode.

```
### Binary Commands
Hekate provides a command line interface for reading and writing secrets to the parameter store. Note that it will automatically create an amazon kms key with the following naming convention as needed `application.environment`


help - lists avalable commands. For help on a specific command issue `hekate command --help` or see documentation in the docs folder.

put - adds one item to the parameter store

get - reads one item from the parameter store

delete - deletes on item from the parameter store

delete_all - deletes all parameters for the given application and environment combination

import - imports a .env formatted secrets file

export - exports to a .env formatted secrets file

### Working when offline
In the event that you need to work offline hekate can fall back to using dotenv files. Offline mode is only available for development and test. Be sure to use `hekate export` to create the necessary files before going offline.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jasonrisch/hekate. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

TODO: 
Check all classes for memoization
Fix existing tests
Add test converage
Fix codecov
private method review
Connect to MM and test

manual Test cli
specs should test that commands hit aws clients