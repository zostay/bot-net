# vim: set ft=perl :

use strict;
use warnings;

use Test::More;
eval "use Test::Pod";
plan skip_all => "Test::POD required for testing POD" if $@;
all_pod_files_ok();
