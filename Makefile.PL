
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Break tasks into labeld units of work that are trackable across hosts and helper systems.',
  'AUTHOR' => 'Mark Swayne <daotoad@cpan.org>',
  'BUILD_REQUIRES' => {
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'Log-Work',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Log::Work',
  'PREREQ_PM' => {
    'Carp' => '0',
    'Exporter' => '0',
    'Log::Lager' => '0',
    'Log::Lager::Message' => '0',
    'Scalar::Util' => '0',
    'Socket' => '0',
    'Sys::Hostname' => '0',
    'Time::HiRes' => '0'
  },
  'VERSION' => '0.02.02',
  'test' => {
    'TESTS' => 't/*.t'
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



