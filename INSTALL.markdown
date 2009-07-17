# Installing RailsCollab

Firstly, a word of warning. You will need a command prompt or terminal open in order to install RailsCollab. 

It would also be advisable to get yourself up to scratch with the finer details of Ruby on Rails deployment, 
especially if you are not planning on deploying using Phusion Passenger.

## Requirements

Along with a working installation of the Ruby on Rails Framework, you will need the 
following to deploy & run RailsCollab:

* *iCalendar* - `sudo gem install icalendar`
* *RedCloth* - `sudo gem install RedCloth`
* *ruby-openid* - `gem install ruby-openid`
* *ActionMailer* - `gem install actionmailer`
* *Ferret* - `gem install ferret`
* *Rspec* - `gem install rspec`

Plus the following which are *optional*:

* *Phusion Passenger* - http://www.modrails.com/ (for easy deployment)
* *ImageMagick* - for generating thumbnails

## Config files

The following configuration files need to be present:

* `config/database.yml` (example at `config/database.yml.template`)
* `config/app_keys.yml` (example at `config/app_keys.yml.template`)

## Deployment

RailsCollab can most optimally be deployed via Phusion Passenger. Simply point a 
VirtualHost to "railscollab/public", and Passenger should do the rest, 
with the exception of setting up the database. You will need to do that yourself.

An example VirtualHost for Phusion Passenger deployment would be:

    <VirtualHost *:80>
	   ServerName megacorp.com
	   DocumentRoot /path/to/railscollab/public
    </VirtualHost>

In order to facilitate deployment, a rake task called db:railscollab:install
has been provided, which will create an initial database.
The rake task accepts the following environment variables:

	RAILSCOLLAB_INITIAL_USER
		The username of the administrative user
		(default='admin')
	RAILSCOLLAB_INITIAL_DISPLAYNAME
		The display name of the administrative user
		(default='Administrator')
	RAILSCOLLAB_INITIAL_PASSWORD
		The password of the administrative user
		(default='password')
	RAILSCOLLAB_INITIAL_EMAIL
		The email address of the administrative user
		(default='better.set.this@localhost')
	RAILSCOLLAB_INITIAL_COMPANY
		The initial name of the owner company
		(default='Company')
	RAILSCOLLAB_SITE_URL
		The url of your RailsCollab installation
		(default='http://localhost:3000')

So from scratch, you'd likely do something like to following to install:
1. Create a 'railscollab' database
2. Create a config/database.yml file based on config/database.yml.template, using either the development or production environments as your basis.
3. Run the snippit below
4. Insert the previously mentioned VirtualHost configuration into your Phusion Passenger installation.
5. Go to http://servername and login using your supplied credentials

The snippit:

	RAILSCOLLAB_INITIAL_USER="ole" \
	RAILSCOLLAB_INITIAL_DISPLAYNAME="Ole Reifschneider" \
	RAILSCOLLAB_INITIAL_PASSWORD="pass" \
	RAILSCOLLAB_INITIAL_EMAIL="or@netactive.de" \
	RAILSCOLLAB_INITIAL_COMPANY="netactive" \
	RAILSCOLLAB_SITE_URL="localhost:3000" \
	rake db:railscollab:install


For more advanced deployment (e.g. using FastCGI or load balancing proxies), refer to the Ruby on Rails documentation.
