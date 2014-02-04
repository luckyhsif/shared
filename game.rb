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
# validations
# http://apidock.com/rails/ActiveModel/Validations/ClassMethods/validates

class Game < ActiveRecord::Base

  TYPES = {flash: 'flash', html5: 'html5'}

  validates_presence_of :name
  # => :description
  validates_presence_of :identifier
  validates_uniqueness_of :identifier
  validates_presence_of :casino
  validates_presence_of :skin
  validates_uniqueness_of :skin
  validates_numericality_of :skin, only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 9999

  validates_presence_of :image_url
  validates_presence_of :thumb_url
  validates_presence_of :coin
  validates_presence_of :language

  belongs_to :category
  has_many :gameplays
  has_many :users, through: :gameplays
  validates_presence_of :alt_category_name
  validates_presence_of :wmode
  validates_presence_of :platform
  validates :platform, inclusion: {in: IGE_ISB_API::Constants::ALLOWED_GAME_TYPES}
  validates :wmode, inclusion: {in: IGE_ISB_API::Constants::ALLOWED_MODES}
  # html5_url_fun
  # html5_url_real
  scope :progressive_jackpots, ->{where(progressive_jackpot: true)}
  scope :popular, ->{where(popular: true)}
  scope :fun, ->{where(fun: true)}
  scope :real, ->{where(real: true)}
  scope :flash, ->{where(platform: TYPES[:flash])}
  scope :html5, ->{where(platform: TYPES[:html5])}

  def host(mode)
    check_mode!(mode)
    return self.host_fun if mode == :fun
    return self.host_real if mode == :real
  end

  def swf_path(mode)
    check_mode!(mode)
    return self.swf_path_fun if mode == :fun
    return self.swf_path_real if mode == :real
  end

  def swf_url(mode)
    check_mode!(mode)
    return self.swf_url_fun if mode == :fun
    return self.swf_url_real if mode == :real
  end

  def html5_url(mode)
    check_mode!(mode)
    return self.html5_url_fun if mode == :fun
    return self.html5_url_real if mode == :real
  end

  def progressive_jackpot?
    return self.progressive_jackpot
  end

  def popular?
    return self.popular
  end

  def fun?
    return self.fun
  end

  def real?
    return self.real
  end

  def mobile?
    return (TYPES[:html5] == self.platform)
  end

  def to_summary
    return {id: id, name: name, description: description, icon: image_url, thumb: thumb_url}
  end

  def launcher_url(mode, opts = {})
    check_mode!(mode)
    options = {
        fun: mode == :fun,
        language: self.language,
        game_html5_url: self.html5_url(mode)
    }.merge(opts)
    return IGE_ISB_API::Game.game_launcher_url(options)

  end

  # required options
  # =>  host, player_id, currency, colour
  # Optional options
  # => fun
  def embed_flash(mode, opts = {})
    check_mode!(mode)
    options = {
        name: self.name,
        identifier: self.identifier,
        skin: self.skin,
        casino: self.casino,
        host: self.host(mode),
        game_swf_path: self.swf_path(mode),
        game_swf_url: self.swf_url(mode),
        fun: mode == :fun,
        language: self.language,
        coin_min: self.coin,
        main_category: self.alt_category_name,
        wmode: self.wmode,
        colour: '#ffffff'
    }.merge(opts)
    return IGE_ISB_API::Game.embed_swfobject(options)
  end

  private

  def check_mode!(mode)
    raise ArgumentError, "mode is :fun but game does not allow fun mode." if mode == :fun && !self.fun?
    raise ArgumentError, "mode is :real but game does not allow real mode." if mode == :real && !self.real?
    raise ArgumentError, "mode must be :fun or :real" unless mode == :fun || mode == :real
  end
end