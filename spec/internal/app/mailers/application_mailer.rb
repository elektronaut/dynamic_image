# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: "test@example.com"

  helper ApplicationHelper
end
