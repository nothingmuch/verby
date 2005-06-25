# Expected variables are:
# c.project_root
# demographics.demographic
# id (lower case proper name with _ for spaces)
# proper_name (the english name)
# table.
#    name (name of the table)
#    id (primary key/id for the table)

#!/usr/bin/perl
# --------------------------------------------------------------------------------------------------- #
# EERS test configuration file
# --------------------------------------------------------------------------------------------------- #
# author : stevan little
# email  : stevan@iinteractive.com
# date   : 12.9.2004
# --------------------------------------------------------------------------------------------------- #
# changes:
# --------------------------------------------------------------------------------------------------- #
#
# --------------------------------------------------------------------------------------------------- #	

BEGIN {
    # first load our module path, ...
    unshift @INC => qw(
                /var/www/perl
                /var/www/EERS/perl                
                [% c.project_root %]/
                [% c.project_root %]/perl             
                );
                
} 

use UNIVERSAL::require;

use IOC;
use IOC::Config::XML;

use II::IOC::Container::Database;
use II::IOC::Service::EntityManager;

use II::Persistence;
use II::Database qw(MySQL);

use EERS::ReportCycles;
use EERS::UserAccessLevels;

use EERS::Report::Tree;
use EERS::Report::Questions;

use EERS::Demographics::Tree;
use EERS::Demographics::Tree::Manager;

use EERS::Entities::StandardReport;
use EERS::Entities::Organization;

my $RUNNING_LOCALLY = 1;

if (-e '[% c.project_root %]/conf/startup.xml') {
    IOC::Config::XML->new()->read('[% c.project_root %]/conf/startup.xml');
    $RUNNING_LOCALLY = 0;
}
elsif (-e 'conf/startup.xml') {
    IOC::Config::XML->new()->read('conf/startup.xml');
}
else {
    die "Cannot find my path";
}

my $registry = IOC::Registry->new();

my $EERS_c = $registry->getRegisteredContainer('EERS');

# --------------------------------------------------------------------------------------------------- #	
# Database Container
# --------------------------------------------------------------------------------------------------- #	

my $db_c = II::IOC::Container::Database->new('MySQL', '[% database.dsn %]', '[% database.username %]', '[% database.password %]'); 
$db_c->asMock() if $RUNNING_LOCALLY;

#     $db_c->addProxy('connection' => IOC::Proxy->new({
#         on_method_call => sub {
#             my (undef, $method_name, undef, $args) = @_;
#             warn(('-' x 80) . "\nExecuting the following SQL :\n\t" . $args->[1] . "\n" . ('-' x 80))
#                 if ($method_name eq 'executeSQL');
#         }
#     }));

$EERS_c->addSubContainer($db_c);

# --------------------------------------------------------------------------------------------------- #	
# Persistence Container
# --------------------------------------------------------------------------------------------------- #	

my $persistence_c = $EERS_c->getSubContainer('Persistence');

$persistence_c->register(II::IOC::Service::EntityManager->new('EntityManager' => (
    'EERS::EntityManager' => [
        [ 'User'         => 'tbl_user'          ],
        [ 'Organization' => 'lkup_orgs'          ],
        [ 'UserListing'  => 'view_user_listing' ],
        [ 'Session'      => 'tbl_sessions'      ],
        # links
        [[ 'User', 'Organization' ], 'link_user_organization' ]
])));

# --------------------------------------------------------------------------------------------------- #	
# Filter Factory
# --------------------------------------------------------------------------------------------------- #	

use EERS::Filter::Factory;
use EERS::Filter;
use EERS::Filter::Demographic;
use EERS::Filter::Demographic::SQLGenerator;
use EERS::Filter::Demographic::Tree::SQLGenerator;
use EERS::Filter::Demographic::Organization::SQLGenerator;
use EERS::Filter::Demographic::View;
use EERS::Filter::Demographic::Tree::View;
use EERS::Filter::Demographic::Organization::View;

$EERS_c->register(IOC::Service->new('FilterFactory' => sub {
    my $c = shift;
    EERS::Filter::Factory->new(
        filter   =>	[ 
            'EERS::Filter' => { 
                        sql_generator =>  'EERS::Filter::SQLGenerator',
                        view          =>  'EERS::Filter::View',
                        } 
        ],
        type_map => {
            'org' => {
                demographic   => EERS::Filter::Demographic->new('org'),
                sql_generator => EERS::Filter::Demographic::Organization::SQLGenerator->new('tbl_org', 'org_id', $c->get('TreeManager')->getTreeIndex('Organizations')),
                view          => EERS::Filter::Demographic::Organization::View->new('Organizational Level' => $c->get('TreeManager')->getTreeIndex('Organizations'))
            },
            'org_level' => {
                demographic   => EERS::Filter::Demographic->new('org_level'),
                sql_generator => EERS::Filter::Demographic::Tree::SQLGenerator->new('tbl_org', 'org_id', $c->get('TreeManager')->getTreeIndex('Organizations')),
                view          => EERS::Filter::Demographic::Tree::View->new('Organizational Level' => $c->get('TreeManager')->getTreeIndex('Organizations'))
            },     
            [% FOREACH demographic IN demographics %]       
            '[% demographic.id %]' => {
                demographic   => EERS::Filter::Demographic->new('[% demographic.id %]'),
                sql_generator => EERS::Filter::Demographic::SQLGenerator->new('[% demographic.table.name %]', '[% demographic.table.id %]'),
                view          => EERS::Filter::Demographic::View->new('[% demographic.proper_name %]' => $c->find('Demographics/[% demographic.table_name %]'))
            },
            [% END %]
        }
    ); 
}));

# --------------------------------------------------------------------------------------------------- #	
# end CONFIG
# --------------------------------------------------------------------------------------------------- #	

use Premier;

use generics Premier => (
    BASE_URL => "[% c.project_url %]",
    COMPANY_NAME => "[% c.company_name %]",
    SYSTEM_NAME  => "Employee Engagement Reporting Toolkit"    
    );	

Premier->setSessionManager($registry->locateService('/EERS/Web/SessionManager'));
    
use EERS::Handlers::PDFReport;    
    
use generics EERS::Handlers::PDFReport => (
	PDF_DIR => "[% c.project_root %]/htdocs/static/pdf/"
	);	    
  
1;
