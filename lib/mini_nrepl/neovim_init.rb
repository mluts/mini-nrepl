# frozen_string_literal: true

require_relative './version'

require 'bundler/setup'
$LOAD_PATH.unshift(File.expand_path('..', __dir__))
require 'mini_nrepl'
require 'mini_nrepl/neovim'
MiniNrepl::NeovimPlugin.new.init!
