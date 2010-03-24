require File.dirname(__FILE__) + '/../test_helper'
require 'mocha'

class PersonTest < ActiveSupport::TestCase
#  Person, CustomValue, TrainingAnswer, 
#  Address, User,
#  Ministry, GroupInvolvement, GroupType, Group


  def setup
    setup_n_campus_involvements(10)
    setup_addresses
    setup_campuses
    setup_ministries
    Factory(:ministrycampus_1)
    Factory(:ministrycampus_2)
    Factory(:ministrycampus_3)
    setup_school_years
    setup_ministry_roles
    setup_users
    setup_people
    setup_n_people(2)
    setup_ministry_involvements
    @josh = Person.find(50000)
    @sue = Person.find(2000)
    @personfirst = Person.find(1)
    @person2 = Person.find(2)    
  end


  def test_full_destroy
    p = Factory(:person_1)
    Factory(:user_1)
    Factory(:access_1)
    Factory(:emerg_1)
    Factory(:cimhrdbpersonyear_1)
    Factory(:cimhrdbpersonyear_2)

    pid = p.id
    uid = p.user.id
    aid = p.access.id
    eid = p.emerg.id
    yid1 = p.cim_hrdb_person_years.first.id
    yid2 = p.cim_hrdb_person_years.last.id

    assert_instance_of(::Person, p)
    assert_instance_of(::User, p.user)
    assert_instance_of(::Access, p.access)
    assert_instance_of(::Emerg, p.emerg)
    assert_instance_of(::CimHrdbPersonYear, p.cim_hrdb_person_years.first)
    assert_instance_of(::CimHrdbPersonYear, p.cim_hrdb_person_years.last)

    p.full_destroy

    assert_raise(ActiveRecord::RecordNotFound) {::Person.find(pid)}
    assert_raise(ActiveRecord::RecordNotFound) {::User.find(uid)}
    assert_raise(ActiveRecord::RecordNotFound) {::Access.find(aid)}
    assert_raise(ActiveRecord::RecordNotFound) {::Emerg.find(eid)}
    assert_raise(ActiveRecord::RecordNotFound) {::CimHrdbPersonYear.find(yid1)}
    assert_raise(ActiveRecord::RecordNotFound) {::CimHrdbPersonYear.find(yid2)}
  end

  def test_map_cim_hrdb_to_mt
    flunk("this test doesn't work yet, mc.try(:ministry) is returning nil")
    CampusInvolvement.delete_all
    MinistryInvolvement.delete_all

    p = Factory(:person_1)
    setup_assignmentstatuses
    Factory(:assignment_1)
    Factory(:cimhrdbstaff_1)
    Factory(:ministrycampus_1)
    Factory(:ministry_1)

    p.map_cim_hrdb_to_mt
  end

  def test_get_highest_assignment
    p = Factory(:person_1)

    setup_assignmentstatuses
    Factory(:assignment_1)
    Factory(:assignment_2)
    Factory(:assignment_3)
    Factory(:assignment_6)

    assert_equal(Factory(:assignment_1), p.get_highest_assignment)

    p = Person.find(1)
    assert_equal(Factory(:assignment_6), p.get_highest_assignment)
  end

  def test_upgrade_ministry_involvement
    flunk("this test doesn't work yet, mi isn't being saved in second upgrade_ministry_involvement call")
    p = Factory(:person_111)

    assert_equal([], p.ministry_involvements)

    p.upgrade_ministry_involvement(Factory(:ministry_1), Factory(:ministryrole_6))
    assert_equal(::StudentRole, p.ministry_involvements.first.ministry_role.class)

    p.upgrade_ministry_involvement(Factory(:ministry_1), Factory(:ministryrole_9))
    assert_equal(::StaffRole, p.ministry_involvements.first.ministry_role.class)
    assert_equal(1, p.ministry_involvements.size)
  end

  def test_map_cim_hrdb_to_mt_old
    MinistryInvolvement.delete_all
    CampusInvolvement.delete_all
    setup_assignments
    setup_assignmentstatuses
    setup_ministry_campuses
    Factory(:user_1)
    Factory(:access_1)
    Factory(:cimhrdbpersonyear_1)
    Factory(:cimhrdbstaff_1)
    p = Factory(:person_1)

    p.map_cim_hrdb_to_mt_old

    assert_equal(Factory(:ministry_1).id, p.ministry_involvements.first.ministry_id)
    assert_equal("Staff Team", p.ministry_involvements.first.ministry_role.name)

    assert_equal(Factory(:ministry_6).id, p.ministry_involvements.last.ministry_id)
    assert_equal("Staff", p.ministry_involvements.last.ministry_role.name)

    assert_equal(Factory(:campus_1).id, p.campus_involvements.first.campus_id)
    assert_equal(Factory(:ministry_6).id, p.campus_involvements.first.ministry_id)
    assert_equal(Factory(:schoolyear_10).name, p.campus_involvements.first.school_year.name)
  end

  def test_map_cim_hrdb_to_mt_old_not_staff
    MinistryInvolvement.delete_all
    CampusInvolvement.delete_all
    setup_assignments
    setup_assignmentstatuses
    setup_ministry_campuses
    Factory(:user_1)
    Factory(:access_1)
    Factory(:cimhrdbpersonyear_1)
    p = Factory(:person_1)

    p.map_cim_hrdb_to_mt_old

    assert_equal([], p.ministry_involvements)

    assert_equal(Factory(:campus_1).id, p.campus_involvements.first.campus_id)
    assert_equal(Factory(:ministry_6).id, p.campus_involvements.first.ministry_id)
    assert_equal(Factory(:schoolyear_3).name, p.campus_involvements.first.school_year.name)
  end

  def test_find_user
    p = Factory(:person_1)
    a = Factory(:address_1)
    u = Factory(:user_1)
    u.username = p.email
    u.save

    # test no access
    p = ::Person.find_user(p, a)
    assert_equal(u, p.user)

    # test has access
    p = ::Person.find_user(p, a)
    assert_equal(u, p.user)
  end

  def test_find_user_no_user
    p = Factory(:person_1)
    a = Factory(:address_1)

    p = ::Person.find_user(p, a)
    assert_equal(p.user.user_id, p.email)
  end

  def test_search
    assert_equal([Factory(:person_1)], ::Person.search("Josh", 1, 10))
    assert_equal([::Person.find(2)], ::Person.search("A2", 1, 10))
    assert_equal(::Person.all(:conditions => "person_id IN (1, 2, 3, 111, 50000)"), ::Person.search("A", 1, 10))
    assert_equal(nil, ::Person.search(nil, 1, 1))
  end

  def test_is_student
    p = Factory(:person_1)
    assert_equal(false, p.is_student)
    p.ministry_involvements.delete_all
    assert_equal(true, p.is_student)
  end

  def test_setup_and_create_access
    Factory(:AccoutnadminAccessgroup_1)
    Factory(:person_1).setup_and_create_access(Factory(:user_1))

    assert_equal(Factory(:user_1), ::AccountadminVieweraccessgroup.first.user)
    assert_equal(Factory(:AccoutnadminAccessgroup_1).id, ::AccountadminVieweraccessgroup.first.accessgroup_id)
    assert_equal(Factory(:user_1), Factory(:person_1).user)
  end

  def test_relationships
    assert_not_nil(@personfirst.campus_involvements)
    assert_not_nil(@personfirst.campuses)
    assert_not_nil(@personfirst.ministries)
  end

  def test_human_gender
    p = Person.new(:gender => '1')
    assert_equal p.human_gender, 'Male'
  end

  def test_set_gender_blank
    p = Person.new
    p.gender = ''
    assert_equal nil, p.human_gender
  end

  def test_initiate_addresses
    p = Person.new
    p.initialize_addresses
    assert_not_nil p.current_address
    assert_not_nil p.permanent_address
    assert_not_nil p.emergency_address
  end

  def test_find_exact_from_username
    #username match
    assert_equal(@josh, Person.find_exact(@josh, @josh.current_address))
  end

  def test_find_exact_from_email
    #email match
    assert_equal(@sue, Person.find_exact(@sue, @sue.current_address))
  end

  def test_find_exact_from_orphan_user
    #test orphan user
    u = User.new(:username => "orphan@user.com", :person_id => nil, :guid => "",
                 :last_login => 10.days.ago)
    u.save
    a = Address.new(:email => u.username)
    a.save
    assert_equal(u, Person.find_exact(Factory(:person_1), a).user)
  end

  def test_full_name
    assert_equal('Josh Starcher', @josh.full_name)
  end

  def test_male?
    assert(@josh.male?)
    assert_equal(false, @sue.male?)
  end

  test "person should be born in the past" do
    person = Person.new
    person.first_name = "Invalid Birth Date Test"
    person.last_name = "last name"
    person.person_legal_lname = "last name"
    person.person_legal_fname = "first name"
    person.save

    assert person.valid?

    person.birth_date = Date.today + 1.days
    assert !person.valid?

    person.birth_date = Date.today - 1.days
    assert person.valid?
  end

  test "his - her" do
    assert_equal('his', @josh.hisher)
    assert_equal('her', @sue.hisher)
  end

  test "him - her" do
    assert_equal('him', @josh.himher)
    assert_equal('her', @sue.himher)
  end

  test "he - she" do
    assert_equal('he', @josh.heshe)
    assert_equal('she', @sue.heshe)
  end

  test "person's role in a ministry" do
    assert_equal(@ministry_role_one, @josh.role(@ministry_yfc))
  end

  test "add_or_update_campus adds a campus" do
    assert_difference('CampusInvolvement.count', 1) do
      @personfirst.add_or_update_campus Campus.last.id, SchoolYear.first.id, Ministry.first.id, Person.last
    end
  end

  test "add_or_update_campus updates a campus" do
    ci = CampusInvolvement.first
    @person = ci.person
    assert_no_difference('CampusInvolvement.count') do
      @person.add_or_update_campus ci.campus, SchoolYear.first.id, Ministry.first.id, Person.last
    end
  end

  test "add_or_update_ministry adds a ministry" do
    @person = Person.find 111 # someone without ministry roles
    assert_difference('MinistryInvolvement.count', 1) do
      @person.add_or_update_ministry Ministry.first(2), MinistryRole.find(2)
    end
  end

  test "add_or_update_ministry updates a campus" do
    mi = MinistryInvolvement.first
    @person = mi.person
    assert_no_difference('MinistryInvolvement.count') do
      @person.add_or_update_ministry mi.ministry, MinistryRole.find(2)
    end
  end

  test "working campuses" do
    Factory(:campusinvolvement_3)
    Factory(:ministry_1)
    wc = Factory(:person_1).working_campuses(Factory(:ministryinvolvement_1))
    assert_equal(Factory(:campus_3).id, wc[0]["campus_id"])
    assert_equal(Factory(:campus_1).id, wc[1]["campus_id"])

    Factory(:campusinvolvement_6)
    wc = Factory(:person_2).working_campuses(Factory(:ministryinvolvement_3))
    assert_equal(Factory(:campus_1).id, wc[0]["campus_id"])
  end

  test "add_or_update_campus different school year" do
    ci = Factory(:person_1).add_or_update_campus(Factory(:campusinvolvement_3).campus_id, Factory(:schoolyear_2).id, Factory(:campusinvolvement_3).ministry_id, Factory(:person_1).id)
    assert_equal(Factory(:schoolyear_2), ci.school_year)
  end

  test "admin?" do
    assert_equal(true, Factory(:person_1).admin?(Factory(:ministry_1)))
  end

  test "campus list" do
    Factory(:campusinvolvement_6)
    c = Factory(:person_2).campus_list(Factory(:ministryinvolvement_3))
    assert_equal(1, c[0].id)
    assert_equal(1, c.size)

    c = Factory(:person_1).campus_list(Factory(:ministryinvolvement_1))
    assert_equal(2, c[0].id)
    assert_equal(3, c[1].id)
    assert_equal(1, c[2].id)
    assert_equal(3, c.size)
  end

  test "ministry_tree" do
    mt = Factory(:person_1).ministry_tree
    assert_equal(Factory(:ministry_1), mt.detect {|m| m.id == 1})
    assert_equal(Factory(:ministry_2), mt.detect {|m| m.id == 2})
    assert_equal(Factory(:ministry_3), mt.detect {|m| m.id == 3})
    assert_equal(Factory(:ministry_7), mt.detect {|m| m.id == 6})
    assert_equal(4, mt.size)
  end

  test "email=" do
    # Factory(:person_1) has an address already
    Factory(:person_1).email = "test@internets.ca"
    a = CimHrdbCurrentAddress.find(:first, :conditions => {:person_id => Factory(:person_1).id})
    assert_equal("test@internets.ca", a.email)

    # Factory(:person_2) doesn't have an address
    Factory(:person_2).email = "test@internets.ca"
    a = CimHrdbCurrentAddress.find(:first, :conditions => {:person_id => Factory(:person_2).id})
    assert_equal("test@internets.ca", a.email)
  end

  test "email" do
    assert_equal('josh.starcher@uscm.org', Factory(:person_1).email)
  end

  test "sanify addresses" do
    Factory(:person_1).sanify_addresses
    assert_equal(nil, Factory(:person_1).current_address.state)
  end

  test "most nested ministry" do
    assert_equal(Factory(:ministry_2), Factory(:person_1).most_nested_ministry)
  end

  test "to liquid" do
    Factory(:access_1)
    assert_equal({"preferred_name" => "Josh",
        "himher" => "him",
        "currentaddress" => CimHrdbCurrentAddress.find(Factory(:person_1).id),
        "last_name" => "Starcher",
        "hisher" => "his", "heshe" => "he",
        "user" => Factory(:user_1), "first_name" => "Josh"},
      Factory(:person_1).to_liquid)
  end

  test "most recent involvement" do
    Factory(:campusinvolvement_2)
    Factory(:campusinvolvement_4)

    assert_equal(Factory(:campusinvolvement_4), Factory(:person_3).most_recent_involvement)
  end

  test "get best assigned campus" do
    setup_assignments
    assert_equal(Factory(:person_1).get_best_assigned_campus, Factory(:campus_3))
  end

  test "import gcx profile" do
    attrib = [{"value" => "test_email", "displayname" => "emailAddress"},
              {"value" => "test_city", "displayname" => "city"},
              {"value" => "test_phone", "displayname" => "landPhone"},
              {"value" => "test_alternate_phone", "displayname" => "mobilePhone"},
              {"value" => "test_zip", "displayname" => "zip"},
              {"value" => "test_address1", "displayname" => "location"},
              {"value" => "test_first_name", "displayname" => "firstName"},
              {"value" => "test_last_name", "displayname" => "lastName"},
              {"value" => "test_birth_date", "displayname" => "birthdate"},
              {"value" => "test_gender", "displayname" => "gender"}]

    CASClient::Frameworks::Rails::Filter.stubs(:client).returns(CASClient.new)
    CASClient.any_instance.stubs(:request_proxy_ticket).returns(ProxyTicket.new)
    ProxyTicket.any_instance.stubs(:ticket).returns("proxy_ticket")
    Factory(:person_1).stubs(:Hpricot).returns(Hpricot.new)
    Hpricot.any_instance.stubs(:/).returns(attrib)

    assert_equal(true, Factory(:person_1).import_gcx_profile(GcxTicket.new))

    a = ::Person.find(50000).current_address

    assert_equal("test_email", a.email)
    assert_equal("test_city", a.city)
    assert_equal("test_phone", a.phone)
    assert_equal("test_alternate_phone", a.alternate_phone)
    assert_equal("test_zip", a.zip)
    assert_equal("test_address1", a.address1)
  end

end

class GcxTicket ; end
class CASClient
  def request_proxy_ticket(proxy_granting_ticket, service_uri) ; end
end
class CASClient::Frameworks ; end
class CASClient::Frameworks::Rails ; end
class CASClient::Frameworks::Rails::Filter
  def self.client ; end
end
class CASClient::ServiceTicket
  def initialize(proxy_ticket = nil, service_uri = nil) ; end
end
class ProxyTicket
  def ticket ; end
end
class Hpricot
  def /(val) ; end
end
