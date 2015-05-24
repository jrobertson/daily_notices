#!/usr/bin/env ruby

# file: daily_notices.rb

require 'activity-logger'

class DailyNotices < ActivityLogger

  def initialize(dir: nil, options: {})
    super(dir: dir, options: options)
  end

end