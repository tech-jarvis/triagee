class PopulateIssues
  # TODO - test
  def self.call(repo, state = 'open')
    new(repo, state).populate_multi_issues!
  end

  # TODO - test
  def initialize(repo, state)
    @repo = repo
    @state = state
  end

  # TODO - test
  def populate_multi_issues!
    page = 1
    while populate_issues(page)
      page += 1
    end
  end

  private

  def fetcher(page)
    GithubFetcher::Issues.new(
      user_name: user_name,
      name: name,
      page: page,
      state: state,
    )
  end

  attr_reader :repo, :state

  def populate_issues(page)
    json = fetcher(page).as_json

    if json.respond_to(:error_message)
      repo.update_attributes(github_error_msg: response.error_message)
      false
    else
      json.each do |issue_hash|
        logger.info "Issue: number: #{issue_hash['number']}, "\
                    "updated_at: #{issue_hash['updated_at']}"
        Issue.find_or_create_from_hash!(issue_hash, repo)
      end
    end
  end
end
