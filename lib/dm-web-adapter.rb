require 'dm-core'
require 'dm-web-adapter/web_adapter'
require 'mechanize'

::DataMapper::Adapters.const_added(:WebAdapter)