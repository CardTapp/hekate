# [Hekate](http://www.ancient.eu/Hecate/)

[![CircleCI](https://circleci.com/gh/CardTapp/hekate.svg?style=svg)](https://circleci.com/gh/CardTapp/hekate)
[![codecov](https://codecov.io/gh/cardtapp/hekate/branch/master/graph/badge.svg)](https://codecov.io/gh/krimsonkla/hekate)
[![Maintainability](https://api.codeclimate.com/v1/badges/1f576a8d9c31d00c3e3e/maintainability)](https://codeclimate.com/github/CardTapp/hekate/maintainability)
![Snyk Vulnerabilities for GitHub Repo](https://img.shields.io/snyk/vulnerabilities/github/krimsonkla/hekate)

Written by Jason Risch for Cardtapp LLC

Storing configuration in the environment is one of the tenets of a twelve-factor app. Anything that is likely to change between deployment environments–such as resource handles for databases or credentials for external services–should be extracted from the code into environment variables.

But it is not always practical to set environment variables on development machines or continuous integration servers where multiple projects are run. Hekate loads variables from AWS Systems Manager Parameter Store into ENV when the environment is bootstrapped.

Parameter Store was chosen over secrets manager due to performance. Secret Manager can only return one secret value at a time. Using parameter store, we can fetch secrets in bulk.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'hekate'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hekate
    
Add the following to application.rb near the top. It must be loaded early to ensure all parameters are available when needed.
    
    require "hekate"
    Hekate.configure do |config|
        config.application = "mortgagemapp"
    end


The first step in using Hekate will be to place your parameters into AWS. Hekate provides a cli for managing parameters. See the the Binary Commands section below for an introduction to the cli or documentation in the docs folder for more information.

Each parameter that is stored in parameter store is pathed in the following format where application is the configured app name, environment is the rails environment and key is the key name. 

```
/application/environment/key
```


When included in a rails application Hekate will read application secrets directly from AWS SMS Parameter Store. They are loaded in much the same fashion as with the dotenv gem. Root items are loaded first, then overloaded with more specific settings.

For example, when the following keys exist in the parameter store

    /myapp/root/SOMEKEY = basevalue
    /myapp/staging/SOMEKEY = stagingvalue
    
The resulting environment settings would be

    ENV["SOMEKEY"] = stagingvalue
    
This is done to allow setting common parameters in root which will be applied to all other environments unless overridden.
    
## Usage
### AWS Authentication
Hekate requires AWS authentication in order to read or set parameters and assumes credentials are provided via an approved AWS methods (assumed role, cli configuration etc). The gem does not provide authentication in any form.

### AWS Security
Note: this gem takes no responsibility for the security of your stored secrets/parameters. You will need to configure IAM security policies to provide read/write access to the kms encryption keys and parameters as necessary.

Below are some sample amazon iam security policies to get you started. 


Read only parameter access for developers
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
              "arn:aws:ssm:us-east-1:123456789012:parameter/myapp/root/*",
              "arn:aws:ssm:us-east-1:123456789012:parameter/myapp/development/*"
            ]
        },
        {
            "Sid": "Stmt1497208350001",
            "Effect": "Allow",
            "Action": "kms:Decrypt",
            "Resource": "arn:aws:kms:us-east-1:123456789012:key/3299b89c-2ced-4219-a9ad-70d6acc851e6"
        }
    ]
}
```

Read only parameter access for production
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
              "arn:aws:ssm:us-east-1:123456789012:parameter/myapp/root/*",
              "arn:aws:ssm:us-east-1:123456789012:parameter/myapp/development/*"
            ]
        },
        {
            "Sid": "Stmt1497208350001",
            "Effect": "Allow",
            "Action": "kms:Decrypt",
            "Resource": "arn:aws:kms:us-east-1:123456789012:key/3299b89c-2ced-4219-a9ad-70d6acc851e6"
        }
    ]
}
```

Read/write access for a parameter maintainer
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
            "Resource": "arn:aws:ssm:us-east-1:123456789012:parameter/myapp/*"
        },
        {
            "Sid": "Stmt1497208350001",
            "Effect": "Allow",
            "Action": "kms:*",
            "Resource": "*"
        }
    ]
}
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

You will need to export the params to a .env file for each environment you will want to work in. This will normally mean exporting 3 .env files with the proper names (root, development and test). See dotenv gem for configuration and use of .env files. 

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jasonrisch/hekate. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
