require 'augmented_commit'

class CommitAugmenter
  def initialize(store, repo)
    @store = store
    @repo = repo
  end

  def augment(commits)
    infos_by_commit = @store.commit_info @repo, commits.map(&:sha)
    commits.map {|commit|
      AugmentedCommit.new(commit).tap {|c|
        info = infos_by_commit[c.sha]
        next unless info
        c.suppressed_issues.merge info["suppressed_issues"] || []
        c.added_issues.merge info["added_issues"] || []
      }
    }
  end
end
