require 'weighable/version'
require 'bigdecimal'
require 'bigdecimal/util'
require 'weighable/errors'
require 'weighable/weight'

module Weighable
end

require 'weighable/railtie' if defined? Rails
