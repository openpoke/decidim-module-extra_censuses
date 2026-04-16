# frozen_string_literal: true

require "spec_helper"

module Decidim
  module ExtraCensuses
    describe ResponseOptionFormOverride do
      describe "group_id attribute" do
        let(:form) do
          Decidim::Elections::Admin::ResponseOptionForm.from_params(
            response_option: { body: { en: "Opt" }, group_id: }
          )
        end

        context "when group_id is a hex string" do
          let(:group_id) { "abc12345" }

          it "is exposed on the form" do
            expect(form.group_id).to eq("abc12345")
          end
        end

        context "when group_id is blank" do
          let(:group_id) { "" }

          it "is exposed as a blank string" do
            expect(form.group_id).to eq("")
          end
        end

        context "when group_id is missing from params" do
          let(:form) do
            Decidim::Elections::Admin::ResponseOptionForm.from_params(
              response_option: { body: { en: "Opt" } }
            )
          end

          it "is nil" do
            expect(form.group_id).to be_nil
          end
        end
      end
    end
  end
end
