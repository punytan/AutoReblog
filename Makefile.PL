use inc::Module::Install;
name 'App-AutoReblog';
all_from 'lib/App/AutoReblog.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
