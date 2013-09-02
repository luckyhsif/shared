class Message < ActiveRecord::Base
  belongs_to :sender, class_name: 'AdminUser', foreign_key: :sender_id
  has_and_belongs_to_many :recipients, class_name: 'AdminUser', association_foreign_key: :recipient_id
  belongs_to :reply_to, class_name: 'Message'

  def create_reply(sender, recipients, body)
  	return Message.create(sender: sender,
  							recipients: recipients,
  							body: body,
  							subject: self.subject,
  							reply_to: self)
  end
 
end
