# frozen_string_literal: true

require "spec_helper"

module Decidim
  module ExtraCensuses
    describe GroupedResponseOptionsHelper do
      let(:election) { create(:election) }

      describe "#response_option_group_forms" do
        let(:question) do
          create(:election_question,
                 election:,
                 settings: {
                   "grouped" => true,
                   "groups" => [
                     { "id" => "g1aaaaaa", "title" => { "en" => "First" }, "position" => 0 },
                     { "id" => "g2bbbbbb", "title" => { "en" => "Second" }, "position" => 1 }
                   ]
                 })
        end

        it "returns ResponseOptionGroupForm instances populated from settings" do
          forms = helper.response_option_group_forms(question)
          expect(forms).to all(be_a(Decidim::ExtraCensuses::Elections::Admin::ResponseOptionGroupForm))
          expect(forms.map(&:id)).to eq(%w(g1aaaaaa g2bbbbbb))
          expect(forms.map(&:position)).to eq([0, 1])
          expect(forms.first.title).to eq("en" => "First")
        end

        it "exposes form-only attributes so fields_for works in the admin edit view" do
          form = helper.response_option_group_forms(question).first
          expect(form.deleted).to be(false)
          expect(form).to respond_to(:persisted?)
          expect(form).to respond_to(:to_model)
        end
      end

      describe "#grouped_response_options" do
        context "when the question has two groups with options each" do
          let(:question) do
            create(:election_question,
                   election:,
                   settings: {
                     "grouped" => true,
                     "groups" => [
                       { "id" => "g1aaaaaa", "title" => { "en" => "First" }, "position" => 0 },
                       { "id" => "g2bbbbbb", "title" => { "en" => "Second" }, "position" => 1 }
                     ]
                   })
          end
          let!(:option_a1) { create(:election_response_option, question:, group_id: "g1aaaaaa") }
          let!(:option_a2) { create(:election_response_option, question:, group_id: "g1aaaaaa") }
          let!(:option_b1) { create(:election_response_option, question:, group_id: "g2bbbbbb") }

          it "returns [group, options] pairs in group position order" do
            pairs = helper.grouped_response_options(question)
            expect(pairs.size).to eq(2)
            expect(pairs[0].first.id).to eq("g1aaaaaa")
            expect(pairs[0].last).to contain_exactly(option_a1, option_a2)
            expect(pairs[1].first.id).to eq("g2bbbbbb")
            expect(pairs[1].last).to contain_exactly(option_b1)
          end

          it "does not include a nil group entry when there are no orphans" do
            pairs = helper.grouped_response_options(question)
            expect(pairs.map(&:first)).to all(be_a(Decidim::ExtraCensuses::ResponseOptionGroup))
          end
        end

        context "when an option has a stale group_id" do
          let(:question) do
            create(:election_question,
                   election:,
                   settings: {
                     "grouped" => true,
                     "groups" => [{ "id" => "g1aaaaaa", "title" => { "en" => "First" }, "position" => 0 }]
                   })
          end
          let!(:known_option) { create(:election_response_option, question:, group_id: "g1aaaaaa") }
          let!(:stale_option) { create(:election_response_option, question:, group_id: "gunknown") }

          it "appends the stale option under a nil group entry" do
            pairs = helper.grouped_response_options(question)
            expect(pairs.size).to eq(2)
            expect(pairs[0].first.id).to eq("g1aaaaaa")
            expect(pairs[0].last).to contain_exactly(known_option)
            expect(pairs[1].first).to be_nil
            expect(pairs[1].last).to contain_exactly(stale_option)
          end
        end

        context "when an option has a blank group_id" do
          let(:question) do
            create(:election_question,
                   election:,
                   settings: {
                     "grouped" => true,
                     "groups" => [{ "id" => "g1aaaaaa", "title" => { "en" => "First" }, "position" => 0 }]
                   })
          end
          let!(:known_option) { create(:election_response_option, question:, group_id: "g1aaaaaa") }
          let!(:blank_option) { create(:election_response_option, question:, group_id: nil) }

          it "appends the blank-group_id option under a nil group entry" do
            pairs = helper.grouped_response_options(question)
            expect(pairs.last.first).to be_nil
            expect(pairs.last.last).to contain_exactly(blank_option)
          end
        end
      end

      describe "#ungrouped_response_options" do
        let(:question) do
          create(:election_question,
                 election:,
                 settings: {
                   "grouped" => true,
                   "groups" => [{ "id" => "g1aaaaaa", "title" => { "en" => "First" }, "position" => 0 }]
                 })
        end

        context "when the question is not grouped" do
          let(:question) { create(:election_question, election:, settings: { "grouped" => false }) }

          it "returns an empty array regardless of group_id state" do
            create(:election_response_option, question:, group_id: nil)
            create(:election_response_option, question:, group_id: "anything")
            expect(helper.ungrouped_response_options(question)).to eq([])
          end
        end

        context "when grouped and all options match a known group" do
          let!(:matched) { create(:election_response_option, question:, group_id: "g1aaaaaa") }

          it "returns an empty array" do
            expect(helper.ungrouped_response_options(question)).to eq([])
          end
        end

        context "when grouped and an option has a stale group_id" do
          let!(:stale) { create(:election_response_option, question:, group_id: "gunknown") }

          it "is included in the result" do
            expect(helper.ungrouped_response_options(question)).to contain_exactly(stale)
          end
        end

        context "when grouped and an option has a blank group_id" do
          let!(:blank) { create(:election_response_option, question:, group_id: nil) }

          it "is included in the result" do
            expect(helper.ungrouped_response_options(question)).to contain_exactly(blank)
          end
        end
      end
    end
  end
end
