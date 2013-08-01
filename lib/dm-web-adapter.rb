require 'dm-core'
require 'dm-web-adapter/parser'
require 'dm-web-adapter/url_builder'
require 'dm-web-adapter/form_helper'
require 'dm-web-adapter/web_adapter'
require 'mechanize'

::DataMapper::Adapters.const_added(:WebAdapter)