use inc::Module::Install;
name 'App-AutoReblog';
all_from 'lib/App/AutoReblog.pm';

# requires '';

requires 'WebService::Google::Reader';
requires 'LWP::UserAgent';
requires 'sane';
requires 'JSON';
requires 'Config::PP';
requires 'OAuth::Lite';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More'  => 0.98;

install_script 'bin/autoreblog.pl';

auto_set_repository;
auto_include;
WriteAll;
