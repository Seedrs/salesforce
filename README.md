# SalesforceSync

_Note: the first version of the gem is still under development_

SalesforceSync gem provides three set of features:
- an event based architecture to handle asynchronous Rails resource synchronisation on Salesforce
- a set of actions to trigger on demand bulk synchronisation
- the management of the Salesforce ids of your resources

## Installation

Add this line to your application's Gemfile:

```ruby
  gem "salesforce_sync", github: "Seedrs/salesforce"
```

And then execute:

    $ bundle

Create the table to store Salesforce ids:

    $ bin/rails generate migration CreateSalesforceIdentifiers salesforce_type:string resource_id:integer salesforce_id:string timestamps
    $ bin/rake db:migrate

Create default SalesforceSync initializer file:

    $ rails g salesforce_sync:initializer

## Connection configuration

In order to connect to Salesforce using SalesforceSync set Salesforce username, password, security token, client ID, client secret and API version in environment variables:

```
  export SALESFORCE_USERNAME="username"
  export SALESFORCE_PASSWORD="password"
  export SALESFORCE_SECURITY_TOKEN="security token"
  export SALESFORCE_CLIENT_ID="client id"
  export SALESFORCE_CLIENT_SECRET="client secret"
```

## Basic Usage

### Sync application users with Salesforce contacts

There is a Rails `User` model to sync with your Salesforce contact.
Meaning:
- when a `User` is created in the Rails application a contact needs to be created on Salesforce
- when a `User` is updated in the Rails application the associated contact needs to be updated on Salesforce
- when a `User` is deleted in the Rails application the associated contact needs to be deleted on Salesforce

First, the bridge between a `User` in the application and a Contact on Salesforce needs to be crossed.
For this create a child of the class `SalesforceSync::Resource::Base` which implement the following three methods:
- `self.sf_type`: the name of the object on Salesforce, here it is `"Contact"`
- `self.resource_id_name`: the name of your application id on Salesforce, let's say here: `"User_Id__c"`
- `all_fields`: the list of fields you want to send to Salesforce, whatever fields configured on your Salesforce account for contacts

Here is a simple example, that can be stored in `lib/salesforce_resource/user.rb`, with the following content:

```ruby
module SalesforceResource
  class User < SalesforceSync::Resource::Base
    def self.sf_type
      "Contact"
    end

    def self.resource_id_name
      "User_ID__c"
    end

    def all_fields
      {
        User_ID__c: resource.id,
        FirstName: resource.first_name,
        LastName: resource.last_name,
        Email: resource.last_name,
        Phone: resource.telephone
      }
    end
  end
end
```

_Note: the path of the file is up to you, as long as it is loaded and extend `SalesforceSync::Resource::Base`_

Then, `SalesforceSync` gem needs to know that the `User` class relates with the `SalesforceResource::User`.
For that in the `config/initializers/salesforce_sync.rb` declare the following `resources_by_class`:

```ruby
  SalesforceSync.configure do |config|
    config.resources_by_class = { User => SalesforceResource::User }
```

Now let's announce events when a `User` is saved and destroy:
In the `User` class add the following events `after_save` and `after_destroy` this way:

```ruby
  after_save :track_after_save

  def track_after_save
    EventBus.announce("user.save", resource: self, changed_attributes: changed_attributes)
  end
```

```ruby
  after_destroy :track_after_destroy

  def track_after_save
    EventBus.announce("user.destroy", resource: self)
  end
```

_Note: each event needs to provide at least the associated resource._

Finally, `SalesforceSync` needs to subscribe to those events.
For that, add them in the `config,events` through the file `config/initializers/salesforce_sync.rb` as following :

```ruby
  config.events = %w(user.save user.destroy)
```

That's all. From now on, users are synced Salesforce contacts through delayed job.

Oh, but wait, something is off! Some sync fail because Salesforce contact requires an email address.
No worries, `SalesforceSync::Resource::Base` provides an api that lets you control exactly when to trigger a sync or not.
Implement the method `require_upsert?` like this :
```ruby
  def require_upsert?(_event = nil, _changed_attributes = {})
    resource.email.present?
  end
```

_Note 1: require_upsert? takes the event and changed_attributes as arguments, so you can optimize your Salesforce Api usage._
_Note 2: see the implementation of SalesforceSync::Resource::Base for more customization._

### Synchronise existing users

Now that users are synced with Salesforce contacts, all previously existing users may need to be synced as well.

`SalesforceSync` provides two ways to trigger on demand synchronisation:
- use `SalesforceSync::Api#resource_synchronisation` to sync one resource
- use `SalesforceSync::Api#bulk_synchronisation` to sync multiple resources

In our case since there may be a lot of users to sync, so we will prefer to use the `SalesforceSync::Api#bulk_synchronisation`.
Now that `SalesforceSync` knows how to build a Salesforce Contact from a `User`, syncing all your users that have an email can be done like this:

```ruby
  user_ids = User.where.not(email: nil).pluck(:id)
  SalesforceSync::Api.bulk_synchronisation(User => user_ids)
```

## Documentation

### Configuration

TODO: Write Configuration documentation here

### SalesforceSync::Resource::Base api

TODO: Write SalesforceSync::Resource::Base documentation here

### SalesforceSync::Api

TODO: Write SalesforceSync::Api documentation here

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Seedrs/salesforce.
_For pull request do not forget to update and add rspec tests in the spec folder._

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
