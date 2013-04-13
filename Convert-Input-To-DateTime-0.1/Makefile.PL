
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Upload and email photo(s) demo using ssmpt and Hotmail",
  "AUTHOR" => "Austin Kenny <aibistin.cionnaith\@gmail.com>",
  "BUILD_REQUIRES" => {
    "Dancer::Test" => 0,
    "ExtUtils::MakeMaker" => 0,
    "File::Find" => 0,
    "File::Spec::Functions" => 0,
    "File::Temp" => 0,
    "List::Util" => 0,
    "Test::More" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Convert-Input-To-DateTime",
  "EXE_FILES" => [
    "bin/app.pl"
  ],
  "LICENSE" => "perl",
  "NAME" => "Convert::Input::To::DateTime",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Dancer2" => 0,
    "Dancer2::Core::Error" => 0,
    "Data::Dump" => 0,
    "Email::Sender::Simple" => 0,
    "Email::Sender::Transport::SMTP::TLS" => 0,
    "Email::Valid" => 0,
    "File::LibMagic" => 0,
    "IO::All" => 0,
    "MIME::Entity" => 0,
    "Template" => 0,
    "Try::Tiny" => 0
  },
  "VERSION" => "0.1",
  "test" => {
    "TESTS" => "t/*.t"
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



