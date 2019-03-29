# README

This Application is simple contact form where you can inquiry/ask question/report issue through email.

you can login on http://localhost:3000/ and fill the form with your queries in message block and press send email button.

Email is sent to default email id maintain in application.this is small demo app to demonstrate behaviour of sidekiq gem.


### Sidekiq

Simple, efficient background processing for Ruby.

Sidekiq uses threads to handle many jobs at the same time in the same process. It does not require Rails but will integrate tightly with Rails to make background processing dead simple.

### Lets Build up

Let's generate a controller, view, and route for a contact form. This course assumes that you are familiar with how to do this in Rails. In brief, let's create a controller:
```
$ rails generate controller Registrations
```
and give it  new  and  create  actions:

app/controllers/registrations_controller.rb
```
  ...
  def new
  end

  def create
    # we'll create our Registraion job here
  end
```
Then let's add routes for these two actions:

config/routes.rb
```
   get 'registrations/new'
   resources :registrations
   root 'registrations#new'
  ```
And finally create the HTML for the form in a view template:

app/views/registraions/new.html.erb
```
<% if flash[:notice] %>
	<h2>Email Sent Successfully</h2>
<% end %>
<%= form_tag registrations_path do |f| %>
  <h2>Have a question, request, or an issue? Contact us!</h2>

  <p>
    <%= text_area_tag :message %>
  </p>

  <p>
    <%= submit_tag 'Send Mail'%>
  </p>
<% end %>
```

Next, let's generate our background job.
```
$ bin/rails generate job registration
      invoke  test_unit
      create    test/jobs/registration_job_test.rb
      create  app/jobs/registration_job.rb
```
Jobs go in app/jobs, with one method called perform. They look like this, :

app/jobs/registration_job.rb
```
class RegistrationJob < ApplicationJob
  queue_as :default

  def perform(*args)
    # send our email here
  end
end
```
Now we need an email template and mailer:
```
$ bin/rails generate mailer RegistrationMailer
      create  app/mailers/registration_mailer.rb
      invoke  erb
      create    app/views/registration_mailer
      invoke  test_unit
      create    test/mailers/registration_mailer_test.rb
      create    test/mailers/previews/registration_mailer_preview.rb
```
      
In the mailer we'll expect the message from the form:

app/mailers/registration_mailer.rb
```
class RegistrationMailer < ApplicationMailer
	default from: 'abc@gmail.com'

	CONTACT_EMAIL = 'def@gmail.com'

	def submission(message)
    	@message = message
    	mail(to: CONTACT_EMAIL, subject: 'New registration page submission')
  	end

end
```

Replace the value of the constant   CONTACT_EMAIL  with an email address where you can receive email from your local machine.

app/views/contact_mailer/submission.html.erb
```
<!DOCTYPE html>
<html>
  <head>
    <meta content='text/html; charset=UTF-8' http-equiv='Content-Type' />
  </head>
  <body>
    <h1>New registration page submission, yay!</h1>
    <p><%=@message%></p>
  </body>
</html>
```
 Now we can go back and ask our  RegistrationJob  to send a  RegistrationMailer  :

app/jobs/contact_job.rb
```
class RegistrationJob < ApplicationJob
  queue_as :default

  def perform(message)
  	# send our email here
    RegistrationMailer.submission(message).deliver
  end
end
```
Finally, we can go back and create the job inside our Registration controller. We'll do this by using a method called  perform_later  that is available to any class that inherits from  ApplicationJob  :

app/controllers/registrations_controller.rb
```
class RegistrationsController < ApplicationController
	def new
	end

	def create
		 # we'll create our registration job here
		 RegistrationJob.perform_later params.permit(:message)[:message]
		 flash.now[:notice] = "Email Sent Successfully"
		 render :new
	end
end
```
 The parameters we pass to  perform_later  will be stored in Redis for use when our background server executes this job. At that time, these arguments will be retrieved from Redis and passed to the  perform  method of  RegistrationJob  . In essence, calling  perform_later  is like calling  perform  , except that the method call gets executed later, by another server.

### Run Background Jobs with Sidekiq

#### Install Redis server

  As we mentioned, we'll be relying on a database called Redis to store the jobs.

##### Key-Value storage with Redis

  Redis is a different kind of database from Postgres or Mysql. Where they have columns and rows of data, Redis is more like a giant Ruby  Hash  object. When you want to store data in Redis, you simply pass the data as a string to Redis and assign it a unique key. When you want to get the data back out, you just ask for it by the key.

  Think of it like a coat check at a museum. You give the coat check attendant your items, whatever they are, and they give you a unique number. When you bring that number back, you get your items back. That's what happens when you store a value like a string, number, or a list, with Redis.

You can learn more about Redis [here](https://redis.io/)

##### Post jobs and execute them with the Sidekiq client and server

  To post our email jobs and execute them we'll use a popular library called Sidekiq. It provides us with a client that posts the jobs to the Redis list, and a server process that will run down the list and execute the jobs as they're defined in our Rails app.

Before setting Redis up on your background servers, let's get it working on your local machine. Install and start the Redis server from your console like this:
```
$ brew install redis
```

##### Set up Sidekiq

Next, add the Sidekiq gem:

Gemfile
```
gem 'sidekiq'
```
and run Bundler to install it:
```
$ bundle
```
For Sidekiq to work with Rails' jobs API, we need to tell Rails to use Sidekiq as the "queue_adapter":

config/application.rb
```
config.active_job.queue_adapter = :sidekiq
```
Next we need to start the sidekiq server:
```
$ bundle exec sidekiq
```
Reload your server, and load the contact page. If you've done all these steps correctly, then when you submit a message, you should receive an email!
