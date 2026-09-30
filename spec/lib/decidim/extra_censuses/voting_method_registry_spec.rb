# frozen_string_literal: true

require "spec_helper"

module Decidim
  module ExtraCensuses
    describe "voting_method_registry" do
      subject { Decidim::ExtraCensuses.voting_method_registry }

      it "finds the borda manifest by string name" do
        expect(subject.find("borda").name).to eq(:borda)
      end

      it "finds the borda manifest by symbol name" do
        expect(subject.find(:borda).name).to eq(:borda)
      end

      it "returns nil for an unknown name" do
        expect(subject.find("nope")).to be_nil
      end

      it "registers the borda manifest" do
        expect(subject.manifests.map(&:name)).to include(:borda)
      end

      it "does not register a manifest for the upstream-default approval method" do
        expect(subject.manifests.map(&:name)).not_to include(:approval)
      end
    end
  end
end
