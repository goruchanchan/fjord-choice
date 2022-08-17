# frozen_string_literal: true

class AssignedIssue < ApplicationRecord
  require 'octokit'
  has_many :user_assigned_issues, dependent: :destroy
  has_many :users, through: :user_assigned_issues

  class << self
    def client
      Octokit::Client.new(client_id: ENV['GITHUB_KEY'],
                          client_secret: ENV['GITHUB_SECRET'])
    end

    def api_request
      (1..1).map do |page|
        client.search_issues('repo:fjordllc/bootcamp is:issue', { state: 'all', sort: 'updated', per_page: 10, page: page })
      end
    end

    # rubocop:disable Metrics/MethodLength
    def create
      api_request.each do |issue|
        issue[:items].each do |i|
          next if AssignedIssue.exists?(number: i[:number])

          assigned_issue = AssignedIssue.new
          assigned_issue.number = i[:number]

          i[:labels].each do |label|
            next if label[:name].to_i.zero?

            assigned_issue.point = label[:name].to_i
          end
          i[:assignees].each do |assignee|
            assigned_issue.assignees = []
            assigned_issue.assignees << assignee[:id]
          end
          assigned_issue.save!
        end
      end
    end
    # rubocop:enable Metrics/MethodLength
  end
end
