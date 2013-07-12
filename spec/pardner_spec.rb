require './pardner.rb'

describe Pardner do
  let(:pardner) { Pardner.new( unused_user = nil ) }

  describe "#first_parents" do
    it "returns the list of commits from the mainline" do
      APP_ROOT = File.expand_path(File.dirname(File.expand_path(__FILE__)) + "/..")
      commits = File.readlines("#{APP_ROOT}/test/fixtures/all_with_parents.txt").map do |line|
        sha, parents = line.chomp.split(' ', 2)
        parents = parents.split(' ')
        Commit.new.tap {|c|
          c.sha = sha
          c.parents = parents
        }
      end

      expected_first_parents = "
9da403bc5290db86a231e4960231a949b42823f5
6118c0f21daccfa807a191405d5d0ac8eb63812b
0850298e9badd1d1d631c7dd4b782036d68f87ba
33d72575e687a1d3b1b6a71f803407220fb14772
ab7ddc56b80a13f7258bbae9fbd9c137696b4368
112ae8c2e09c9520e8c11d6eda8f2441941ea325
65985239d670be74928651e6898aa9ab82205b19
66a55b431f40cdc8e0a65aa28824c86bb8d0b10e
6a8bec877880f33d3912c06a26f1d5549c1b28e3
23408b52b70a6fd5d0fd66fd2470328107bb176f
a6edd88b4fa37c24fd58360c740dfdfee1d2eec2
3aac85007f430655a4ba4f6545def785263fa019
4b3c4088491c30ca36c9dcd1f38b0550d0062ec4
a432e26fdbe976f8b11e555c15ea0700a7ab3f80
883844fcaf2c5f84d493b34ee49c144c082e85b3
257db5a9153bd8336935069308825767e992d168
b1253933b77ff0769d35b73fe9765b47750608c9
4881259df61f9b90d4d7acd4d8466ce7e607d856
70de5aee068e196120a4eb4bb1fc1828c0658508
556a171365dd30cf7cc7d447fe80bcedc17a8fc2
      ".split("\n").map{|l| l.strip}.reject{|l| l.empty?}

      actual = pardner.first_parents(commits, commits.first.sha)
      actual.map(&:sha).should == expected_first_parents
    end
  end

  describe "#grouped_commits" do
    # scenarios to cover
    # non-merge commit on mainline (A)
    # merge commits started from mainline commit (C)
    # merge commits started from an unincluded commit (G, I)
    # merge commits started from a commit in branch already merged (E)
    #
    #  A
    #  |
    #  B
    #  |\
    #  | C
    #  |/
    #  D
    #  |\
    #  | E
    #  | |
    #  F |
    #  |\|
    #  | G
    #  | |
    #  H I
    #  | |
    #  J K

    let(:all) { [] }
    before do
      all << commit('K', [])
      all << commit('J', [])
      all << commit('I', ['K'])
      all << commit('H', ['J'])
      all << commit('G', ['I'])
      all << commit('F', ['H', 'G'])
      all << commit('E', ['G'])
      all << commit('D', ['F', 'E'])
      all << commit('C', ['D'])
      all << commit('B', ['D', 'C'])
      all << commit('A', ['B'])
    end

    it "identifies first parents" do
      first_parents = pardner.first_parents all, all.last.sha
      first_parents.map(&:sha).should == %w(A B D F H J)
    end

    it "groups commits by their first parent" do
      grouped = pardner.grouped_commits all, all.last.sha
      grouped.map(&:sha).should == %w(A B D F H J)
      grouped[0].contributing_commits.map(&:sha).should == []
      grouped[1].contributing_commits.map(&:sha).should == %w(C)
      grouped[2].contributing_commits.map(&:sha).should == %w(E)
      grouped[3].contributing_commits.map(&:sha).should == %w(G I K)
      grouped[4].contributing_commits.map(&:sha).should == []
      grouped[5].contributing_commits.map(&:sha).should == []
    end
  end

  def commit sha, parent_shas
    Commit.new.tap {|c|
      c.sha = sha
      c.parents = parent_shas
    }
  end
end
