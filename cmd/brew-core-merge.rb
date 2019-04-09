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

  def passed_ci?(pr)
    statuses = GitHub.open_api(pr["statuses_url"])

    latest_pr_status = statuses.select { |status| status["context"] == "continuous-integration/jenkins/ghprb" }
      .max_by { |status| Time.parse(status["updated_at"]) }

    latest_pr_status&.fetch("state") == "success"
  end

  def ready_to_merge?(pr)
    pr["labels"].each do |label|
      return true if label["name"] == "ready to merge" and label["id"] == 778631352
    end
    return false
  end

  def core_merge
    core_merge_args.parse

    core_name = CoreTap.instance.full_name
    odie "This command may only be run by maintainers" unless GitHub.write_access? core_name

    open_pull_requests = GitHub.pull_requests(core_name, state: :open, base: "master")

    ready_prs = open_pull_requests.collect do |pr|
      next unless ready_to_merge? pr
      next unless passed_ci? pr
      pr["number"]
    end
    ready_prs.compact!

    ohai "Now run:"
    puts "brew pull --bottle #{ready_prs.join(' ')}"
    puts "git diff origin/master"
  end
end

Homebrew.core_merge

