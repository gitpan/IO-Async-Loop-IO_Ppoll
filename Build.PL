use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new
  (
   module_name => 'IO::Async::Loop::IO_Ppoll',
   requires => {
                 'IO::Async::Loop' => 0.20,
                 'IO::Ppoll' => 0.05,
               },
   build_requires => {
                 'Test::More' => 0,
                 'Test::Exception' => 0,
                 'Time::HiRes' => 0,
               },
   license => 'perl',
   create_makefile_pl => 'traditional',
  );
  
$build->create_build_script;
