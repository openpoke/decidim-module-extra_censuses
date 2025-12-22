# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Elections
    module CustomCsvCensus
      describe Types do
        describe ".find" do
          it "returns Alphanumeric for 'alphanumeric'" do
            expect(described_class.find("alphanumeric")).to eq(Types::Alphanumeric)
          end

          it "returns TextTrim for 'text_trim'" do
            expect(described_class.find("text_trim")).to eq(Types::TextTrim)
          end

          it "returns Date for 'date'" do
            expect(described_class.find("date")).to eq(Types::Date)
          end

          it "returns Number for 'number'" do
            expect(described_class.find("number")).to eq(Types::Number)
          end

          it "returns Base for unknown type" do
            expect(described_class.find("unknown")).to eq(Types::Base)
          end

          it "returns Base for nil" do
            expect(described_class.find(nil)).to eq(Types::Base)
          end
        end

        describe ".validate" do
          it "delegates to the correct type class" do
            expect(described_class.validate("number", "123")).to be_nil
            expect(described_class.validate("number", "abc")).to eq("invalid_number")
          end
        end

        describe ".transform" do
          it "delegates to the correct type class" do
            expect(described_class.transform("alphanumeric", "abc-123")).to eq("abc123")
          end
        end
      end

      describe Types::Base do
        describe ".validate" do
          it "returns nil for any value" do
            expect(described_class.validate("anything")).to be_nil
            expect(described_class.validate("")).to be_nil
            expect(described_class.validate("!@#$%")).to be_nil
          end
        end

        describe ".transform" do
          it "returns value unchanged" do
            expect(described_class.transform("hello")).to eq("hello")
            expect(described_class.transform("  spaces  ")).to eq("  spaces  ")
            expect(described_class.transform("123-abc")).to eq("123-abc")
          end
        end
      end

      describe Types::Alphanumeric do
        describe ".validate" do
          it "returns nil for any value (no validation)" do
            expect(described_class.validate("abc123")).to be_nil
            expect(described_class.validate("!@#")).to be_nil
          end
        end

        describe ".transform" do
          it "keeps only letters and digits" do
            expect(described_class.transform("abc123")).to eq("abc123")
            expect(described_class.transform("ABC123")).to eq("ABC123")
          end

          it "removes spaces" do
            expect(described_class.transform("abc 123")).to eq("abc123")
            expect(described_class.transform("  hello  ")).to eq("hello")
          end

          it "removes special characters" do
            expect(described_class.transform("abc-123")).to eq("abc123")
            expect(described_class.transform("hello_world")).to eq("helloworld")
            expect(described_class.transform("test@email.com")).to eq("testemailcom")
          end

          it "removes punctuation" do
            expect(described_class.transform("hello!")).to eq("hello")
            expect(described_class.transform("what?")).to eq("what")
            expect(described_class.transform("a,b,c")).to eq("abc")
          end

          it "removes unicode characters" do
            expect(described_class.transform("cafeс")).to eq("cafe")
            expect(described_class.transform("nino")).to eq("nino")
          end

          it "returns empty string when no alphanumeric" do
            expect(described_class.transform("!@#$%")).to eq("")
            expect(described_class.transform("---")).to eq("")
          end
        end
      end

      describe Types::TextTrim do
        describe ".validate" do
          it "returns nil for any value (no validation)" do
            expect(described_class.validate("hello")).to be_nil
            expect(described_class.validate("  spaces  ")).to be_nil
          end
        end

        describe ".transform" do
          it "removes leading spaces" do
            expect(described_class.transform("  hello")).to eq("hello")
            expect(described_class.transform("   test")).to eq("test")
          end

          it "removes trailing spaces" do
            expect(described_class.transform("hello  ")).to eq("hello")
            expect(described_class.transform("test   ")).to eq("test")
          end

          it "removes both leading and trailing spaces" do
            expect(described_class.transform("  hello  ")).to eq("hello")
            expect(described_class.transform("   test   ")).to eq("test")
          end

          it "preserves inner spaces" do
            expect(described_class.transform("  hello world  ")).to eq("hello world")
            expect(described_class.transform("  a   b   c  ")).to eq("a   b   c")
          end

          it "handles tabs and newlines" do
            expect(described_class.transform("\thello\t")).to eq("hello")
            expect(described_class.transform("\nhello\n")).to eq("hello")
            expect(described_class.transform(" \t\n hello \n\t ")).to eq("hello")
          end

          it "returns empty string for only whitespace" do
            expect(described_class.transform("   ")).to eq("")
            expect(described_class.transform("\t\n")).to eq("")
          end

          it "returns value unchanged if no surrounding whitespace" do
            expect(described_class.transform("hello")).to eq("hello")
            expect(described_class.transform("test123")).to eq("test123")
          end
        end
      end

      describe Types::Date do
        describe ".validate" do
          context "with valid dates" do
            it "accepts ISO format YYYY-MM-DD" do
              expect(described_class.validate("2024-01-15")).to be_nil
              expect(described_class.validate("2000-12-31")).to be_nil
              expect(described_class.validate("1990-06-01")).to be_nil
            end

            it "accepts European format DD/MM/YYYY" do
              expect(described_class.validate("15/01/2024")).to be_nil
              expect(described_class.validate("31/12/2000")).to be_nil
            end

            it "accepts US format MM/DD/YYYY" do
              expect(described_class.validate("01/15/2024")).to be_nil
              expect(described_class.validate("12/31/2000")).to be_nil
            end

            it "accepts format with dots DD.MM.YYYY" do
              expect(described_class.validate("15.01.2024")).to be_nil
              expect(described_class.validate("31.12.2000")).to be_nil
            end

            it "accepts written month names" do
              expect(described_class.validate("January 15, 2024")).to be_nil
              expect(described_class.validate("15 January 2024")).to be_nil
              expect(described_class.validate("Jan 15, 2024")).to be_nil
            end

            it "accepts month and year" do
              expect(described_class.validate("January 2024")).to be_nil
              expect(described_class.validate("01/2024")).to be_nil
            end
          end

          context "with invalid dates" do
            it "rejects random text" do
              expect(described_class.validate("not a date")).to eq("invalid_date")
              expect(described_class.validate("hello world")).to eq("invalid_date")
            end

            it "rejects empty-like strings" do
              expect(described_class.validate("")).to eq("invalid_date")
              expect(described_class.validate("   ")).to eq("invalid_date")
            end

            it "accepts numbers as years" do
              expect(described_class.validate("2024")).to be_nil
              expect(described_class.validate("12345")).to be_nil
            end

            it "rejects very large numbers" do
              expect(described_class.validate("999999999")).to eq("invalid_date")
            end

            it "rejects special characters only" do
              expect(described_class.validate("!@#$%")).to eq("invalid_date")
              expect(described_class.validate("---")).to eq("invalid_date")
            end

            it "rejects malformed date strings" do
              expect(described_class.validate("2024-13-45")).to be_nil
              expect(described_class.validate("abc-def-ghi")).to eq("invalid_date")
            end
          end
        end

        describe ".transform" do
          it "returns value unchanged (no transformation)" do
            expect(described_class.transform("2024-01-15")).to eq("2024-01-15")
            expect(described_class.transform("15/01/2024")).to eq("15/01/2024")
          end
        end
      end

      describe Types::Number do
        describe ".validate" do
          context "with valid numbers" do
            it "accepts single digit" do
              expect(described_class.validate("0")).to be_nil
              expect(described_class.validate("5")).to be_nil
              expect(described_class.validate("9")).to be_nil
            end

            it "accepts multiple digits" do
              expect(described_class.validate("123")).to be_nil
              expect(described_class.validate("999999")).to be_nil
              expect(described_class.validate("00001")).to be_nil
            end

            it "accepts long numbers" do
              expect(described_class.validate("12345678901234567890")).to be_nil
            end

            it "accepts leading zeros" do
              expect(described_class.validate("007")).to be_nil
              expect(described_class.validate("0000")).to be_nil
            end
          end

          context "with invalid numbers" do
            it "rejects negative numbers" do
              expect(described_class.validate("-123")).to eq("invalid_number")
              expect(described_class.validate("-1")).to eq("invalid_number")
            end

            it "rejects decimal numbers" do
              expect(described_class.validate("123.45")).to eq("invalid_number")
              expect(described_class.validate("0.5")).to eq("invalid_number")
              expect(described_class.validate("3.14")).to eq("invalid_number")
            end

            it "rejects numbers with comma" do
              expect(described_class.validate("1,000")).to eq("invalid_number")
              expect(described_class.validate("123,456")).to eq("invalid_number")
            end

            it "rejects numbers with spaces" do
              expect(described_class.validate("123 456")).to eq("invalid_number")
              expect(described_class.validate(" 123")).to eq("invalid_number")
              expect(described_class.validate("123 ")).to eq("invalid_number")
            end

            it "rejects letters" do
              expect(described_class.validate("abc")).to eq("invalid_number")
              expect(described_class.validate("123abc")).to eq("invalid_number")
              expect(described_class.validate("abc123")).to eq("invalid_number")
            end

            it "rejects special characters" do
              expect(described_class.validate("123!")).to eq("invalid_number")
              expect(described_class.validate("#123")).to eq("invalid_number")
              expect(described_class.validate("12+34")).to eq("invalid_number")
            end

            it "rejects empty string" do
              expect(described_class.validate("")).to eq("invalid_number")
            end

            it "rejects scientific notation" do
              expect(described_class.validate("1e10")).to eq("invalid_number")
              expect(described_class.validate("1E5")).to eq("invalid_number")
            end

            it "rejects plus sign" do
              expect(described_class.validate("+123")).to eq("invalid_number")
            end
          end
        end

        describe ".transform" do
          it "returns value unchanged (no transformation)" do
            expect(described_class.transform("123")).to eq("123")
            expect(described_class.transform("007")).to eq("007")
          end
        end
      end
    end
  end
end
