# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Elections
    module Admin
      module Censuses
        describe CustomCsv do
          subject { described_class.new(form, election) }

          let(:organization) { create(:organization) }
          let(:participatory_process) { create(:participatory_process, organization:) }
          let(:component) { create(:elections_component, participatory_space: participatory_process) }
          let(:election) { create(:election, component:, census_manifest: "custom_csv", census_settings:) }
          let(:census_settings) do
            {
              "columns" => [
                { "name" => "Name", "column_type" => "free_text" },
                { "name" => "ID", "column_type" => "alphanumeric" }
              ]
            }
          end

          let(:form) do
            instance_double(
              Admin::Censuses::CustomCsvForm,
              invalid?: form_invalid,
              valid?: !form_invalid,
              file: form_file,
              remove_all: form_remove_all,
              data: form_data
            )
          end
          let(:form_invalid) { false }
          let(:form_file) { nil }
          let(:form_remove_all) { false }
          let(:form_data) { [] }

          describe "#call" do
            context "when form is invalid" do
              let(:form_invalid) { true }

              it "broadcasts :invalid" do
                expect { subject.call }.to broadcast(:invalid)
              end

              it "does not create voters" do
                expect { subject.call }.not_to change(Decidim::Elections::Voter, :count)
              end
            end

            context "when remove_all is true" do
              let(:form_remove_all) { true }

              context "when census has voters" do
                before do
                  create_list(:election_voter, 3, election:)
                end

                it "broadcasts :ok" do
                  expect { subject.call }.to broadcast(:ok)
                end

                it "removes all voters" do
                  expect { subject.call }.to change { election.voters.count }.from(3).to(0)
                end
              end

              context "when census is empty" do
                it "broadcasts :invalid" do
                  expect { subject.call }.to broadcast(:invalid)
                end
              end
            end

            context "when file is blank (no upload)" do
              let(:form_file) { nil }

              it "broadcasts :ok" do
                expect { subject.call }.to broadcast(:ok)
              end

              it "does not create voters" do
                expect { subject.call }.not_to change(Decidim::Elections::Voter, :count)
              end
            end

            context "when file is present but data is empty" do
              let(:form_file) { "some_file.csv" }
              let(:form_data) { [] }

              it "broadcasts :invalid" do
                expect { subject.call }.to broadcast(:invalid)
              end

              it "does not create voters" do
                expect { subject.call }.not_to change(Decidim::Elections::Voter, :count)
              end
            end

            context "when file has valid data" do
              let(:form_file) { "valid_file.csv" }
              let(:form_data) do
                [
                  { "Name" => "John Doe", "ID" => "12345" },
                  { "Name" => "Jane Smith", "ID" => "67890" }
                ]
              end

              it "broadcasts :ok" do
                expect { subject.call }.to broadcast(:ok)
              end

              it "creates voters for each row" do
                expect { subject.call }.to change(Decidim::Elections::Voter, :count).by(2)
              end

              it "creates voters with correct data" do
                subject.call
                voter = election.voters.first
                expect(voter.data).to be_present
              end

              it "associates voters with election" do
                subject.call
                expect(election.voters.count).to eq(2)
              end
            end

            context "when file has single row" do
              let(:form_file) { "single_row.csv" }
              let(:form_data) do
                [{ "Name" => "Single Person", "ID" => "11111" }]
              end

              it "broadcasts :ok" do
                expect { subject.call }.to broadcast(:ok)
              end

              it "creates one voter" do
                expect { subject.call }.to change(Decidim::Elections::Voter, :count).by(1)
              end
            end

            context "when voters already exist" do
              let(:form_file) { "new_file.csv" }
              let(:form_data) do
                [{ "Name" => "New Person", "ID" => "99999" }]
              end

              before do
                create(:election_voter, election:)
              end

              it "broadcasts :ok" do
                expect { subject.call }.to broadcast(:ok)
              end

              it "adds new voters without removing existing" do
                expect { subject.call }.to change(Decidim::Elections::Voter, :count).by(1)
              end
            end
          end
        end
      end
    end
  end
end
