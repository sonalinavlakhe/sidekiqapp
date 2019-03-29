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
