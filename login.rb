class Login < ActiveRecord::Base

  belongs_to :user
  validates :in_out, inclusion: { in: ['I','O'] }

  scope :logins, ->{ where(in_out: 'I') }
  scope :logouts, ->{ where(in_out: 'O') }

end