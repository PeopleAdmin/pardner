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
        if info
          c.suppress(info["suppressed_issues"])
          c.addend(info["added_issues"])
        end
      }
    }
  end
end
