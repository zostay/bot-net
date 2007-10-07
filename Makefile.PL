use inc::Module::Install;

name     'Bot-Net';
all_from 'lib/Bot/Net.pm';

requires 'App::CLI';
requires 'App::CLI::Command';
requires 'App::CLI::Command::Help';
requires 'Class::Accessor::Fast';
requires 'Class::Data::Inheritable';
requires 'Class::Trigger';
requires 'Data::Remember'           => 0.04;
requires 'File::Find::Rule';
requires 'Hash::Merge';
requires 'Log::Log4perl';
requires 'POE';
requires 'POE::Declarative'         => 0.004;
requires 'POE::Declarative::Mixin';
requires 'Readonly';
requires 'Regexp::Common';
requires 'UNIVERSAL::require';
requires 'YAML::Syck';

auto_install;
WriteMakefile;
