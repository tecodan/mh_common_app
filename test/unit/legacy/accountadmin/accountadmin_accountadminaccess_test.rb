require File.dirname(__FILE__) + '/../../../test_helper'

class AccountadminAccessTest < ActiveSupport::TestCase

  def test_ensure_user_exists
    Factory(:user_1)
    a = Factory(:accountadminaccountadminaccess_1)

    assert_no_difference('a.errors.size') do
      a.ensure_user_exists
    end

    User.delete_all

    assert_difference('a.errors.size') do
      a.ensure_user_exists
    end
  end

  def test_human_privilege
    setup_cim_hrdb_privs

    Factory(:user_1)
    a = Factory(:accountadminaccountadminaccess_1)

    assert_equal('site', a.human_privilege)

    Factory(:user_3)
    a = Factory(:accountadminaccountadminaccess_3)

    assert_equal('group', a.human_privilege)
  end
end