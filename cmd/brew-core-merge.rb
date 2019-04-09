require "cli_parser"
require "utils/github"
require "tap"

module Homebrew
  module_function

  def core_merge_args
    Homebrew::CLI::Parser.new do
      switch "--dry-run"
    end
  end

  def core_merge
    core_merge_args.parase

    ohai "Dry run" if args.dry_run?
  end
end

Homebrew.core_merge

