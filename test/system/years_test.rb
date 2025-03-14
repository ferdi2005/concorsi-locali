require "application_system_test_case"

class YearsTest < ApplicationSystemTestCase
  setup do
    @year = years(:one)
  end

  test "visiting the index" do
    visit years_url
    assert_selector "h1", text: "Years"
  end

  test "creating a Year" do
    visit years_url
    click_on "New Year"

    check "Special" if @year.special
    fill_in "Special category", with: @year.special_category
    fill_in "Special category label", with: @year.special_category_label
    check "Storicized" if @year.storicized
    fill_in "Year", with: @year.year
    click_on "Create Year"

    assert_text "Year was successfully created"
    click_on "Back"
  end

  test "updating a Year" do
    visit years_url
    click_on "Edit", match: :first

    check "Special" if @year.special
    fill_in "Special category", with: @year.special_category
    fill_in "Special category label", with: @year.special_category_label
    check "Storicized" if @year.storicized
    fill_in "Year", with: @year.year
    click_on "Update Year"

    assert_text "Year was successfully updated"
    click_on "Back"
  end

  test "destroying a Year" do
    visit years_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Year was successfully destroyed"
  end
end
