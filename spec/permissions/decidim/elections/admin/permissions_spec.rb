# frozen_string_literal: true

require "spec_helper"

# Covers the :response_option_label/:update case added by
# Decidim::ExtraCensuses::ElectionsAdminPermissionsOverride: winner-label editing
# is allowed while the label is still editable and denied once results are
# published, per results_availability mode.
describe Decidim::Elections::Admin::Permissions do
  subject { described_class.new(user, permission_action, context).permissions.allowed? }

  let(:component) { create(:elections_component) }
  let(:organization) { component.organization }
  let(:user) { create(:user, :admin, :confirmed, organization:) }
  let(:question) { create(:election_question, election:) }
  let(:context) { { current_component: component, resource: question } }
  let(:permission_action) { Decidim::PermissionAction.new(scope: :admin, action: :update, subject: :response_option_label) }

  shared_examples "editable" do
    it { is_expected.to be(true) }
  end

  shared_examples "locked" do
    it { is_expected.to be(false) }
  end

  context "when there is no user" do
    let(:election) { create(:election, :after_end, :published, :ongoing, component:) }
    let(:user) { nil }

    it "does not set the permission" do
      expect { subject }.to raise_error(Decidim::PermissionAction::PermissionNotSetError)
    end
  end

  context "when the action scope is not admin" do
    let(:election) { create(:election, :after_end, :published, :ongoing, component:) }
    let(:permission_action) { Decidim::PermissionAction.new(scope: :public, action: :update, subject: :response_option_label) }

    it "does not set the permission" do
      expect { subject }.to raise_error(Decidim::PermissionAction::PermissionNotSetError)
    end
  end

  context "when results_availability is per_question" do
    let(:election) { create(:election, :per_question, :published, :ongoing, component:) }

    context "and the question results are not published" do
      it_behaves_like "editable"
    end

    context "and the question results are published" do
      let(:question) { create(:election_question, :published_results, election:) }

      it_behaves_like "locked"
    end
  end

  context "when results_availability is real_time" do
    context "and the election is ongoing" do
      let(:election) { create(:election, :real_time, :published, :ongoing, component:) }

      it_behaves_like "editable"
    end

    context "and the election is finished" do
      let(:election) { create(:election, :real_time, :published, :finished, component:) }

      it_behaves_like "locked"
    end
  end

  context "when results_availability is after_end" do
    context "and results are not published" do
      let(:election) { create(:election, :after_end, :published, :ongoing, component:) }

      it_behaves_like "editable"
    end

    context "and results are published" do
      let(:election) { create(:election, :after_end, :published_results, component:) }

      it_behaves_like "locked"
    end
  end

  context "without a resource" do
    let(:election) { create(:election, :after_end, :published, :ongoing, component:) }
    let(:context) { { current_component: component } }

    it_behaves_like "locked"
  end
end
