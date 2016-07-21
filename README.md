# azure-scalable-iaas
ARM templates and Chef cookbooks for deployment of a simple, scalable IaaS based web application.

## Requirements
Tested with:

1. Microsoft Azure for hosting platform
2. Hosted Chef for configuration management
3. Ubuntu 14.04.4-LTS for OS
4. nginx 1.4.6 for web tier service
5. Apache Tomcat 8.5.3 for app tier service
6. Windows 10 for deployment workstation with
* Azure PowerShell Module 1.4.0
* Chef DK 0.14.25

Prerequesites

* [Azure PowerShell Module](http://aka.ms/webpi-azps) 
* [Chef DK](https://downloads.chef.io/chef-dk/) 
* [Azure Subscription](https://azure.microsoft.com/en-gb/free/)
* [Hosted Chef](https://manage.chef.io/signup)


## First Deployment

1. Create new Chef Organisation
2. Download and extract Chef Starter Kit
3. Create local copy of this repo
4. Update Azure deployment template parameters in ./azure-scalable-iaas/arm-template/Templates/azuredeploy.*.parameters.json files
* `chefValidationKey` must be JSON escaped string from validator pem
* `vmssNameAffix` must be no longer than 6 alphanumeric characters
5. Update web-cookbook attributes under ./azure-scalable-iaas/cookbooks/web-cookbook/attributes/default.rb
* `zip-source` must be URI to zip containing web app static content
* `static-dir-name` must match URI root path for web app
6. Update app-cookbook attributes under ./azure-scalable-iaas/cookbooks/app-cookbook/attributes/default.rb
* `war-source` must be URI to war containing web app dynamic content
* `prevayler-dir` must be added if Prevayler is used and hardcoded to write to specific path
7. Upload web-cookbook and app-cookbook to Hosted Chef instance with `berks install` and `berks upload`
8. Modify `cd` path root in ./azure-scalable-iaas/powershell-scripts/Main-Deploy.ps1
9. Validate resource group naming and run `Main-Deploy.ps1`

## Scaling

The number of instances in each tier can be modified by changing the `webInstanceCount` and `appInstanceCount` values in the Azure template parameter files and redeploying the template with `Main-Deploy.ps1`

## Licence and Authors
The MIT License (MIT) 
Copyright (c) 2016 farthir

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

## Copyright
Certain ARM templates are Copyright 2016 Microsoft, Corp. under MIT Licence
https://github.com/Azure/azure-quickstart-templates

Certain Cookbooks are Copyright 2008-2014, Chef Software, Inc. under Apache License, Version 2.0
Any edits to original code are marked with comments
http://www.apache.org/licenses/LICENSE-2.0
