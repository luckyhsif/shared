#!/user/bin/env ruby
#coding: utf-8

# some notes that have helped me debug active_record stuff in the past
#
# declaration order counts.
# http://pivotallabs.com/activerecord-callbacks-autosave-before-this-and-that-etc/
#
# never end a callback with a false.
# http://blog.danielparnell.com/?p=20
# Case Insensitive searches in Postgres use ILIKE
# http://stackoverflow.com/questions/5052051/not-case-sensitive-search-with-active-record

class ISoftbetLog < ActiveRecord::Base
  
  ALLOWED_TYPES = %w(deposit withdrawal bet win register login limits chargeback adjustment bonus)
  
  validates_presence_of :command
  belongs_to :user
  belongs_to :txid, class_name: 'TxId'

  scope :deposits, ->{ where(command: 'deposit') }
  scope :withdrawals, ->{ where(command: 'withdrawal') }
  scope :bets, ->{ where(command: 'deposit') }
  scope :wins, ->{ where(command: 'withdrawal') }
  scope :money_transactions, ->{ where(command: %w(deposit withdrawal bet win)) }
  scope :registrations, ->{ where(command: 'register') }
  scope :logins, ->{ where(command: 'login') }
  scope :limits, ->{ where(command: 'limits') }
  scope :bonuses, ->{ where(command: 'bonus') }
  scope :chargebacks, ->{ where(command: 'chargeback') }
  scope :adjustments, ->{ where(command: 'adjustment') }

  scope :created_on_or_before, ->(a_date){where("created_at < ?", IGE_LGF::Application::Services.to_endtime(a_date))}
  scope :updated_on_or_before, ->(a_date){where("updated_at < ?", IGE_LGF::Application::Services.to_endtime(a_date))}
  scope :created_before, ->(a_date){where("created_at < ?", IGE_LGF::Application::Services.to_starttime(a_date))}
  scope :updated_before, ->(a_date){where("updated_at < ?", IGE_LGF::Application::Services.to_starttime(a_date))}
  scope :created_on_or_after, ->(a_date){where("created_at > ?", IGE_LGF::Application::Services.to_starttime(a_date))}
  scope :updated_on_or_after, ->(a_date){where("updated_at > ?", IGE_LGF::Application::Services.to_starttime(a_date))}
  scope :created_after, ->(a_date){where("created_at > ?", IGE_LGF::Application::Services.to_endtime(a_date))}
  scope :updated_after, ->(a_date){where("updated_at > ?", IGE_LGF::Application::Services.to_endtime(a_date))}
  scope :created_on, ->(a_date){where(created_at: IGE_LGF::Application::Services.to_timerange(a_date))}
  scope :updated_on, ->(a_date){where(updated_at: IGE_LGF::Application::Services.to_timerange(a_date))}
end
