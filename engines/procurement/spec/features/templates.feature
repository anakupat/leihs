Feature: Templates

  Background:
    Given the basic dataset is ready

  @templates
  Scenario: Create a Template Category
    Given I am Barbara

#!!# already defined internally for Barbara
#    And I am responsible for one group

    When I navigate to the templates page
    Then there is an empty category line for creating a new category
    When I enter the category name
    And I click on save
    Then I see a success message
    And the category is saved to the database

  @templates
  Scenario: Create a Template Article
    Given I am Barbara
    And a template category exists
    When I navigate to the templates page
    And I edit the category
#!!# merged to a table
#    And I enter an article name
#    And I enter the article/suppliernr.
#    And I enter the price
#    And I enter the supplier
    And the following fields are filled
      | Article                    |
      | Article nr. / Producer nr. |
      | Price                      |
      | Supplier                   |

    And I click on save
    Then I see a success message
    And the data entered is saved to the database

  @templates
  Scenario: Deleting a Template Category
    Given I am Barbara
    And a template category exists
    And the template category contains articles
    When I navigate to the templates page
    And I delete the template category
    Then the template category is marked red
    When I click on save
    Then I see a success message
    And the deleted template category is deleted from the database

  @templates
  Scenario: Deleting an Article
    Given I am Barbara
    And a template category exists
#!!# this could also be with many articles, reusing existing step
    And the template category contains articles
    When I navigate to the templates page

#!!# referring to 'the'
#    And I edit a category
    And I edit the category
    And I delete an article from the category
    Then the article of the category is marked red
    When I click on save
    Then I see a success message
    And the category article is deleted from the database

  @templates
  Scenario: Editing a Template
    Given I am Barbara
    And a template category exists
    And the template category has one article
    When I navigate to the templates page
    #!!# this is needed to open
    And I edit the category
    And I modify the category name
#!!# merged to a table
#    And I modify the article name
#    And I modify the article/suppliernr.
#    And I modify the price
#    And I modify the supplier
    And the following fields are modified
      | Article                    |
      | Article nr. / Producer nr. |
      | Price                      |
      | Supplier                   |
    And I click on save
    Then I see a success message
    And the data modified is saved to the database

  @templates
  Scenario: Deleting information of some fields of an article
    Given I am Barbara
    And a template category exists
    And the template category has one article
    When I navigate to the templates page
    And I edit the category
#!!# merged to a table
#    And the article name is filled
#    And the article/suppliernr. is filled
#    And the price is filled
#    And the supplier is filled
    And the following fields are filled
      | Article                    |
      | Article nr. / Producer nr. |
      | Price                      |
      | Supplier                   |
#!!# merged to a table
#    When I delete the article/suppliernr.
#    And I delete the price
#    And I delete the supplier
    When I delete the following fields
      | Article nr. / Producer nr. |
      | Price                      |
      | Supplier                   |
    And I click on save
    Then I see a success message
    And the deleted data is deleted from the database

  @templates
  Scenario: Sorting of categories and articles
    Given I am Barbara
    And several template categories exist
    And several articles in categories exist
    When I navigate to the templates page
    Then the categories are sorted 0-10 and a-z
    And the articles inside a category are sorted 0-10 and a-z

  @templates
  Scenario: Nullify id in request when articlename and article nr./supplier nr. have been changed
    Given I am Barbara

#!!# we have to refer to a specific template
#    And several template categories exist
#    And several articles in categories exist
    And a template category exists
    And the template category has one article
    And the template is already used in many requests
    When I navigate to the templates page
    And I edit the category
#!!# merged to a table
#    And I change the name of an article
#    And I change or delete the article nr./supplier nr. of the same article
    And the following fields are modified
      | Article                    |
      | Article nr. / Producer nr. |
    And I click on save
    Then I see a success message
    And the data modified is saved to the database
#!!# already checked in previous step
#    And this template id saved in requests is nullified
    And the requests are nullified
