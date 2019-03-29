class RegistrationMailer < ApplicationMailer
	default from: 'abc@gmail.com'

	CONTACT_EMAIL = 'def@gmail.com'

	def submission(message)
    	@message = message
    	mail(to: CONTACT_EMAIL, subject: 'New registration page submission')
  	end

end
